# How the skills fit together

Mermaid diagrams of the skills in this repository.

Legend: a solid arrow means the skill calls or hands over to the other one. A dotted arrow means a mention, a recommendation, or something that only happens when needed. Grey rounded boxes are not skills.

## 1. Planning: which skill uses which

```mermaid
flowchart LR
  jp["jira-planner"]
  way["wayfinder"]
  grill["grilling"]
  dm["domain-modeling"]
  pr["agent-plan-review"]
  res["research"]
  cd["codebase-design"]
  proto["prototype"]

  jp -->|"decision map"| way
  jp -->|"teach-back and stress-test"| grill
  jp --> dm
  jp -->|"review loop"| pr
  jp -.->|"only when the frontier needs it"| res
  jp -.-> cd
  jp -.-> proto

  way --> grill
  way --> dm
  way -->|"research tickets"| res
  way -->|"prototype tickets"| proto

  pr -.->|"open questions"| grill
  pr -.-> dm
  pr -.->|"module design"| cd
  pr -.->|"related"| jp
```

## 2. Review, the GitHub track and signature

```mermaid
flowchart LR
  ghplan["gh-plan"]
  ghsync["gh-sync"]
  hpr["human-plan-review"]
  hcr["human-code-review"]
  pr["agent-plan-review"]
  jp["jira-planner"]
  sig["signature"]

  ghplan -->|"on Build"| ghsync
  hpr -.->|"reviews a plan such as the one gh-plan writes"| ghplan
  hpr -.->|"never runs it; the developer says Build afterwards"| ghsync

  hpr -.->|"optional signature line"| sig
  hcr -.->|"optional signature line"| sig
  jp -.->|"related: sign text before pasting"| sig

  jp -.->|"related"| hpr
  pr -.->|"not for: use it to check understanding"| hpr
```

## 3. Where each skill fits in the work

```mermaid
flowchart TD
  idea(["Idea or issue"])
  track{"Which tracker?"}

  big{"Too big for one session?"}
  way["wayfinder, by your choice"]
  ghplan["gh-plan: local plan from a GitHub issue"]
  hpr["human-plan-review: quiz on the plan"]
  sync["gh-sync: issues and relations, on Build"]

  jp["jira-planner: plan from Jira issue text"]
  inside["Inside jira-planner: wayfinder, grilling, domain-modeling"]
  pr["agent-plan-review: report in the review loop"]
  paste(["You paste the plan into Jira"])

  impl(["Implementation, not a skill"])
  conflict["solve-conflicts, if git reports conflicts"]
  hcr["human-code-review: quiz on the diff"]
  merge(["Merge"])
  sig["signature, on text the agent wrote"]

  idea --> track
  track -->|"GitHub"| big
  big -->|"yes"| way
  way -.->|"then you start gh-plan on an issue"| ghplan
  big -->|"no"| ghplan
  ghplan -.->|"optional, before Build"| hpr
  hpr -.->|"you say Build"| sync
  ghplan -->|"Build"| sync
  sync --> impl

  track -->|"Jira"| jp
  jp --> inside
  jp -->|"review loop"| pr
  jp --> paste
  paste --> impl

  impl --> conflict
  conflict --> hcr
  impl --> hcr
  hcr --> merge
  hcr -.-> sig
  jp -.-> sig

  classDef notskill fill:#eeeeee,stroke:#999999,color:#333333
  class idea,paste,impl,merge notskill
```

## 4. jira-planner step by step

```mermaid
flowchart TD
  gate{"Issue key and issue text given?"}
  stop1(["Ask for them and stop"])
  code{"Code readable?"}
  unverified["Mark claims about code as unverified and ask whether to continue"]
  s1["1. Take the issue text from the user"]
  s2a["2a. Decision map, or a documented skip"]
  s2b["2b. Teach-back: the user confirms"]
  s3["3. Technical draft: plan and snapshot"]
  s4["4. Stress-test the draft"]
  s5["5. agent-plan-review report, iteration n"]
  open{"Anything blocking or should-fix still open?"}
  fix["Fix the plan, then n = n + 1"]
  limit{"n greater than 5?"}
  ask(["Stop and show the open findings to the user"])
  s6["6. Paste-ready plan for the Plan field"]
  s7["7. Show paste instructions"]
  stop7(["STOP: no subtasks and no code in this turn"])
  s8["8. Subtask descriptions, one per PR"]

  gate -->|"no"| stop1
  gate -->|"yes"| code
  code -->|"no, and the user says continue"| unverified --> s1
  code -->|"yes"| s1
  s1 --> s2a --> s2b --> s3 --> s4 --> s5 --> open
  open -->|"yes"| fix --> limit
  limit -->|"yes"| ask
  limit -->|"no"| s5
  open -->|"no"| s6 --> s7 --> stop7
  stop7 -.->|"only if the user later asks explicitly"| s8
```

## 5. wayfinder: charting and working through the map

```mermaid
flowchart TD
  subgraph CHART["Chart the map (one session)"]
    c1["Name the destination with grilling and domain-modeling"]
    c2["Map the frontier breadth-first"]
    fog{"Any fog left?"}
    noMap(["No map needed: ask the user how to proceed"])
    c3["Create the map"]
    c4["Create the tickets you can specify now"]
    c5["Wire blocking in a second pass"]
    c6["Start research subagents for research tickets"]
    c1 --> c2 --> fog
    fog -->|"no"| noMap
    fog -->|"yes"| c3 --> c4 --> c5 --> c6
  end

  endc(["Session ends: charting resolves nothing by hand"])

  subgraph WORK["Work through the map (one ticket per session)"]
    w1["Load the map"]
    w2["Choose a frontier ticket and claim it"]
    w3{"Ticket type"}
    tr["research"]
    tp["prototype"]
    tg["grilling"]
    tt["task"]
    w4["Record the resolution and close the ticket"]
    w5["Add new tickets, graduate fog, rule out of scope"]
    wd{"Frontier empty and no fog or open tickets left?"}
    ready(["The way to the destination is clear"])
    w1 --> w2 --> w3
    w3 --> tr --> w4
    w3 --> tp --> w4
    w3 --> tg --> w4
    w3 --> tt --> w4
    w4 --> w5 --> wd
    wd -->|"no: next session"| w1
    wd -->|"yes"| ready
  end

  c6 --> endc
  endc -.->|"a later session starts with the map"| w1
```

## 6. The quiz in human-code-review and human-plan-review

```mermaid
sequenceDiagram
  actor Dev as Developer
  participant Agent
  participant Shell

  Note over Agent: Hard gate and early checks can stop the run here
  Agent->>Dev: Show target, version, scope, overlapping work, unresolved items for plans
  Agent->>Agent: Map comprehension-critical areas
  Agent->>Dev: Note about option F, shown once
  loop For each question
    Agent->>Shell: Random answer slot and option length
    Shell-->>Agent: Numbers
    Agent->>Dev: Question with options A to F
    Dev-->>Agent: Answer
    alt Answer is F, bug or flaw
      Agent->>Dev: Ask for a justification if none was given
      Agent->>Dev: Assessment: likely genuine or not
      Note over Agent: Counts as wrong. A likely genuine one is also recorded as a confirmed bug or flaw
    end
    Agent->>Dev: Correct or not, plus a comprehension question
    Dev-->>Agent: Comprehension feedback
  end
  Agent->>Dev: Diagnosis: knowledge gap, unclear code or plan, or unclear question
  Note over Agent: Wrong answers that match overlapping work are left out of the score
  opt Unclear code or plan
    Agent->>Dev: Offer a clearer version
    Dev-->>Agent: Approve or decline
  end
  Agent->>Dev: Score
  alt Passed and no confirmed bug or flaw
    Agent->>Dev: Human understanding statement
    opt Code review, or a plan with a tracking issue
      Agent->>Dev: Offer to post only the statement, asks first
    end
  else Failed or a confirmed bug or flaw
    Agent->>Dev: Disapproval text and weakest areas
  end
```

## 7. What each skill needs before it starts

Every skill with requirements has a hard gate: it stops and says what is missing. The diagram shows tools and, in grey, the inputs and files a skill needs.

```mermaid
flowchart LR
  gh["gh, authenticated"]
  git["git"]
  jq["jq"]
  bash["bash with RANDOM"]
  sha["sha256sum"]
  pm["package manager"]
  jpin(["issue key, issue text, reports directory, readable code"])
  prin(["plan text, reports directory, readable code"])
  none(["Only the agent itself"])

  ghplan["gh-plan"] --> gh
  ghsync["gh-sync"] -->|"2.94 or newer, triage access"| gh
  hcr["human-code-review"] --> git
  hcr --> gh
  hcr --> jq
  hcr --> bash
  hpr["human-plan-review"] --> bash
  hpr -->|"one of"| git
  hpr -->|"one of"| sha
  hpr -.->|"only if the plan names an issue"| gh
  pr["agent-plan-review"] --> prin
  pr -.->|"only if the plan is in a PR"| gh
  sig["signature"] --> bash
  sig --> gh
  sc["solve-conflicts"] --> git
  sc -.->|"only if a lockfile conflicts"| pm
  jp["jira-planner"] --> jpin
  blocks["wayfinder, grilling, domain-modeling, research, codebase-design, prototype"] --> none

  classDef notool fill:#eeeeee,stroke:#999999,color:#333333
  class jpin,prin,none notool
```
