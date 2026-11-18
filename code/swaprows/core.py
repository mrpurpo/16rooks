"""Build and invoke the C++ core (build/swapcore)."""

from __future__ import annotations

import json
import os
import subprocess
import sys

from .board import Board
from .pieces import Piece

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BIN = os.path.join(ROOT, "build", "swapcore")
SOURCES = [os.path.join(ROOT, "src", f) for f in
           ("main.cpp", "core.hpp", "solve.hpp", "construct.hpp")] + [os.path.join(ROOT, "Makefile")]


class CoreError(RuntimeError):
    pass


def ensure_built() -> None:
    newest = max(os.path.getmtime(f) for f in SOURCES)
    if os.path.exists(BIN) and os.path.getmtime(BIN) >= newest:
        return
    print("building the C++ core (make) ...", file=sys.stderr)
    p = subprocess.run(["make", "-C", ROOT], capture_output=True, text=True)
    if p.returncode != 0:
        raise CoreError("compilation failed:\n" + p.stdout + p.stderr)


def run_core(mode: str, board: Board, piece: Piece, extra: list[str],
             quiet: bool = False) -> tuple[int, dict]:
    """Run the core; stderr (progress) is passed through unless quiet."""
    ensure_built()
    cmd = [BIN, mode, "--files", str(board.F), "--ranks", str(board.R),
           "--dirs", piece.dirs_arg(), "--slides", "1" if piece.slides else "0"] + extra
    if quiet:
        cmd.append("--quiet")
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=None if not quiet else subprocess.PIPE,
                       text=True)
    try:
        result = json.loads(p.stdout.strip().splitlines()[-1])
    except (json.JSONDecodeError, IndexError):
        raise CoreError(f"core produced no result (exit {p.returncode}): {p.stdout!r}") from None
    return p.returncode, result
