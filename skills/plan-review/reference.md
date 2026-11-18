# Plan review – checklist

Go through **all** sections. Mark N/A only with a reason.

## 1. Goal and scope

- [ ] The problem/need is clear (why, not only what)
- [ ] Measurable / verifiable outcomes or acceptance criteria
- [ ] The plan's steps cover the goals without widening scope needlessly
- [ ] Explicit out-of-scope where it prevents misunderstanding
- [ ] Issue summary/description ↔ technical plan is consistent
- [ ] No "nice-to-have" hidden as a must-have

## 2. Structure and feasibility

- [ ] Logical order; dependencies are visible
- [ ] Vertical slices where it makes sense (not only layer by layer)
- [ ] The work can be split into PRs of ≤ 500 lines
- [ ] A feature flag (environment-based) has been considered for new functionality
- [ ] Rollback / feature-off strategy mentioned where relevant
- [ ] The estimated affected modules/packages are realistic
- [ ] Diagrams only where they help; dark theme if used

## 3. Domain and documentation

- [ ] Terminology matches GLOSSARY.md / the domain language (if one exists)
- [ ] No conflict with relevant ADRs
- [ ] The plan builds on existing patterns in the affected modules
- [ ] Contradictions between the plan and the actual code are flagged

## 4. Technical risks

- [ ] Security: authorisation, input validation, secrets, injection
- [ ] GDPR / personal data / special-category data
- [ ] Backwards compatibility of APIs and contracts
- [ ] Data: migration, idempotency, consistency, retention
- [ ] Operations: health checks, configuration examples, no secrets in images
- [ ] Performance / availability where relevant
- [ ] Error handling and observability (logs without personal data in URLs)
- [ ] Unknowns and assumptions are listed explicitly

## 5. Testing and quality

- [ ] TDD / test strategy for the change
- [ ] Deterministic tests; external dependencies handled
- [ ] A QA plan is sketched, or points to a QA checklist for afterwards
- [ ] Accessibility (WCAG) where UI or user-facing text is touched

## 6. Process (project rules)

- [ ] Branch/PR strategy (no direct commits to the default branch without agreement)
- [ ] No planned push/deploy to test/production from an agent
- [ ] The review changes nothing in the issue tracker
- [ ] Atomic commits / commit language mentioned where relevant
- [ ] Naming and placement follow the project's conventions

## 7. Strengths (required)

Find at least 2–3 concrete things that are **well** planned (precise goals, good decomposition, realistic risk, good reuse of existing patterns, and so on). An empty "Strengths" section is not allowed.

## 8. Severity

| Level | Meaning |
|-------|---------|
| Blocking | Unsafe or unclear to start development |
| Should fix | Should be settled in the plan before start |
| Minor | A clarification or improvement; does not block |

Only findings with high confidence (> 80 %). Separate a gap from speculation.
