"""Distance-matching lower bound.

Every piece must finish on a distinct square of its target rank, and a piece
that travels from square s to square t needs at least d(s, t) moves, where d
is the empty-board distance (obstacles only make it longer).  Each move moves
one piece, so the total number of moves is at least

    min over bijections (white -> rank R squares) of  sum d(s, sigma(s))
  + min over bijections (black -> rank 1 squares) of  sum d(s, tau(s)),

two optimal assignment problems, solved with the Hungarian algorithm (or by
brute force over permutations for small F).
"""

from __future__ import annotations

import itertools
import math

from .board import Board
from .pieces import Piece

INF = math.inf


def hungarian(cost: list[list[float]]) -> tuple[float, list[int]]:
    """Minimum-cost perfect matching on a square matrix (O(n^3), potentials).
    Returns (cost, assignment row -> column).  Infinite entries are allowed;
    the result is inf if no finite perfect matching exists."""
    n = len(cost)
    if n == 0:
        return 0, []
    big = 1 + sum(max((c for c in row if c != INF), default=0) for row in cost)
    a = [[(c if c != INF else big * 4) for c in row] for row in cost]
    u = [0.0] * (n + 1)
    v = [0.0] * (n + 1)
    p = [0] * (n + 1)      # p[j] = row matched to column j (1-based)
    way = [0] * (n + 1)
    for i in range(1, n + 1):
        p[0] = i
        j0 = 0
        minv = [math.inf] * (n + 1)
        used = [False] * (n + 1)
        while True:
            used[j0] = True
            i0, delta, j1 = p[j0], math.inf, 0
            for j in range(1, n + 1):
                if not used[j]:
                    cur = a[i0 - 1][j - 1] - u[i0] - v[j]
                    if cur < minv[j]:
                        minv[j], way[j] = cur, j0
                    if minv[j] < delta:
                        delta, j1 = minv[j], j
            for j in range(n + 1):
                if used[j]:
                    u[p[j]] += delta
                    v[j] -= delta
                else:
                    minv[j] -= delta
            j0 = j1
            if p[j0] == 0:
                break
        while True:
            j1 = way[j0]
            p[j0] = p[j1]
            j0 = j1
            if j0 == 0:
                break
    assign = [0] * n
    for j in range(1, n + 1):
        assign[p[j] - 1] = j - 1
    total = sum(cost[i][assign[i]] for i in range(n))
    return total, assign


def brute_force(cost: list[list[float]]) -> tuple[float, list[int]]:
    n = len(cost)
    best, arg = INF, list(range(n))
    for perm in itertools.permutations(range(n)):
        c = sum(cost[i][perm[i]] for i in range(n))
        if c < best:
            best, arg = c, list(perm)
    return best, arg


def distance_matrix(board: Board, piece: Piece, sources, targets) -> list[list[float]]:
    # distances from each target (moves are reversible, so d is symmetric)
    dist_from = {t: board.empty_distance(piece, [t]) for t in targets}
    return [[dist_from[t][s] for t in targets] for s in sources]


def lower_bounds(board: Board, piece: Piece, method: str = "auto") -> dict:
    w, b = board.start()
    white = sorted(w)
    black = sorted(b)
    rank1 = white            # white start squares = black targets
    rankR = black            # black start squares = white targets
    solver = hungarian
    if method == "brute" or (method == "auto" and board.F <= 7):
        solver = brute_force
    cw = distance_matrix(board, piece, white, rankR)
    cb = distance_matrix(board, piece, black, rank1)
    vw, aw = solver(cw)
    vb, ab = solver(cb)
    to_r = board.empty_distance(piece, rankR)
    to_1 = board.empty_distance(piece, rank1)
    nearest = sum(to_r[s] for s in white) + sum(to_1[s] for s in black)
    return {
        "matching": vw + vb, "white": vw, "black": vb,
        "white_assignment": [(white[i], rankR[aw[i]]) for i in range(len(white))],
        "black_assignment": [(black[i], rank1[ab[i]]) for i in range(len(black))],
        "nearest": nearest,
        "method": "brute force" if solver is brute_force else "Hungarian algorithm",
    }
