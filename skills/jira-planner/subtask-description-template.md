# Subtask description template

Use the fenced body below as the description of one subtask per PR. The agent fills in every placeholder; nothing is filled in by a script.

Rules for the agent:

- Placeholders MUST be filled with **PR-specific** content (Goal, Steps, Files, Tests, DoD).
- Forbidden: generic scope text that is identical on every PR; "see the parent plan" or a reference to the local plan file instead of slice content; instruction-style bullet points.
- The parent reference is metadata (navigation), not a replacement for content.
- PR slice only: do not paste shared background or risk from the parent.

Placeholders: `{{pr}}`, `{{title}}`, `{{parent}}`, `{{app}}`, `{{content}}`, `{{steps}}`, `{{files}}`, `{{tests}}`, `{{dod}}`.

```markdown
## PR {{pr}} – {{title}}

**Parent:** {{parent}}
**App:** {{app}}

### Goal

{{content}}

### Steps

{{steps}}

### Files

{{files}}

### Tests

{{tests}}

### DoD

{{dod}}
```
