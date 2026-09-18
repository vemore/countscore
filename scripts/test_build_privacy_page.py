"""Tests for scripts/build_privacy_page.py — the privacy page freshness check.

    uv run --no-project --with pytest pytest scripts/test_build_privacy_page.py

Run by the `backend` CI job. No pandoc and no network: the rendering itself is proven by
the `--check` step that follows these tests in the same job.
"""

from __future__ import annotations

import importlib.util
import re
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
_spec = importlib.util.spec_from_file_location(
    "build_privacy_page", ROOT / "scripts" / "build_privacy_page.py"
)
assert _spec is not None and _spec.loader is not None
page = importlib.util.module_from_spec(_spec)
sys.modules["build_privacy_page"] = page
_spec.loader.exec_module(page)

POLICY = """# Privacy Policy for CountScore

**Last Updated**: September 18, 2026

**Effective Date**: Applies to CountScore v1.1.0 and later

The app stores scores on the device.
"""


def test_an_unchanged_policy_needs_no_new_date() -> None:
    assert not page.last_updated_missing(POLICY, POLICY)


def test_a_new_policy_needs_no_new_date() -> None:
    assert not page.last_updated_missing(None, POLICY)


def test_a_changed_policy_with_the_same_date_is_refused() -> None:
    changed = POLICY.replace("on the device", "on the device and on your server")
    assert page.last_updated_missing(POLICY, changed)


def test_a_changed_policy_with_a_new_date_passes() -> None:
    changed = POLICY.replace("on the device", "on the device and on your server").replace(
        "September 18, 2026", "September 19, 2026"
    )
    assert not page.last_updated_missing(POLICY, changed)


def test_a_date_that_only_moves_elsewhere_is_not_a_bump() -> None:
    # The date text reappearing in the body is not the **Last Updated** line changing.
    changed = POLICY + "\nSee the change of September 19, 2026.\n"
    assert page.last_updated_missing(POLICY, changed)


def test_a_removed_last_updated_line_counts_as_changed() -> None:
    # Deleting the line is a visible change a reviewer sees; the check only catches silence.
    changed = POLICY.replace("**Last Updated**: September 18, 2026\n", "")
    assert not page.last_updated_missing(POLICY, changed)


def test_the_real_policy_has_exactly_one_last_updated_line() -> None:
    text = (ROOT / "privacy_policy.md").read_text(encoding="utf-8")
    assert len(page.last_updated_lines(text)) == 1


def test_a_matching_page_has_no_diff() -> None:
    assert page.stale_diff("<p>a</p>\n", "<p>a</p>\n") == []


def test_a_stale_page_has_a_diff_naming_both_sides() -> None:
    diff = "".join(page.stale_diff("<p>a</p>\n", "<p>b</p>\n"))
    assert "-<p>a</p>" in diff and "+<p>b</p>" in diff
    assert "(committed)" in diff and "(rendered from privacy_policy.md)" in diff


@pytest.mark.parametrize(
    "path, pattern",
    [
        (".github/workflows/ci.yml", r'PANDOC_VERSION: "([0-9.]+)"'),
        ("docs/README.md", r"pandoc \*\*([0-9.]+)\*\*"),
    ],
)
def test_the_pandoc_pin_is_the_same_everywhere(path: str, pattern: str) -> None:
    found = re.search(pattern, (ROOT / path).read_text(encoding="utf-8"))
    assert found is not None, f"{path} does not record the pandoc version"
    assert found.group(1) == page.PANDOC_VERSION
