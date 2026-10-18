# Source and acceptance-test provenance

The target repository's existing history is preserved, starting at
`66c314b3b4214eba59bc345c7af28f3dae45fc39`, on `codex/complete-rwa-lab`.
The uploaded overlay archive was inspected before use: 24 regular files or
folders, no absolute/traversal paths, links or `.git` members. It was removed
from the final tracked tree after assembly.

The initial cached source was verified against the lecturer's GitHub tree at
`5314178034f1879a9676dc59817c6fd6ff8aaafd`. A fresh clone was subsequently
completed successfully with scoped network permission; `git clone` exited 0,
and the clone's HEAD is that same commit. No lecturer Git history was copied
into the student's source tree.

All **662** upstream `lib/` files are present and byte-identical to the fresh
clone, including their licenses and supporting files. Both immutable acceptance
files are also byte-identical:

| File | Lecturer Git blob SHA-1 |
|---|---|
| `test/TBill.t.sol` | `30d5f14d1ccc0fef2b184cc95099db4ccb66e9c8` |
| `test/exercises/02_QueueTasks.t.sol` | `4cbe273d4d3135fb68f724d7d922771287c995c2` |

Student TODOs were completed in Ex2–Ex4 tests, queue implementation, invariant
handler/properties and Ex7. The original Ex7 fixture and success assertions are
retained. Optional tests are supplied by the overlay and were repaired using
exact ABI error assertions. Formatting changes apply to student-owned overlay
files, leaving the two acceptance files unchanged.

The Makefile and doctor explicitly select the seven original core tests;
the full `forge test` command still includes every exercise, challenge,
optional, deployment and regression test. Neither exclusions nor relaxed
assertions were added to the full suite. GitHub Actions repeats the same seven
check commands and uploads its own actual logs; local evidence is recorded
separately and does not claim a remote CI outcome.

The formal Assignment Three PDF was not available. Written questions were
verified against the lecturer's original Markdown, and rubric priorities follow
the user's supplied assignment brief. The repository metadata currently reports
public visibility; no visibility change was made.

The review branch separates the 676-file immutable base/dependency import into
its own commit, followed by the exercise, optional, deployment, documentation
and evidence changes. Reviewers can inspect the second commit independently
without repeatedly reviewing the vendored dependency import.
