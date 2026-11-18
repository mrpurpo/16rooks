// Heuristic construction for large boards: IDA* with the admissible heuristic
//   h = sum over pieces of the empty-board distance to the nearest square of
//       the piece's target rank,
// a transposition table of dead positions, randomized move ordering and
// restarts.  See README.md ("construct").
#pragma once

#include <random>
#include <unordered_map>

#include <iostream>

#include "core.hpp"

struct ConstructOptions {
    bool tight = false, symmetric = false, quiet = false;
    int start_slack = 0;  // first slack (threshold h0 + start_slack) to try
    int slack = -1;  // tight: extra slack allowed (default 0); otherwise max slack (-1 = unbounded)
    double timeout = 0;
    unsigned long long seed = 1, node_limit = 0;
};

struct PosKey {
    u64 w, b;
    bool operator==(const PosKey& o) const { return w == o.w && b == o.b; }
};
struct PosHash {
    size_t operator()(const PosKey& k) const {
        u64 x = k.w * 0x9E3779B97F4A7C15ULL ^ (k.b + 0x632BE59BD9B4E019ULL + (k.w << 6) + (k.w >> 2));
        x ^= x >> 31; x *= 0xBF58476D1CE4E5B9ULL; x ^= x >> 29;
        return (size_t)x;
    }
};

struct ConstructResult {
    std::string status;      // found | no-solution | timeout | impossible
    int lower = -1;          // h(start)
    int length = -1;
    int slack_used = -1;
    int proved_no_slack_below = -1;  // all slacks < this were exhausted (proved no solution)
    std::vector<std::pair<int, int>> moves;  // global squares
    unsigned long long nodes = 0;
    int restarts = 0;
    bool symmetric = false;
};

class Constructor {
public:
    Constructor(const Board& B, const Problem& full, const std::vector<int>& comp,
                const ConstructOptions& o, const Clock& clock)
        : B_(B), P_(full), o_(o), clock_(clock) {
        const int INF = 1 << 20;
        distW_.assign(B.N, INF);
        distB_.assign(B.N, INF);
        bfs_dist(distW_, B.R - 1);
        bfs_dist(distB_, 0);
        for (int s : comp) {
            int r = s / B.F;
            if (r == 0) startW_ |= 1ULL << s;
            if (r == B.R - 1) startB_ |= 1ULL << s;
        }
        rot_ok_ = true;
        for (int s : comp) {
            if (std::find(comp.begin(), comp.end(), B.rot180(s)) == comp.end()) rot_ok_ = false;
        }
    }

    ConstructResult run() {
        ConstructResult res;
        int h0 = h(startW_, startB_);
        res.lower = h0;
        if (h0 >= (1 << 19)) { res.status = "impossible"; return res; }
        sym_ = o_.symmetric && rot_ok_;
        res.symmetric = sym_;
        int maxslack = o_.tight ? std::max({0, o_.slack, o_.start_slack}) : (o_.slack < 0 ? 1 << 20 : o_.slack);
        res.proved_no_slack_below = 0;  // only counts exhausted slacks from 0 upward
        if (o_.start_slack > 0) res.proved_no_slack_below = -1;
        unsigned long long limit = o_.node_limit ? o_.node_limit : 200000;
        rng_.seed(o_.seed);
        for (int slack = o_.start_slack; slack <= maxslack; slack++) {
            if (sym_ && slack % 2) {  // symmetric pairs always use an even amount of slack
                if (res.proved_no_slack_below == slack) res.proved_no_slack_below = slack + 1;
                continue;
            }
            T_ = h0 + slack;
            unsigned long long lim = limit;
            for (;;) {
                if (o_.timeout > 0 && clock_.elapsed() > o_.timeout) {
                    res.status = "timeout"; res.nodes = total_nodes_;
                    if (sym_) res.proved_no_slack_below = -1;
                    return res;
                }
                nodes_ = 0; budget_ = lim; aborted_ = false; path_.clear();
                bool found = dfs(startW_, startB_, slack);
                total_nodes_ += nodes_;
                if (found) {
                    // Exhausting a slack level in symmetric mode only rules out
                    // SYMMETRIC solutions, so it proves nothing in general.
                    if (sym_) res.proved_no_slack_below = -1;
                    std::reverse(path_.begin(), path_.end());
                    res.status = "found";
                    res.moves = path_;
                    res.length = (int)path_.size();
                    res.slack_used = slack;
                    res.nodes = total_nodes_;
                    res.restarts = restarts_;
                    return res;
                }
                if (!aborted_) break;  // exhaustive: no solution with this slack
                restarts_++;
                lim = lim + lim / 2;
                if (!o_.quiet && restarts_ % 10 == 0)
                    std::fprintf(stderr, "  slack %d: %d restarts, %llu nodes, %zu dead positions  [%.1fs]\n",
                                 slack, restarts_, total_nodes_, dead_.size(), clock_.elapsed());
            }
            if (res.proved_no_slack_below == slack) res.proved_no_slack_below = slack + 1;
            if (!o_.quiet)
                std::fprintf(stderr, "  no %ssolution of length %d (slack %d) exists -- search exhausted  [%.1fs]\n",
                             sym_ ? "symmetric " : "", h0 + slack, slack, clock_.elapsed());
        }
        res.status = "no-solution";
        if (sym_) res.proved_no_slack_below = -1;
        res.nodes = total_nodes_;
        res.restarts = restarts_;
        return res;
    }

private:
    const Board& B_;
    const Problem& P_;  // whole board, local == global
    const ConstructOptions& o_;
    const Clock& clock_;
    std::vector<int> distW_, distB_;
    u64 startW_ = 0, startB_ = 0;
    bool rot_ok_ = false, sym_ = false;
    int T_ = 0;
    unsigned long long nodes_ = 0, budget_ = 0, total_nodes_ = 0;
    int restarts_ = 0;
    bool aborted_ = false;
    std::mt19937_64 rng_;
    std::unordered_map<PosKey, int, PosHash> dead_;  // position -> largest slack proven insufficient
    std::vector<std::pair<int, int>> path_;          // moves, filled in reverse on success
    static constexpr size_t kMaxDead = 30000000;     // memory cap for the dead table

    void bfs_dist(std::vector<int>& d, int rank) {
        std::vector<int> q;
        for (int f = 0; f < B_.F; f++) { d[B_.sq(f, rank)] = 0; q.push_back(B_.sq(f, rank)); }
        for (size_t i = 0; i < q.size(); i++) {
            int s = q[i];
            for (auto& ray : B_.rays[s])
                for (int t : ray)
                    if (d[t] > d[s] + 1) { d[t] = d[s] + 1; q.push_back(t); }
        }
    }
    int h(u64 w, u64 b) const {
        int s = 0;
        for (; w; w &= w - 1) s += distW_[ctz64(w)];
        for (; b; b &= b - 1) s += distB_[ctz64(b)];
        return s;
    }

    struct Cand { int s, t, cost; uint64_t r; };

    void gen(u64 w, u64 b, int side, int rs, std::vector<Cand>& out) {
        u64 occ = w | b, mine = side == 0 ? w : b;
        const auto& dist = side == 0 ? distW_ : distB_;
        int mult = sym_ ? 2 : 1;
        for (u64 m = mine; m; m &= m - 1) {
            int s = ctz64(m);
            for (int r = P_.rayBeg[s]; r < P_.rayBeg[s + 1]; r++)
                for (int i = P_.off[r]; i < P_.off[r + 1]; i++) {
                    int t = P_.raysq[i];
                    if (occ >> t & 1) break;
                    int cost = (1 + dist[t] - dist[s]) * mult;
                    if (cost <= rs) out.push_back({s, t, cost, rng_()});
                }
        }
    }
    static bool legal(const Problem& P, u64 occ, int s, int t) {
        for (int r = P.rayBeg[s]; r < P.rayBeg[s + 1]; r++)
            for (int i = P.off[r]; i < P.off[r + 1]; i++) {
                int x = P.raysq[i];
                if (occ >> x & 1) break;
                if (x == t) return true;
            }
        return false;
    }

    // rs = remaining slack = T - g - h(w,b)
    bool dfs(u64 w, u64 b, int rs) {
        if (w == startB_ && b == startW_) return true;
        if (++nodes_ > budget_) { aborted_ = true; return false; }
        if ((nodes_ & 0xFFFF) == 0 && o_.timeout > 0 && clock_.elapsed() > o_.timeout) {
            aborted_ = true; return false;
        }
        std::vector<Cand> c;
        gen(w, b, 0, rs, c);
        if (!sym_) gen(w, b, 1, rs, c);
        std::sort(c.begin(), c.end(), [](const Cand& x, const Cand& y) {
            return x.cost != y.cost ? x.cost < y.cost : x.r < y.r;
        });
        for (auto& m : c) {
            bool isw = (w >> m.s) & 1;
            u64 nw = w, nb = b;
            if (isw) nw ^= (1ULL << m.s) | (1ULL << m.t);
            else nb ^= (1ULL << m.s) | (1ULL << m.t);
            int bs = -1, bt = -1;
            if (sym_) {  // paired black move: 180-degree image of the white move
                bs = B_.rot180(m.s); bt = B_.rot180(m.t);
                if (!(nb >> bs & 1) || !legal(P_, nw | nb, bs, bt)) continue;
                nb ^= (1ULL << bs) | (1ULL << bt);
            }
            int nrs = rs - m.cost;
            auto it = dead_.find({nw, nb});
            if (it != dead_.end() && it->second >= nrs) continue;
            if (dfs(nw, nb, nrs)) {
                if (sym_) path_.push_back({bs, bt});
                path_.push_back({m.s, m.t});
                return true;
            }
            if (aborted_) return false;
        }
        // Exhaustive failure (no abort below us): a fact independent of the path.
        if (dead_.size() > kMaxDead) dead_.clear();
        auto ins = dead_.try_emplace(PosKey{w, b}, rs);
        if (!ins.second) ins.first->second = std::max(ins.first->second, rs);
        return false;
    }
};

inline int run_construct(const ConstructOptions& o, const Board& B) {
    Clock clock;
    std::vector<int> whole(B.N);
    std::iota(whole.begin(), whole.end(), 0);
    Problem full;
    full.build(B, whole);
    auto comps = components(B);

    struct Item { std::vector<int> sq; ConstructResult r; int reuse = -1; std::string sym; };
    std::vector<Item> items;
    for (auto& c : comps) {
        int nw = 0, nb = 0;
        for (int s : c) { nw += s / B.F == 0; nb += s / B.F == B.R - 1; }
        if (nw + nb == 0) continue;
        items.push_back({c, {}, -1, ""});
    }
    // symmetries of the problem, used to reuse a component's construction
    std::vector<std::pair<std::string, std::function<int(int)>>> syms;
    if (B.dirs_invariant(-1, 1)) syms.push_back({"mirror", [&B](int s) { return B.mirror(s); }});
    if (B.dirs_invariant(1, -1)) syms.push_back({"flip+colour-swap", [&B](int s) { return B.flipv(s); }});
    syms.push_back({"rot180+colour-swap", [&B](int s) { return B.rot180(s); }});

    bool all_found = true;
    std::string overall = "found";
    for (size_t i = 0; i < items.size(); i++) {
        auto& it = items[i];
        int nw = 0, nb = 0;
        for (int s : it.sq) { nw += s / B.F == 0; nb += s / B.F == B.R - 1; }
        if (nw != nb) { it.r.status = "impossible"; all_found = false; overall = "impossible"; continue; }
        for (size_t j = 0; j < i && it.reuse < 0; j++) {
            if (items[j].reuse >= 0 || items[j].r.status != "found") continue;
            for (auto& [name, f] : syms) {
                std::vector<int> img;
                for (int s : it.sq) img.push_back(f(s));
                std::sort(img.begin(), img.end());
                if (img == items[j].sq) {
                    it.reuse = (int)j; it.sym = name; it.r = items[j].r;
                    it.r.moves.clear();
                    for (auto [s, d] : items[j].r.moves) it.r.moves.push_back({f(s), f(d)});
                    break;
                }
            }
        }
        if (it.reuse >= 0) continue;
        if (!o.quiet)
            std::fprintf(stderr, "[component %zu/%zu] %zu squares: searching ...\n", i + 1, items.size(),
                         it.sq.size());
        Constructor C(B, full, it.sq, o, clock);
        it.r = C.run();
        if (!o.quiet)
            std::fprintf(stderr, "[component %zu/%zu] %s: lower bound %d, length %d, %llu nodes  [%.2fs]\n",
                         i + 1, items.size(), it.r.status.c_str(), it.r.lower, it.r.length, it.r.nodes,
                         clock.elapsed());
        if (it.r.status != "found") {
            all_found = false;
            if (overall == "found" || it.r.status == "impossible") overall = it.r.status;
        }
    }
    auto name = [&B](int s) { return B.name(s); };
    std::ostringstream out;
    int total = 0, lower = 0;
    for (auto& it : items) { total += std::max(0, it.r.length); lower += std::max(0, it.r.lower); }
    out << "{\"status\":\"" << overall << "\"";
    if (all_found) out << ",\"length\":" << total;
    out << ",\"lower_bound\":" << lower << ",\"elapsed\":" << clock.elapsed() << ",\"components\":[";
    for (size_t i = 0; i < items.size(); i++) {
        auto& it = items[i];
        out << (i ? "," : "") << "{\"squares\":[";
        for (size_t j = 0; j < it.sq.size(); j++) out << (j ? "," : "") << "\"" << name(it.sq[j]) << "\"";
        out << "],\"status\":\"" << it.r.status << "\",\"lower_bound\":" << it.r.lower
            << ",\"length\":" << it.r.length << ",\"slack_used\":" << it.r.slack_used
            << ",\"proved_no_slack_below\":" << it.r.proved_no_slack_below
            << ",\"nodes\":" << it.r.nodes << ",\"restarts\":" << it.r.restarts
            << ",\"symmetric\":" << (it.r.symmetric ? "true" : "false");
        if (it.reuse >= 0) out << ",\"reused\":\"component " << it.reuse + 1 << " via " << it.sym << "\"";
        out << ",\"moves\":[";
        for (size_t j = 0; j < it.r.moves.size(); j++)
            out << (j ? "," : "") << "\"" << name(it.r.moves[j].first) << "-" << name(it.r.moves[j].second) << "\"";
        out << "]}";
    }
    out << "]}\n";
    std::cout << out.str();
    return 0;
}
