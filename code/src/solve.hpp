// Exact solver: layered BFS + meet in the middle via the colour-swap symmetry.
// See README.md ("solve") for the correctness argument.
#pragma once

#include "core.hpp"

#ifdef _OPENMP
#include <parallel/algorithm>
#endif

struct SolveOptions {
    bool print_solution = false;
    bool count = false;
    bool alternate = false;
    int first = 2;             // alternate: 0 = white first, 1 = black first, 2 = either
    double timeout = 0;        // seconds, 0 = none
    bool quiet = false;
    double mem_limit = 0;      // bytes; abort if the stored layers exceed it
    size_t buffer_keys = size_t(1) << 25;
};

struct Ctx {
    Clock clock;
    const SolveOptions* opt = nullptr;
    std::string label;
    void check_time() const {
        if (opt->timeout > 0 && clock.elapsed() > opt->timeout) throw TimeoutError();
    }
    void progress(const char* fmt, ...) const __attribute__((format(printf, 2, 3)));
};

#include <cstdarg>
inline void Ctx::progress(const char* fmt, ...) const {
    if (opt->quiet) return;
    std::fprintf(stderr, "%s", label.c_str());
    va_list ap;
    va_start(ap, fmt);
    std::vfprintf(stderr, fmt, ap);
    va_end(ap);
    std::fprintf(stderr, "  [%.2fs]\n", clock.elapsed());
    std::fflush(stderr);
}

struct CompResult {
    std::string status = "impossible";  // solved | impossible
    int min = -1;
    std::string count;                  // decimal, "" if not counted
    bool count_overflow = false;
    std::vector<std::pair<int, int>> moves;  // local squares
    unsigned long long positions = 0;        // total positions stored over all layers
    int layers = 0;
};

// ---------------------------------------------------------------------------
// Sorted-vector helpers
// ---------------------------------------------------------------------------

template <class T>
inline void psort(std::vector<T>& v) {
#ifdef _OPENMP
    if (v.size() > (1u << 16)) { __gnu_parallel::sort(v.begin(), v.end()); return; }
#endif
    std::sort(v.begin(), v.end());
}

template <class K>
inline bool contains(const std::vector<K>& v, K x) {
    return std::binary_search(v.begin(), v.end(), x);
}

// Sorted, de-duplicated neighbours of `layer` that are in none of `excl`.
// Neighbours are generated in slices (bounded buffer), and each slice is
// sorted, de-duplicated, filtered and merged into the result.
template <class K>
std::vector<K> expand(const Problem& P, const std::vector<K>& layer,
                      const std::vector<const std::vector<K>*>& excl, bool alternate,
                      const Ctx& ctx) {
    int maxdeg = 0;
    for (int s = 0; s < P.n; s++) maxdeg = std::max(maxdeg, P.off[P.rayBeg[s + 1]] - P.off[P.rayBeg[s]]);
    size_t branch = std::max<size_t>(1, size_t(2 * P.k) * maxdeg);
    size_t slice = std::max<size_t>(256, ctx.opt->buffer_keys / branch);

    std::vector<K> next, buf, tmp;
    int nthreads = 1;
#ifdef _OPENMP
    nthreads = omp_get_max_threads();
#endif
    std::vector<std::vector<K>> local(nthreads);
    for (size_t lo = 0; lo < layer.size(); lo += slice) {
        ctx.check_time();
        size_t hi = std::min(layer.size(), lo + slice);
#pragma omp parallel
        {
            int tid = 0;
#ifdef _OPENMP
            tid = omp_get_thread_num();
#endif
            auto& out = local[tid];
            out.clear();
#pragma omp for schedule(dynamic, 1024)
            for (size_t i = lo; i < hi; i++)
                for_neighbors<K>(P, layer[i], alternate, [&](K y, int, int) { out.push_back(y); });
            std::sort(out.begin(), out.end());
            out.erase(std::unique(out.begin(), out.end()), out.end());
        }
        buf.clear();
        for (auto& v : local) buf.insert(buf.end(), v.begin(), v.end());
        psort(buf);
        buf.erase(std::unique(buf.begin(), buf.end()), buf.end());
        // filter out positions of the excluded layers
        std::vector<char> keep(buf.size());
#pragma omp parallel for schedule(static)
        for (size_t i = 0; i < buf.size(); i++) {
            bool k = true;
            for (auto* e : excl) if (contains(*e, buf[i])) { k = false; break; }
            keep[i] = k;
        }
        size_t w = 0;
        for (size_t i = 0; i < buf.size(); i++) if (keep[i]) buf[w++] = buf[i];
        buf.resize(w);
        if (next.empty()) { next.swap(buf); continue; }
        tmp.resize(next.size() + buf.size());
        auto end = std::set_union(next.begin(), next.end(), buf.begin(), buf.end(), tmp.begin());
        tmp.resize(end - tmp.begin());
        next.swap(tmp);
        tmp.clear(); tmp.shrink_to_fit();
    }
    for (auto& v : local) { v.clear(); v.shrink_to_fit(); }
    return next;
}

template <class K>
void check_memory(const std::vector<std::vector<K>>& L, const Ctx& ctx, size_t extra_bytes = 0) {
    double bytes = double(extra_bytes);
    for (auto& v : L) bytes += double(v.capacity()) * sizeof(K);
    if (ctx.opt->mem_limit > 0 && bytes > ctx.opt->mem_limit)
        throw MemoryError("memory limit exceeded (" + std::to_string(bytes / 1e9) +
                          " GB stored); use `construct` mode or a smaller board");
}

// Path start -> x through layers L[0..k] (x in L[k]); positions in order.
template <class K>
std::vector<K> backtrack(const Problem& P, const std::vector<std::vector<K>>& L, K x, int k,
                         bool alternate) {
    std::vector<K> path{x};
    K c = x;
    for (int i = k; i > 0; i--) {
        bool found = false;
        K nxt{};
        for_neighbors<K>(P, c, alternate, [&](K y, int, int) {
            if (!found && contains(L[i - 1], y)) { nxt = y; found = true; }
        });
        if (!found) throw std::logic_error("backtrack failed");
        c = nxt;
        path.push_back(c);
    }
    std::reverse(path.begin(), path.end());
    return path;
}

// ---------------------------------------------------------------------------
// Non-alternating exact solve (minimum only, optional reconstruction).
//
// Moves are reversible, so the move graph is undirected and BFS layer k+1 is
// N(L_k) \ (L_k u L_{k-1}).  dist(x, goal) = dist(swap(x), start) because the
// colour swap maps the start to the goal and moves to moves.  At layer k:
//   x in L_k and swap(x) in L_{k-1}  =>  a path of length 2k-1 exists,
//   x in L_k and swap(x) in L_k      =>  a path of length 2k exists,
// and the midpoint of an optimal path of length n is detected exactly at
// layer ceil(n/2), so the first layer with a hit gives the exact minimum.
// ---------------------------------------------------------------------------
template <class K>
CompResult solve_bfs(const Problem& P, const Ctx& ctx) {
    using O = KeyOps<K>;
    const SolveOptions& o = *ctx.opt;
    bool keep = o.print_solution;
    CompResult res;
    std::vector<std::vector<K>> L;
    L.push_back({O::pack(P.startW, P.startB)});
    res.positions = 1;
    ctx.progress("layer 0: 1 position");
    for (int k = 0;; k++) {
        ctx.check_time();
        if (k >= 1) {
            const auto& cur = L[k];
            const auto& prev = L[k - 1];
            long long odd = -1, even = -1;
#pragma omp parallel for schedule(static)
            for (size_t i = 0; i < cur.size(); i++) {
                K y = O::swap(cur[i]);
                if (contains(prev, y)) {
#pragma omp critical
                    if (odd < 0 || (long long)i < odd) odd = (long long)i;
                } else if (contains(cur, y)) {
#pragma omp critical
                    if (even < 0 || (long long)i < even) even = (long long)i;
                }
            }
            if (odd >= 0 || even >= 0) {
                bool isodd = odd >= 0;
                res.status = "solved";
                res.min = isodd ? 2 * k - 1 : 2 * k;
                res.layers = k;
                if (keep) {
                    K x = cur[isodd ? odd : even];
                    K y = O::swap(x);
                    auto a = backtrack<K>(P, L, x, k, false);
                    auto b = backtrack<K>(P, L, y, isodd ? k - 1 : k, false);
                    std::vector<K> full = a;
                    for (int i = (int)b.size() - 2; i >= 0; i--) full.push_back(O::swap(b[i]));
                    for (size_t i = 0; i + 1 < full.size(); i++)
                        res.moves.push_back(move_between<K>(full[i], full[i + 1]));
                }
                return res;
            }
        }
        std::vector<const std::vector<K>*> excl{&L[k]};
        if (k >= 1) excl.push_back(&L[k - 1]);
        auto next = expand<K>(P, L[k], excl, false, ctx);
        if (next.empty()) {
            res.status = "impossible";
            res.layers = k;
            ctx.progress("layer %d is empty: the reachable component is exhausted", k + 1);
            return res;
        }
        res.positions += next.size();
        L.push_back(std::move(next));
        if (!keep && k >= 1) { std::vector<K>().swap(L[k - 1]); }
        check_memory(L, ctx);
        ctx.progress("layer %d: %zu positions", k + 1, L[k + 1].size());
    }
}

// ---------------------------------------------------------------------------
// Alternating turns.  The state carries the side to move; the state graph is
// directed (a move cannot be undone by the same side immediately), so BFS
// keeps the full visited set.  With D_s = distance from the start with side s
// to move, and swap' = colour swap keeping the turn bit, reversing a path and
// swapping colours gives
//     dist(x -> goal) = min_s D_s(swap'(x)).
// If either side may start, BFS from both seeds gives D = min_s D_s directly.
// If the first mover c is fixed, D_{1-c}(y) = D_c(sigma(y)) where sigma = 180
// degree rotation + colour swap + turn flip (it fixes the start position).
// The midpoint argument is the same as above.
// ---------------------------------------------------------------------------
inline u64 rot_mask(u64 m, int N) {
    u64 r = 0;
    for (; m; m &= m - 1) r |= 1ULL << (N - 1 - ctz64(m));
    return r;
}

template <class K>
CompResult solve_alternate(const Problem& P, const Ctx& ctx) {
    using O = KeyOps<K>;
    const SolveOptions& o = *ctx.opt;
    CompResult res;
    std::vector<K> seeds;
    K s0 = O::pack(P.startW, P.startB);
    if (o.first == 0 || o.first == 2) seeds.push_back(s0);
    if (o.first == 1 || o.first == 2) seeds.push_back(s0 | O::TURN);
    std::sort(seeds.begin(), seeds.end());
    auto sigma = [&](K y) {
        K t = (y & O::TURN) ^ O::TURN;
        return t | O::pack(rot_mask(O::Bm(y), P.n), rot_mask(O::W(y), P.n));
    };
    std::vector<std::vector<K>> L;  // L[0..k]; visited = union
    std::vector<K> visited = seeds;
    L.push_back(seeds);
    res.positions = seeds.size();
    ctx.progress("layer 0: %zu position(s)", seeds.size());
    for (int k = 0;; k++) {
        ctx.check_time();
        if (k >= 1) {
            const auto& cur = L[k];
            const auto& prev = L[k - 1];
            bool odd = false, even = false;
#pragma omp parallel for schedule(static) reduction(|| : odd, even)
            for (size_t i = 0; i < cur.size(); i++) {
                K y = O::swap(cur[i]);
                bool inprev = contains(prev, y), incur = contains(cur, y);
                if (o.first != 2) {
                    K z = sigma(y);
                    inprev = inprev || contains(prev, z);
                    incur = incur || contains(cur, z);
                }
                if (inprev) odd = true;
                else if (incur) even = true;
            }
            if (odd || even) {
                res.status = "solved";
                res.min = odd ? 2 * k - 1 : 2 * k;
                res.layers = k;
                return res;
            }
        }
        std::vector<const std::vector<K>*> excl{&visited};
        auto next = expand<K>(P, L[k], excl, true, ctx);
        if (next.empty()) {
            res.status = "impossible";
            res.layers = k;
            ctx.progress("layer %d is empty: the reachable states are exhausted", k + 1);
            return res;
        }
        std::vector<K> merged(visited.size() + next.size());
        std::merge(visited.begin(), visited.end(), next.begin(), next.end(), merged.begin());
        visited.swap(merged);
        std::vector<K>().swap(merged);
        res.positions += next.size();
        L.push_back(std::move(next));
        if (k >= 1) std::vector<K>().swap(L[k - 1]);
        check_memory(L, ctx, visited.capacity() * sizeof(K));
        ctx.progress("layer %d: %zu states (visited %zu)", k + 1, L[k + 1].size(), visited.size());
    }
}

// ---------------------------------------------------------------------------
// Counting optimal move sequences.
//
// c(x) = number of shortest paths start -> x, computed layer by layer:
// c(y) = sum of c(x) over neighbours x of y in the previous layer (two
// different moves from x always give different positions, so paths = move
// sequences).  By the colour-swap bijection the number of shortest paths
// x -> goal equals c(swap(x)).  Every optimal path of length n has a unique
// midpoint at index k = ceil(n/2), which lies in L_k with swap(x) in L_{n-k},
// so the total is  sum_{x in L_k, swap(x) in L_{n-k}} c(x) * c(swap(x)).
// Counts are 128-bit; overflow is detected and reported.
// ---------------------------------------------------------------------------
inline bool add_ovf(u128& a, u128 b) { return __builtin_add_overflow(a, b, &a); }

template <class K>
CompResult count_bfs(const Problem& P, const Ctx& ctx) {
    using O = KeyOps<K>;
    CompResult res;
    bool overflow = false;
    std::vector<std::vector<K>> L;      // keys per layer (only the last two kept)
    std::vector<std::vector<u128>> C;   // counts per layer
    L.push_back({O::pack(P.startW, P.startB)});
    C.push_back({1});
    res.positions = 1;
    ctx.progress("layer 0: 1 position");

    int maxdeg = 0;
    for (int s = 0; s < P.n; s++) maxdeg = std::max(maxdeg, P.off[P.rayBeg[s + 1]] - P.off[P.rayBeg[s]]);
    size_t branch = std::max<size_t>(1, size_t(2 * P.k) * maxdeg);
    size_t slice = std::max<size_t>(256, ctx.opt->buffer_keys / branch / 2);
    int nthreads = 1;
#ifdef _OPENMP
    nthreads = omp_get_max_threads();
#endif
    using E = std::pair<K, u128>;
    auto by_key = [](const E& a, const E& b) { return a.first < b.first; };

    for (int k = 0;; k++) {
        ctx.check_time();
        if (k >= 1) {
            const auto &cur = L[k], &prev = L[k - 1];
            const auto &cc = C[k], &cp = C[k - 1];
            u128 odd = 0, even = 0;
            bool hodd = false, heven = false;
            for (size_t i = 0; i < cur.size(); i++) {
                K y = O::swap(cur[i]);
                auto ip = std::lower_bound(prev.begin(), prev.end(), y);
                if (ip != prev.end() && *ip == y) {
                    u128 m;
                    if (__builtin_mul_overflow(cc[i], cp[ip - prev.begin()], &m) || add_ovf(odd, m)) overflow = true;
                    hodd = true;
                    continue;
                }
                auto ic = std::lower_bound(cur.begin(), cur.end(), y);
                if (ic != cur.end() && *ic == y) {
                    u128 m;
                    if (__builtin_mul_overflow(cc[i], cc[ic - cur.begin()], &m) || add_ovf(even, m)) overflow = true;
                    heven = true;
                }
            }
            if (hodd || heven) {
                res.status = "solved";
                res.min = hodd ? 2 * k - 1 : 2 * k;
                res.count = u128_to_string(hodd ? odd : even);
                res.count_overflow = overflow;
                res.layers = k;
                return res;
            }
        }
        // expand layer k with counts
        const auto& layer = L[k];
        const auto& lc = C[k];
        std::vector<E> next, buf, tmp;
        std::vector<std::vector<E>> local(nthreads);
        for (size_t lo = 0; lo < layer.size(); lo += slice) {
            ctx.check_time();
            size_t hi = std::min(layer.size(), lo + slice);
#pragma omp parallel
            {
                int tid = 0;
#ifdef _OPENMP
                tid = omp_get_thread_num();
#endif
                auto& out = local[tid];
                out.clear();
#pragma omp for schedule(dynamic, 1024)
                for (size_t i = lo; i < hi; i++)
                    for_neighbors<K>(P, layer[i], false, [&](K y, int, int) { out.push_back({y, lc[i]}); });
            }
            buf.clear();
            for (auto& v : local) buf.insert(buf.end(), v.begin(), v.end());
#ifdef _OPENMP
            if (buf.size() > (1u << 16)) __gnu_parallel::sort(buf.begin(), buf.end(), by_key);
            else
#endif
                std::sort(buf.begin(), buf.end(), by_key);
            // aggregate equal keys and drop positions of layers k, k-1
            size_t w = 0;
            for (size_t i = 0; i < buf.size();) {
                size_t j = i;
                u128 sum = 0;
                while (j < buf.size() && buf[j].first == buf[i].first) {
                    if (add_ovf(sum, buf[j].second)) overflow = true;
                    j++;
                }
                K y = buf[i].first;
                bool excluded = contains(L[k], y) || (k >= 1 && contains(L[k - 1], y));
                if (!excluded) buf[w++] = {y, sum};
                i = j;
            }
            buf.resize(w);
            // merge (summing equal keys) into next
            tmp.clear();
            tmp.reserve(next.size() + buf.size());
            size_t a = 0, b = 0;
            while (a < next.size() || b < buf.size()) {
                if (b == buf.size() || (a < next.size() && next[a].first < buf[b].first)) tmp.push_back(next[a++]);
                else if (a == next.size() || buf[b].first < next[a].first) tmp.push_back(buf[b++]);
                else {
                    E e = next[a++];
                    if (add_ovf(e.second, buf[b++].second)) overflow = true;
                    tmp.push_back(e);
                }
            }
            next.swap(tmp);
        }
        if (next.empty()) {
            res.status = "impossible";
            res.layers = k;
            ctx.progress("layer %d is empty: the reachable component is exhausted", k + 1);
            return res;
        }
        std::vector<K> nk(next.size());
        std::vector<u128> nc(next.size());
        for (size_t i = 0; i < next.size(); i++) { nk[i] = next[i].first; nc[i] = next[i].second; }
        std::vector<E>().swap(next);
        res.positions += nk.size();
        L.push_back(std::move(nk));
        C.push_back(std::move(nc));
        if (k >= 1) { std::vector<K>().swap(L[k - 1]); std::vector<u128>().swap(C[k - 1]); }
        check_memory(L, ctx, [&] { size_t b = 0; for (auto& v : C) b += v.capacity() * 16; return b; }());
        ctx.progress("layer %d: %zu positions", k + 1, L[k + 1].size());
    }
}
