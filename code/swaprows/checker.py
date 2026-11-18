"""Move-list checker: replays a sequence and verifies legality and the goal."""

from __future__ import annotations

from dataclasses import dataclass, field

from .board import BLACK, COLOUR_NAME, WHITE, Board
from .pieces import Piece


@dataclass
class CheckResult:
    ok: bool
    num_moves: int
    reached_goal: bool
    error: str | None = None
    error_index: int | None = None  # 0-based index of the offending move
    colours: list[int] = field(default_factory=list)  # colour of each move


def check_moves(board: Board, piece: Piece, moves, alternate: bool = False,
                first: str = "either") -> CheckResult:
    """Replay ``moves`` (list of (from, to) square indices) from the start.

    With ``alternate`` the colours must alternate; ``first`` is ``white``,
    ``black`` or ``either``.
    """
    white, black = (set(x) for x in board.start())
    colours: list[int] = []
    for i, (s, d) in enumerate(moves):
        err = board.move_error(piece, white, black, s, d)
        if err is not None:
            return CheckResult(False, len(moves), False,
                               f"move {i + 1} ({board.name(s)}-{board.name(d)}): {err}",
                               i, colours)
        col = WHITE if s in white else BLACK
        if alternate:
            if i == 0:
                if first in ("white", "black") and COLOUR_NAME[col] != first:
                    return CheckResult(False, len(moves), False,
                                       f"move 1: {first} must move first", 0, colours)
            elif col == colours[-1]:
                return CheckResult(False, len(moves), False,
                                   f"move {i + 1}: {COLOUR_NAME[col]} moved twice in a row "
                                   "(--alternate)", i, colours)
        colours.append(col)
        side = white if col == WHITE else black
        side.remove(s)
        side.add(d)
    gw, gb = board.goal()
    reached = white == set(gw) and black == set(gb)
    if not reached:
        return CheckResult(False, len(moves), False,
                           "all moves are legal but the final position is not the goal",
                           None, colours)
    return CheckResult(True, len(moves), True, None, None, colours)
