"""All test cases, grouped by feature.  Tests marked slow=True only run in the
full suite (run_full_tests.py)."""

from __future__ import annotations

import os

from testlib import DATA, expect, run_cli, test

from swaprows.board import Board, parse_moves
from swaprows.checker import check_moves
from swaprows.pieces import BUILTIN


def data(name: str) -> str:
    return os.path.join(DATA, name)


def read(name: str) -> str:
    with open(data(name), encoding="utf-8") as fh:
        return fh.read()


def check_ok(piece: str, F: int, R: int, moves_text: str, n: int | None = None,
             alternate: bool = False, first: str = "either"):
    b = Board(F, R)
    res = check_moves(b, BUILTIN[piece], parse_moves(b, moves_text), alternate, first)
    expect(res.ok, f"{piece} {F}x{R}: checker rejected: {res.error}")
    if n is not None:
        expect(res.num_moves == n, f"expected {n} moves, got {res.num_moves}")


def check_bad(piece: str, F: int, R: int, moves_text: str, fragment: str = "",
              alternate: bool = False, first: str = "either"):
    b = Board(F, R)
    res = check_moves(b, BUILTIN[piece], parse_moves(b, moves_text), alternate, first)
    expect(not res.ok, f"{piece} {F}x{R}: checker accepted invalid sequence")
    expect(fragment in (res.error or ""), f"error {res.error!r} lacks {fragment!r}")


# ======================================================================
# 1. checker
# ======================================================================

@test("checker")
def check_rook_33_known_solution():
    rc, out, _ = run_cli("check", "rook", 8, 8, "--file", data("rook8x8_33.txt"))
    expect(rc == 0 and "OK: 33 legal moves" in out, out)


@test("checker")
def check_king_112_known_solution():
    rc, out, _ = run_cli("check", "king", 8, 8, "--file", data("king8x8_112.txt"))
    expect(rc == 0 and "OK: 112 legal moves" in out, out)


@test("checker")
def check_other_paper_solutions():
    check_ok("knight", 8, 8, read("knight8x8_64_paper.txt"), 64)
    check_ok("bishop", 8, 8, read("bishop8x8_30_paper.txt"), 30)
    check_ok("queen", 8, 8, read("queen8x8_23_paper.txt"), 23)
    # the knight and queen sequences in the paper also alternate colours
    check_ok("queen", 8, 8, read("queen8x8_23_paper.txt"), 23, True, "white")
    check_ok("knight", 8, 8, read("knight8x8_64_paper.txt"), 64, True, "white")


@test("checker")
def check_rejects_illegal_moves():
    check_bad("rook", 8, 8, "a1-b2", "not a rook move")
    check_bad("rook", 8, 8, "a1-a8", "occupied")
    check_bad("rook", 8, 8, "b8-b2 b1-b3", "blocked at b2")
    check_bad("rook", 8, 8, "c4-c5", "no piece on c4")
    check_bad("bishop", 8, 8, "b8-e5 a1-f6", "blocked at e5")
    # 3 legal moves (d1-h5 slides over the empty e2,f3,g4), undone, then a solution
    check_ok("bishop", 8, 8, "c1-a3 b8-h2 d1-h5 h5-d1 h2-b8 a3-c1 "
             + read("bishop8x8_30_paper.txt"), 36)
    check_bad("knight", 8, 8, "b1-b3", "not a knight move")
    check_bad("king", 8, 8, "e1-e3", "not a king move")


@test("checker")
def check_knight_jumps_and_incomplete():
    check_bad("knight", 8, 8, "b1-c3 g8-f6", "not the goal")  # legal but incomplete
    check_bad("rook", 2, 3, "", "not the goal")


@test("checker")
def check_tampered_solutions_rejected():
    king = parse_moves(Board(8, 8), read("king8x8_112.txt"))
    b = Board(8, 8)
    res = check_moves(b, BUILTIN["king"], king[:-1])
    expect(not res.ok and "not the goal" in res.error, res.error)
    res = check_moves(b, BUILTIN["king"], king[1:])
    expect(not res.ok and res.error_index is not None, res.error)
    rook = parse_moves(b, read("rook8x8_33.txt"))
    res = check_moves(b, BUILTIN["rook"], rook[::-1])
    expect(not res.ok, "reversed rook solution accepted")
    res = check_moves(b, BUILTIN["queen"], rook)  # rook moves are queen moves
    expect(res.ok, "rook solution must also be a valid queen solution")


@test("checker")
def check_alternation_rules():
    check_bad("queen", 8, 8, read("queen8x8_23_paper.txt"), "black must move first",
              True, "black")
    check_bad("rook", 8, 8, read("rook8x8_33.txt"), "moved twice", True)


@test("checker")
def check_cli_parsing_and_errors():
    rc, out, err = run_cli("check", "rook", 2, 3, "a1-a2 zz")
    expect(rc == 2 and "cannot parse" in err, err)
    rc, out, err = run_cli("check", "rook", 2, 3, "a1-c2")
    expect(rc == 2 and "off the" in err, err)
    rc, out, _ = run_cli("check", "rook", 8, 8, "--file", "-", stdin=read("rook8x8_33.txt"))
    expect(rc == 0, out)
    rc, out, _ = run_cli("check", "rook", 8, 8, "a1-b2")
    expect(rc == 1 and "INVALID" in out, out)
    rc, out, _ = run_cli("check", "pawn", 8, 8, "a1-a2")
    expect(rc == 0 and "IMPOSSIBLE" in out, out)
    rc, _, err = run_cli("check", "custom", 3, 3, "--dirs", "1,2", "a1-b3")
    expect(rc == 2 and "not closed under negation" in err, err)
    # custom piece = knight, written explicitly
    rc, out, _ = run_cli("check", "custom", 8, 8, "--dirs",
                         "1,2;2,1;2,-1;1,-2;-1,-2;-2,-1;-2,1;-1,2", "--slides", "false",
                         "--file", data("knight8x8_64_paper.txt"))
    expect(rc == 0, out)


# ======================================================================
# 2. solve
# ======================================================================

from reference import reference_solve  # noqa: E402
from swaprows.pieces import make_piece  # noqa: E402


def solve_json(*args, timeout=3600):
    import json
    rc, out, err = run_cli("solve", *args, "--json", "--quiet", timeout=timeout)
    try:
        return rc, json.loads(out)
    except Exception:  # noqa: BLE001
        raise AssertionError(f"no JSON (rc={rc}): {out!r} {err!r}")


def expect_min(piece, F, R, expected, *extra):
    rc, d = solve_json(piece, F, R, *extra)
    if expected is None:
        expect(d["status"] == "impossible", f"{piece} {F}x{R}: expected impossible, got {d}")
    else:
        expect(d["status"] == "solved" and d["min"] == expected,
               f"{piece} {F}x{R}: expected {expected}, got {d.get('status')} {d.get('min')}")
    return d


EXACT_FAST = [
    ("rook", 2, 3, 10), ("rook", 2, 8, 9), ("rook", 3, 3, 14), ("rook", 3, 8, 13),
    ("rook", 4, 4, 18), ("rook", 4, 5, 17),
    ("bishop", 3, 8, None), ("bishop", 4, 4, 14), ("bishop", 5, 5, 18), ("bishop", 6, 6, 22),
    ("bishop", 7, 7, 26),
    ("knight", 3, 3, 8), ("knight", 3, 4, 16), ("knight", 3, 5, 14), ("knight", 4, 4, 16),
    ("knight", 4, 5, 16), ("knight", 5, 4, 22),
    ("king", 2, 3, 8), ("king", 3, 4, 18), ("king", 4, 5, 32),
]


def _make_exact_test(piece, F, R, val, slow=False):
    def fn():
        expect_min(piece, F, R, val, *(["--force"] if slow else []))
    fn.__name__ = f"solve_{piece}_{F}x{R}_{'impossible' if val is None else val}"
    test("solve", slow=slow)(fn)


for _p, _F, _R, _v in EXACT_FAST:
    _make_exact_test(_p, _F, _R, _v)
_make_exact_test("bishop", 8, 8, 30, slow=True)


@test("solve")
def solve_bishop_2xR_impossible_all_R():
    for R in range(2, 33):
        expect_min("bishop", 2, R, None)


@test("solve")
def solve_knight_2xR_impossible_all_R():
    for R in range(2, 33):
        expect_min("knight", 2, R, None)


@test("solve")
def solve_print_solution_is_valid_and_optimal():
    for piece, F, R, val in [("rook", 3, 3, 14), ("rook", 4, 5, 17), ("bishop", 5, 5, 18),
                             ("bishop", 6, 6, 22), ("knight", 3, 5, 14), ("king", 3, 4, 18),
                             ("queen", 3, 4, None), ("knight", 4, 5, 16)]:
        rc, d = solve_json(piece, F, R, "--print-solution")
        if val is None:
            val = d["min"]
        expect(d["status"] == "solved" and d["min"] == val, f"{piece} {F}x{R}: {d}")
        moves = " ".join(m for c in d["components"] for m in c["moves"])
        check_ok(piece, F, R, moves, val)


@test("solve")
def solve_cli_text_output_and_recheck():
    rc, out, _ = run_cli("solve", "rook", 2, 3, "--print-solution", "--quiet")
    expect(rc == 0 and "minimum = 10 moves (exact)" in out and "re-checked: OK" in out, out)
    rc, out, _ = run_cli("solve", "bishop", 3, 8, "--quiet")
    expect(rc == 0 and "IMPOSSIBLE" in out, out)
    rc, out, _ = run_cli("solve", "pawn", 8, 8)
    expect(rc == 0 and "IMPOSSIBLE" in out and "file" in out, out)


TINY = [(2, 3), (3, 2), (2, 4), (3, 3), (4, 2), (2, 5), (3, 4), (4, 3)]
CUSTOM = {
    "wazir": ("1,0;-1,0;0,1;0,-1", "false"),
    "ferz": ("1,1;1,-1;-1,1;-1,-1", "false"),
    "dabbaba-rider": ("2,0;-2,0;0,2;0,-2", "true"),
    "camel": ("1,3;3,1;-1,3;-3,1;1,-3;3,-1;-1,-3;-3,-1", "false"),
    "vertical-rook": ("0,1;0,-1", "true"),
}


@test("solve")
def solve_matches_bruteforce_reference():
    """C++ (meet in the middle + components + symmetry reuse) vs plain BFS."""
    for name in ["rook", "bishop", "queen", "king", "knight"] + list(CUSTOM):
        if name in CUSTOM:
            piece = make_piece("custom", *CUSTOM[name])
            extra = ["--dirs", CUSTOM[name][0], "--slides", CUSTOM[name][1]]
            cli_name = "custom"
        else:
            piece, extra, cli_name = make_piece(name), [], name
        for F, R in TINY:
            ref, _ = reference_solve(Board(F, R), piece)
            rc, d = solve_json(cli_name, F, R, *extra)
            got = d["min"] if d["status"] == "solved" else None
            expect(got == ref, f"{name} {F}x{R}: core {got}, reference {ref}")


def _alternate_vs_reference(boards):
    for name in ["rook", "queen", "king", "knight", "bishop"]:
        piece = make_piece(name)
        for F, R in boards:
            for first in ("white", "black", "either"):
                ref, _ = reference_solve(Board(F, R), piece, True, first)
                rc, d = solve_json(name, F, R, "--alternate", "--first", first)
                got = d["min"] if d["status"] == "solved" else None
                expect(got == ref, f"{name} {F}x{R} alternate first={first}: core {got}, "
                                   f"reference {ref}")


@test("solve")
def solve_alternate_matches_bruteforce_reference():
    _alternate_vs_reference([(2, 3), (3, 3), (2, 4), (3, 4), (4, 3)])


@test("solve", slow=True)
def solve_alternate_matches_bruteforce_reference_4x4():
    _alternate_vs_reference([(4, 4)])  # slow only because the Python reference is slow


@test("solve")
def solve_alternate_never_shorter():
    for piece, F, R in [("rook", 3, 4), ("king", 3, 4), ("knight", 3, 5)]:
        _, free = solve_json(piece, F, R)
        _, alt = solve_json(piece, F, R, "--alternate")
        expect(alt["status"] == "impossible" or alt["min"] >= free["min"], f"{piece} {alt} {free}")


@test("solve")
def solve_safety_refusal_and_timeout():
    rc, out, _ = run_cli("solve", "rook", 8, 8, "--quiet")
    expect(rc == 3 and "REFUSED" in out and "construct" in out, out)
    rc, out, _ = run_cli("solve", "rook", 4, 5, "--quiet", "--max-positions", "1000")
    expect(rc == 3 and "REFUSED" in out, out)
    rc, out, _ = run_cli("solve", "rook", 4, 5, "--quiet", "--max-positions", "1000", "--force")
    expect(rc == 0 and "minimum = 17" in out, out)
    rc, out, _ = run_cli("solve", "bishop", 8, 8, "--quiet", "--force", "--timeout", "1")
    expect(rc == 4 and "TIMEOUT" in out, out)


@test("solve")
def solve_components_and_symmetry_reuse():
    _, d = solve_json("bishop", 4, 4)
    comps = d["components"]
    expect(len(comps) == 2 and comps[1].get("reused", "").startswith("component 1"), str(d))
    _, d = solve_json("bishop", 5, 5)  # odd: classes differ, both solved
    expect(len(d["components"]) == 2 and d["min"] == 18, str(d))


# ======================================================================
# 3. construct
# ======================================================================

def construct_json(*args, timeout=3600):
    import json
    rc, out, err = run_cli("construct", *args, "--json", "--quiet", timeout=timeout)
    try:
        return json.loads(out)
    except Exception:  # noqa: BLE001
        raise AssertionError(f"no JSON (rc={rc}): {out!r} {err!r}")


def construct_and_check(piece, F, R, expected_len, *args):
    d = construct_json(piece, F, R, *args)
    expect(d["status"] == "found", f"{piece} {F}x{R} {args}: {d['status']}")
    expect(d["length"] == expected_len, f"{piece} {F}x{R}: length {d['length']} != {expected_len}")
    moves = " ".join(m for c in d["components"] for m in c["moves"])
    check_ok(piece, F, R, moves, expected_len)  # independent checker accepts it
    rc, out, _ = run_cli("check", piece, F, R, moves)
    expect(rc == 0 and f"OK: {expected_len} legal moves" in out, out)
    return d


@test("construct")
def construct_knight_8x8_tight_symmetric_64():
    d = construct_and_check("knight", 8, 8, 64, "--tight", "--symmetric")
    expect(d["components"][0]["symmetric"], "symmetric mode was not used")


@test("construct")
def construct_king_8x8_tight_112():
    construct_and_check("king", 8, 8, 112, "--tight")


@test("construct")
def construct_bishop_8x8_30_fifteen_per_class():
    # Each colour class has heuristic bound 14 but optimum 15 (the two corner
    # bishops share the long diagonal), so one unit of slack per class is needed.
    d = construct_and_check("bishop", 8, 8, 30, "--tight", "--slack", "1")
    expect([c["length"] for c in d["components"]] == [15, 15], str(d["components"]))


@test("construct")
def construct_bishop_8x8_strict_tight_proves_14_impossible():
    d = construct_json("bishop", 8, 8, "--tight")
    expect(d["status"] == "no-solution", d["status"])
    for c in d["components"]:
        expect(c["lower_bound"] == 14 and c["proved_no_slack_below"] == 1, str(c))


@test("construct")
def construct_robust_to_seeds():
    for seed in (2, 3, 4):
        construct_and_check("knight", 8, 8, 64, "--tight", "--symmetric", "--seed", seed)
        construct_and_check("king", 8, 8, 112, "--tight", "--seed", seed)
    construct_and_check("knight", 8, 8, 64, "--tight")  # also without the symmetric pairing


@test("construct")
def construct_ida_star_is_optimal_on_small_boards():
    # Without restarts cutting it short, IDA* proves every smaller threshold
    # infeasible, so the construction length equals the exact minimum.
    for piece, F, R, val in [("rook", 3, 3, 14), ("rook", 2, 5, None), ("knight", 3, 4, 16),
                             ("king", 3, 4, 18), ("bishop", 5, 5, 18), ("queen", 3, 3, None)]:
        if val is None:
            _, s = solve_json(piece, F, R)
            val = s["min"]
        construct_and_check(piece, F, R, val, "--timeout", "60")


@test("construct")
def construct_impossible_and_timeout():
    d = construct_json("bishop", 3, 8)
    expect(d["status"] == "impossible", d["status"])
    d = construct_json("knight", 2, 4)
    expect(d["status"] == "impossible", d["status"])
    rc, out, _ = run_cli("construct", "rook", 8, 8, "--timeout", "2", "--quiet")
    expect(rc == 1 and "TIMEOUT" in out, out)
    rc, out, _ = run_cli("construct", "king", 8, 8, "--tight", "--quiet")
    expect(rc == 0 and "OPTIMAL" in out and "re-checked: OK" in out, out)
    rc, out, _ = run_cli("construct", "rook", 3, 3, "--quiet")
    expect(rc == 0 and "OPTIMAL: IDA* exhausted" in out, out)
    # symmetric exhaustion must NOT be reported as a general proof
    d = construct_json("bishop", 8, 8, "--tight", "--symmetric")
    expect(all(c["proved_no_slack_below"] == -1 for c in d["components"]), str(d))


# ======================================================================
# 4. count
# ======================================================================

def count_of(piece, F, R, *extra):
    rc, out, err = run_cli("solve", piece, F, R, "--count", "--quiet", *extra)
    expect(rc == 0, f"rc={rc} {out} {err}")
    if "IMPOSSIBLE" in out:
        return None, 0
    import re
    m = re.search(r"minimum = (\d+) moves", out)
    c = re.search(r"number of optimal move sequences: (\d+)", out)
    expect(m and c, out)
    return int(m.group(1)), int(c.group(1))


@test("count")
def count_rook_2x3_112():
    expect(count_of("rook", 2, 3) == (10, 112), str(count_of("rook", 2, 3)))


@test("count")
def count_rook_2x5_432():
    expect(count_of("rook", 2, 5) == (9, 432), str(count_of("rook", 2, 5)))


@test("count")
def count_rook_3x3_9792():
    expect(count_of("rook", 3, 3) == (14, 9792), str(count_of("rook", 3, 3)))


@test("count")
def count_matches_bruteforce_reference():
    """Includes multi-component pieces (bishop, knight, custom), which checks the
    interleaving formula prod(c_i) * multinomial used to combine components."""
    for name in ["rook", "bishop", "queen", "king", "knight", "ferz", "camel", "wazir"]:
        if name in CUSTOM:
            piece = make_piece("custom", *CUSTOM[name])
            extra = ["--dirs", CUSTOM[name][0], "--slides", CUSTOM[name][1]]
            cli = "custom"
        else:
            piece, extra, cli = make_piece(name), [], name
        for F, R in TINY:
            ref = reference_solve(Board(F, R), piece)
            got = count_of(cli, F, R, *extra)
            expect(got == ref, f"{name} {F}x{R}: core {got}, reference {ref}")


@test("count")
def count_with_print_solution_and_larger_boards():
    rc, out, _ = run_cli("solve", "rook", 3, 3, "--count", "--print-solution", "--quiet")
    expect(rc == 0 and "9792" in out and "re-checked: OK" in out, out)
    n, c = count_of("bishop", 6, 6)
    expect(n == 22 and c > 0, str((n, c)))
    n, c = count_of("rook", 4, 5)
    expect(n == 17 and c > 0, str((n, c)))
    expect(count_of("bishop", 3, 8) == (None, 0), "bishop 3x8 should be impossible")


# ======================================================================
# 5. bound
# ======================================================================

import math  # noqa: E402
import random  # noqa: E402

from swaprows.bound import brute_force, hungarian, lower_bounds  # noqa: E402


@test("bound")
def bound_hungarian_matches_brute_force():
    rng = random.Random(12345)
    for trial in range(400):
        n = rng.randint(1, 7)
        m = [[(math.inf if rng.random() < 0.2 else rng.randint(0, 9)) for _ in range(n)]
             for _ in range(n)]
        h, ha = hungarian(m)
        b, _ = brute_force(m)
        expect(h == b, f"trial {trial}: hungarian {h} != brute {b} for {m}")
        if h != math.inf:
            expect(sorted(ha) == list(range(n)) and sum(m[i][ha[i]] for i in range(n)) == h,
                   "assignment inconsistent")


@test("bound")
def bound_known_values_8x8():
    for piece, val in [("rook", 16), ("queen", 16), ("king", 112), ("knight", 64), ("bishop", 28)]:
        r = lower_bounds(Board(8, 8), BUILTIN[piece])
        expect(r["matching"] == val, f"{piece}: {r['matching']} != {val}")
        r2 = lower_bounds(Board(8, 8), BUILTIN[piece], "hungarian")
        expect(r2["matching"] == val, piece)


@test("bound")
def bound_is_a_valid_lower_bound():
    for piece, F, R, val in EXACT_FAST + [("bishop", 8, 8, 30)]:
        r = lower_bounds(Board(F, R), BUILTIN[piece])
        if val is None:
            continue
        expect(r["matching"] <= val, f"{piece} {F}x{R}: bound {r['matching']} > exact {val}")
        expect(r["nearest"] <= r["matching"], f"{piece} {F}x{R}: nearest > matching")
        # brute force and Hungarian agree on the bound itself
        expect(lower_bounds(Board(F, R), BUILTIN[piece], "brute")["matching"] ==
               lower_bounds(Board(F, R), BUILTIN[piece], "hungarian")["matching"], piece)


@test("bound")
def bound_cli_and_impossible():
    rc, out, _ = run_cli("bound", "king", 8, 8)
    expect(rc == 0 and "lower bound = 112" in out, out)
    rc, out, _ = run_cli("bound", "bishop", 3, 8)
    expect(rc == 0 and "IMPOSSIBLE" in out, out)
    rc, out, _ = run_cli("bound", "knight", 3, 3, "--verbose")
    expect(rc == 0 and "lower bound = 8" in out and "assignment" in out, out)
    # bound attained by the construction => construction is optimal (king, knight)
    for piece in ("king", "knight"):
        d = construct_json(piece, 8, 8, "--tight", "--symmetric")
        expect(d["length"] == lower_bounds(Board(8, 8), BUILTIN[piece])["matching"], piece)


# ======================================================================
# 6. export
# ======================================================================

import re as _re  # noqa: E402
import shutil  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402

from swaprows.export import appendix_tuples, labelled_moves, typst_table  # noqa: E402


def typst_compiles(source: str) -> None:
    exe = shutil.which("typst")
    expect(exe is not None, "typst is not installed: cannot verify the export compiles")
    with tempfile.TemporaryDirectory() as d:
        src = os.path.join(d, "t.typ")
        with open(src, "w", encoding="utf-8") as fh:
            fh.write(source)
        p = subprocess.run([exe, "compile", src, os.path.join(d, "t.pdf")],
                           capture_output=True, text=True)
        expect(p.returncode == 0, f"typst compile failed:\n{p.stderr}\n--- source ---\n{source}")


def paper_items(name):
    return [tuple(line.split()) for line in read(name).splitlines() if line.strip()]


@test("export")
def export_labels_match_paper_appendix():
    for name, piece in [("rook8x8_33.txt", "rook"), ("king8x8_112.txt", "king"),
                        ("knight8x8_64_paper.txt", "knight"), ("bishop8x8_30_paper.txt", "bishop")]:
        b = Board(8, 8)
        items = labelled_moves(b, BUILTIN[piece], parse_moves(b, read(name)))
        expect(items == paper_items(name), f"{name}: labels/moves differ from the paper")


@test("export")
def export_table_layout_four_blocks():
    b = Board(8, 8)
    items = labelled_moves(b, BUILTIN["rook"], parse_moves(b, read("rook8x8_33.txt")))
    t = typst_table(items, 4)
    expect(t.count("[*N.º*], [*Movimiento*]") == 4, "header must have 4 N.º/Movimiento blocks")
    expect("columns: 8" in t, "8 columns expected")
    rows = [l for l in t.splitlines() if l.strip().startswith("[") and "`" in l]
    expect(len(rows) == 9, f"33 moves in 4 blocks -> 9 rows, got {len(rows)}")
    expect(rows[0].strip().startswith("[1], [`B a1-a3`], [10], [`B d1-d8`], [19], "),
           rows[0])
    expect("[33], [`N a2-a1`]" in t and "[], []" in t, "last move / padding missing")
    cells = _re.findall(r"\[`([BN]) ([a-z]\d+-[a-z]\d+)`\]", t)
    expect(sorted(cells) == sorted(items), "every move appears exactly once")


@test("export")
def export_typst_compiles():
    b = Board(8, 8)
    items = labelled_moves(b, BUILTIN["king"], parse_moves(b, read("king8x8_112.txt")))
    typst_compiles(typst_table(items, 4))
    typst_compiles(typst_table(items, 4, caption="Reyes, 112 movimientos"))
    typst_compiles(typst_table(items[:5], 3))
    # appendix format compiles together with the paper's move-table definition
    with open(os.path.join(os.path.dirname(DATA), "..", "..", "paper", "sections",
                           "apendice.typ"), encoding="utf-8") as fh:
        src = fh.read()
    definition = src[src.index("#let move-table"):src.index("#pagebreak()")]
    typst_compiles(definition + "\n" + appendix_tuples(items))


@test("export")
def export_appendix_format_round_trip():
    b = Board(8, 8)
    items = labelled_moves(b, BUILTIN["rook"], parse_moves(b, read("rook8x8_33.txt")))
    out = appendix_tuples(items)
    expect(_re.findall(r'\("([BN])", "([a-h]\d-[a-h]\d)"\)', out) == items, "round trip failed")


@test("export")
def export_cli_and_integration():
    with tempfile.TemporaryDirectory() as d:
        f = os.path.join(d, "rook.typ")
        rc, out, err = run_cli("export", "rook", 8, 8, "--file", data("rook8x8_33.txt"), "-o", f)
        expect(rc == 0 and os.path.exists(f), out + err)
        with open(f, encoding="utf-8") as fh:
            typst_compiles(fh.read())
        rc, out, err = run_cli("export", "rook", 8, 8, "a1-b2")
        expect(rc == 1 and "INVALID" in err, err)
        g = os.path.join(d, "solve.typ")
        rc, out, _ = run_cli("solve", "rook", 3, 3, "--quiet", "--export", g)
        expect(rc == 0 and "wrote Typst" in out, out)
        with open(g, encoding="utf-8") as fh:
            t = fh.read()
        expect("// 14 moves" in t, t[:80])
        typst_compiles(t)
        h = os.path.join(d, "construct.typ")
        rc, out, _ = run_cli("construct", "knight", 8, 8, "--tight", "--symmetric", "--quiet",
                             "--export", h)
        expect(rc == 0, out)
        with open(h, encoding="utf-8") as fh:
            t = fh.read()
        expect("// 64 moves" in t, t[:80])
        typst_compiles(t)
