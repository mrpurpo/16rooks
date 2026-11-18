// Core data structures shared by all modes: board geometry, pieces as data,
// connected components of the move graph, position keys, small utilities.
#pragma once

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <map>
#include <numeric>
#include <sstream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#ifdef _OPENMP
#include <omp.h>
#endif

using u64 = uint64_t;
using u128 = unsigned __int128;

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

struct Clock {
    std::chrono::steady_clock::time_point t0 = std::chrono::steady_clock::now();
    double elapsed() const {
        return std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
    }
};

struct TimeoutError : std::runtime_error {
    TimeoutError() : std::runtime_error("timeout") {}
};
struct MemoryError : std::runtime_error {
    using std::runtime_error::runtime_error;
};

inline std::string u128_to_string(u128 v) {
    if (v == 0) return "0";
    std::string s;
    while (v) { s.push_back(char('0' + int(v % 10))); v /= 10; }
    std::reverse(s.begin(), s.end());
    return s;
}

inline std::string json_escape(const std::string& s) {
    std::string o;
    for (char c : s) {
        if (c == '"' || c == '\\') { o.push_back('\\'); o.push_back(c); }
        else if (c == '\n') o += "\\n";
        else o.push_back(c);
    }
    return o;
}

// Available memory in bytes (MemAvailable from /proc/meminfo), 0 if unknown.
inline double available_memory_bytes() {
    std::ifstream f("/proc/meminfo");
    std::string key; double val; std::string unit;
    while (f >> key >> val >> unit) {
        if (key == "MemAvailable:") return val * 1024.0;
    }
    return 0.0;
}

inline long double binom(int n, int k) {
    if (k < 0 || k > n) return 0;
    long double r = 1;
    for (int i = 1; i <= k; i++) r = r * (n - k + i) / i;
    return r;
}

inline int popcount64(u64 x) { return __builtin_popcountll(x); }
inline int ctz64(u64 x) { return __builtin_ctzll(x); }

// ---------------------------------------------------------------------------
// Board + piece
// ---------------------------------------------------------------------------

static const char* FILE_LETTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

struct Board {
    int F = 0, R = 0, N = 0;
    std::vector<std::pair<int, int>> dirs;  // (dfile, drank)
    bool slides = false;
    // rays[s] = list of rays from global square s; each ray lists the squares
    // in order.  For non-sliding pieces each ray has length 1.
    std::vector<std::vector<std::vector<int>>> rays;

    void build() {
        N = F * R;
        rays.assign(N, {});
        for (int s = 0; s < N; s++) {
            int f0 = s % F, r0 = s / F;
            for (auto [df, dr] : dirs) {
                std::vector<int> ray;
                int f = f0 + df, r = r0 + dr;
                while (f >= 0 && f < F && r >= 0 && r < R) {
                    ray.push_back(r * F + f);
                    if (!slides) break;
                    f += df; r += dr;
                }
                if (!ray.empty()) rays[s].push_back(ray);
            }
        }
    }
    std::string name(int s) const {
        return std::string(1, FILE_LETTERS[s % F]) + std::to_string(s / F + 1);
    }
    int sq(int f, int r) const { return r * F + f; }
    bool dirs_invariant(int sf, int sr) const {  // under (df,dr)->(sf*df, sr*dr)
        for (auto [df, dr] : dirs) {
            if (std::find(dirs.begin(), dirs.end(), std::make_pair(sf * df, sr * dr)) == dirs.end())
                return false;
        }
        return true;
    }
    // Square maps for the symmetries that preserve the problem.
    int mirror(int s) const { return sq(F - 1 - s % F, s / F); }          // left-right
    int flipv(int s) const { return sq(s % F, R - 1 - s / F); }           // top-bottom (+colour swap)
    int rot180(int s) const { return N - 1 - s; }                         // (+colour swap)
};

// Connected components of the empty-board move graph.  Pieces in different
// components can never interact: a piece never leaves its component and a
// sliding ray lies entirely inside one component.
inline std::vector<std::vector<int>> components(const Board& B) {
    std::vector<int> comp(B.N, -1);
    std::vector<std::vector<int>> out;
    for (int s = 0; s < B.N; s++) {
        if (comp[s] != -1) continue;
        std::vector<int> stack{s}, members;
        comp[s] = (int)out.size();
        while (!stack.empty()) {
            int x = stack.back(); stack.pop_back();
            members.push_back(x);
            for (auto& ray : B.rays[x]) {
                int y = ray[0];  // one step suffices for connectivity
                if (comp[y] == -1) { comp[y] = comp[s]; stack.push_back(y); }
            }
        }
        std::sort(members.begin(), members.end());
        out.push_back(members);
    }
    return out;
}

// A sub-problem on a set of squares, with squares renumbered 0..n-1.
struct Problem {
    int n = 0;
    std::vector<int> global;   // local -> global square
    std::vector<int> local;    // global -> local (-1 if not in the problem)
    // Flattened rays in local indices: for square s, rays rayBeg[s]..rayBeg[s+1]-1;
    // ray r occupies sq[off[r]] .. sq[off[r+1]-1].
    std::vector<int> rayBeg, off;
    std::vector<uint8_t> raysq;
    u64 startW = 0, startB = 0;  // local masks
    int k = 0;                   // pieces per colour

    void build(const Board& B, const std::vector<int>& squares) {
        global = squares;
        n = (int)squares.size();
        local.assign(B.N, -1);
        for (int i = 0; i < n; i++) local[squares[i]] = i;
        rayBeg.assign(n + 1, 0);
        off.assign(1, 0);
        raysq.clear();
        int nr = 0;
        for (int i = 0; i < n; i++) {
            rayBeg[i] = nr;
            for (auto& ray : B.rays[global[i]]) {
                for (int g : ray) raysq.push_back((uint8_t)local[g]);
                off.push_back((int)raysq.size());
                nr++;
            }
        }
        rayBeg[n] = nr;
        startW = startB = 0;
        for (int i = 0; i < n; i++) {
            int r = global[i] / B.F;
            if (r == 0) startW |= 1ULL << i;
            if (r == B.R - 1) startB |= 1ULL << i;
        }
        k = popcount64(startW);
    }
    bool feasible_counts() const { return popcount64(startW) == popcount64(startB); }
};

// ---------------------------------------------------------------------------
// Position keys.  A position is two masks (white, black) over the n squares of
// a Problem, packed into one integer: (white << HALF) | black.  K = u64
// (HALF = 32) when n <= 32, otherwise u128 (HALF = 64).  In --alternate mode
// the top bit of the key is the side to move (0 = white, 1 = black), so
// alternate mode needs n <= HALF - 1.
// ---------------------------------------------------------------------------

template <class K>
struct KeyOps {
    static constexpr int HALF = sizeof(K) * 4;
    static constexpr K LOW = (K(1) << HALF) - 1;
    static constexpr K TURN = K(1) << (2 * HALF - 1);
    static K pack(u64 w, u64 b) { return (K(w) << HALF) | K(b); }
    static u64 W(K k) { return u64((k & ~TURN) >> HALF); }
    static u64 Bm(K k) { return u64(k & LOW); }
    static K swap(K k) { return (k & TURN) | pack(Bm(k), W(k)); }  // colours swapped, turn kept
    static int turn(K k) { return (k & TURN) ? 1 : 0; }
};

// Enumerate all positions reachable in one move (both colours, or only the
// side to move when `alternate`).  f(newkey, from_local, to_local).
template <class K, class Fn>
inline void for_neighbors(const Problem& P, K key, bool alternate, Fn&& f) {
    using O = KeyOps<K>;
    u64 w = O::W(key), b = O::Bm(key), occ = w | b;
    K turnbit = key & O::TURN;
    for (int side = 0; side < 2; side++) {
        if (alternate && side != O::turn(key)) continue;
        u64 mine = side == 0 ? w : b;
        for (u64 m = mine; m; m &= m - 1) {
            int s = ctz64(m);
            for (int r = P.rayBeg[s]; r < P.rayBeg[s + 1]; r++) {
                for (int i = P.off[r]; i < P.off[r + 1]; i++) {
                    int t = P.raysq[i];
                    if (occ >> t & 1) break;
                    u64 nm = mine ^ (1ULL << s) ^ (1ULL << t);
                    K nk = side == 0 ? O::pack(nm, b) : O::pack(w, nm);
                    if (alternate) nk |= turnbit ^ O::TURN;
                    f(nk, s, t);
                }
            }
        }
    }
}

// The move (from, to) between two positions that differ by one move.
template <class K>
inline std::pair<int, int> move_between(K a, K b) {
    using O = KeyOps<K>;
    u64 dw = O::W(a) ^ O::W(b), db = O::Bm(a) ^ O::Bm(b);
    u64 before = dw ? O::W(a) : O::Bm(a);
    u64 d = dw ? dw : db;
    int s1 = ctz64(d), s2 = ctz64(d & (d - 1));
    if (before >> s1 & 1) return {s1, s2};
    return {s2, s1};
}
