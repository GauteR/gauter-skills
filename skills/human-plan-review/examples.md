# Examples

Fill-in templates for `human-plan-review`. All values are synthetic examples. Replace them with the real ones from the review, and translate fixed phrases into the developer's language (see "Language" in `SKILL.md`; a Norwegian set is at the end).

## Plan summary (step 2)

```text
Plan:      Retry for loan renewals (retry-loan-renewals.plan.md)
Version:   3f9a1c2, modified 2026-11-17 14:05
Tracking:  #410 (open)
Scope:     3 PR items, 5 decisions, 9 todos, 86 lines
Staleness: `RenewalScheduler` was renamed to `RenewalDispatcher` after the plan was written
```

## Overlapping plans notice (step 2)

```text
These plans also cover parts of this scope:
- renewal-queue-rework.plan.md (replaces the PR B split)
I'll avoid questions about those parts unless you want them included.
```

## Unresolved items (step 2)

```text
The plan leaves these open:
- Decision 4 (backoff strategy) is marked "not locked".
- Assumption: the downstream service is idempotent. Not verified.
- Open question: should failed renewals notify the patron?

These are not quiz material as if they were decided. I'll only ask about their status.
```

If the open items cover the core of the plan:

```text
Most of the plan's core decisions are still open. Do you want to settle them first and review the plan afterwards?
```

## Note before the quiz (step 6)

```text
Tracking issue: https://github.com/<owner>/<repo>/issues/410

If you understand what the plan says but believe it is wrong (contradicts the code, impossible, or missing something essential), use (F) Flaw. A justification is optional.
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
(F) Flaw (optional justification)
```

### Example per kind

Each example shows the shape and the level of detail for the options. Write the real ones from the actual plan. Options must be about equally long and detailed; the correct one is placed in a random slot (here shown as B).

**Scope**

```text
❓ **What is not included**: The plan adds retries for loan renewals. Which of these does the plan explicitly leave out?

(A) Retrying renewals that fail with a permanent error
(B) Notifying the patron when all retries have failed
(C) Recording each attempt in the audit log
(D) Limiting the number of attempts per loan
(E) I don't know
(F) Flaw (optional justification)
```

**Reasoning**

```text
❓ **Why split into three PRs**: The plan puts the schema change in its own first PR. What is the main reason given for this ordering?

(A) The schema change can be reverted without touching the job
(B) The job cannot be written until the schema exists in production
(C) Database changes need a separate review by the platform team
(D) The first PR is the smallest and unblocks the other two
(E) I don't know
(F) Flaw (optional justification)
```

**Failure mode**

```text
❓ **Rollback after PR B**: PR B has been deployed and the retry job misbehaves. According to the plan, what is the intended way to stop it?

(A) Revert PR B, which also drops the new table
(B) Turn off the feature flag, leaving the table and code in place
(C) Pause the scheduler, then delete the queued renewals by hand
(D) Redeploy PR A, which restores the previous job behaviour
(E) I don't know
(F) Flaw (optional justification)
```

**Dependency**

```text
❓ **What blocks PR C**: PR C turns the feature on for all libraries. What must be true before it can be merged?

(A) PR B is deployed and the idempotency question is answered
(B) PR A is merged and the feature flag exists in all environments
(C) The plan in `renewal-queue-rework` has been approved
(D) The load test in QA has run for at least a week
(E) I don't know
(F) Flaw (optional justification)
```

**Prediction**

```text
❓ **Merged out of order**: PR C is merged before PR B. With the feature flag on in staging, what does the plan imply happens to a failed renewal?

(A) It is retried according to the backoff in decision 4
(B) It fails once, because the retry job from PR B is missing
(C) It is queued but never processed, and stays pending
(D) The deploy fails because PR C checks that PR B is present
(E) I don't know
(F) Flaw (optional justification)
```

## Answer feedback and comprehension question (step 7)

```text
Correct. You chose (B), which is right.

❓ **How well did you understand this part of the plan?**

(A) I understand it well
(B) Unsure
(C) Hard to understand from the plan
(D) The question itself was unclear
```

Wrong answer:

```text
Not quite. You chose (A). The correct answer is (B): <one or two sentences on why, grounded in the plan>.

❓ **How well did you understand this part of the plan?**

(A) …
```

## Flaw assessment (step 7, option F)

```text
You chose (F) Flaw. Your justification: "<justification>".

Assessment: <likely a genuine flaw | probably intended>. <Reasoning with a pointer to the relevant part of the plan and, if relevant, the code it contradicts.>

This counts as a wrong answer. <It is also recorded as a confirmed flaw. | It is not recorded as a flaw.>
```

## Diagnosis (step 8)

```text
Diagnosis:
- Question 2: (B) unclear plan. The reason for the PR order is only implied.
- Question 4: (A) knowledge gap. The blocked-by relation is stated in the plan.
- Question 5: (C) ambiguous question. Left out of the score.
```

## Plan improvement proposal (step 9)

```text
Likely source of difficulty: <e.g. the order of PR B and PR C is implied by the todos but never stated>.

Proposal: <e.g. add a "Depends on" line to each PR item and a sentence on why PR B must be deployed first>.

Before:
<short excerpt>

After:
<short excerpt>

Do you want me to apply this to the plan file? Nothing else will be changed.
```

After applying:

```text
Applied. The plan's content hash is now 7be40d1 (was 3f9a1c2). Questions about the changed passages no longer count as reliable signals.
```

## Score (step 10)

```text
4 correct out of 5.
```

## Understanding statement (step 11)

With a tracking issue:

```text
<!-----BEGIN HUMAN UNDERSTANDING STATEMENT----->
🖋️ Kari Nordmann understands this plan: https://github.com/<owner>/<repo>/issues/410
`retry-loan-renewals.plan.md` @ `7be40d1`
<!-----END HUMAN UNDERSTANDING STATEMENT----->
```

Without a tracking issue:

```text
<!-----BEGIN HUMAN UNDERSTANDING STATEMENT----->
🖋️ Kari Nordmann understands this plan:
`retry-loan-renewals.plan.md` @ `7be40d1`
<!-----END HUMAN UNDERSTANDING STATEMENT----->
```

## Issue comment (step 12)

The statement above, unchanged, followed by the signature line if the repo has a signature skill. No score, no failure details, no plan contents. Ask before posting.

## Failure (step 13)

```text
You have not demonstrated that you understand this plan.

Result: 3/5

Weakest areas:
- How to roll back after PR B is deployed
- Why PR C depends on PR B

Review these parts of the plan before trying again.
```

With a confirmed flaw:

```text
Too many errors in the plan. Fix them and run human-plan-review again.

Result: 5/5

Weakest areas:
- Confirmed flaw: PR A names a module that no longer exists

Review these parts of the plan before trying again.
```

## Norwegian fixed phrases

| English | Norwegian |
| --- | --- |
| Question 1 of 5 | Spørsmål 1 av 5 |
| I don't know | Jeg vet ikke |
| Flaw (optional justification) | Feil i planen (valgfri begrunnelse) |
| If you understand what the plan says but believe it is wrong (contradicts the code, impossible, or missing something essential), use (F) Flaw. A justification is optional. | Hvis du forstår hva planen sier, men mener den er feil (motsier koden, er umulig eller mangler noe vesentlig), bruk (F) Feil i planen. Begrunnelse er valgfri. |
| I understand it well | Jeg forstår det godt |
| Unsure | Usikker |
| Hard to understand from the plan | Vanskelig å forstå fra planen |
| The question itself was unclear | Selve spørsmålet var uklart |
| <CORRECT> correct out of <TOTAL>. | <CORRECT> riktige av <TOTAL>. |
| understands this plan | forstår denne planen |
| You have not demonstrated that you understand this plan. | Du har ikke vist at du forstår denne planen. |
| Too many errors in the plan. Fix them and run human-plan-review again. | For mange feil i planen. Rett dem og kjør human-plan-review på nytt. |
| Result | Resultat |
| Weakest areas | Svakeste områder |
| Review these parts of the plan before trying again. | Gå gjennom disse delene av planen før du prøver igjen. |

Keep the `BEGIN`/`END HUMAN UNDERSTANDING STATEMENT` markers in English.
