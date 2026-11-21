#!/usr/bin/env python3
"""Enumerate every optimal rook sequence and check its structure (paper, Prop. rows).

For a board with n files and m >= 5 ranks the minimum is 4n + 1, and the proof
of the proposition shows that every optimal sequence has a rigid structure.
This program enumerates *all* optimal sequences and checks, for each one:

  1. there is exactly one exceptional column c*, with l* = 0 and out* = 1, and
     every other column has out_j = l_j >= 1;
  2. V = 4n - L (every rook attains the bound of the vertical lemma);
  3. exactly three rooks pass through c*, none of them makes a long move, and
     their parking rows are distinct.

It also checks the stronger ordering 2 <= p_E < p_Q < p_S <= m - 1 from the
proof (after swapping colours / flipping the board when Q is black), where Q is
the original rook of c* that never leaves, S the other original rook and E the
rook that enters c*.

Definitions (as in the paper): a move is horizontal if it stays on its rank and
vertical otherwise; a vertical move is long if it goes between rank 1 and rank
m.  out_j = number of horizontal moves leaving column j; l_j = number of rooks
with at least one long move in column j; L = number of rooks with at least one
long move; V = number of vertical moves.  The parking row of a rook without
long moves is the rank it reaches with its first vertical move.

The program is self-contained: it generates rook moves itself and computes the
distances with its own BFS, sharing no code with the C++ core or with the
swaprows package.  The number of optimal sequences it finds is therefore an
independent check of `swaprows.py solve rook n m --count`.

Usage:
    python3 tests/structure.py            # the six boards of the paper
    python3 tests/structure.py 3 6        # n = 3 files, m = 6 ranks
"""

from __future__ import annotations

import multiprocessing as mp
import sys
import time
from collections import deque

# Global state, shared with forked workers.
N = M = 0
DIST: dict[tuple[int, int], int] = {}
T = 0


def rook_targets(s: int, occ: int):
    """Squares a rook on s can reach (s = rank * N + file, 0-based)."""
    f, r = s % N, s // N
    for df, dr in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ff, rr = f + df, r + dr
        while 0 <= ff < N and 0 <= rr < M:
            t = rr * N + ff
            if occ >> t & 1:
                break
            yield t
            ff += df
            rr += dr


def neighbours(w: int, b: int):
    occ = w | b
    for colour in (0, 1):
        mine = w if colour == 0 else b
        x = mine
        while x:
            s = (x & -x).bit_length() - 1
            x &= x - 1
            for t in rook_targets(s, occ):
                nm = mine ^ (1 << s) ^ (1 << t)
                yield (nm, b) if colour == 0 else (w, nm)


def bfs_from(src: tuple[int, int]) -> dict[tuple[int, int], int]:
    dist = {src: 0}
    q = deque([src])
    while q:
        x = q.popleft()
        d = dist[x] + 1
        for y in neighbours(*x):
            if y not in dist:
                dist[y] = d
                q.append(y)
    return dist


def analyse(moves) -> tuple[bool, bool]:
    """moves: list of (rook id, from, to).  Rooks 0..N-1 are the white rooks of
    files 0..N-1, rooks N..2N-1 the black ones.  Returns (props 1-3, ordering)."""
    out = [0] * N
    long_rooks = [set() for _ in range(N)]
    has_long = set()
    nvert = [0] * (2 * N)
    park = [-1] * (2 * N)
    cols = [{i % N} for i in range(2 * N)]
    V = 0
    for rid, fr, to in moves:
        ff, fr_r = fr % N, fr // N
        tf, to_r = to % N, to // N
        if fr_r == to_r:
            out[ff] += 1
            cols[rid].add(tf)
        else:
            V += 1
            nvert[rid] += 1
            if nvert[rid] == 1:
                park[rid] = to_r
            if {fr_r, to_r} == {0, M - 1}:
                long_rooks[ff].add(rid)
                has_long.add(rid)
    ell = [len(s) for s in long_rooks]
    L = len(has_long)

    # 1. exactly one exceptional column, with l* = 0 and out* = 1
    exc = [j for j in range(N) if not (out[j] == ell[j] >= 1)]
    p1 = len(exc) == 1 and ell[exc[0]] == 0 and out[exc[0]] == 1
    # 2. V = 4n - L
    p2 = V == 4 * N - L
    if not (p1 and p2):
        return False, False
    c = exc[0]
    # 3. three rooks through c*, no long moves, distinct parking rows
    through = [i for i in range(2 * N) if c in cols[i]]
    p3 = (len(through) == 3 and not any(i in has_long for i in through)
          and all(nvert[i] == 2 for i in through)
          and len({park[i] for i in through}) == 3)
    if not p3:
        return False, False
    # stronger ordering from the proof: p_E < p_Q < p_S (normalised so Q is white)
    q = [i for i in (c, N + c) if cols[i] == {c}]
    e = [i for i in through if i % N != c]
    if len(q) != 1 or len(e) != 1:
        return True, False
    q = q[0]
    s = N + c if q == c else c
    e = e[0]
    p = {i: (park[i] if q < N else M - 1 - park[i]) for i in (q, s, e)}
    return True, 1 <= p[e] < p[q] < p[s] <= M - 2


def dfs(state, depth, moves, rooks, acc):
    """Extend `moves` along every optimal continuation.  `rooks[i]` is the square
    of rook i.  acc = [sequences, props 1-3, ordering]."""
    if depth == T:
        a, b = analyse(moves)
        acc[0] += 1
        acc[1] += a
        acc[2] += b
        return
    w, b = state
    occ = w | b
    for rid in range(2 * N):
        s = rooks[rid]
        white = rid < N
        for t in rook_targets(s, occ):
            if white:
                ns = (w ^ (1 << s) ^ (1 << t), b)
            else:
                ns = (w, b ^ (1 << s) ^ (1 << t))
            if DIST.get(ns, -1) != T - depth - 1:
                continue
            rooks[rid] = t
            moves.append((rid, s, t))
            dfs(ns, depth + 1, moves, rooks, acc)
            moves.pop()
            rooks[rid] = s


def prefixes(state, depth, moves, rooks, k, outl):
    """Optimal prefixes of length k, to split the enumeration between workers."""
    if depth == k or depth == T:
        outl.append((state, depth, list(moves), list(rooks)))
        return
    w, b = state
    occ = w | b
    for rid in range(2 * N):
        s = rooks[rid]
        for t in rook_targets(s, occ):
            ns = ((w ^ (1 << s) ^ (1 << t), b) if rid < N else (w, b ^ (1 << s) ^ (1 << t)))
            if DIST.get(ns, -1) != T - depth - 1:
                continue
            rooks[rid] = t
            moves.append((rid, s, t))
            prefixes(ns, depth + 1, moves, rooks, k, outl)
            moves.pop()
            rooks[rid] = s


def work(task):
    state, depth, moves, rooks = task
    acc = [0, 0, 0]
    dfs(state, depth, moves, rooks, acc)
    return acc


def run(n: int, m: int):
    global N, M, DIST, T
    N, M = n, m
    full = (1 << N) - 1
    start = (full, full << (N * (M - 1)))
    goal = (start[1], start[0])
    DIST = bfs_from(goal)
    T = DIST[start]
    tasks: list = []
    prefixes(start, 0, [], [i % N + (0 if i < N else N * (M - 1)) for i in range(2 * N)],
             3, tasks)
    with mp.get_context("fork").Pool() as pool:
        res = pool.map(work, tasks, chunksize=1)
    total = [sum(r[i] for r in res) for i in range(3)]
    return T, total


BOARDS = [(2, 5), (2, 6), (2, 7), (2, 8), (3, 5), (3, 6)]  # (n files, m ranks)


def main(argv) -> int:
    boards = [(int(argv[1]), int(argv[2]))] if len(argv) == 3 else BOARDS
    print(f"{'board (m x n)':>14} {'T_min':>6} {'optimal seqs':>14} {'props 1-3':>12} "
          f"{'p_E<p_Q<p_S':>12} {'time':>7}")
    ok = True
    for n, m in boards:
        t0 = time.time()
        Tm, (tot, p13, order) = run(n, m)
        print(f"{f'{m} x {n}':>14} {Tm:>6} {tot:>14} {p13:>12} {order:>12} "
              f"{time.time() - t0:>6.1f}s", flush=True)
        ok &= Tm == 4 * n + 1 and p13 == tot and order == tot
    print("all sequences satisfy properties 1-3" if ok else "VIOLATIONS FOUND")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
