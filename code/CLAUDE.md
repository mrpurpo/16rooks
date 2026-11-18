WORKFLOW
- Build the tool one feature at a time, in the order: checker, solve, construct, count, bound,
  export.
- After finishing each feature, run the test suite (tests/run_fast_tests.py) and fix every
  failure before starting the next feature. Never delete or weaken a test to make it pass.
- At the end, run tests/run_full_tests.py and report the exact commands you ran and their
  output. If something was not run, say so.
