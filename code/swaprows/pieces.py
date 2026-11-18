"""Piece definitions.

A piece is pure data: a list of (dfile, drank) directions plus a ``slides``
flag.  A non-sliding piece (king, knight, ...) jumps exactly one step in a
direction; a sliding piece (rook, bishop, queen) repeats the step any number of
times while the squares are empty.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Piece:
    name: str
    dirs: tuple[tuple[int, int], ...]
    slides: bool

    def dirs_arg(self) -> str:
        """Directions in the ``"df,dr;df,dr;..."`` command-line format."""
        return ";".join(f"{df},{dr}" for df, dr in self.dirs)

    def is_reversible(self) -> bool:
        """Moves are reversible iff the direction set is closed under negation."""
        s = set(self.dirs)
        return all((-df, -dr) in s for df, dr in s)

    def is_mirror_symmetric(self) -> bool:
        """Invariant under the left-right reflection (df -> -df)."""
        s = set(self.dirs)
        return all((-df, dr) in s for df, dr in s)


_ORTHO = ((1, 0), (-1, 0), (0, 1), (0, -1))
_DIAG = ((1, 1), (1, -1), (-1, 1), (-1, -1))
_KNIGHT = ((1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2))

BUILTIN = {
    "rook": Piece("rook", _ORTHO, True),
    "bishop": Piece("bishop", _DIAG, True),
    "queen": Piece("queen", _ORTHO + _DIAG, True),
    "king": Piece("king", _ORTHO + _DIAG, False),
    "knight": Piece("knight", _KNIGHT, False),
}

PAWN_EXPLANATION = """\
Pawns: the swap is IMPOSSIBLE (for every board with at least 2 ranks).

Without captures a pawn never leaves its file: its only non-capturing moves
are straight forward.  In every file the white pawn (rank 1) moves up and the
black pawn (rank R) moves down along the SAME file, so the two pawns approach
each other and end up blocking one another; neither can ever jump over the
other.  Moreover pawns never move backwards, so the white pawn can never reach
rank R while the black pawn stands between it and rank R.  Hence no sequence
of legal moves exchanges the two rows."""


class PieceError(ValueError):
    pass


def parse_dirs(text: str) -> tuple[tuple[int, int], ...]:
    """Parse ``"1,2;2,1;-1,0"`` into a tuple of (dfile, drank) pairs."""
    out: list[tuple[int, int]] = []
    for chunk in text.replace(" ", "").split(";"):
        if not chunk:
            continue
        parts = chunk.split(",")
        if len(parts) != 2:
            raise PieceError(f"bad direction {chunk!r}: expected 'dfile,drank'")
        try:
            d = (int(parts[0]), int(parts[1]))
        except ValueError:
            raise PieceError(f"bad direction {chunk!r}: not integers") from None
        if d == (0, 0):
            raise PieceError("direction (0,0) is not a move")
        if d not in out:
            out.append(d)
    if not out:
        raise PieceError("no directions given")
    return tuple(out)


def parse_bool(text: str) -> bool:
    t = text.strip().lower()
    if t in ("1", "true", "yes", "y", "on"):
        return True
    if t in ("0", "false", "no", "n", "off"):
        return False
    raise PieceError(f"expected true/false, got {text!r}")


def make_piece(name: str, dirs: str | None = None, slides: str | None = None,
               symmetrize: bool = False) -> Piece:
    """Resolve a piece from a built-in name or from custom ``--dirs/--slides``."""
    name = name.lower()
    if name == "pawn":
        raise PieceError("pawn")  # handled by the CLI (explanation)
    if name in BUILTIN and dirs is None and slides is None:
        p = BUILTIN[name]
    else:
        if dirs is None:
            if name not in BUILTIN:
                raise PieceError(f"unknown piece {name!r}; use one of "
                                 f"{', '.join(BUILTIN)}, pawn, or 'custom' with --dirs")
            d = BUILTIN[name].dirs
        else:
            d = parse_dirs(dirs)
        if slides is None:
            s = BUILTIN[name].slides if name in BUILTIN else False
        else:
            s = parse_bool(slides)
        p = Piece(name if name in BUILTIN and dirs is None else "custom", d, s)
    if symmetrize:
        d = list(p.dirs)
        for df, dr in p.dirs:
            if (-df, -dr) not in d:
                d.append((-df, -dr))
        p = Piece(p.name, tuple(d), p.slides)
    if not p.is_reversible():
        raise PieceError(
            "the direction set is not closed under negation, so moves are not "
            "reversible; the exact solver relies on reversibility (layered BFS "
            "and meet in the middle).  Add the opposite directions or pass "
            "--symmetrize.")
    return p
