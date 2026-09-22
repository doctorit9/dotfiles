#!/usr/bin/env python3
"""Apply Matugen colors to COSMIC without touching anything else.

Pipeline per wallpaper run:
  1. `cosmic-settings appearance export` captures the LIVE builder, including
     the user's roundness / density / gaps / frosted / alpha-map preferences.
  2. Only color values (palette entries + color overrides) are swapped for the
     Matugen colors. Existing alpha channels are preserved.
  3. The merged RON is applied with `cosmic-settings appearance import`,
     which rebuilds the derived theme live.

Nothing but colors changes: no geometry, no frosted flags, no mode switch
beyond what the palette already implies.
"""
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

EXPORT_KEYS = (
    "neutral_tint",
    "bg_color",
    "primary_container_bg",
    "secondary_container_bg",
    "text_tint",
    "accent",
    "success",
    "warning",
    "destructive",
    "window_hint",
)
COLORS_JSON = Path("/home/doctorit/.config/matugen/themes/matugen-colors.json")
MERGED_RON = Path("/home/doctorit/.config/matugen/themes/matugen-dark.ron")


def run(*args: str) -> None:
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stderr.strip() or f"command failed: {' '.join(args)}", file=sys.stderr)
        sys.exit(1)


def swap_rgb_keep_alpha(old_hex: str, new_rgb: str) -> str:
    """Replace the RGB of a bare RRGGBB[AA] hex string, keep its alpha."""
    alpha = old_hex[6:8] if len(old_hex) == 8 else "FF"
    return f"{new_rgb.upper()}{alpha.upper()}"


def main() -> int:
    colors = json.loads(COLORS_JSON.read_text(encoding="utf-8"))
    palette = {k: v.lstrip("#") for k, v in colors["palette"].items()}
    overrides = {k: v.lstrip("#") for k, v in colors["overrides"].items()}

    with tempfile.NamedTemporaryFile("r", suffix=".ron", delete=False) as tmp:
        tmp_path = tmp.name
    run("/usr/bin/cosmic-settings", "appearance", "export", tmp_path)
    ron = Path(tmp_path).read_text(encoding="utf-8")

    # Palette name (first `name: "..."` in the file).
    ron, n = re.subn(r'name: "[^"]*"', f'name: "{colors["palette_name"]}"', ron, count=1)
    if n != 1:
        print("Error: palette name line not found in export", file=sys.stderr)
        return 1

    # Palette entries: `key: "#RRGGBBAA",` (indentation-agnostic).
    missing = []
    for key, rgb in palette.items():
        pat = re.compile(r"(^\s*" + re.escape(key) + r': "#)([0-9A-Fa-f]{6,8})(",)', re.M)

        def repl(m: re.Match) -> str:
            return m.group(1) + swap_rgb_keep_alpha(m.group(2), rgb) + m.group(3)

        ron, count = pat.subn(repl, ron)
        if count != 1:
            missing.append(key)
    if missing:
        print(f"Error: palette keys not found: {missing}", file=sys.stderr)
        return 1

    # Overrides: `    key: Some("#RRGGBBAA"),` (keep alpha) or `None` (set it).
    for key in EXPORT_KEYS:
        if key not in overrides:
            continue
        rgb = overrides[key]
        pat_some = re.compile(r"(^\s*" + re.escape(key) + r': Some\("#)([0-9A-Fa-f]{6,8})("\),)', re.M)

        def repl_some(m: re.Match) -> str:
            return m.group(1) + swap_rgb_keep_alpha(m.group(2), rgb) + m.group(3)

        ron, count = pat_some.subn(repl_some, ron)
        if count == 0:
            default_alpha = "D1" if key == "bg_color" else "FF"
            pat_none = re.compile(r"(^\s*" + re.escape(key) + r": )None(,)", re.M)
            ron, count = pat_none.subn(
                lambda m: f"{m.group(1)}Some(\"{rgb.upper()}{default_alpha}\"){m.group(2)}", ron
            )
            if count != 1:
                print(f"Error: override key not found: {key}", file=sys.stderr)
                return 1

    MERGED_RON.write_text(ron, encoding="utf-8")
    run("/usr/bin/cosmic-settings", "appearance", "import", str(MERGED_RON))
    print(f"Applied Matugen colors from {COLORS_JSON.name} (geometry untouched)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
