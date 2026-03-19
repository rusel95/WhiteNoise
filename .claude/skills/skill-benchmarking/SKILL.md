---
name: skill-benchmarking
description: "Run tiered skill benchmarks against evals-tiered.json for any model. Use when benchmarking a skill against a model not yet tested, running with_skill/without_skill eval pairs, producing benchmark-<model>-tiered.json, re-grading an existing run, adding Phase 2 model comparison results, or updating README benchmark tables. Enforces strict grader isolation (the context that generates responses never grades them) and evidence-only passing (assertions pass only on explicit content, never on implication or charity)."
---

# Skill Benchmarking

Strict, model-agnostic benchmark runner for `evals-tiered.json` skill evaluation. Produces `benchmark-<model>-tiered.json` with tiered pass rates (simple/medium/complex) and a discriminating assertion list.

## Non-Negotiable Invariants

1. **Grader isolation** — the context/subagent that generated responses does NOT grade them
2. **Evidence-only** — assertions pass only when the required content is EXPLICITLY stated in the response; implication, adjacency, and partial coverage all fail
3. **Blind grading** — the grader does not know whether it is grading a with_skill or without_skill response
4. **Model-agnostic** — model slug is always supplied by the caller; never infer or hardcode it

Violating any of these means the benchmark is invalid. Start over.

---

## Scripts vs AI — Task Assignment

| Task | Tool | Why |
|------|------|-----|
| Create workspace dirs + `eval_metadata.json` | `scripts/scaffold.py` | Deterministic file layout |
| Write `response.md` from a pre-existing batch outputs JSON | `scripts/unpack-outputs.py` | Deterministic file layout |
| Grade responses against assertions | **AI subagent (Explore)** | Requires language understanding |
| Write `grading.json` files from batch AI grading output | `scripts/ingest-grades.py` | Deterministic file layout |
| Produce `benchmark-<model>-tiered.json` | `scripts/aggregate.py` | Pure arithmetic |
| Update README benchmark tables | **AI (main context)** | README structure is flexible, not strict |
| Improve skill based on failed assertions | **AI (main context)** | Requires judgment about what to generalise |

---

## Workflow (6 Phases)

```
Phase 1: Scaffold    → create iteration dir + eval_metadata.json          [script]
Phase 2: Generate    → produce with_skill and without_skill responses      [AI or unpack-outputs]
Phase 3: Grade       → isolated subagent grades responses                  [AI subagent, strict]
Phase 4: Aggregate   → produce benchmark-<model>-tiered.json              [script]
Phase 5: README      → update skill README with new benchmark results     [AI]
Phase 6: Improve     → add missing content to skill files                 [AI]
```

For a **new benchmark**: run all 6.
For a **re-grade only**: run Phases 3-4.
For **adding a new model to an existing iteration**: run Phases 2-4 (scaffold already done, metadata exists).
For **README + skill update only**: run Phases 5-6 after a completed benchmark.

---

## Phase 1: Scaffold

```bash
python .github/skills/skill-benchmarking/scripts/scaffold.py \
  skills/<platform>/<skill-name> \
  workspaces/<platform>/<skill-name>/iteration-N \
  <model-slug>
```

Auto-detect next iteration N by listing existing `iteration-*` dirs and incrementing.
Creates `eval-<name>/eval_metadata.json` and empty output dirs for `<model-slug>-with` and `<model-slug>-without`, with **3 run slots** (`run-1/`, `run-2/`, `run-3/`) per variant by default. Use `--runs 1` to scaffold only one run.

---

## Phase 2: Generate Responses

### Option A — AI generates live (model accessible in this session)

For **each** eval in `evals-tiered.json`, produce two responses in the **same model, same settings**.
Never use a stronger/different model for `with_skill` vs `without_skill`.

**with_skill prompt:**
```
Read the following skill file and every reference file it mentions:
  skills/<platform>/<skill-name>/SKILL.md

Then answer this question. Save your complete response (no preamble) to:
  workspaces/<platform>/<skill-name>/iteration-N/eval-<name>/<model-slug>-with/run-1/outputs/response.md

Question: <eval.prompt>
```

**without_skill prompt:**
```
Answer this question. Do NOT read any skill or reference files.
Save your complete response (no preamble) to:
  workspaces/<platform>/<skill-name>/iteration-N/eval-<name>/<model-slug>-without/run-1/outputs/response.md

Question: <eval.prompt>
```

### Option B — Unpack a pre-existing batch outputs JSON

If responses were already generated and stored in a standard batch file:
```json
{
  "model": "<model-slug>",
  "skill": "<skill-name>",
  "outputs": [
    {
      "eval_name": "queue-creation-simple",
      "response_with_skill": "...",
      "response_without_skill": "..."
    }
  ]
}
```

```bash
python .github/skills/skill-benchmarking/scripts/unpack-outputs.py \
  evals/<platform>/<skill-name>/<model-slug>-outputs.json \
  workspaces/<platform>/<skill-name>/iteration-N
```

---

## Phase 3: Grade (MUST BE ISOLATED)

Grade in a **separate `Explore` subagent** that has NOT read the skill being tested.

Pass ONLY:
- All `response.md` contents for one variant (with OR without — not both)
- Assertions from each `eval_metadata.json`
- Full text of `references/grading-rules.md`

Do NOT pass: SKILL.md, any skill reference files, or any description of what the skill teaches.
Grade with and without variants in **separate subagent calls**.

### Grading subagent prompt (batch — all evals for one variant)

```
You are a strict evaluator. Your only job is to grade responses against assertions.

## Grading Rules
<full contents of .github/skills/skill-benchmarking/references/grading-rules.md>

## Your Task
Grade each response below. Evidence-only. No charity. No benefit of the doubt.
- PASS: include a short direct quote from the response.
- FAIL: state exactly what was missing.

Return a single JSON array, no preamble, no explanation:
[
  {
    "eval_id": <number>,
    "variant": "SET_A",
    "eval_name": "<name>",
    "assertions": [{"id": "X1.1", "passed": true|false, "notes": "..."}],
    "summary": {"passed": N, "failed": N, "total": N, "pass_rate": 0.XX}
  }
]

## Evals to Grade
### Eval <id>: <eval_name>
**Assertions:** [...]
**Response:**
<response content>
---
<repeat for each eval>
```

After receiving the JSON array, save it to `/tmp/grades_SET_A_run1.json` and ingest:
```bash
python .github/skills/skill-benchmarking/scripts/ingest-grades.py \
  /tmp/grades_SET_A_run1.json \
  workspaces/<platform>/<skill-name>/iteration-N \
  <model-slug> \
  --run 1
```
Repeat the grade+ingest cycle for `--run 2` and `--run 3` (each run gets an independent response and grading). Repeat for the other variant (SET_B = without_skill).

`aggregate.py` auto-detects all `run-*` dirs and averages pass_rates across runs.

---

## Phase 4: Aggregate

```bash
python .github/skills/skill-benchmarking/scripts/aggregate.py \
  workspaces/<platform>/<skill-name>/iteration-N \
  <model-slug>
```

Reads all `eval-*/eval_metadata.json` and `<model-slug>-{with,without}/run-1/grading.json`.
Writes `benchmark-<model-slug>-tiered.json` to `iteration-N/`.

If the script reports missing grading files, grade the missing evals first.

---

## Phase 5: README Update (AI)

Read `skills/<platform>/<skill-name>/README.md` and the new `benchmark-<model-slug>-tiered.json`.
Add to the README:
1. A new row in the Results Summary table
2. A `#### Tiered Results (<Display Name>)` section matching the format of existing rows
3. A `#### Tiered Key Discriminating Assertions (<Display Name>)` section listing top misses

Do not reformat or rewrite existing content — only add new content in the established structure.

---

## Phase 6: Skill Improvement (AI)

If `with_skill` pass rate is below 95% in any tier, the skill under-specifies that tier.

1. Read `discriminating_assertions_failed_by_baseline` from the benchmark JSON
2. For each gap, identify which reference file should cover it
3. Add content generalised as a reusable rule or pattern — never write content shaped only to pass a specific assertion wording
4. Re-run Phases 1-4 into `iteration-N+1` to confirm improvement

---

## Fallback: No Subagent Available

If the `Explore` subagent cannot be invoked:
1. Start a **fresh chat** with no prior context about the skill being tested
2. Paste the grading prompt template directly
3. Save the JSON array to a file and run `ingest-grades.py`

Never grade in the same context where you read the skill's SKILL.md or references.

---

## References

| File | Purpose |
|------|---------|
| `scripts/scaffold.py` | Create iteration workspace from `evals-tiered.json` |
| `scripts/unpack-outputs.py` | Write `response.md` files from a pre-existing batch outputs JSON |
| `scripts/ingest-grades.py` | Write `grading.json` files from a batch AI grading response |
| `scripts/aggregate.py` | Aggregate grading artifacts into `benchmark-<model>-tiered.json` |
| `references/grading-rules.md` | Strict pass/fail contract for graders |
