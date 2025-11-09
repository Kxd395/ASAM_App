#!/usr/bin/env python3
import argparse, json, os, subprocess, sys, hashlib, random, string

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def rand_id(n=8):
    import secrets, string
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(n))

def canonical_bytes(obj) -> bytes:
    return json.dumps(obj, sort_keys=True, separators=(",", ":")).encode("utf-8")

def cmd_scaffold(args):
    os.makedirs("out", exist_ok=True)
    print("Scaffold complete. Place your ASAM PDF at assets/ASAM_TreatmentPlan_Template.pdf")

def cmd_plan_hash(args):
    with open(args.infile, "r", encoding="utf-8") as f:
        obj = json.load(f)
    h = hashlib.sha256(canonical_bytes(obj)).hexdigest()
    print(h)

def cmd_plan_validate(args):
    with open(args.infile, "r", encoding="utf-8") as f:
        plan = json.load(f)
    errs = []
    if not plan.get("patientFullName"): errs.append("patientFullName is required")
    if not plan.get("levelOfCare"): errs.append("levelOfCare is required")
    if not isinstance(plan.get("problems", []), list): errs.append("problems must be a list")
    if errs:
        for e in errs: print(f"error: {e}", file=sys.stderr)
        sys.exit(1)
    print("ok")

def cmd_pdf_export(args):
    pdf = os.path.abspath(args.pdf)
    plan = os.path.abspath(args.plan)
    sig = os.path.abspath(args.sig) if args.sig else ""
    out = os.path.abspath(args.out)
    exe = os.path.join(ROOT, "tools", "pdf_export", "pdf_export")
    if not os.path.exists(exe):
        print("pdf_export not built. Run VS Code task: Agent: Build pdf_export", file=sys.stderr)
        sys.exit(2)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    cmd = [exe, "--pdf", pdf, "--plan", plan, "--out", out]
    if sig: cmd += ["--sig", sig]
    subprocess.check_call(cmd)
    print(f"Wrote {out}")

def cmd_rand_id(args):
    print(rand_id())

def main():
    ap = argparse.ArgumentParser(prog="asm.py")
    sp = ap.add_subparsers(dest="cmd")

    p = sp.add_parser("scaffold"); p.set_defaults(func=cmd_scaffold)
    p = sp.add_parser("plan.hash"); p.add_argument("--in", dest="infile", required=True); p.set_defaults(func=cmd_plan_hash)
    p = sp.add_parser("plan.validate"); p.add_argument("--in", dest="infile", required=True); p.set_defaults(func=cmd_plan_validate)
    p = sp.add_parser("pdf.export")
    p.add_argument("--plan", required=True); p.add_argument("--pdf", required=True)
    p.add_argument("--sig", required=False); p.add_argument("--out", required=True)
    p.set_defaults(func=cmd_pdf_export)

    p = sp.add_parser("rand.id"); p.set_defaults(func=cmd_rand_id)

    args = ap.parse_args()
    if not args.cmd:
        ap.print_help(); sys.exit(1)
    args.func(args)

if __name__ == "__main__":
    main()
