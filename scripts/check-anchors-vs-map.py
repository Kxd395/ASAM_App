#!/usr/bin/env python3
"""
Compares rule anchors (discovered) to mapping/fields_map.json keys.

Exit codes:
  0 = OK
  1 = Missing anchors (strict)
Env:
  LENIENT=1 to ignore missing anchors (prints a warning only)
  RULES_DIR=custom/path   (default: rules)
  MAP_PATH=custom/path    (default: mapping/fields_map.json)
"""
import json, os, re, sys, glob

RULES_DIR = os.environ.get("RULES_DIR", "rules")
MAP_PATH  = os.environ.get("MAP_PATH", "mapping/fields_map.json")
LENIENT   = os.environ.get("LENIENT", "0") == "1"

def read(path):
    with open(path, "rb") as f:
        return f.read()

def discover_anchors():
    anchors = set()

    # Prefer explicit anchors.json if present
    anchors_json = os.path.join(RULES_DIR, "anchors.json")
    if os.path.exists(anchors_json):
        try:
            obj = json.loads(read(anchors_json))
            if isinstance(obj, list):
                anchors.update([str(x) for x in obj])
            elif isinstance(obj, dict):
                anchors.update([str(k) for k in obj.keys()])
                if "anchors" in obj and isinstance(obj["anchors"], list):
                    anchors.update([str(x) for x in obj["anchors"]])
        except Exception as e:
            print(f"⚠️  Could not parse {anchors_json}: {e}", file=sys.stderr)

    # Heuristic scrape of other JSON files
    pats = [
        r"dom\.[A-F]\.[A-Za-z0-9_]+",
        r"flags\.[A-Za-z0-9_]+",
        r"substance\.[A-Za-z0-9_\.]+",
        r"loc\.recommendation\.code",
        r"wm\.[A-Za-z0-9_]+",
    ]
    rx = [re.compile(p) for p in pats]

    for path in glob.glob(os.path.join(RULES_DIR, "*.json")):
        try:
            s = read(path).decode("utf-8", errors="ignore")
        except Exception:
            continue
        for r in rx:
            for m in r.findall(s):
                anchors.add(m)

    # Allow an ignore list
    ignore_path = os.path.join("mapping", "ignore_anchors.txt")
    if os.path.exists(ignore_path):
        for line in read(ignore_path).decode("utf-8", errors="ignore").splitlines():
            line = line.strip()
            if line and not line.startswith("#"):
                anchors.discard(line)

    return anchors

def load_map():
    try:
        obj = json.loads(read(MAP_PATH))
        if isinstance(obj, dict):
            return set(obj.keys()), obj
    except Exception as e:
        print(f"❌ Could not parse {MAP_PATH}: {e}", file=sys.stderr)
        sys.exit(1)
    print(f"❌ {MAP_PATH} must be a JSON object", file=sys.stderr)
    sys.exit(1)

def main():
    discovered = discover_anchors()
    mapped, raw = load_map()

    missing = sorted(discovered - mapped)
    extra   = sorted(mapped - discovered)  # not an error, just FYI

    print(f"🔎 Discovered anchors: {len(discovered)}")
    print(f"🗺️  Mapped anchors:    {len(mapped)}")

    if extra:
        print(f"ℹ️  Mapped-but-not-discovered (OK): {', '.join(extra[:20])}" + (" …" if len(extra) > 20 else ""))

    if missing:
        print(f"❗ Missing from mapping ({len(missing)}):")
        for m in missing:
            print(f"   - {m}")
        if LENIENT:
            print("⚠️  LENIENT=1 set — not failing build.")
            sys.exit(0)
        sys.exit(1)

    print("✅ Mapping covers all discovered anchors.")
    sys.exit(0)

if __name__ == "__main__":
    main()
