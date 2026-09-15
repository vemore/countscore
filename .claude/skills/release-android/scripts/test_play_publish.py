"""Tests for play_publish.py — no network, no credentials: the Google service is a fake.

    uv run --with pytest --with google-api-python-client --with google-auth \
        pytest .claude/skills/release-android/scripts/
"""

from __future__ import annotations

import io
import sys
from pathlib import Path
from typing import Any

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent))
import play_publish as pp  # noqa: E402


# ------------------------------------------------------------------ fakes


class _Request:
    def __init__(self, service: "FakeService", method: str, kwargs: dict[str, Any]):
        self.service, self.method, self.kwargs = service, method, kwargs

    def execute(self) -> Any:
        self.service.calls.append((self.method, self.kwargs))
        answer = self.service.responses.get(self.method, {})
        if isinstance(answer, Exception):
            raise answer
        return answer


class _Resource:
    def __init__(self, service: "FakeService", path: str):
        self._service, self._path = service, path

    def __getattr__(self, name: str) -> Any:
        path = f"{self._path}.{name}" if self._path else name

        def call(**kwargs: Any) -> Any:
            if kwargs:  # a method call: edits().insert(packageName=...)
                return _Request(self._service, path, kwargs)
            return _Resource(self._service, path)  # a sub-resource: edits().tracks()

        return call


class FakeService(_Resource):
    """Mimics googleapiclient's `service.edits().tracks().update(...).execute()` chains."""

    def __init__(self, responses: dict[str, Any] | None = None):
        self.calls: list[tuple[str, dict[str, Any]]] = []
        self.responses = {
            "edits.insert": {"id": "edit-1"},
            "edits.tracks.list": {
                "tracks": [
                    {"track": "internal", "releases": [{"name": "1.0.1 (3)", "versionCodes": ["3"], "status": "completed"}]},
                    {"track": "production", "releases": [{"versionCodes": ["2"], "status": "completed"}]},
                ]
            },
            "edits.bundles.upload": {"versionCode": 4},
            "edits.listings.list": {"listings": [{"language": "en-US", "title": "CountScore"}]},
        }
        self.responses.update(responses or {})
        super().__init__(self, "")

    def methods(self) -> list[str]:
        return [m for m, _ in self.calls]


def fake_media(path: Path, mimetype: str) -> tuple[str, str]:
    return (str(path), mimetype)


@pytest.fixture
def repo(tmp_path: Path) -> Path:
    (tmp_path / "pubspec.yaml").write_text("name: countscore\nversion: 1.1.0+4\n", encoding="utf-8")
    for locale in pp.LOCALES:
        d = tmp_path / "store_listing" / locale
        d.mkdir(parents=True)
        (d / "release_notes_v1.1.0.txt").write_text(f"Notes {locale}\n", encoding="utf-8")
        (d / "title.txt").write_text("CountScore\n", encoding="utf-8")
        (d / "short_description.txt").write_text("Keep score\n", encoding="utf-8")
        (d / "full_description.txt").write_text("A long description\n", encoding="utf-8")
    phone = tmp_path / "store_listing" / "assets" / "screenshots" / "phone"
    phone.mkdir(parents=True)
    (tmp_path / "store_listing" / "assets" / "feature_graphic.png").write_bytes(b"png")
    for name in ("02_b.png", "01_a.png"):
        (phone / name).write_bytes(b"png")
    return tmp_path


def publish(repo: Path, service: FakeService, **opts: Any) -> str:
    out = io.StringIO()
    pp.cmd_publish(service, repo, pp.PublishOptions(**opts), media=fake_media, out=out)
    return out.getvalue()


# ------------------------------------------------------------------ local files


def test_version_and_notes(repo: Path) -> None:
    assert pp.read_version(repo) == ("1.1.0", 4)
    assert pp.read_release_notes(repo, "1.1.0") == [
        {"language": "en-US", "text": "Notes en-US"},
        {"language": "fr-FR", "text": "Notes fr-FR"},
    ]


def test_notes_over_500_characters_refused(repo: Path) -> None:
    (repo / "store_listing" / "fr-FR" / "release_notes_v1.1.0.txt").write_text("x" * 501, encoding="utf-8")
    with pytest.raises(pp.PublishError, match="501 characters; Play allows 500"):
        pp.read_release_notes(repo, "1.1.0")


def test_notes_of_exactly_500_characters_accepted(repo: Path) -> None:
    (repo / "store_listing" / "en-US" / "release_notes_v1.1.0.txt").write_text("x" * 500 + "\n", encoding="utf-8")
    assert pp.read_release_notes(repo, "1.1.0")[0]["text"] == "x" * 500


def test_missing_notes_refused(repo: Path) -> None:
    (repo / "store_listing" / "en-US" / "release_notes_v1.1.0.txt").unlink()
    with pytest.raises(pp.PublishError, match="missing"):
        pp.read_release_notes(repo, "1.1.0")


def test_listing(repo: Path) -> None:
    listing = pp.read_listing(repo)
    assert listing["fr-FR"] == {
        "language": "fr-FR",
        "title": "CountScore",
        "shortDescription": "Keep score",
        "fullDescription": "A long description",
    }
    (repo / "store_listing" / "en-US" / "title.txt").write_text("t" * 31, encoding="utf-8")
    with pytest.raises(pp.PublishError, match="Play allows 30"):
        pp.read_listing(repo)


def test_screenshots_in_name_order(repo: Path) -> None:
    _, shots = pp.graphics_files(repo)
    assert [p.name for p in shots] == ["01_a.png", "02_b.png"]


def test_service_account_setup_named_when_missing(repo: Path) -> None:
    with pytest.raises(pp.PublishError, match="Play API access"):
        pp.read_service_account_path(repo)
    (repo / "android").mkdir()
    (repo / "android" / "key.properties").write_text("storeFile=/x\n", encoding="utf-8")
    with pytest.raises(pp.PublishError, match="no playServiceAccount= line"):
        pp.read_service_account_path(repo)
    key = repo / "sa.json"
    key.write_text("{}", encoding="utf-8")
    (repo / "android" / "key.properties").write_text(f"playServiceAccount={key}\n", encoding="utf-8")
    assert pp.read_service_account_path(repo) == key


# ------------------------------------------------------------------ the edit


def test_validate_without_commit_deletes_the_edit(repo: Path) -> None:
    service = FakeService()
    out = publish(repo, service, track="internal")
    assert service.methods() == [
        "edits.insert",
        "edits.tracks.list",
        "edits.bundles.upload",
        "edits.tracks.update",
        "edits.validate",
        "edits.delete",
    ]
    assert "validated, nothing published" in out
    upload = dict(service.calls)["edits.bundles.upload"]
    assert upload["media_body"][1] == "application/octet-stream"
    update = dict(service.calls)["edits.tracks.update"]
    assert update["track"] == "internal"
    assert update["body"]["releases"] == [
        {
            "name": "1.1.0 (4)",
            "versionCodes": ["4"],
            "status": "completed",
            "releaseNotes": [
                {"language": "en-US", "text": "Notes en-US"},
                {"language": "fr-FR", "text": "Notes fr-FR"},
            ],
        }
    ]


def test_commit_only_with_flag(repo: Path) -> None:
    service = FakeService()
    publish(repo, service, track="closed", commit=True)
    assert service.methods()[-2:] == ["edits.validate", "edits.commit"]
    assert "edits.delete" not in service.methods()
    assert dict(service.calls)["edits.tracks.update"]["track"] == "alpha"


def test_low_version_code_refused_before_upload(repo: Path) -> None:
    service = FakeService({"edits.tracks.list": {"tracks": [{"track": "alpha", "releases": [{"versionCodes": ["4"]}]}]}})
    with pytest.raises(pp.PublishError, match="not above 4, already on track 'alpha'"):
        publish(repo, service, track="internal", commit=True)
    assert service.methods() == ["edits.insert", "edits.tracks.list", "edits.delete"]


def test_bundle_version_code_mismatch_refused(repo: Path) -> None:
    service = FakeService({"edits.bundles.upload": {"versionCode": 5}})
    with pytest.raises(pp.PublishError, match="rebuild the bundle"):
        publish(repo, service, track="internal", commit=True)
    assert "edits.commit" not in service.methods()
    assert service.methods()[-1] == "edits.delete"


def test_production_is_a_staged_rollout(repo: Path) -> None:
    service = FakeService()
    publish(repo, service, track="production")
    release = dict(service.calls)["edits.tracks.update"]["body"]["releases"][0]
    assert release["status"] == "inProgress"
    assert release["userFraction"] == 0.2


def test_draft(repo: Path) -> None:
    service = FakeService()
    publish(repo, service, track="production", draft=True)
    release = dict(service.calls)["edits.tracks.update"]["body"]["releases"][0]
    assert release["status"] == "draft"
    assert "userFraction" not in release


@pytest.mark.parametrize("fraction", [0, 1, 1.5, -0.1])
def test_rollout_outside_open_interval_refused(repo: Path, fraction: float) -> None:
    service = FakeService()
    with pytest.raises(pp.PublishError, match="strictly between 0 and 1"):
        publish(repo, service, track="production", rollout=fraction)
    assert service.calls == []


def test_listing_and_graphics(repo: Path) -> None:
    service = FakeService()
    publish(repo, service, track="internal", listing=True, graphics=True)
    methods = service.methods()
    assert methods.count("edits.listings.update") == 2
    # per locale: deleteall + 1 feature graphic, deleteall + 2 screenshots
    assert methods.count("edits.images.deleteall") == 4
    assert methods.count("edits.images.upload") == 6
    assert methods.index("edits.images.upload") < methods.index("edits.validate")
    shots = [
        c["media_body"][0]
        for m, c in service.calls
        if m == "edits.images.upload" and c["imageType"] == "phoneScreenshots" and c["language"] == "en-US"
    ]
    assert [Path(s).name for s in shots] == ["01_a.png", "02_b.png"]


def test_changes_not_sent_for_review_is_reported_not_retried(repo: Path) -> None:
    service = FakeService({"edits.commit": RuntimeError("400: changesNotSentForReview must be set")})
    with pytest.raises(pp.PublishError, match="changesNotSentForReview"):
        publish(repo, service, track="internal", commit=True)
    assert service.methods().count("edits.commit") == 1
    assert service.methods()[-1] == "edits.delete"


def test_status_is_read_only(repo: Path) -> None:
    service = FakeService()
    out = io.StringIO()
    pp.cmd_status(service, out=out)
    assert service.methods() == ["edits.insert", "edits.tracks.list", "edits.listings.list", "edits.delete"]
    assert "internal: 1.0.1 (3) [completed] versionCodes 3" in out.getvalue()


def test_rollout_flag_only_for_production() -> None:
    assert pp.main(["publish", "--track", "internal", "--rollout", "0.5"]) == 1
