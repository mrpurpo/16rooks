"""Independent brute-force reference solver (pure Python, tiny boards only).

Plain forward BFS from the start with a full visited dictionary until the goal
is dequeued -- no meet in the middle, no component splitting, no symmetry --
so it cross-checks every shortcut used by the C++ core.  It also counts
shortest paths (sum of predecessor counts) and supports alternating turns.
"""

from __future__ import annotations

import os
import sys
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

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
                            raise RuntimeError(f"reference solver: more than {limit} positions (raise --limit)")
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


def main(argv=None) -> int:
    """Command line: python3 tests/reference.py PIECE F R [--limit N]."""
    import argparse

    from swaprows.pieces import make_piece

    ap = argparse.ArgumentParser(description="Plain-BFS reference solver (tiny boards).")
    ap.add_argument("piece")
    ap.add_argument("files", type=int)
    ap.add_argument("ranks", type=int)
    ap.add_argument("--limit", type=int, default=3_000_000,
                    help="maximum number of stored positions (default 3e6)")
    a = ap.parse_args(argv)
    best, total = reference_solve(Board(a.files, a.ranks), make_piece(a.piece), limit=a.limit)
    name = f"{a.piece} on {a.files}x{a.ranks}"
    if best is None:
        print(f"{name}: IMPOSSIBLE")
    else:
        print(f"{name}: minimum = {best} moves, {total} optimal sequences (reference BFS)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
