"""Minimal test harness shared by run_fast_tests.py and run_full_tests.py."""

from __future__ import annotations

import os
import subprocess
import sys
import time
import traceback

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DATA = os.path.join(HERE, "data")
CLI = [sys.executable, os.path.join(ROOT, "swaprows.py")]

sys.path.insert(0, ROOT)

_TESTS: list[tuple[str, str, bool, object]] = []  # (feature, name, slow, fn)


def test(feature: str, slow: bool = False):
    def deco(fn):
        _TESTS.append((feature, fn.__name__, slow, fn))
        return fn
    return deco


class Fail(AssertionError):
    pass


def run_cli(*args, timeout: float = 3600, stdin: str | None = None):
    """Run the CLI; return (returncode, stdout, stderr)."""
    p = subprocess.run(CLI + [str(a) for a in args], capture_output=True, text=True,
                       timeout=timeout, input=stdin)
    return p.returncode, p.stdout, p.stderr


def expect(cond, msg: str):
    if not cond:
        raise Fail(msg)


def run_all(include_slow: bool) -> int:
    import cases  # noqa: F401  (registers the tests)
    selected = [t for t in _TESTS if include_slow or not t[2]]
    only = os.environ.get("ONLY")
    if only:
        selected = [t for t in selected if only in t[1] or only == t[0]]
    print(f"running {len(selected)} tests ({'full' if include_slow else 'fast'} suite)")
    failures = []
    t_all = time.time()
    for feature, name, slow, fn in selected:
        t0 = time.time()
        try:
            fn()
            status = "PASS"
        except Exception as e:  # noqa: BLE001
            status = "FAIL"
            detail = "".join(traceback.format_exception_only(type(e), e)).strip()
            if not isinstance(e, Fail):
                detail = traceback.format_exc()
            failures.append((feature, name, detail))
        dt = time.time() - t0
        print(f"[{status}] {feature:9s} {name:45s} {dt:8.2f}s", flush=True)
        if status == "FAIL":
            print("        " + failures[-1][2].replace("\n", "\n        "), flush=True)
    print(f"\n{len(selected) - len(failures)}/{len(selected)} passed "
          f"in {time.time() - t_all:.1f}s")
    return 1 if failures else 0
