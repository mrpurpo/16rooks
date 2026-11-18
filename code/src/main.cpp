// swapcore: performance-critical core of the row-swap research tool.
//
//   swapcore solve     --files F --ranks R --dirs "df,dr;..." --slides 0|1 [options]
//   swapcore construct --files F --ranks R --dirs ... --slides ... [options]
//
// Progress goes to stderr; the final result is ONE JSON object on stdout,
// consumed by the Python CLI (swaprows.py).
#include "core.hpp"
#include "solve.hpp"
#include "construct.hpp"

#include <iostream>

namespace {

struct Args {
    std::string mode;
    int F = 0, R = 0;
    std::string dirs;
    bool slides = false;
    SolveOptions so;
    ConstructOptions co;
    bool force = false;
    double max_positions = 1e8;
};

[[noreturn]] void usage(const std::string& msg) {
    std::cout << "{\"status\":\"error\",\"message\":\"" << json_escape(msg) << "\"}\n";
    std::exit(2);
}

Args parse(int argc, char** argv) {
    Args a;
    if (argc < 2) usage("missing mode (solve|construct)");
    a.mode = argv[1];
    for (int i = 2; i < argc; i++) {
        std::string k = argv[i];
        auto val = [&]() -> std::string {
            if (i + 1 >= argc) usage("missing value for " + k);
            return argv[++i];
        };
        if (k == "--files") a.F = std::stoi(val());
        else if (k == "--ranks") a.R = std::stoi(val());
        else if (k == "--dirs") a.dirs = val();
        else if (k == "--slides") a.slides = val() == "1";
        else if (k == "--print-solution") a.so.print_solution = true;
        else if (k == "--count") a.so.count = true;
        else if (k == "--alternate") a.so.alternate = true;
        else if (k == "--first") {
            std::string v = val();
            a.so.first = v == "white" ? 0 : v == "black" ? 1 : 2;
        }
        else if (k == "--timeout") a.so.timeout = a.co.timeout = std::stod(val());
        else if (k == "--quiet") a.so.quiet = a.co.quiet = true;
        else if (k == "--force") a.force = true;
        else if (k == "--max-positions") a.max_positions = std::stod(val());
        else if (k == "--threads") {
#ifdef _OPENMP
            omp_set_num_threads(std::stoi(val()));
#else
            val();
#endif
        }
        else if (k == "--tight") a.co.tight = true;
        else if (k == "--slack") a.co.slack = std::stoi(val());
        else if (k == "--start-slack") a.co.start_slack = std::stoi(val());
        else if (k == "--symmetric") a.co.symmetric = true;
        else if (k == "--seed") a.co.seed = std::stoull(val());
        else if (k == "--node-limit") a.co.node_limit = std::stoull(val());
        else usage("unknown option " + k);
    }
    if (a.F < 1 || a.R < 2 || a.F * a.R > 64) usage("need F >= 1, R >= 2, F*R <= 64");
    return a;
}

Board make_board(const Args& a) {
    Board B;
    B.F = a.F; B.R = a.R; B.slides = a.slides;
    std::stringstream ss(a.dirs);
    std::string item;
    while (std::getline(ss, item, ';')) {
        if (item.empty()) continue;
        auto c = item.find(',');
        if (c == std::string::npos) usage("bad direction " + item);
        B.dirs.push_back({std::stoi(item.substr(0, c)), std::stoi(item.substr(c + 1))});
    }
    if (B.dirs.empty()) usage("no directions");
    for (auto [df, dr] : B.dirs)
        if (std::find(B.dirs.begin(), B.dirs.end(), std::make_pair(-df, -dr)) == B.dirs.end())
            usage("direction set not closed under negation (moves not reversible)");
    B.build();
    return B;
}

std::string moves_json(const Board& B, const std::vector<std::pair<int, int>>& mv) {
    std::string s = "[";
    for (size_t i = 0; i < mv.size(); i++) {
        if (i) s += ",";
        s += "\"" + B.name(mv[i].first) + "-" + B.name(mv[i].second) + "\"";
    }
    return s + "]";
}

std::string squares_json(const Board& B, const std::vector<int>& sq) {
    std::string s = "[";
    for (size_t i = 0; i < sq.size(); i++) {
        if (i) s += ",";
        s += "\"" + B.name(sq[i]) + "\"";
    }
    return s + "]";
}

// A symmetry of the whole problem: square map + its name.
struct Sym {
    std::string name;
    std::function<int(int)> map;
};

std::vector<Sym> problem_symmetries(const Board& B) {
    std::vector<Sym> out;
    if (B.dirs_invariant(-1, 1)) out.push_back({"mirror", [&B](int s) { return B.mirror(s); }});
    if (B.dirs_invariant(1, -1)) out.push_back({"flip+colour-swap", [&B](int s) { return B.flipv(s); }});
    out.push_back({"rot180+colour-swap", [&B](int s) { return B.rot180(s); }});  // reversible
    return out;
}

struct CompOut {
    std::vector<int> squares;  // global
    int k = 0;
    std::string status;        // solved | impossible | trivial
    std::string reason;
    int min = -1;
    std::string count;
    bool overflow = false;
    std::vector<std::pair<int, int>> moves;  // global
    std::string reused;                      // "component i via <sym>"
    unsigned long long positions = 0;
    long double estimate = 0;
};

template <class Fn>
CompResult dispatch_key(const Problem& P, bool alternate, Fn&& fn64_128) {
    int need = P.n + (alternate ? 1 : 0);
    if (need <= 32) return fn64_128((u64)0, P);
    return fn64_128((u128)0, P);
}

std::string comp_json(const Board& B, const CompOut& c) {
    std::ostringstream o;
    o << "{\"squares\":" << squares_json(B, c.squares) << ",\"pieces_per_colour\":" << c.k
      << ",\"status\":\"" << c.status << "\"";
    if (!c.reason.empty()) o << ",\"reason\":\"" << json_escape(c.reason) << "\"";
    if (c.min >= 0) o << ",\"min\":" << c.min;
    if (!c.count.empty()) o << ",\"count\":\"" << c.count << "\"";
    if (c.overflow) o << ",\"count_overflow\":true";
    if (!c.reused.empty()) o << ",\"reused\":\"" << json_escape(c.reused) << "\"";
    o << ",\"positions\":" << c.positions << ",\"estimate\":" << (double)c.estimate;
    o << ",\"moves\":" << moves_json(B, c.moves) << "}";
    return o.str();
}

int run_solve(const Args& a, const Board& B) {
    SolveOptions so = a.so;
    double avail = available_memory_bytes();
    so.mem_limit = avail > 0 ? 0.85 * avail : 0;
    if (so.alternate && (so.count || so.print_solution))
        usage("--count/--print-solution are not supported together with --alternate");

    // Decompose into independent components (not valid with alternating turns:
    // the turn order couples the components, so then we solve the whole board).
    std::vector<std::vector<int>> comps;
    auto all = components(B);
    if (so.alternate) {
        for (auto& c : all) {  // impossibility per component is still valid
            Problem P; P.build(B, c);
            if (!P.feasible_counts()) {
                std::string why = "component " + squares_json(B, c) +
                                  " has different numbers of rank-1 and rank-R squares";
                std::cout << "{\"status\":\"impossible\",\"reason\":\"" << json_escape(why)
                          << "\",\"components\":[]}\n";
                return 0;
            }
        }
        std::vector<int> whole(B.N);
        std::iota(whole.begin(), whole.end(), 0);
        comps.push_back(whole);
    } else {
        comps = all;
    }

    std::vector<CompOut> outs;
    std::vector<Problem> probs;
    for (auto& c : comps) {
        Problem P; P.build(B, c);
        if (P.k == 0 && popcount64(P.startB) == 0) continue;  // no pieces
        CompOut co; co.squares = c; co.k = P.k;
        co.estimate = binom(P.n, P.k) * binom(P.n - P.k, popcount64(P.startB)) * (so.alternate ? 2 : 1);
        outs.push_back(co);
        probs.push_back(P);
    }
    auto syms = problem_symmetries(B);

    // Safety check (only for the components that will actually be searched).
    std::vector<int> reuse_of(outs.size(), -1);
    std::vector<std::string> reuse_sym(outs.size());
    for (size_t i = 0; i < outs.size() && !so.alternate; i++) {
        for (size_t j = 0; j < i && reuse_of[i] < 0; j++) {
            if (reuse_of[j] >= 0) continue;
            for (auto& sy : syms) {
                std::vector<int> img;
                for (int s : outs[i].squares) img.push_back(sy.map(s));
                std::sort(img.begin(), img.end());
                if (img == outs[j].squares) { reuse_of[i] = (int)j; reuse_sym[i] = sy.name; break; }
            }
        }
    }
    for (size_t i = 0; i < outs.size(); i++) {
        if (reuse_of[i] >= 0 || !probs[i].feasible_counts()) continue;
        long double est = outs[i].estimate;
        double bytes = (double)est * (probs[i].n + (so.alternate ? 1 : 0) <= 32 ? 8 : 16) *
                       (so.count ? 3.0 : 1.0);
        bool too_many = est > a.max_positions;
        bool too_big = so.mem_limit > 0 && bytes > so.mem_limit;
        if ((too_many || too_big) && !a.force) {
            std::ostringstream m;
            m << "refusing to run: the state space of component " << i + 1 << " has up to "
              << (double)est << " positions (C(N,k)*C(N-k,k) with N=" << probs[i].n
              << ", k=" << probs[i].k << "), needing up to ~" << bytes / 1e9
              << " GB; limits: " << a.max_positions << " positions, " << so.mem_limit / 1e9
              << " GB available.  Use `construct` mode for large boards, or pass --force "
                 "(meet in the middle usually visits far fewer positions).";
            std::cout << "{\"status\":\"refused\",\"message\":\"" << json_escape(m.str()) << "\"}\n";
            return 3;
        }
    }

    Ctx ctx;
    ctx.opt = &so;
    try {
        for (size_t i = 0; i < outs.size(); i++) {
            auto& co = outs[i];
            const Problem& P = probs[i];
            if (!P.feasible_counts()) {
                co.status = "impossible";
                co.reason = "the component has " + std::to_string(popcount64(P.startW)) +
                            " squares on rank 1 but " + std::to_string(popcount64(P.startB)) +
                            " on rank R, so the pieces cannot be exchanged inside it";
                continue;
            }
            if (reuse_of[i] >= 0) {
                const auto& src = outs[reuse_of[i]];
                co.status = src.status; co.min = src.min; co.count = src.count;
                co.overflow = src.overflow; co.reason = src.reason;
                co.reused = "component " + std::to_string(reuse_of[i] + 1) + " via " + reuse_sym[i];
                for (auto& sy : syms)
                    if (sy.name == reuse_sym[i])
                        for (auto [s, d] : src.moves) co.moves.push_back({sy.map(s), sy.map(d)});
                if (!so.quiet)
                    std::fprintf(stderr, "[component %zu/%zu] symmetric image of component %d (%s): reused\n",
                                 i + 1, outs.size(), reuse_of[i] + 1, reuse_sym[i].c_str());
                continue;
            }
            ctx.label = outs.size() > 1 ? "[component " + std::to_string(i + 1) + "/" +
                                              std::to_string(outs.size()) + "] " : "";
            CompResult r = dispatch_key(P, so.alternate, [&](auto zero, const Problem& PP) {
                using K = decltype(zero);
                if (so.alternate) return solve_alternate<K>(PP, ctx);
                if (so.count) {
                    CompResult c = count_bfs<K>(PP, ctx);
                    if (so.print_solution && c.status == "solved") {
                        CompResult m = solve_bfs<K>(PP, ctx);
                        c.moves = m.moves;
                    }
                    return c;
                }
                return solve_bfs<K>(PP, ctx);
            });
            co.status = r.status; co.min = r.min; co.count = r.count; co.overflow = r.count_overflow;
            co.positions = r.positions;
            if (r.status == "impossible")
                co.reason = "BFS exhausted all reachable positions without meeting the goal";
            for (auto [s, d] : r.moves) co.moves.push_back({P.global[s], P.global[d]});
        }
    } catch (TimeoutError&) {
        std::cout << "{\"status\":\"timeout\",\"message\":\"timeout after " << ctx.clock.elapsed()
                  << " s\"}\n";
        return 4;
    } catch (MemoryError& e) {
        std::cout << "{\"status\":\"memory\",\"message\":\"" << json_escape(e.what()) << "\"}\n";
        return 5;
    }

    bool impossible = false;
    int total = 0;
    for (auto& c : outs) {
        if (c.status != "solved") impossible = true;
        else total += c.min;
    }
    std::ostringstream o;
    o << "{\"status\":\"" << (impossible ? "impossible" : "solved") << "\"";
    if (!impossible) o << ",\"min\":" << total;
    o << ",\"elapsed\":" << ctx.clock.elapsed() << ",\"components\":[";
    for (size_t i = 0; i < outs.size(); i++) o << (i ? "," : "") << comp_json(B, outs[i]);
    o << "]}\n";
    std::cout << o.str();
    return 0;
}

}  // namespace

int main(int argc, char** argv) {
    Args a = parse(argc, argv);
    Board B = make_board(a);
    try {
        if (a.mode == "solve") return run_solve(a, B);
        if (a.mode == "construct") return run_construct(a.co, B);
    } catch (std::exception& e) {
        usage(std::string("internal error: ") + e.what());
    }
    usage("unknown mode " + a.mode);
}
