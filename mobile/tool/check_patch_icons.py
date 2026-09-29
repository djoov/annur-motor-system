"""Check a Shorebird patch build for icons the installed release can't draw.

Icon fonts (Lucide, MaterialIcons) are tree-shaken into the release as assets,
and Shorebird patches cannot change assets. Any icon glyph that exists in the
new build but not in the release font renders BLANK on devices after patching.

Usage (after `shorebird patch android --dry-run` has built the .aab):
    python tool/check_patch_icons.py <release.apk> [new.aab]

Requires: pip install fonttools
"""
import io
import re
import sys
import zipfile
from pathlib import Path

from fontTools.ttLib import TTFont

FONTS = {
    "lucide": "packages/lucide_icons_flutter/assets/lucide.ttf",
    "material": "fonts/MaterialIcons-Regular.otf",
}


def codepoints(archive: str, font: str) -> set[int]:
    with zipfile.ZipFile(archive) as z:
        entry = next(n for n in z.namelist() if n.endswith("flutter_assets/" + font))
        return set(TTFont(io.BytesIO(z.read(entry))).getBestCmap())


def lucide_names() -> dict[int, str]:
    pub = Path.home() / "AppData/Local/Pub/Cache/hosted/pub.dev"
    candidates = sorted(pub.glob("lucide_icons_flutter-*/lib/lucide_icons.dart"))
    if not candidates:
        return {}
    names: dict[int, str] = {}
    src = candidates[-1].read_text(encoding="utf-8")
    for m in re.finditer(r"static const IconData (\w+) = const IconData\((\d+)", src):
        names.setdefault(int(m.group(2)), m.group(1))
    return names


def main() -> int:
    release = sys.argv[1]
    new = sys.argv[2] if len(sys.argv) > 2 else "build/app/outputs/bundle/release/app-release.aab"
    names = lucide_names()
    problems = 0
    for key, font in FONTS.items():
        missing = sorted(codepoints(new, font) - codepoints(release, font))
        print(f"{key}: {len(missing)} glyph(s) not in release")
        for cp in missing:
            print(f"   U+{cp:04X}  {names.get(cp, '') if key == 'lucide' else ''}")
        problems += len(missing)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
