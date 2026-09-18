"""Tests for compose_screenshots.py — synthetic captures, no device, no network.

uv run --no-project --with pytest --with pillow pytest scripts/test_compose_screenshots.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import compose_screenshots as cs

REPO = Path(__file__).resolve().parents[1]


@pytest.fixture()
def repo(tmp_path: Path) -> Path:
    raw = tmp_path / "store_listing" / "assets" / "screenshots" / "phone"
    raw.mkdir(parents=True)
    for name in ("01_a", "02_b"):
        Image.new("RGBA", (1080, 2400), (250, 240, 255, 255)).save(raw / f"{name}.png")
    for locale in ("fr-FR", "en-US"):
        (tmp_path / "store_listing" / locale).mkdir()
        (tmp_path / "store_listing" / locale / "title.txt").write_text("t", encoding="utf-8")
    (tmp_path / "store_listing" / "fr-FR" / cs.CAPTIONS_FILE).write_text(
        "# comment\n01_a: Toutes vos parties, d'un coup d'œil\n02_b: Votre jeu n'y est pas ? Créez-le\n",
        encoding="utf-8",
    )
    return tmp_path


def font() -> str:
    return str(cs.find_font("fr-FR"))


def test_output_is_1080x1920_opaque_rgb(repo: Path) -> None:
    written = cs.compose_locale(repo, "fr-FR", font())
    assert [p.name for p in written] == ["01_a.png", "02_b.png"]
    for path in written:
        assert path.parent == repo / "store_listing" / "fr-FR" / "screenshots" / "phone"
        with Image.open(path) as im:
            assert im.size == (1080, 1920)
            assert im.mode == "RGB"
        assert cs.check_image(path) is None


def test_check_flags_a_locale_without_a_set(repo: Path) -> None:
    cs.compose_locale(repo, "fr-FR", font())
    assert cs.check(repo, ["fr-FR"]) == []
    problems = cs.check(repo, ["fr-FR", "en-US"])
    assert len(problems) == 2 and all(p.startswith("en-US: missing") for p in problems)


def test_check_flags_a_raw_capture(repo: Path) -> None:
    out = repo / "store_listing" / "fr-FR" / "screenshots" / "phone"
    out.mkdir(parents=True)
    for name in ("01_a", "02_b"):
        Image.new("RGBA", (1080, 2400)).save(out / f"{name}.png")
    assert len(cs.check(repo, ["fr-FR"])) == 2


def test_listing_locales_match_play_publish(repo: Path) -> None:
    assert cs.listing_locales(repo) == ["en-US", "fr-FR"]


def test_captions_must_cover_every_capture(repo: Path) -> None:
    path = repo / "store_listing" / "fr-FR" / cs.CAPTIONS_FILE
    path.write_text("01_a: seul\n", encoding="utf-8")
    with pytest.raises(cs.ComposeError, match="no caption for 02_b"):
        cs.read_captions(path, ["01_a", "02_b"])
    path.write_text("01_a: x\n02_b: y\n03_c: z\n", encoding="utf-8")
    with pytest.raises(cs.ComposeError, match="no raw capture named 03_c"):
        cs.read_captions(path, ["01_a", "02_b"])


def test_no_break_space_is_never_a_line_break() -> None:
    f = cs.ImageFont.truetype(font(), 84)
    _, lines = cs.fit_caption("Votre jeu n'y est pas ? Créez-le", Path(font()), "fr-FR")
    assert all(not line.startswith("?") for line in lines)
    assert len(cs.wrap("a b", f, 10, by_char=False)) == 1


def test_a_caption_too_long_is_refused() -> None:
    with pytest.raises(cs.ComposeError, match="too long"):
        cs.fit_caption("mot " * 60, Path(font()), "fr-FR")


def test_main_skips_locales_without_captions(
    repo: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    assert cs.main(["--root", str(repo), "--font", font()]) == 0
    assert "no screenshot_captions.txt for en-US" in capsys.readouterr().err
    assert cs.main(["--root", str(repo), "--check", "--locale", "fr-FR"]) == 0
    assert cs.main(["--root", str(repo), "--check"]) == 1


def test_committed_sets_are_compliant() -> None:
    """Every composed set in the repository is what Play accepts."""
    sets = [
        p
        for p in sorted((REPO / "store_listing").glob("*/screenshots/phone/*.png"))
        if p.parts[-4] != "assets"
    ]
    assert sets, "no composed set committed"
    for path in sets:
        assert cs.check_image(path) is None
