#!/usr/bin/env python3
"""Render the Autoload Last Save AMUMSS script.

Reads the patched value in src/patches.tsv (FILE, PROPERTY, BASE, VALUE)
and writes the rendered script plus the expected values that make verify
checks the built EXML against. The table drives both, so a value can
never be patched without also being checked, and the two can never drift
apart.
"""

import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def read_table(path):
    """Return the patch rows as (file, prop, base, value) tuples."""
    rows = []
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            line = line.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) != 4:
                raise SystemExit("bad patch row (need 4 tab separated fields): %r" % line)
            file_path, prop, base, value = (p.strip() for p in parts)
            if not file_path or not prop or not value:
                raise SystemExit("bad patch row (empty field): %r" % line)
            rows.append((file_path, prop, base, value))
    if not rows:
        raise SystemExit("no patch rows in %s" % path)
    return rows


def render_block(file_path, prop, value):
    """Return one MBIN_CHANGE_TABLE entry for a single value patch."""
    return (
        '    {\n'
        '        ["MBIN_FILE_SOURCE"]  = "%s",\n'
        '        ["MXML_CHANGE_TABLE"] = {\n'
        '            {\n'
        '                ["VALUE_CHANGE_TABLE"] = {\n'
        '                    {"%s", "%s"},\n'
        '                },\n'
        '            },\n'
        '        },\n'
        '    },' % (file_path, prop, value)
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--table", default=os.path.join(HERE, "patches.tsv"))
    parser.add_argument("--template", default=os.path.join(HERE, "autoload.lua.in"))
    parser.add_argument("--out-script", required=True)
    parser.add_argument("--out-expected", required=True)
    args = parser.parse_args()

    rows = read_table(args.table)
    with open(args.template, encoding="utf-8") as handle:
        template = handle.read()
    if "@MBINBLOCK@" not in template:
        raise SystemExit("template has no @MBINBLOCK@ marker")

    blocks = "\n".join(render_block(f, p, v) for f, p, _, v in rows)
    script = template.replace("@MBINBLOCK@", blocks)
    with open(args.out_script, "w", encoding="utf-8") as handle:
        handle.write(script)

    with open(args.out_expected, "w", encoding="utf-8") as handle:
        for file_path, prop, base, value in rows:
            handle.write("%s\t%s\t%s\t%s\n" % (file_path, prop, base, value))


if __name__ == "__main__":
    sys.exit(main())
