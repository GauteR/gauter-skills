# Examples

Fill-in templates for `human-code-review`. All values are synthetic examples. Replace them with the real ones from the review, and translate fixed phrases into the developer's language (see "Language" in `SKILL.md`; a Norwegian set is at the end).

## Context summary (step 2)

```text
HEAD:  a1b2c3d  Add retry to loan renewal job
Base:  9f8e7d6  Extract renewal scheduler   (from: gh stack)
Scope: 4 commits, 6 files, +182 / −41 lines
Stack: layer 2 of 3 (#412)
```

## Overlapping PRs notice (step 2)

```text
These PRs outside the stack also change code in this change:
- #398 (rewrites the retry backoff in `RenewalJob`)
I'll avoid questions about that code unless you want them included.
```

## Base question (step 2, stacked branch without gh stack)

```text
Which branch do you want to review against: feature/renewal-scheduler (suggested), feature/job-base, origin/main?
```

## Note before the quiz (step 6)

```text
PR: https://github.com/<owner>/<repo>/pull/412

If you understand what happens but believe it is a bug, use (F) Bug. A justification is optional.
```

## Question (step 7)

```text
Question 1 of 5

❓ **<title>**: <body>

(A) <option>
(B) <option>
(C) <option>
(D) <option>
(E) I don't know
(F) Bug (optional justification)
```

### Example per kind

Each example shows the shape and the level of detail for the options. Write the real ones from the actual diff. Options must be about equally long and detailed; the correct one is placed in a random slot (here shown as B).

**Behaviour**

```text
❓ **Duplicate renewals**: A renewal request arrives for a loan that already has a renewal queued. What does the new code do with the second request?

(A) It replaces the queued renewal and resets its attempt counter
(B) It returns the existing queued renewal without creating a new one
(C) It queues a second renewal that runs after the first completes
(D) It rejects the request with a conflict error before queuing
(E) I don't know
(F) Bug (optional justification)
```

**Reasoning**

```text
❓ **Why a separate table**: The change stores attempt state in a new table instead of a column on the loan row. What is the main reason this design is safer here?

(A) Retry state can be updated without taking a lock on the loan row
(B) The loan table has no room for another integer column
(C) The scheduler can only read tables that it owns exclusively
(D) A separate table lets old attempts be archived by a database trigger
(E) I don't know
(F) Bug (optional justification)
```

**Failure mode**

```text
❓ **Timeout mid-renewal**: The downstream service times out after it has accepted the renewal but before the response arrives. What state is the loan in after the job gives up?

(A) The loan is unchanged and the job records a failed attempt
(B) The loan is renewed and the job may retry the same renewal
(C) The loan is marked as pending and a human must resolve it
(D) The loan is renewed and the job records a successful attempt
(E) I don't know
(F) Bug (optional justification)
```

**Dependency**

```text
❓ **What else reads this**: The change renames the status value `PENDING` to `QUEUED`. Which other part of the system still depends on the old value?

(A) The nightly report, which filters on `PENDING` in a stored query
(B) The API schema, which lists `QUEUED` as its only valid status
(C) The scheduler, which compares status with a shared constant
(D) Nothing, because the old value was only used inside this class
(E) I don't know
(F) Bug (optional justification)
```

**Prediction**

```text
❓ **Third attempt**: A renewal has failed twice with a temporary error, and the third attempt starts at 12:00 with a base delay of 30 seconds. When is the fourth attempt scheduled, if the third also fails?

(A) At 12:00:30, because the delay is constant
(B) At 12:02:00, because the delay doubles on each failure
(C) At 12:01:30, because the delay grows by 30 seconds
(D) Never, because three attempts is the limit
(E) I don't know
(F) Bug (optional justification)
```

## Answer feedback and comprehension question (step 7)

```text
Correct. You chose (B), which is right.

❓ **How well did you understand this part of the code?**

(A) I understand it well
(B) Unsure
(C) Hard to understand from the code
(D) The question itself was unclear
```

Wrong answer:

```text
Not quite. You chose (A). The correct answer is (B): <one or two sentences on why, grounded in the code>.

❓ **How well did you understand this part of the code?**

(A) …
```

## Bug assessment (step 7, option F)

```text
You chose (F) Bug. Your justification: "<justification>".

Assessment: <likely a genuine bug | probably intended behaviour>. <Reasoning with a pointer to the relevant behaviour in the diff.>

This counts as a wrong answer. <It is also recorded as a confirmed bug. | It is not recorded as a bug.>
```

## Diagnosis (step 8)

```text
Diagnosis:
- Question 2: (B) unclear code. The retry decision is split across two methods.
- Question 4: (A) knowledge gap. The status rename was in the diff but not noticed.
- Question 5: (C) ambiguous question. Left out of the score.
```

## Code improvement proposal (step 9)

```text
Likely source of difficulty: <e.g. the retry decision is spread across `shouldRetry` and `onFailure`, and the attempt counter is mutated in both>.

Proposal: <e.g. move the decision and the counter update into one method that returns the next state>.

Before:
<short excerpt>

After:
<short excerpt>

Do you want me to apply this?
```

## Score (step 10)

```text
4 correct out of 5.
```

## Understanding statement (step 11)

GitHub repo known:

```text
<!-----BEGIN HUMAN UNDERSTANDING STATEMENT----->
🖋️ Kari Nordmann understands this change: https://github.com/<owner>/<repo>/compare/9f8e7d6c1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d...a1b2c3d4e5f60718293a4b5c6d7e8f9a0b1c2d3e
<!-----END HUMAN UNDERSTANDING STATEMENT----->
```

Repo not known:

```text
<!-----BEGIN HUMAN UNDERSTANDING STATEMENT----->
🖋️ Kari Nordmann understands this change:
`git diff 9f8e7d6c1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d..a1b2c3d4e5f60718293a4b5c6d7e8f9a0b1c2d3e`
<!-----END HUMAN UNDERSTANDING STATEMENT----->
```

## PR comment (step 12)

The statement above, unchanged, followed by the signature line if the repo has a signature skill. No score, no failure details.

## Failure (step 13)

```text
You have not demonstrated that you understand this change.

Result: 3/5

Weakest areas:
- What happens to a renewal when the downstream call times out
- Which readers still depend on the old status value

Review these parts of the change before trying again.
```

With a confirmed bug:

```text
Too many errors in the code. Fix them and run human-code-review again.

Result: 5/5

Weakest areas:
- Confirmed bug: a timed-out renewal is retried without an idempotency key

Review these parts of the change before trying again.
```

## Norwegian fixed phrases

| English | Norwegian |
| --- | --- |
| Question 1 of 5 | Spørsmål 1 av 5 |
| I don't know | Jeg vet ikke |
| Bug (optional justification) | Bug (valgfri begrunnelse) |
| If you understand what happens but believe it is a bug, use (F) Bug. A justification is optional. | Hvis du forstår hva som skjer, men mener det er en bug, bruk (F) Bug. Begrunnelse er valgfri. |
| I understand it well | Jeg forstår det godt |
| Unsure | Usikker |
| Hard to understand from the code | Vanskelig å forstå fra koden |
| The question itself was unclear | Selve spørsmålet var uklart |
| <CORRECT> correct out of <TOTAL>. | <CORRECT> riktige av <TOTAL>. |
| understands this change | forstår denne endringen |
| You have not demonstrated that you understand this change. | Du har ikke vist at du forstår denne endringen. |
| Too many errors in the code. Fix them and run human-code-review again. | For mange feil i koden. Rett dem og kjør human-code-review på nytt. |
| Result | Resultat |
| Weakest areas | Svakeste områder |
| Review these parts of the change before trying again. | Gå gjennom disse delene av endringen før du prøver igjen. |

Keep the `BEGIN`/`END HUMAN UNDERSTANDING STATEMENT` markers in English.
