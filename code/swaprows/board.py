"""Board geometry, square notation and move legality (pure Python).

Squares are indexed ``s = rank * F + file`` with 0-based file/rank.  Files are
written with letters ``a..z`` followed by ``A..Z`` (F*R <= 64 implies F <= 32),
ranks with 1-based numbers, e.g. ``a1``, ``h8``, ``b12``.
"""

from __future__ import annotations

import re
from collections import deque

from .pieces import Piece

FILE_LETTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
WHITE, BLACK = 0, 1
COLOUR_NAME = {WHITE: "white", BLACK: "black"}


class BoardError(ValueError):
    pass


class Board:
    def __init__(self, files: int, ranks: int):
        if files < 1 or ranks < 2:
            raise BoardError("need at least 1 file and 2 ranks")
        if files * ranks > 64:
            raise BoardError(f"F*R = {files * ranks} > 64 is not supported")
        self.F = files
        self.R = ranks
        self.N = files * ranks

    # --- notation -----------------------------------------------------
    def sq(self, f: int, r: int) -> int:
        return r * self.F + f

    def fr(self, s: int) -> tuple[int, int]:
        return s % self.F, s // self.F

    def name(self, s: int) -> str:
        f, r = self.fr(s)
        return f"{FILE_LETTERS[f]}{r + 1}"

    def parse_square(self, text: str) -> int:
        m = re.fullmatch(r"([a-zA-Z])(\d+)", text)
        if not m:
            raise BoardError(f"bad square {text!r}")
        f = FILE_LETTERS.find(m.group(1))
        r = int(m.group(2)) - 1
        if not (0 <= f < self.F and 0 <= r < self.R):
            raise BoardError(f"square {text!r} is off the {self.F}x{self.R} board")
        return self.sq(f, r)

    # --- positions ----------------------------------------------------
    def start(self) -> tuple[frozenset[int], frozenset[int]]:
        return (frozenset(self.sq(f, 0) for f in range(self.F)),
                frozenset(self.sq(f, self.R - 1) for f in range(self.F)))

    def goal(self) -> tuple[frozenset[int], frozenset[int]]:
        w, b = self.start()
        return b, w

    # --- moves --------------------------------------------------------
    def targets(self, piece: Piece, s: int, occupied) -> list[int]:
        """Squares reachable from s in one move given the occupied set."""
        f0, r0 = self.fr(s)
        out = []
        for df, dr in piece.dirs:
            f, r = f0 + df, r0 + dr
            while 0 <= f < self.F and 0 <= r < self.R:
                t = self.sq(f, r)
                if t in occupied:
                    break
                out.append(t)
                if not piece.slides:
                    break
                f, r = f + df, r + dr
        return out

    def move_error(self, piece: Piece, white, black, s: int, d: int) -> str | None:
        """None if moving the piece on s to d is legal, else a reason."""
        if s not in white and s not in black:
            return f"no piece on {self.name(s)}"
        occ = white | black
        if d in occ:
            return f"destination {self.name(d)} is occupied"
        f0, r0 = self.fr(s)
        f1, r1 = self.fr(d)
        dF, dR = f1 - f0, r1 - r0
        for df, dr in piece.dirs:
            if piece.slides:
                # d must be a positive multiple of (df, dr)
                k = None
                if df == 0 and dF == 0 and dr != 0 and dR % dr == 0:
                    k = dR // dr
                elif dr == 0 and dR == 0 and df != 0 and dF % df == 0:
                    k = dF // df
                elif df != 0 and dr != 0 and dF % df == 0 and dR % dr == 0 \
                        and dF // df == dR // dr:
                    k = dF // df
                if k is None or k < 1:
                    continue
                for i in range(1, k):
                    t = self.sq(f0 + i * df, r0 + i * dr)
                    if t in occ:
                        return (f"path from {self.name(s)} to {self.name(d)} "
                                f"is blocked at {self.name(t)}")
                return None
            elif (df, dr) == (dF, dR):
                return None
        return f"{self.name(s)}-{self.name(d)} is not a {piece.name} move"

    def empty_distance(self, piece: Piece, sources) -> list[float]:
        """Empty-board move distance from every square to the set `sources`
        (multi-source BFS; moves are reversible so distances are symmetric)."""
        INF = float("inf")
        dist = [INF] * self.N
        q = deque()
        for s in sources:
            dist[s] = 0
            q.append(s)
        while q:
            s = q.popleft()
            for t in self.targets(piece, s, ()):
                if dist[t] == INF:
                    dist[t] = dist[s] + 1
                    q.append(t)
        return dist


MOVE_RE = re.compile(r"^([a-zA-Z]\d+)-([a-zA-Z]\d+)$")
IGNORED_TOKEN_RE = re.compile(r"^(\d+\.?|[BNWbnw]:?|,)$")


def parse_moves(board: Board, text: str) -> list[tuple[int, int]]:
    """Parse ``"a1-b3 c8-d6 ..."``.  Move numbers (``12.``) and colour labels
    (``B``/``N``/``W``) are ignored; anything else is an error."""
    moves = []
    for tok in re.split(r"[\s,;]+", text.strip()):
        if not tok or IGNORED_TOKEN_RE.match(tok):
            continue
        tok = tok.replace("–", "-").replace("—", "-")
        m = MOVE_RE.match(tok)
        if not m:
            raise BoardError(f"cannot parse move token {tok!r}")
        moves.append((board.parse_square(m.group(1)), board.parse_square(m.group(2))))
    return moves


def format_moves(board: Board, moves) -> str:
    return " ".join(f"{board.name(s)}-{board.name(d)}" for s, d in moves)
