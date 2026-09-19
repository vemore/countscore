#!/usr/bin/env python3
"""CountScore - generate THIRD_PARTY_LICENSES.md from pubspec.yaml.

The file used to be written by hand and drifted: it named a 2025 dependency set while
pubspec.yaml moved on (wip/done/2026-09-14-third-party-licenses-stale.md). It is now
generated, and the `app` CI job fails when the committed file differs.

Where each part comes from:
  - the package list: the direct `dependencies:` and `dev_dependencies:` of pubspec.yaml
  - the licence and copyright line: that package's LICENSE, found through
    .dart_tool/package_config.json - the pub cache directory of the version pubspec.lock
    resolves, or the Flutter SDK for an `sdk: flutter` package
  - the repository: the package's own pubspec.yaml (`repository:`, else `homepage:`)
  - everything else (summary sentence, notes, the Nunito font, licence texts): this file

No version numbers are written: they belong to pubspec.lock, and printing them would turn
every Dependabot week red. The file changes when a direct dependency is added or removed,
or when a package's LICENSE changes its licence or copyright line.

A LICENSE this script cannot classify is an error, never a guess: a new licence family
must be read by a human and added to LICENSE_TEXTS below.

Stdlib only. Needs `flutter pub get` first (it reads .dart_tool/package_config.json).

Exit codes: 0 written / up to date - 1 --check found a difference - 3 environment
(no package_config.json, a package or LICENSE missing, an unknown licence)

Usage:
  uv run --no-project scripts/third_party_licenses.py            regenerate the file
  uv run --no-project scripts/third_party_licenses.py --check    fail if it is stale
"""

from __future__ import annotations

import argparse
import difflib
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = "THIRD_PARTY_LICENSES.md"
FLUTTER_REPOSITORY = "https://github.com/flutter/flutter"

# Hand-written notes, keyed by package name. A note on a package that is no longer a
# direct dependency is an error, so a stale note cannot survive a removal.
NOTES: dict[str, str] = {
    "in_app_review": (
        "on Android it links `com.google.android.play:review` and `play-services-base`, "
        "Google binaries covered by the Play Core Software Development Kit Terms of Service "
        "rather than by an open-source licence. They are not redistributed by this "
        "repository; Gradle resolves them at build time."
    ),
}


class EnvironmentProblem(Exception):
    """Something the script needs is missing: exit 3."""


@dataclass(frozen=True)
class Dependency:
    name: str
    dev: bool
    sdk: bool


@dataclass(frozen=True)
class Package:
    dependency: Dependency
    license: str
    copyright: str
    repository: str


def read_direct_dependencies(pubspec: str) -> list[Dependency]:
    """The keys of the top-level `dependencies:` and `dev_dependencies:` blocks.

    pubspec.yaml is YAML, but only this narrow shape matters: a block key at column 0,
    a package name at two spaces, and an optional `sdk:` child below it.
    """
    deps: list[Dependency] = []
    section: str | None = None
    current: tuple[str, bool] | None = None
    sdk_names: set[str] = set()
    for raw in pubspec.splitlines():
        line = raw.split(" #", 1)[0].rstrip() if not raw.lstrip().startswith("#") else ""
        if not line.strip():
            continue
        indent = len(line) - len(line.lstrip(" "))
        if indent == 0:
            key = line.split(":", 1)[0]
            section = key if key in ("dependencies", "dev_dependencies") else None
            current = None
            continue
        if section is None:
            continue
        if indent == 2:
            name = line.strip().split(":", 1)[0]
            current = (name, section == "dev_dependencies")
            deps.append(Dependency(name, current[1], False))
        elif current is not None and line.strip().startswith("sdk:"):
            sdk_names.add(current[0])
    return [Dependency(d.name, d.dev, d.name in sdk_names) for d in deps]


def classify_license(text: str) -> str:
    """The SPDX identifier of a LICENSE text, or EnvironmentProblem."""
    flat = " ".join(text.split())
    if "Permission is hereby granted, free of charge" in flat:
        return "MIT"
    if "Redistribution and use in source and binary forms" in flat:
        if re.search(r"Neither the name of .* nor the names of its contributors", flat):
            return "BSD-3-Clause"
        return "BSD-2-Clause"
    raise EnvironmentProblem("unknown licence")


def copyright_line(text: str) -> str:
    """The first `Copyright <year|(c)|©> ...` line, or a marker when there is none."""
    for line in text.splitlines():
        stripped = line.strip()
        if re.match(r"Copyright\s+(\(c\)|©|\d)", stripped, re.IGNORECASE):
            return stripped
    return "not stated in the package's LICENSE"


def package_roots(package_config: Path) -> dict[str, Path]:
    data = json.loads(package_config.read_text(encoding="utf-8"))
    roots: dict[str, Path] = {}
    for pkg in data["packages"]:
        uri = pkg["rootUri"]
        if uri.startswith("file://"):
            path = Path(unquote(urlparse(uri).path))
        else:  # relative to .dart_tool/ - the app itself, "../"
            path = (package_config.parent / uri).resolve()
        roots[pkg["name"]] = path
    return roots


def find_license(root: Path, sdk: bool) -> Path:
    """The package's LICENSE. An SDK package without one uses the Flutter SDK's."""
    candidates = [root]
    if sdk:  # flutter/packages/<name>/ -> flutter/packages/ -> flutter/
        candidates += [root.parent, root.parent.parent]
    for directory in candidates:
        path = directory / "LICENSE"
        if path.is_file():
            return path
    raise EnvironmentProblem(f"no LICENSE in {root}")


def repository_of(root: Path, dep: Dependency) -> str:
    if dep.sdk:
        return FLUTTER_REPOSITORY
    pubspec = root / "pubspec.yaml"
    fields: dict[str, str] = {}
    if pubspec.is_file():
        for line in pubspec.read_text(encoding="utf-8").splitlines():
            match = re.match(r"(repository|homepage):\s*['\"]?([^'\"\s]+)", line)
            if match:
                fields.setdefault(match.group(1), match.group(2))
    return fields.get("repository") or fields.get("homepage") or f"https://pub.dev/packages/{dep.name}"


def collect(root: Path) -> list[Package]:
    pubspec = root / "pubspec.yaml"
    package_config = root / ".dart_tool" / "package_config.json"
    if not package_config.is_file():
        raise EnvironmentProblem(f"{package_config} is missing: run `flutter pub get` first")
    deps = read_direct_dependencies(pubspec.read_text(encoding="utf-8"))
    names = {d.name for d in deps}
    stale = sorted(set(NOTES) - names)
    if stale:
        raise EnvironmentProblem(f"NOTES names packages that are not direct dependencies: {stale}")
    roots = package_roots(package_config)
    packages: list[Package] = []
    for dep in deps:
        if dep.name not in roots:
            raise EnvironmentProblem(f"{dep.name} is not in package_config.json: run `flutter pub get`")
        pkg_root = roots[dep.name]
        license_path = find_license(pkg_root, dep.sdk)
        text = license_path.read_text(encoding="utf-8", errors="replace")
        try:
            spdx = classify_license(text)
        except EnvironmentProblem:
            raise EnvironmentProblem(
                f"{dep.name}: cannot classify {license_path} - read it, and add its licence to "
                "classify_license() and LICENSE_TEXTS"
            ) from None
        packages.append(Package(dep, spdx, copyright_line(text), repository_of(pkg_root, dep)))
    return packages


def render_package(pkg: Package) -> list[str]:
    dep = pkg.dependency
    lines = [
        f"### {dep.name}" + (" (Flutter SDK)" if dep.sdk else ""),
        f"**License:** {pkg.license}  ",
        f"**Copyright:** {pkg.copyright}  ",
        f"**Repository:** {pkg.repository}",
    ]
    if dep.name in NOTES:
        lines[-1] += "  "
        lines.append(f"**Note:** {NOTES[dep.name]}")
    return lines + [""]


def render(packages: list[Package]) -> str:
    runtime = [p for p in packages if not p.dependency.dev]
    dev = [p for p in packages if p.dependency.dev]
    used = sorted({p.license for p in packages})
    counts = ", ".join(
        f"{spdx} ({sum(1 for p in runtime if p.license == spdx)})"
        for spdx in used
        if any(p.license == spdx for p in runtime)
    )

    out: list[str] = [
        "# Third-Party Licenses",
        "",
        "<!-- Generated by scripts/third_party_licenses.py from pubspec.yaml and each",
        "     package's LICENSE. Do not edit by hand: CI fails when this file differs from",
        "     the script's output. Regenerate with",
        "     `uv run --no-project scripts/third_party_licenses.py` after `flutter pub get`. -->",
        "",
        "CountScore uses the following open-source packages. We are grateful to their authors "
        "and contributors.",
        "",
        "## Summary",
        "",
        f"The {len(runtime)} direct dependencies the app ships with are under: {counts}. "
        "Every licence below is permissive; none is copyleft, and there is no licence "
        "conflict. The one bundled font, Nunito, is under the **SIL Open Font License 1.1**, "
        "which allows bundling it in any application and asks only that the licence travel "
        "with it; the web version also serves its fallback fonts (Noto, OFL 1.1; Roboto, "
        "Apache 2.0) itself. The one non-open-source item is the Google Play Core review binary that "
        "`in_app_review` links on Android — see its note below.",
        "",
        "Only direct dependencies are listed; their versions, and every transitive package, "
        "are in `pubspec.lock`. The app's licence page (About → Licenses, Flutter's "
        "`showLicensePage`) shows the full text of every package compiled into it, "
        "transitive ones included.",
        "",
        "---",
        "",
        "## Direct Dependencies",
        "",
    ]
    for pkg in runtime:
        out += render_package(pkg)
    out += [
        "---",
        "",
        "## Fonts",
        "",
        "### Nunito",
        "**License:** SIL Open Font License, Version 1.1  ",
        "**Copyright:** Copyright 2014 The Nunito Project Authors (https://github.com/googlefonts/nunito)  ",
        "**Source:** https://github.com/google/fonts/tree/main/ofl/nunito  ",
        "**Files:** `assets/fonts/Nunito-{Regular,SemiBold,Bold,ExtraBold}.ttf` — static "
        "instances (weights 400, 600, 700, 800) of the variable font `Nunito[wght].ttf`, cut "
        "with `fonttools varLib.instancer`  ",
        "**Licence text:** `assets/fonts/OFL.txt`, bundled with the app and shown on its "
        "licence page  ",
        "**Description:** the app's typeface. Bundled rather than fetched at runtime, so "
        "displaying text makes no network request",
        "",
        "### Noto and Roboto (web version only)",
        "**License:** SIL Open Font License, Version 1.1 (Noto); Apache License, Version 2.0 "
        "(Roboto)  ",
        "**Copyright:** The Noto Project Authors (https://github.com/notofonts); Adobe for the "
        "Noto Sans CJK families; Google for Noto Color Emoji and Roboto — each file's name "
        "table carries its own line  ",
        "**Source:** Google Fonts (https://fonts.google.com/noto), the files the Flutter web "
        "engine falls back to, unmodified  ",
        "**Files:** not in the repository: `scripts/build_web.sh` copies them into "
        "`build/web/fallback-fonts/` at build time  ",
        "**Licence text:** `web/fallback-fonts/OFL.txt` and "
        "`web/fallback-fonts/LICENSE-Apache-2.0.txt`, published next to the fonts  ",
        "**Description:** the fonts the PWA falls back to for glyphs Nunito lacks (Chinese, "
        "Japanese, Arabic, Devanagari, emoji...). Served by whoever serves the PWA, so a "
        "browser never asks Google for them. The Android app uses the system's fonts instead",
        "",
        "---",
        "",
        "## Development Dependencies",
        "",
        "Used to build and test the app; not shipped in it.",
        "",
    ]
    for pkg in dev:
        out += render_package(pkg)
    out += ["---", "", "## License Texts", ""]
    for spdx in used:
        out += [f"### {spdx}", "", "```", LICENSE_TEXTS[spdx].strip("\n"), "```", ""]
    out += [
        "---",
        "",
        "## Attribution Requirements",
        "",
        "All of these licences require:",
        "1. **Copyright notice retention**: keep copyright notices in source code",
        "2. **License text inclusion**: include the licence text when redistributing",
    ]
    if "BSD-3-Clause" in used:
        out.append(
            "3. **No endorsement** (BSD-3-Clause): the copyright holders' names may not be "
            "used to promote the app without permission"
        )
    return "\n".join(out) + "\n"


LICENSE_TEXTS: dict[str, str] = {
    "MIT": """
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
""",
    "BSD-3-Clause": """
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
""",
    "BSD-2-Clause": """
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
""",
}


def main(argv: list[str] | None = None, root: Path = ROOT) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--check", action="store_true", help="fail if the committed file is stale")
    args = parser.parse_args(argv)
    try:
        text = render(collect(root))
    except EnvironmentProblem as exc:
        print(f"third_party_licenses: {exc}", file=sys.stderr)
        return 3
    target = root / OUTPUT
    if args.check:
        current = target.read_text(encoding="utf-8") if target.is_file() else ""
        if current == text:
            print(f"{OUTPUT} is up to date")
            return 0
        sys.stdout.writelines(
            difflib.unified_diff(
                current.splitlines(keepends=True),
                text.splitlines(keepends=True),
                f"{OUTPUT} (committed)",
                f"{OUTPUT} (generated)",
            )
        )
        print(
            f"\n{OUTPUT} is stale. Fix: flutter pub get, then "
            "`uv run --no-project scripts/third_party_licenses.py`, and commit the result.",
            file=sys.stderr,
        )
        return 1
    target.write_text(text, encoding="utf-8")
    print(f"wrote {OUTPUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
