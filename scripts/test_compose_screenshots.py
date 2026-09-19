"""Tests for compose_screenshots.py — synthetic captures, no device, no network.

uv run --no-project --with pytest --with pillow pytest scripts/test_compose_screenshots.py
"""

from __future__ import annotations

import re
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


def test_a_forced_break_is_kept_and_not_drawn() -> None:
    _, lines = cs.fit_caption("All your|games", Path(font()), "en-US")
    assert lines == ["All your", "games"]


def test_the_break_prefers_the_end_of_a_clause() -> None:
    f = cs.load_font(Path(font()), 84, "en-US")
    lines = cs.balance(
        ["Game not", "listed? Create it"], "Game not listed? Create it", f, 936, False
    )
    assert lines == ["Game not listed?", "Create it"]


def test_every_store_locale_has_captions() -> None:
    """A store locale without captions would publish the raw captures Play refuses."""
    for locale in cs.listing_locales(REPO):
        assert (REPO / "store_listing" / locale / cs.CAPTIONS_FILE).is_file(), locale


def _raw(directory: Path, names: tuple[str, ...], colour: tuple[int, int, int, int]) -> None:
    directory.mkdir(parents=True, exist_ok=True)
    for name in names:
        Image.new("RGBA", (1080, 2400), colour).save(directory / f"{name}.png")


def test_a_locale_raw_set_replaces_the_shared_one(repo: Path) -> None:
    """The ja-JP carousel is composed from Japanese captures, not the shared French ones."""
    own = repo / "store_listing" / "fr-FR" / cs.LOCALE_RAW_DIR
    _raw(own, ("01_a", "02_b"), (0, 0, 255, 255))
    assert cs.raw_dir(repo, "fr-FR") == own
    assert cs.raw_dir(repo, "en-US") == repo / "store_listing" / cs.RAW_DIR
    written = cs.compose_locale(repo, "fr-FR", font())
    with Image.open(written[0]) as im:
        # The centre of the screen area is the locale's blue capture, not the shared lilac.
        assert im.getpixel((540, 1200)) == (0, 0, 255)


def test_a_locale_raw_set_is_taken_whole(repo: Path) -> None:
    """One file in raw/ does not borrow the others from the shared set: no mixed languages."""
    _raw(repo / "store_listing" / "fr-FR" / cs.LOCALE_RAW_DIR, ("01_a",), (0, 0, 255, 255))
    assert [p.stem for p in cs.raw_captures(repo, "fr-FR")] == ["01_a"]
    with pytest.raises(cs.ComposeError, match="no raw capture named 02_b"):
        cs.compose_locale(repo, "fr-FR", font())


def test_compose_removes_a_screenshot_with_no_capture(repo: Path) -> None:
    out = repo / "store_listing" / "fr-FR" / "screenshots" / "phone"
    out.mkdir(parents=True)
    Image.new("RGB", (1080, 1920)).save(out / "04_old.png")
    cs.compose_locale(repo, "fr-FR", font())
    assert sorted(p.name for p in out.glob("*.png")) == ["01_a.png", "02_b.png"]


def test_check_flags_a_png_the_composer_did_not_write(repo: Path) -> None:
    """A stray capture committed next to the composed set turns --check (and CI) red."""
    cs.compose_locale(repo, "fr-FR", font())
    out = repo / "store_listing" / "fr-FR" / "screenshots" / "phone"
    Image.new("RGBA", (1080, 2400)).save(out / "09_raw.png")
    problems = cs.check(repo, ["fr-FR"])
    assert len(problems) == 1 and "09_raw.png matches no raw capture" in problems[0]


def test_check_follows_the_locale_raw_set(repo: Path) -> None:
    cs.compose_locale(repo, "fr-FR", font())
    _raw(
        repo / "store_listing" / "fr-FR" / cs.LOCALE_RAW_DIR,
        ("01_a", "02_b", "03_c"),
        (0, 0, 0, 255),
    )
    problems = cs.check(repo, ["fr-FR"])
    assert len(problems) == 1 and problems[0].startswith("fr-FR: missing") and "03_c" in problems[0]


def test_the_band_is_the_app_teal() -> None:
    """The gradient starts on kBrandSeedLight, and nothing is left of the old deep purple."""
    theme = (REPO / "lib" / "utils" / "app_theme.dart").read_text(encoding="utf-8")
    match = re.search(r"kBrandSeedLight = Color\(0xFF([0-9A-Fa-f]{6})\)", theme)
    assert match, "kBrandSeedLight not found in app_theme.dart"
    seed = tuple(int(match.group(1)[i : i + 2], 16) for i in (0, 2, 4))
    assert cs.BRAND == seed
    canvas = cs.gradient()
    assert canvas.getpixel((0, 0)) == seed
    assert canvas.getpixel((0, cs.HEIGHT - 1)) == cs.BACKGROUND_BOTTOM
    source = (REPO / "scripts" / "compose_screenshots.py").read_text(encoding="utf-8")
    assert "0x67, 0x3A, 0xB7" not in source and "Deep Purple" not in source


def test_the_committed_raw_sets_match_their_captions() -> None:
    """A locale's raw/ set and its captions name the same captures, or compose would refuse."""
    for locale in cs.listing_locales(REPO):
        stems = [p.stem for p in cs.raw_captures(REPO, locale)]
        cs.read_captions(REPO / "store_listing" / locale / cs.CAPTIONS_FILE, stems)
