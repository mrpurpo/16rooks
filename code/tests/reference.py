"""Independent brute-force reference solver (pure Python, tiny boards only).

Plain forward BFS from the start with a full visited dictionary until the goal
is dequeued -- no meet in the middle, no component splitting, no symmetry --
so it cross-checks every shortcut used by the C++ core.  It also counts
shortest paths (sum of predecessor counts) and supports alternating turns.
"""

from __future__ import annotations

from collections import deque

from swaprows.board import Board
from swaprows.pieces import Piece


def reference_solve(board: Board, piece: Piece, alternate: bool = False,
                    first: str = "either", limit: int = 3_000_000):
    """Return (minimum or None if impossible, number of optimal sequences)."""
    w0, b0 = board.start()
    gw, gb = board.goal()
    if alternate:
        turns = {"white": [0], "black": [1], "either": [0, 1]}[first]
        starts = [(w0, b0, t) for t in turns]
    else:
        starts = [(w0, b0, None)]
    dist = {s: 0 for s in starts}
    cnt = {s: 1 for s in starts}
    q = deque(starts)
    best = None
    total = 0
    while q:
        st = q.popleft()
        w, b, t = st
        d = dist[st]
        if best is not None and d >= best:
            break
        occ = w | b
        for side in (0, 1):
            if alternate and side != t:
                continue
            mine = w if side == 0 else b
            for s in mine:
                for tgt in board.targets(piece, s, occ):
                    nm = (mine - {s}) | {tgt}
                    nw, nb = (nm, b) if side == 0 else (w, nm)
                    ns = (frozenset(nw), frozenset(nb), (1 - t) if alternate else None)
                    if ns not in dist:
                        if len(dist) > limit:
                            raise RuntimeError("reference solver: board too large")
                        dist[ns] = d + 1
                        cnt[ns] = cnt[st]
                        q.append(ns)
                    elif dist[ns] == d + 1:
                        cnt[ns] += cnt[st]
                    if ns[0] == gw and ns[1] == gb and dist[ns] == d + 1:
                        best = d + 1
    if best is None:
        return None, 0
    for st, d in dist.items():
        if st[0] == gw and st[1] == gb and d == best:
            total += cnt[st]
    return best, total
