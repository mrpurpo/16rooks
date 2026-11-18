#!/usr/bin/env python3
"""Run the full test suite (fast tests + slow exact solves and 8x8 constructions)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from testlib import run_all  # noqa: E402

if __name__ == "__main__":
    sys.exit(run_all(include_slow=True))
