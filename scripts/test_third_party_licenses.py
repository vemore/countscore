"""Tests for scripts/third_party_licenses.py - the THIRD_PARTY_LICENSES.md generator.

    uv run --no-project --with pytest pytest scripts/test_third_party_licenses.py

Run by the `app` CI job, before the `--check` step that proves the committed file against
the real pub cache. These tests build their own pubspec, package_config.json and LICENSE
files under tmp_path: no Flutter, no pub cache, no network.
"""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
_spec = importlib.util.spec_from_file_location(
    "third_party_licenses", ROOT / "scripts" / "third_party_licenses.py"
)
assert _spec is not None and _spec.loader is not None
tpl = importlib.util.module_from_spec(_spec)
sys.modules["third_party_licenses"] = tpl
_spec.loader.exec_module(tpl)

MIT = "Copyright (c) 2021 Jane Doe\n\n" + tpl.LICENSE_TEXTS["MIT"]
BSD3 = "Copyright 2013 The Flutter Authors\n\n" + tpl.LICENSE_TEXTS["BSD-3-Clause"]
BSD2 = "Copyright (c) 2019, Someone\n\n" + tpl.LICENSE_TEXTS["BSD-2-Clause"]
# The shape app_links ships: the bare template, CRLF, its appendix's placeholder unfilled.
APACHE2 = (
    "                                 Apache License\r\n"
    "                           Version 2.0, January 2004\r\n"
    "                        http://www.apache.org/licenses/\r\n\r\n"
    "   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION\r\n\r\n"
    "   2. Grant of Copyright License. Subject to the terms and conditions of\r\n\r\n"
    "   Copyright [yyyy] [name of copyright owner]\r\n"
)

PUBSPEC = """name: app
dependencies:
  flutter:
    sdk: flutter
  # a comment line
  alpha: ^1.0.0 # trailing comment
  in_app_review: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  beta: ^2.0.0

flutter:
  uses-material-design: true
"""


def make_project(tmp_path: Path, pubspec: str = PUBSPEC) -> Path:
    project = tmp_path / "project"
    sdk = tmp_path / "sdk" / "flutter"
    cache = tmp_path / "cache"
    (project / ".dart_tool").mkdir(parents=True)
    (project / "pubspec.yaml").write_text(pubspec)
    # The SDK has a LICENSE at its root and in packages/flutter, not in flutter_test.
    for d in (sdk, sdk / "packages" / "flutter", sdk / "packages" / "flutter_test"):
        d.mkdir(parents=True, exist_ok=True)
    (sdk / "LICENSE").write_text(BSD3.replace("2013", "2014"))
    (sdk / "packages" / "flutter" / "LICENSE").write_text(BSD3.replace("2013", "2014"))
    packages = {
        "alpha": (MIT, "repository: https://github.com/jane/alpha\n"),
        "in_app_review": (MIT, "homepage: https://example.org/iar\n"),
        "beta": (BSD2, ""),
    }
    config = [
        {"name": "flutter", "rootUri": (sdk / "packages" / "flutter").as_uri()},
        {"name": "flutter_test", "rootUri": (sdk / "packages" / "flutter_test").as_uri()},
        {"name": "app", "rootUri": "../"},
    ]
    for name, (license_text, extra) in packages.items():
        root = cache / f"{name}-1.0.0"
        root.mkdir(parents=True)
        (root / "LICENSE").write_text(license_text)
        (root / "pubspec.yaml").write_text(f"name: {name}\n{extra}")
        config.append({"name": name, "rootUri": root.as_uri()})
    (project / ".dart_tool" / "package_config.json").write_text(
        json.dumps({"configVersion": 2, "packages": config})
    )
    return project


def test_reads_direct_dependencies_with_sdk_and_dev_flags() -> None:
    deps = tpl.read_direct_dependencies(PUBSPEC)
    assert [(d.name, d.dev, d.sdk) for d in deps] == [
        ("flutter", False, True),
        ("alpha", False, False),
        ("in_app_review", False, False),
        ("flutter_test", True, True),
        ("beta", True, False),
    ]


@pytest.mark.parametrize(
    ("text", "spdx"),
    [(MIT, "MIT"), (BSD3, "BSD-3-Clause"), (BSD2, "BSD-2-Clause"), (APACHE2, "Apache-2.0")],
)
def test_classifies_the_known_licences(text: str, spdx: str) -> None:
    assert tpl.classify_license(text) == spdx


def test_an_unknown_licence_is_an_error_not_a_guess() -> None:
    with pytest.raises(tpl.EnvironmentProblem):
        tpl.classify_license("GNU GENERAL PUBLIC LICENSE Version 3")


def test_copyright_line_skips_the_licence_body() -> None:
    assert tpl.copyright_line(BSD3) == "Copyright 2013 The Flutter Authors"
    assert tpl.copyright_line(tpl.LICENSE_TEXTS["MIT"]).startswith("not stated")
    # The Apache template's appendix placeholder is not a copyright line.
    assert tpl.copyright_line(APACHE2).startswith("not stated")


def test_generates_every_direct_dependency(tmp_path: Path) -> None:
    project = make_project(tmp_path)
    assert tpl.main([], root=project) == 0
    text = (project / tpl.OUTPUT).read_text()
    for name in ("flutter (Flutter SDK)", "alpha", "in_app_review", "flutter_test (Flutter SDK)", "beta"):
        assert f"### {name}\n" in text
    assert "https://github.com/jane/alpha" in text
    assert "https://example.org/iar" in text  # homepage when no repository
    assert "**Note:** on Android it links" in text
    # flutter_test has no LICENSE of its own: the SDK root's is used.
    assert text.count("Copyright 2014 The Flutter Authors") == 2
    # Only the licence families in use get their text.
    assert "### BSD-2-Clause\n" in text and "### MIT\n" in text
    # Dev dependencies come after the runtime ones and do not count in the summary.
    assert text.index("### beta") > text.index("## Development Dependencies")
    assert "The 3 direct dependencies" in text


def test_check_passes_on_a_fresh_file_and_fails_on_a_stale_one(tmp_path: Path) -> None:
    project = make_project(tmp_path)
    assert tpl.main([], root=project) == 0
    assert tpl.main(["--check"], root=project) == 0
    (project / "pubspec.yaml").write_text(PUBSPEC.replace("  beta: ^2.0.0\n", ""))
    assert tpl.main(["--check"], root=project) == 1


def test_check_fails_when_the_file_is_missing(tmp_path: Path) -> None:
    project = make_project(tmp_path)
    assert tpl.main(["--check"], root=project) == 1


def test_no_pub_get_is_an_environment_error(tmp_path: Path) -> None:
    project = make_project(tmp_path)
    (project / ".dart_tool" / "package_config.json").unlink()
    assert tpl.main(["--check"], root=project) == 3


def test_a_note_for_a_removed_package_is_an_error(tmp_path: Path) -> None:
    project = make_project(tmp_path, PUBSPEC.replace("  in_app_review: ^2.0.0\n", ""))
    assert tpl.main([], root=project) == 3


def test_the_committed_file_lists_every_direct_dependency() -> None:
    """The acceptance criterion, without the pub cache: names only."""
    deps = tpl.read_direct_dependencies((ROOT / "pubspec.yaml").read_text())
    text = (ROOT / tpl.OUTPUT).read_text()
    assert len(deps) > 20
    for dep in deps:
        heading = f"### {dep.name}" + (" (Flutter SDK)" if dep.sdk else "")
        assert f"{heading}\n" in text, dep.name
