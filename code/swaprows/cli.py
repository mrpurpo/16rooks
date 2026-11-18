"""Command-line interface for the row-swap research tool."""

from __future__ import annotations

import argparse
import json
import math
import sys

from .board import Board, BoardError, format_moves, parse_moves
from .checker import check_moves
from .core import CoreError, run_core
from .pieces import PAWN_EXPLANATION, PieceError, make_piece


def _common(p: argparse.ArgumentParser) -> None:
    p.add_argument("piece", help="rook|bishop|queen|king|knight|pawn|custom")
    p.add_argument("files", type=int, help="number of files F")
    p.add_argument("ranks", type=int, help="number of ranks R (F*R <= 64)")
    p.add_argument("--dirs", help='custom directions, e.g. "1,2;2,1;-1,2"')
    p.add_argument("--slides", help="custom piece slides? true/false")
    p.add_argument("--symmetrize", action="store_true",
                   help="add the opposite of every direction (makes moves reversible)")


def _read_moves_text(args) -> str:
    if args.file:
        if args.file == "-":
            return sys.stdin.read()
        with open(args.file, encoding="utf-8") as fh:
            return fh.read()
    if args.moves:
        return " ".join(args.moves)
    raise BoardError("no moves given (pass them as arguments or with --file)")


def cmd_check(args, board, piece) -> int:
    moves = parse_moves(board, _read_moves_text(args))
    res = check_moves(board, piece, moves, alternate=args.alternate, first=args.first)
    if res.ok:
        print(f"OK: {res.num_moves} legal moves, final position is the goal.")
        return 0
    print(f"INVALID: {res.error}")
    return 1


def _verify_and_print(board, piece, moves_txt: list[str], label: str) -> bool:
    """Re-check a solution produced by the core with the independent checker."""
    moves = parse_moves(board, " ".join(moves_txt))
    res = check_moves(board, piece, moves)
    print(f"{label} ({len(moves)} moves, independently re-checked: "
          f"{'OK' if res.ok else 'FAILED: ' + str(res.error)}):")
    print(format_moves(board, moves))
    return res.ok


def _print_components(result: dict) -> None:
    comps = result.get("components", [])
    if len(comps) <= 1:
        return
    print(f"independent components of the move graph: {len(comps)}")
    for i, c in enumerate(comps, 1):
        sq = c["squares"]
        desc = f"{len(sq)} squares, {c['pieces_per_colour']} piece(s) per colour"
        line = f"  component {i} ({desc}): {c['status']}"
        if c.get("min") is not None:
            line += f", min {c['min']}"
        if c.get("count"):
            line += f", {c['count']} optimal sequences"
        if c.get("reused"):
            line += f"  [{c['reused']}]"
        if c.get("reason"):
            line += f"  ({c['reason']})"
        print(line)


def _core_status(rc: int, result: dict) -> int | None:
    st = result.get("status")
    if st in ("refused", "timeout", "memory", "error"):
        print(f"{st.upper()}: {result.get('message', '')}")
        return rc if rc else 1
    return None


def cmd_solve(args, board, piece) -> int:
    extra = []
    if args.print_solution or args.export:
        extra.append("--print-solution")
    if args.count:
        extra.append("--count")
    if args.force:
        extra.append("--force")
    if args.timeout:
        extra += ["--timeout", str(args.timeout)]
    if args.alternate:
        extra += ["--alternate", "--first", args.first]
    if args.threads:
        extra += ["--threads", str(args.threads)]
    if args.max_positions:
        extra += ["--max-positions", str(args.max_positions)]
    rc, result = run_core("solve", board, piece, extra, quiet=args.quiet)
    if args.json:
        print(json.dumps(result))
        return 0 if result.get("status") in ("solved", "impossible") else (rc or 1)
    bad = _core_status(rc, result)
    if bad is not None:
        return bad
    title = f"{piece.name} on {board.F}x{board.R}" + (" (alternating turns)" if args.alternate else "")
    _print_components(result)
    if result["status"] == "impossible":
        reasons = [c.get("reason", "") for c in result.get("components", [])
                   if c["status"] != "solved"]
        print(f"{title}: IMPOSSIBLE" + (f" -- {reasons[0]}" if reasons and reasons[0] else
                                        (f" -- {result['reason']}" if "reason" in result else "")))
        return 0
    print(f"{title}: minimum = {result['min']} moves (exact)")
    if args.count:
        total, n = total_count(result)
        print(f"number of optimal move sequences: {total}")
    if args.print_solution or args.export:
        moves = [m for c in result["components"] for m in c["moves"]]
        if not _verify_and_print(board, piece, moves, "optimal solution"):
            return 1
        if args.export:
            _write_export(board, piece, moves, args.export)
    return 0


def total_count(result: dict) -> tuple[int, int]:
    """Combine per-component counts: independent components interleave freely,
    so total = prod(c_i) * multinomial(n; n_1, ..., n_m)."""
    total, n = 1, 0
    for c in result["components"]:
        if c.get("count_overflow"):
            raise CoreError("count overflowed 128 bits in the core")
        total *= int(c["count"])
        n += c["min"]
        total *= math.comb(n, c["min"])
    return total, n


def cmd_construct(args, board, piece) -> int:
    extra = []
    for flag in ("tight", "symmetric"):
        if getattr(args, flag):
            extra.append("--" + flag)
    for opt in ("slack", "start_slack", "seed", "node_limit", "timeout"):
        v = getattr(args, opt)
        if v is not None:
            extra += ["--" + opt.replace("_", "-"), str(v)]
    rc, result = run_core("construct", board, piece, extra, quiet=args.quiet)
    if args.json:
        print(json.dumps(result))
        return 0 if result.get("status") == "found" else 1
    bad = _core_status(rc, result)
    if bad is not None:
        return bad
    title = f"{piece.name} on {board.F}x{board.R}"
    comps = result.get("components", [])
    if len(comps) > 1:
        print(f"independent components of the move graph: {len(comps)}")
    for i, c in enumerate(comps, 1):
        line = (f"  component {i} ({len(c['squares'])} squares): {c['status']}, "
                f"lower bound {c['lower_bound']}")
        if c["length"] >= 0:
            line += f", found {c['length']} moves (slack {c['slack_used']})"
        if c.get("proved_no_slack_below", 0) > 0:
            line += (f"; proved: no solution shorter than "
                     f"{c['lower_bound'] + c['proved_no_slack_below']}")
        if c.get("symmetric"):
            line += ", symmetric pairs"
        if c.get("reused"):
            line += f"  [{c['reused']}]"
        print(line)
    st = result["status"]
    if st != "found":
        msg = {"impossible": "IMPOSSIBLE (a piece cannot reach its target rank, or a component "
                             "has unequal numbers of rank-1 and rank-R squares)",
               "no-solution": "no solution within the allowed slack (search exhausted)",
               "timeout": "TIMEOUT before a solution was found"}.get(st, st)
        print(f"{title}: {msg}")
        return 1
    lb = result["lower_bound"]
    if result["length"] == lb:
        note = " = lower bound, hence OPTIMAL"
    elif all(c.get("proved_no_slack_below", -1) == c["slack_used"] for c in comps):
        note = (f" -- OPTIMAL: IDA* exhausted every shorter length (heuristic lower bound {lb})")
    else:
        note = f" (lower bound {lb}; optimality not proved)"
    print(f"{title}: found a solution with {result['length']} moves{note}")
    moves = [m for c in comps for m in c["moves"]]
    if not _verify_and_print(board, piece, moves, "solution"):
        return 1
    if args.export:
        _write_export(board, piece, moves, args.export)
    return 0


def cmd_bound(args, board, piece) -> int:
    from .bound import lower_bounds
    r = lower_bounds(board, piece, args.method)
    if args.json:
        print(json.dumps({k: v for k, v in r.items()}, default=str))
        return 0
    title = f"{piece.name} on {board.F}x{board.R}"
    if r["matching"] == math.inf:
        print(f"{title}: some piece cannot reach any free target square on the empty board "
              "-> the swap is IMPOSSIBLE (bound = infinity)")
        return 0
    print(f"{title}: distance-matching lower bound = {int(r['matching'])} moves "
          f"(white {int(r['white'])} + black {int(r['black'])}; {r['method']})")
    print(f"  (weaker nearest-target-rank bound used by construct: {int(r['nearest'])})")
    if args.verbose:
        for label, key in (("white", "white_assignment"), ("black", "black_assignment")):
            pairs = ", ".join(f"{board.name(s)}->{board.name(t)}" for s, t in r[key])
            print(f"  optimal {label} assignment: {pairs}")
    return 0


def _write_export(board, piece, moves_txt: list[str], path: str, cols: int = 4,
                  fmt: str = "table", caption: str | None = None) -> None:
    from .export import appendix_tuples, labelled_moves, typst_table
    items = labelled_moves(board, piece, parse_moves(board, " ".join(moves_txt)))
    text = typst_table(items, cols, caption) if fmt == "table" else appendix_tuples(items, cols)
    if path == "-":
        sys.stdout.write(text)
    else:
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(text)
        print(f"wrote Typst {'table' if fmt == 'table' else 'move-table call'} "
              f"({len(items)} moves) to {path}")


def cmd_export(args, board, piece) -> int:
    text = _read_moves_text(args)
    moves = parse_moves(board, text)
    res = check_moves(board, piece, moves)
    if res.error_index is not None:
        print(f"INVALID: {res.error}", file=sys.stderr)
        return 1
    if not res.reached_goal:
        print("warning: the sequence is legal but does not reach the goal", file=sys.stderr)
    _write_export(board, piece, [format_moves(board, moves)], args.output, args.cols,
                  args.format, args.caption)
    return 0


def build_parser() -> argparse.ArgumentParser:
    ap = argparse.ArgumentParser(
        prog="swaprows",
        description="Research tool for swapping two rows of chess pieces.")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("check", help="verify a move list")
    _common(p)
    p.add_argument("moves", nargs="*", help='moves, e.g. "a1-b3 c8-d6"')
    p.add_argument("--file", help="read moves from a file ('-' = stdin)")
    p.add_argument("--alternate", action="store_true", help="colours must alternate")
    p.add_argument("--first", choices=("white", "black", "either"), default="either",
                   help="with --alternate: who moves first (default either)")
    p.set_defaults(func=cmd_check)

    p = sub.add_parser("solve", help="exact minimum by layered BFS + meet in the middle")
    _common(p)
    p.add_argument("--print-solution", action="store_true", help="print one optimal sequence")
    p.add_argument("--count", action="store_true", help="count optimal move sequences")
    p.add_argument("--force", action="store_true", help="skip the state-space size safety check")
    p.add_argument("--max-positions", type=float, help="safety threshold (default 1e8)")
    p.add_argument("--timeout", type=float, help="give up after this many seconds")
    p.add_argument("--alternate", action="store_true", help="colours alternate turns")
    p.add_argument("--first", choices=("white", "black", "either"), default="either",
                   help="with --alternate: who moves first (default either)")
    p.add_argument("--threads", type=int, help="number of threads (default: all cores)")
    p.add_argument("--quiet", action="store_true", help="no per-layer progress")
    p.add_argument("--json", action="store_true", help="print the raw JSON result")
    p.add_argument("--export", metavar="FILE.typ", help="write the optimal solution as a Typst table")
    p.set_defaults(func=cmd_solve)

    p = sub.add_parser("construct", help="find a (not necessarily optimal) solution by IDA*")
    _common(p)
    p.add_argument("--tight", action="store_true",
                   help="only moves that decrease the moving piece's own distance by 1")
    p.add_argument("--slack", type=int,
                   help="with --tight: allow this many extra moves beyond the lower bound "
                        "(default 0); without --tight: maximum slack (default unbounded)")
    p.add_argument("--start-slack", type=int, help="first slack to try (default 0)")
    p.add_argument("--symmetric", action="store_true",
                   help="pair each white move with its 180-degree-rotated black move")
    p.add_argument("--seed", type=int, help="random seed for move ordering (default 1)")
    p.add_argument("--node-limit", type=int, help="nodes per restart (default 200000, grows)")
    p.add_argument("--timeout", type=float, help="give up after this many seconds")
    p.add_argument("--quiet", action="store_true")
    p.add_argument("--json", action="store_true", help="print the raw JSON result")
    p.add_argument("--export", metavar="FILE.typ", help="write the solution as a Typst table")
    p.set_defaults(func=cmd_construct)

    p = sub.add_parser("bound", help="distance-matching lower bound (optimal assignment)")
    _common(p)
    p.add_argument("--method", choices=("auto", "hungarian", "brute"), default="auto",
                   help="assignment solver (auto: brute force for F <= 7, else Hungarian)")
    p.add_argument("--verbose", action="store_true", help="print the optimal assignments")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_bound)

    p = sub.add_parser("export", help="export a move list as a Typst table")
    _common(p)
    p.add_argument("moves", nargs="*", help='moves, e.g. "a1-b3 c8-d6"')
    p.add_argument("--file", help="read moves from a file ('-' = stdin)")
    p.add_argument("-o", "--output", default="-", help="output .typ file (default stdout)")
    p.add_argument("--cols", type=int, default=4, help="blocks side by side (default 4)")
    p.add_argument("--format", choices=("table", "appendix"), default="table",
                   help="table: standalone #table; appendix: move-table(...) call as in "
                        "paper/sections/apendice.typ")
    p.add_argument("--caption", help="wrap the table in a #figure with this caption")
    p.set_defaults(func=cmd_export)
    return ap


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.piece.lower() == "pawn":
            print(PAWN_EXPLANATION)
            return 0
        board = Board(args.files, args.ranks)
        piece = make_piece(args.piece, args.dirs, args.slides, args.symmetrize)
        return args.func(args, board, piece)
    except (BoardError, PieceError, CoreError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
