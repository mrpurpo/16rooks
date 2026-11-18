# swaprows: swapping two rows of chess pieces

A command-line research tool for this problem: on a board with `F` files and `R` ranks
(`F·R ≤ 64`), `F` white pieces start on rank 1 and `F` black pieces start on rank `R`. All
pieces are the same type. A move relocates one piece of either colour according to its
movement rule. There is no turn order unless `--alternate` is given, and there are no captures:
the destination must be empty, and sliding pieces cannot pass through occupied squares. The
goal is to get every white piece onto rank `R` and every black piece onto rank 1. Pieces of the
same colour are interchangeable. The tool finds the minimum number of moves or proves the swap
impossible.

```
python3 swaprows.py solve     rook 4 5 --print-solution     # exact minimum (17)
python3 swaprows.py solve     rook 3 3 --count              # 14 moves, 9792 optimal sequences
python3 swaprows.py construct king 8 8 --tight              # 112-move solution (= lower bound)
python3 swaprows.py construct knight 8 8 --tight --symmetric
python3 swaprows.py check     rook 8 8 --file tests/data/rook8x8_33.txt
python3 swaprows.py bound     bishop 8 8 --verbose
python3 swaprows.py export    king 8 8 --file tests/data/king8x8_112.txt -o reyes.typ
python3 swaprows.py solve     custom 3 4 --dirs "1,2;2,1;2,-1;1,-2;-1,-2;-2,-1;-2,1;-1,2" --slides false
python3 swaprows.py solve     pawn 8 8                      # explains why it is impossible
```

The C++ core is compiled automatically with `make` the first time it is needed. You need
`g++` with C++17 and OpenMP. Python ≥ 3.9 is required, with no third-party packages.

## Contents

```
swaprows.py            entry point
swaprows/pieces.py     pieces as data (directions + slides flag), custom pieces, pawn explanation
swaprows/board.py      geometry, notation, move legality, empty-board distances
swaprows/checker.py    `check`
swaprows/bound.py      `bound` (Hungarian algorithm / brute force)
swaprows/export.py     `export` (Typst)
swaprows/core.py       builds and calls the C++ core
swaprows/cli.py        argument parsing and output
src/core.hpp           board, components, position keys, move generation
src/solve.hpp          `solve` (layered BFS, meet in the middle, --count, --alternate)
src/construct.hpp      `construct` (IDA*)
src/main.cpp           C++ driver (JSON on stdout, progress on stderr)
tests/                 run_fast_tests.py, run_full_tests.py, cases.py, reference.py, data/
```

## Model

**Squares and notation.** Square `s = rank·F + file`, both 0-based. Files are written `a…z`
and then `A…Z`; ranks are written 1-based, as in `a1` or `h8`.

**Pieces are data.** A piece is a list of `(dfile, drank)` directions plus a `slides` flag.
The built-in pieces are rook, bishop, queen, king and knight. Custom pieces come from
`--dirs "1,2;2,1;…" --slides true|false`. The direction set must be closed under negation,
because the exact algorithms rely on moves being reversible. `--symmetrize` adds the missing
opposite directions.

**Pawns.** The tool just prints the argument. Without captures a pawn never leaves its file,
and the white and black pawn of each file approach each other along that same file and block
each other forever, because pawns cannot jump over pieces or move backwards.

**Positions.** A position is two bitmasks, `(white, black)`, packed into one integer
`(white << HALF) | black`. That integer is a 64-bit word when the squares involved number at
most 32 (31 with `--alternate`, which uses the top bit for the side to move), and a 128-bit
integer otherwise.

## Algorithms, and why they are exact

### Independent components

Before searching, `solve` and `construct` split the board into the connected components of
the empty-board move graph. Two squares are connected when one move can lead from one to the
other.

- **Pieces in different components never interact.** A piece never leaves its component.
  Every square on a sliding ray is one step from the previous square, so the whole ray lies
  in one component, and a piece can only ever be blocked by pieces of its own component.
  Hence the minimum is the sum of the per-component minima, and a solution is the
  concatenation of the per-component solutions.
- **Bishops** have two components, the two square colours. **Knights** on narrow boards have
  several.
- **Count condition.** In each component the white pieces must end up on that component's
  rank-`R` squares. So if a component has a different number of rank-1 squares than rank-`R`
  squares, the swap is impossible. This is why the bishop swap is impossible for odd `F` with
  even `R`, such as 3x8.
- **Reusing a solved component.** A component is not searched again when it is the image of
  an already solved component under a symmetry of the whole problem. The symmetries checked
  are:
  - left-right mirror;
  - top-bottom flip plus colour swap;
  - 180° rotation plus colour swap.

  Each of these maps the start to the start, the goal to the goal, and moves to moves
  (provided the direction set is invariant), so the image component has the same minimum and
  count, and the mapped move list is a solution. For bishops with even `F`, the mirror maps
  the dark class onto the light class, so only one class is solved and its result is doubled.
- **`--alternate` disables the decomposition**, because the turn order couples the
  components. The impossibility test still applies.

### `solve`: layered BFS with meet in the middle

**Layered BFS.** Moves are reversible, so the move graph is undirected, and every neighbour of
a position at distance `k` is at distance `k−1`, `k` or `k+1`. Hence

    L(k+1) = N(L(k)) \ (L(k) ∪ L(k−1)),

and only the last two layers need to be stored. Each layer is a sorted vector, built by sort
plus unique and searched by binary search.

**Chunked expansion.** Neighbours are generated in slices with a bounded buffer: one thread
buffer per thread, then a parallel sort, a dedup, a filter against `L(k)` and `L(k−1)`, and a
merge into the new layer. This bounds memory beyond the layers themselves.

**Meet in the middle through the colour swap.** Let `swap(x)` exchange the two colours.
`swap` maps the start to the goal and legal moves to legal moves, and moves are reversible.
Reading a path from `x` to the goal backwards, with colours swapped, gives a path from the
start to `swap(x)`, and vice versa. Therefore

    dist(x, goal) = dist(start, swap(x)).

After building layer `k`, the solver checks every `x ∈ L(k)`:

- if `swap(x) ∈ L(k−1)`, a solution of length `2k−1` exists;
- if `swap(x) ∈ L(k)`, a solution of length `2k` exists.

**Why the first hit is exact.** Each hit is a real solution: a shortest path to `x`, followed
by the image of a shortest path to `swap(x)`. Conversely, take an optimal solution of length
`n` and its position `m` at index `k = ⌈n/2⌉`.

- Its prefix is optimal, so `m ∈ L(k)`.
- Its suffix is optimal, so `dist(start, swap(m)) = n − k`, which is `k` or `k−1`.

So the optimum is detected at layer `⌈n/2⌉`. Any hit at an earlier layer would give a solution
of length at most `2k < n`, which is impossible. Within one layer, `2k−1` is tested before `2k`.
The first layer with a hit therefore gives the exact minimum, and the BFS only goes about
half-way, which is the whole point of the method.

**Impossibility.** If a new layer is empty before any hit, the start's connected component
has been exhausted without reaching the goal, so the goal is unreachable.

**`--print-solution`.** All layers are kept. The path to `x` is rebuilt by repeatedly picking
a neighbour in the previous layer; this is a predecessor, because moves are reversible. The
path to `swap(x)` is rebuilt the same way, then reversed and colour-swapped. The CLI re-checks
every printed solution with the independent Python checker.

### `--count`: number of optimal move sequences

- **Counts per position.** `c(x)` is the number of shortest paths from the start to `x`. It is
  computed as `c(y) = Σ c(x)` over the neighbours `x` of `y` in the previous layer. Two
  different moves from the same position always give different positions, so paths and move
  sequences correspond one to one.
- **Counting through the midpoint.** By the colour-swap bijection, the number of shortest
  paths from `x` to the goal is `c(swap(x))`. Every optimal path has exactly one midpoint, at
  index `⌈n/2⌉`. So the total is `Σ c(x)·c(swap(x))` over the meeting layer: `x ∈ L(k)` with
  `swap(x) ∈ L(k)` when `n = 2k`, and `swap(x) ∈ L(k−1)` when `n = 2k−1`.
- **128-bit counts.** The core counts in 128 bits and reports overflow explicitly.
- **Combining components.** Independent components interleave freely. The Python side
  therefore multiplies the per-component counts by the multinomial coefficient
  `(n₁+…+n_m)! / (n₁!…n_m!)`, using exact big integers.

### `--alternate`: alternating turns (optional)

- **State and seeds.** The state carries the side to move. `--first white|black|either`
  chooses the starting state(s).
- **Full visited set.** The state graph is now directed: the same side cannot immediately undo
  its move. So the BFS keeps the full visited set instead of only the last two layers.
- **Meeting condition, either side may start.** Reverse a path from `x = (position, side t)`
  to the goal and swap the colours. The result is an alternating path from the start, with
  some first mover, to `swap'(x)`, where `swap'` swaps the colours and keeps `t`. Hence
  `dist(x, goal) = min over s of D_s(swap'(x))`, where `D_s` is the BFS distance from the start
  with side `s` to move. With `either`, a BFS from both seeds computes this minimum directly.
- **Meeting condition, fixed first mover `c`.** `D_{1−c}(y) = D_c(σ(y))`, where `σ` is a 180°
  rotation plus colour swap plus turn flip. `σ` fixes the start position and maps moves to
  moves (the direction set is closed under negation). The meeting test therefore also looks
  up `σ(swap'(x))`.
- **Turn parity.** The parity of the turn is built into the state, so the meeting test always
  matches turn parity.
- **Exactness** follows from the same midpoint argument as above.
- **Limitations.** `--count` and `--print-solution` are not supported together with
  `--alternate`.

### Safety

Before `solve` searches a component, it estimates the size of the state space,
`C(N,k)·C(N−k,k)` (doubled with `--alternate`), and the memory that would need. If the
estimate exceeds 1e8 positions (`--max-positions`) or the available RAM (`MemAvailable`), it
refuses and suggests `construct`, unless `--force` is given. Bishop 8x8 needs `--force`: its
estimate is 7.4e8 positions, but meet in the middle visits only about 1.2e8 (at most two layers in memory at once) and finishes in
about 50 s.

During the search, the solver:

- prints progress for each layer;
- aborts cleanly if the stored layers exceed 85% of the available memory;
- obeys `--timeout`.

### `construct`: IDA* for large boards (finds a solution, not necessarily a proof)

**Heuristic.** The heuristic is `h = Σ` over pieces of the empty-board distance from the piece
to the nearest square of its target rank. These distances are precomputed by a multi-source
BFS for the piece type.

**Why `h` is admissible and consistent.** A move on the real board is also a move on the empty
board, so it changes the moving piece's term by `Δ ∈ {−1, 0, +1}` and leaves every other term
unchanged. Searching with `f = g + h ≤ T`, a move costs `1 + Δ` units of "slack" out of the
budget `T − h(start)`.

**Thresholds.** IDA* tries `T = h0, h0+1, …` (`--start-slack` skips ahead). Each iteration is a
DFS with:

- **Randomized move ordering** (`--seed`): cheapest moves first, ties broken at random.
- **Restarts:** a node limit per attempt (`--node-limit`), growing by ×1.5. The attempt is
  restarted with a new random order until it either succeeds or completes without hitting the
  limit.
- **A transposition table of dead positions:** position → the largest remaining slack proven
  insufficient. Such a fact depends only on the position and the slack, not on the path, so it
  stays valid across restarts and thresholds. Entries are recorded only for subtrees that were
  searched completely.

**When the result is optimal.** An iteration that completes without being cut off proves that
no solution of that length exists. So when IDA* climbs to the first threshold that has a
solution, that solution is optimal, and the CLI says so. It also says so when the length
equals `h0`.

**Options.**

- `--tight`: only moves that decrease the moving piece's own distance by 1, i.e. a single
  iteration at `T = h0`. Every solution found then has exactly the lower-bound length.
  `--slack S` allows `S` extra units.
- `--symmetric`: each white move is immediately followed by its 180°-rotated black move. This
  halves the depth. It is used only for components invariant under the rotation; exhausting a
  slack level in this mode only rules out *symmetric* solutions, so it is never reported as a
  proof.

**Results on 8x8** (all re-checked by `check`):

- **Knight:** 64 moves with `--tight --symmetric`, in milliseconds. 64 equals the bound, so it
  is optimal.
- **King:** 112 moves with `--tight`, in milliseconds. 112 equals the bound, so it is optimal.
- **Bishop:** 30 moves with `--tight --slack 1`, 15 per colour class. Strict `--tight` (slack 0)
  cannot work, and the search proves it: each class has heuristic bound 14, but the two corner
  bishops share the long diagonal and block each other, so the true optimum is 15 per class
  (the exact `solve` confirms 30).
- **Rook, queen:** the nearest-rank heuristic is far too weak (16 against the true 33 for
  rooks), and IDA* does not reach a solution in reasonable time. This is a known limitation.
  Use `solve` on boards up to about 4x5, and `check` for hand-made constructions such as the
  33-move rook sequence in `tests/data/`.

### `check`

`check` replays a move list such as `a1-b3 c8-d6 …`. Move numbers and `B`/`N`/`W` labels are
ignored. For every move it verifies:

- there is a piece on the from-square;
- the destination is empty;
- the move matches one of the piece's directions;
- for sliding pieces, every square in between is empty;
- with `--alternate`, the colours alternate.

Finally it checks that the final position is the goal, and reports the number of moves.
`check` is pure Python and shares no move-generation code with the C++ core, so it serves as
an independent verifier.

### `bound`: distance-matching lower bound

Every white piece must end on a distinct rank-`R` square, and a piece travelling from `s` to
`t` needs at least `d(s,t)` moves, where `d` is the empty-board distance (obstacles only make
it longer). Since each move moves one piece:

    moves ≥ min over assignments white→rank R of Σ d  +  min over assignments black→rank 1 of Σ d.

Both terms are assignment problems, solved by the Hungarian algorithm (`O(F³)`) or by brute
force over all permutations (the default for `F ≤ 7`; `--method` to choose). This bound is at
least the nearest-rank bound used by `construct`. If some piece cannot reach any target square
on the empty board, it is infinite, meaning the swap is impossible.

| 8x8 | bound | best known / exact |
|---|---|---|
| rook | 16 | 33 (exact for `m ≥ 5`, from the paper) |
| queen | 16 | 23 (Tokarev) |
| bishop | 28 | 30 (exact, `solve`) |
| knight | 64 | 64 (optimal) |
| king | 112 | 112 (optimal) |

### `export`

`export` writes any legal move list as a Typst table:

- columns `N.º` and `Movimiento`;
- labels `B` (white) and `N` (black), taken from a replay;
- four blocks side by side, column-major (`--cols` to change).

`--format appendix` instead emits the `#move-table((("B","a1-a3"), …))` call used in
`paper/sections/apendice.typ`. `solve` and `construct` accept `--export FILE.typ`.

## Tests

```
python3 tests/run_fast_tests.py    # ~1 min
python3 tests/run_full_tests.py    # ~7 min: fast tests + bishop 8x8 exact (--force) + 4x4 alternate cross-check
```

The tests cover:

- **Every exact minimum** in the specification (rook, bishop, knight, king), plus bishop/knight
  2xR impossible for every `R ≤ 32`.
- **The optimal-sequence counts** 112, 432 and 9792.
- **The 8x8 constructions** (knight 64, bishop 30, king 112), each accepted by `check`.
- **`check`** on the known 33-move rook and 112-move king solutions, plus rejection of illegal,
  incomplete and tampered sequences.
- **An independent brute-force reference** (`tests/reference.py`): plain forward BFS with a full
  visited set, no meet in the middle, no components, no symmetry. It cross-checks minima,
  counts and `--alternate` results on tiny boards for every built-in piece and several custom
  ones.
- **Hungarian against brute force** on random matrices.
- **Exported tables compile** with `typst`.
