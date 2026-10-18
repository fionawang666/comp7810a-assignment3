# Written-answer review

Reviewed `STUDENT-QUESTIONS.md` against the lecturer's original question text at
[`hgwoops/rwa-lab-2026`, commit `5314178034f1879a9676dc59817c6fd6ff8aaafd`](https://github.com/hgwoops/rwa-lab-2026/blob/5314178034f1879a9676dc59817c6fd6ff8aaafd/STUDENT-QUESTIONS.md).
All eight question bodies, the introductory instructions, E scenario wording and
the follow-up attack prompt are preserved. Answers appear under their original
`Your answer` markers, and the seven test names fill the original table.

Word counts use whitespace-separated tokens in each answer, excluding question
wording, headings and the `Your answer` marker. Inline code counts as ordinary
text under that rule. All eight are within the stated 150–300-word range.

| Answer | Words |
|---|---:|
| A1 | 217 |
| A2 | 230 |
| B1 | 243 |
| B2 | 236 |
| C1 | 228 |
| C2 | 246 |
| D1 | 249 |
| D2 | 241 |

Source review covered the base token, compliance registry, vault, custodian,
feed, queue, Ex2–Ex6 test sources, false-NAV challenge and optional permission
and freshness-reader prototypes. The answer review corrected these substantive
points:

- Pending escrow shares remain in total supply but have locked payouts. A1
  removes their floating valuation before adding pending cash liabilities; it
  also includes cash still owed after settled shares are burned.
- `MockPriceFeed.setPrice()` is unrestricted. B1 preserves the question's
  wording but identifies the direct setter as a bypass of the intended
  `REPORTER_ROLE` route.
- The base mock stamps reads with the current block time. B2 explains why that
  cannot establish the age of the underlying valuation.
- A token pause prevents enqueue and the burns required for settlement, while
  an already settled USDC `claim()` remains callable. C2 describes that exact
  boundary.
- E uses seven distinct function names present in
  `test/exercises/01_BridgeTasks.t.sol`. Its extra scenario describes the
  false-NAV challenge, including the fixture's explicit reporter and settler
  privileges, without presenting the exploit as a production deployment.

The local Python review checked exact A1–D2 question text, all word ranges,
existence and uniqueness of all seven E function names, and absence of blank
answer/table placeholders. It completed with exit code **0**. This is a document
and source consistency check; it makes no claim that Foundry tests passed.

The formal Assignment Three grading PDF was not supplied or available in the
repository material reviewed. This review applies the lecturer's source
instructions and the user's requested scope; grading weights and any additional
PDF-only criteria must be checked against the actual PDF before submission.
The student should review the reasoning and fund-policy judgments before using
these answers in a Moodle submission.
