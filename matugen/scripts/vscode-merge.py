#!/usr/bin/env python3
"""Merge Matugen-generated VS Code colors into settings.json.

Only touches `workbench.colorCustomizations` keys that Matugen owns
(tracked in the `__matugenManaged` marker). Every other setting the user
has is preserved byte-for-byte in meaning (key order preserved).
"""
import json
import sys

MARKER = "__matugenManaged"
TARGET = "workbench.colorCustomizations"


def main() -> int:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} GENERATED_COLORS_JSON SETTINGS_JSON", file=sys.stderr)
        return 2
    gen_path, settings_path = sys.argv[1], sys.argv[2]

    with open(gen_path, encoding="utf-8") as f:
        new_colors = json.load(f).get(TARGET, {})

    try:
        with open(settings_path, encoding="utf-8") as f:
            settings = json.load(f)
    except FileNotFoundError:
        settings = {}
    if not isinstance(settings, dict):
        print(f"Error: {settings_path} is not a JSON object", file=sys.stderr)
        return 1

    # Remove previously-managed keys (but keep any user-added customizations).
    owned = settings.get(MARKER, {}).get(TARGET, [])
    current = settings.get(TARGET, {})
    if not isinstance(current, dict):
        current = {}
    for key in owned:
        current.pop(key, None)
    if current:
        settings[TARGET] = current
    else:
        settings.pop(TARGET, None)

    # Apply the fresh Matugen colors.
    if new_colors:
        settings.setdefault(TARGET, {}).update(new_colors)
    settings[MARKER] = {TARGET: sorted(new_colors)}

    with open(settings_path, "w", encoding="utf-8") as f:
        json.dump(settings, f, indent=4)
        f.write("\n")
    print(f"Merged {len(new_colors)} Matugen colors into {settings_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
