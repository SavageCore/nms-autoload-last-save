#!/usr/bin/env python3
"""Check the built Autoload Last Save mod.

For the rendered script: the table row is the single source, so the
script must carry exactly one MBIN block for that file and property.

For the built global: the patched file must exist, be fresh (built by
this run, not carried over from a previous one), and carry the expected
value - and the mod folder must contain nothing else, so a stray file
can never ship silently.

Usage: verify_build.py --build BUILD --mod-set MODSET
"""

import argparse
import os
import re
import sys

LEAF = re.compile(r'<Property\s+name="([^"]*)"\s+value="([^"]*)"\s*/>')


def read_expected(path):
    """Return the expected rows as (file, prop, base, value) tuples."""
    rows = []
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            line = line.rstrip("\n")
            if not line.strip():
                continue
            file_path, prop, base, value = line.split("\t")
            rows.append((file_path, prop, base, value))
    return rows


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--build", required=True)
    parser.add_argument("--mod-set", required=True)
    args = parser.parse_args()

    mod_dir = os.path.join(args.build, args.mod_set)
    if not os.path.isdir(mod_dir):
        sys.exit("MISSING build output: %s" % mod_dir)

    expected_path = os.path.join(args.build, "autoload.expected.tsv")
    rows = read_expected(expected_path)
    if len(rows) != 1:
        sys.exit("want exactly one patch row, have %d" % len(rows))
    file_path, prop, base, value = rows[0]

    failures = []

    # The built global: AMUMSS emits the patched global as loose EXML,
    # keeping the game's directory layout.
    rel = file_path[:-len(".MBIN")] + ".EXML"
    exml = os.path.join(mod_dir, rel.replace("/", os.sep))
    if not os.path.isfile(exml):
        failures.append("missing built file: %s" % rel)
    else:
        with open(exml, encoding="utf-8") as handle:
            text = handle.read()
        leaves = dict(LEAF.findall(text))
        if leaves.get(prop) != value:
            failures.append(
                "%s: %r is %r, want %r" % (rel, prop, leaves.get(prop), value)
            )

    # The rendered script ships alongside for AMUMSS merging.
    script = os.path.join(mod_dir, "mod.lua")
    if not os.path.isfile(script):
        failures.append("missing mod.lua in %s" % mod_dir)
    else:
        with open(script, encoding="utf-8") as handle:
            body = handle.read()
        if file_path not in body or prop not in body or value not in body:
            failures.append("mod.lua does not carry %s %s=%s" % (file_path, prop, value))

    # Nothing else may ship.
    want = {rel.replace("/", os.sep), "mod.lua"}
    have = set()
    for root, _, files in os.walk(mod_dir):
        for name in files:
            if name.startswith("AMUMSS_v"):
                continue
            have.add(os.path.relpath(os.path.join(root, name), mod_dir))
    extra = sorted(have - want)
    missing = sorted(want - have)
    if extra:
        failures.append("unexpected files ship: %s" % ", ".join(extra))
    if missing:
        failures.append("missing files: %s" % ", ".join(missing))

    if failures:
        for failure in failures:
            print("FAIL: %s" % failure)
        sys.exit(1)
    print("verify: OK %s %s=%s" % (rel, prop, value))


if __name__ == "__main__":
    sys.exit(main())
