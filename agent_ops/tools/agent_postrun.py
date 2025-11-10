#!/usr/bin/env python3
import json, sys, argparse, datetime, os, subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DOCS = os.path.join(ROOT, "docs")

def load_index():
    with open(os.path.join(DOCS, "TODO_INDEX.json"), "r", encoding="utf-8") as f:
        return json.load(f)

def save_index(idx):
    idx["updated_at"] = datetime.datetime.now().isoformat()
    with open(os.path.join(DOCS, "TODO_INDEX.json"), "w", encoding="utf-8") as f:
        json.dump(idx, f, indent=2)

def render_master(idx):
    lines = []
    lines.append("# MASTER_TODO")
    lines.append("This document is generated from `docs/TODO_INDEX.json`. Do not edit by hand.\n")
    open_count = sum(1 for t in idx["tasks"] if t["status"]=="open")
    done_count = sum(1 for t in idx["tasks"] if t["status"]=="done")
    lines.append(f"Updated: {idx['updated_at']}")
    lines.append(f"Open: {open_count}  |  Done: {done_count}\n")
    lines.append("| ID | Status | Priority | Title | Owner | Due |")
    lines.append("|----|--------|----------|-------|-------|-----|")
    for t in idx["tasks"]:
        due = t["due"] if t["due"] else ""
        lines.append(f"| {t['id']} | {t['status']} | {t['priority']} | {t['title']} | {t['owner']} | {due} |")
    lines.append("\n## Checklist")
    for t in idx["tasks"]:
        mark = " " if t["status"]!="done" else "x"
        lines.append(f"- [{mark}] {t['id']}  {t['title']} ({t['priority']})")
    with open(os.path.join(DOCS, "MASTER_TODO.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

def append_run_log(args):
    log_path = os.path.join(DOCS, "RUN_LOG.md")
    if not os.path.exists(log_path):
        with open(log_path, "w", encoding="utf-8") as f:
            f.write("# RUN_LOG\n\nAppend-only log of automated runs. No PHI. Times in ISO 8601.\n\n")
            f.write("| time | run_id | actor | branch | tasks_completed | artifacts | summary |\n")
            f.write("|------|--------|-------|--------|-----------------|-----------|---------|\n")
    branch = os.environ.get("GIT_BRANCH", "")
    row = f"| {datetime.datetime.now().isoformat()} | {args.run_id} | {args.actor} | {branch} | {','.join(args.completed)} | {','.join(args.artifacts)} | {args.summary.replace('|','/')} |"
    with open(log_path, "a", encoding="utf-8") as f:
        f.write(row + "\n")

def check_root():
    try:
        subprocess.check_call([sys.executable, os.path.join(ROOT, "tools", "check_root_files.py")])
    except subprocess.CalledProcessError as e:
        print("Root hygiene check failed.", file=sys.stderr)
        sys.exit(e.returncode)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--run-id", required=True)
    ap.add_argument("--actor", default="agent")
    ap.add_argument("--summary", default="")
    ap.add_argument("--completed", nargs="*", default=[])
    ap.add_argument("--artifacts", nargs="*", default=[])
    args = ap.parse_args()

    idx = load_index()
    idset = set(args.completed)
    for t in idx["tasks"]:
        if t["id"] in idset:
            t["status"] = "done"
    save_index(idx)
    render_master(idx)
    append_run_log(args)
    check_root()
    print("Post-run updates complete.")
if __name__ == "__main__":
    main()
