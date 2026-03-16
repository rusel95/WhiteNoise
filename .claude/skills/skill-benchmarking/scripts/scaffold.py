#!/usr/bin/env python3
"""
scaffold.py — Prepare a benchmark iteration workspace.

Usage:
  python scaffold.py <skill_root> <iteration_root> <model_slug>

  skill_root     : e.g. skills/ios/gcd-operationqueue
  iteration_root : e.g. skills/ios/gcd-operationqueue-workspace/iteration-2
  model_slug     : e.g. gpt-5-4  (only alphanumeric + hyphens)

Creates:
  iteration_root/
    eval-<name>/
      eval_metadata.json          ← copy of eval from evals-tiered.json
      <model_slug>-with/run-1/outputs/   ← empty, ready for response.md
      <model_slug>-without/run-1/outputs/
"""

import argparse
import json
import re
import sys
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="Scaffold benchmark iteration workspace")
    parser.add_argument("skill_root", help="Path to skill directory (e.g. skills/ios/gcd-operationqueue)")
    parser.add_argument("iteration_root", help="Output path for this iteration")
    parser.add_argument("model_slug", help="Lowercase hyphenated model identifier (e.g. gpt-5-4)")
    args = parser.parse_args()

    skill_root = Path(args.skill_root).resolve()
    iteration_root = Path(args.iteration_root).resolve()
    model_slug = args.model_slug

    if not re.fullmatch(r"[a-z0-9][a-z0-9\-]*", model_slug):
        sys.exit(f"[scaffold] Invalid model_slug '{model_slug}'. Use lowercase alphanumeric + hyphens only.")

    # evals-tiered.json lives in evals/<platform>/<skill-name>/ (sibling of skills/)
    # Try canonical location first: evals/<platform>/<skill-name>/evals-tiered.json
    # skill_root is e.g. skills/ios/gcd-operationqueue → platform=ios, skill=gcd-operationqueue
    parts = skill_root.parts
    try:
        skills_idx = next(i for i, p in enumerate(parts) if p == "skills")
        platform = parts[skills_idx + 1]
        skill_name_part = parts[skills_idx + 2]
        repo_root = Path(*parts[:skills_idx]) if skills_idx > 0 else Path(".")
        evals_path = repo_root / "evals" / platform / skill_name_part / "evals-tiered.json"
    except (StopIteration, IndexError):
        evals_path = skill_root / "evals" / "evals-tiered.json"
    if not evals_path.exists():
        sys.exit(f"[scaffold] evals-tiered.json not found at {evals_path}")

    data = json.loads(evals_path.read_text(encoding="utf-8"))
    evals = data.get("evals")
    if not isinstance(evals, list) or not evals:
        sys.exit(f"[scaffold] No 'evals' array found in {evals_path}")

    print(f"[scaffold] Skill      : {skill_root.name}")
    print(f"[scaffold] Model slug : {model_slug}")
    print(f"[scaffold] Iteration  : {iteration_root}")
    print(f"[scaffold] Evals      : {len(evals)}")
    print()

    created = 0
    skipped = 0

    for ev in evals:
        name = ev.get("name")
        if not name:
            print(f"  [!] Eval id={ev.get('id')} has no 'name' field — skipped", file=sys.stderr)
            continue

        eval_dir = iteration_root / f"eval-{name}"

        # Create output dirs for both variants
        for variant in (f"{model_slug}-with", f"{model_slug}-without"):
            out_dir = eval_dir / variant / "run-1" / "outputs"
            out_dir.mkdir(parents=True, exist_ok=True)

        # Write eval_metadata.json (only if not already present)
        meta_path = eval_dir / "eval_metadata.json"
        if not meta_path.exists():
            meta_path.write_text(json.dumps(ev, indent=2, ensure_ascii=False), encoding="utf-8")
            print(f"  [+] eval-{name}/eval_metadata.json")
            created += 1
        else:
            print(f"  [=] eval-{name}/eval_metadata.json (exists, not overwritten)")
            skipped += 1

    print()
    print(f"[scaffold] Created: {created}  Skipped (already present): {skipped}")
    print(f"[scaffold] Next step: generate with_skill and without_skill responses.")
    print(f"[scaffold] Output dirs ready: eval-*/{model_slug}-with/run-1/outputs/")
    print(f"[scaffold]                    eval-*/{model_slug}-without/run-1/outputs/")


if __name__ == "__main__":
    main()
