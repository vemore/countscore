#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "google-api-python-client>=2.100",
#   "google-auth>=2.23",
# ]
# ///
"""Publish CountScore to Google Play through the Play Developer Publishing API (v3).

    uv run --script .claude/skills/release-android/scripts/play_publish.py status
    uv run --script .claude/skills/release-android/scripts/play_publish.py publish --track internal
    uv run --script .claude/skills/release-android/scripts/play_publish.py publish --track internal --commit

Run from the checkout that built the bundle. Every change goes through one *edit*: nothing
is visible in the Play Console until `edits.commit`, which happens only with --commit.
Without it the edit is validated by Google and then deleted.

The service-account key is named by `playServiceAccount=` in android/key.properties; the
one-time setup is in .claude/skills/release-android/SKILL.md, "Play API access".
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable, TextIO

PACKAGE = "com.vemore.countscore"
SCOPE = "https://www.googleapis.com/auth/androidpublisher"
LOCALES = ("en-US", "fr-FR")
NOTES_LIMIT = 500
LISTING_FILES = {  # file -> (API field, Play's limit)
    "title.txt": ("title", 30),
    "short_description.txt": ("shortDescription", 80),
    "full_description.txt": ("fullDescription", 4000),
}
# The Console's "Closed testing" is the API track `alpha`.
TRACKS = {"internal": "internal", "closed": "alpha", "production": "production"}
DEFAULT_ROLLOUT = 0.2
DEFAULT_AAB = "build/app/outputs/bundle/release/app-release.aab"
SETUP_HINT = (
    "One-time setup: .claude/skills/release-android/SKILL.md, section 'Play API access' "
    "(service account, JSON key at ~/.config/countscore/play-service-account.json, "
    "then playServiceAccount=<absolute path> in android/key.properties)."
)


class PublishError(Exception):
    """A refusal or failure with a message meant for the person running the script."""


# ----------------------------------------------------------------- local files


def repo_root() -> Path:
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True
        )
        return Path(out.stdout.strip())
    except (OSError, subprocess.CalledProcessError):
        return Path(__file__).resolve().parents[4]


def read_version(root: Path) -> tuple[str, int]:
    """`version: x.y.z+n` from pubspec.yaml -> ("x.y.z", n)."""
    text = (root / "pubspec.yaml").read_text(encoding="utf-8")
    m = re.search(r"^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$", text, re.MULTILINE)
    if not m:
        raise PublishError("pubspec.yaml has no `version: x.y.z+n` line")
    return m.group(1), int(m.group(2))


def read_service_account_path(root: Path) -> Path:
    props = root / "android" / "key.properties"
    if not props.is_file():
        raise PublishError(f"{props} does not exist. {SETUP_HINT}")
    value = None
    for line in props.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("playServiceAccount="):
            value = line.split("=", 1)[1].strip()
    if not value:
        raise PublishError(f"no playServiceAccount= line in {props}. {SETUP_HINT}")
    path = Path(value).expanduser()
    if not path.is_absolute():
        path = root / "android" / path
    if not path.is_file():
        raise PublishError(f"the service-account key {path} does not exist. {SETUP_HINT}")
    return path


def _read_text(path: Path, limit: int) -> str:
    if not path.is_file():
        raise PublishError(f"missing {path}")
    text = path.read_text(encoding="utf-8").strip()
    if not text:
        raise PublishError(f"{path} is empty")
    if len(text) > limit:
        raise PublishError(f"{path} is {len(text)} characters; Play allows {limit}")
    return text


def read_release_notes(root: Path, version: str) -> list[dict[str, str]]:
    return [
        {
            "language": locale,
            "text": _read_text(
                root / "store_listing" / locale / f"release_notes_v{version}.txt", NOTES_LIMIT
            ),
        }
        for locale in LOCALES
    ]


def read_listing(root: Path) -> dict[str, dict[str, str]]:
    listings = {}
    for locale in LOCALES:
        body = {"language": locale}
        for name, (field, limit) in LISTING_FILES.items():
            body[field] = _read_text(root / "store_listing" / locale / name, limit)
        listings[locale] = body
    return listings


def graphics_files(root: Path) -> tuple[Path, list[Path]]:
    assets = root / "store_listing" / "assets"
    feature = assets / "feature_graphic.png"
    if not feature.is_file():
        raise PublishError(f"missing {feature}")
    shots = sorted((assets / "screenshots" / "phone").glob("*.png"), key=lambda p: p.name)
    if not shots:
        raise PublishError(f"no PNG in {assets / 'screenshots' / 'phone'}")
    if len(shots) > 8:
        raise PublishError(f"{len(shots)} phone screenshots; Play allows 8")
    return feature, shots


def build_release(
    version: str, code: int, notes: list[dict[str, str]], track: str, draft: bool, rollout: float
) -> dict[str, Any]:
    release: dict[str, Any] = {
        "name": f"{version} ({code})",
        "versionCodes": [str(code)],
        "releaseNotes": notes,
    }
    if draft:
        release["status"] = "draft"
    elif track == "production":
        release["status"] = "inProgress"
        release["userFraction"] = rollout
    else:
        release["status"] = "completed"
    return release


# ----------------------------------------------------------------- Google side


def build_service(key_path: Path) -> Any:  # pragma: no cover - needs real credentials
    from google.oauth2 import service_account
    from googleapiclient.discovery import build

    credentials = service_account.Credentials.from_service_account_file(
        str(key_path), scopes=[SCOPE]
    )
    return build("androidpublisher", "v3", credentials=credentials, cache_discovery=False)


def media_upload(path: Path, mimetype: str) -> Any:  # pragma: no cover - thin wrapper
    from googleapiclient.http import MediaFileUpload

    return MediaFileUpload(str(path), mimetype=mimetype, resumable=True)


def max_version_code(service: Any, edit_id: str) -> tuple[int, str]:
    """Highest version code on any track, and the track holding it."""
    tracks = service.edits().tracks().list(packageName=PACKAGE, editId=edit_id).execute()
    best, where = 0, "none"
    for track in tracks.get("tracks", []):
        for release in track.get("releases", []):
            for vc in release.get("versionCodes", []):
                if int(vc) > best:
                    best, where = int(vc), track.get("track", "?")
    return best, where


def describe_tracks(tracks: dict[str, Any]) -> list[str]:
    lines = []
    for track in tracks.get("tracks", []):
        releases = track.get("releases", [])
        if not releases:
            lines.append(f"  {track.get('track')}: no release")
        for r in releases:
            fraction = f" {float(r['userFraction']):.0%}" if "userFraction" in r else ""
            codes = ",".join(r.get("versionCodes", [])) or "-"
            lines.append(
                f"  {track.get('track')}: {r.get('name', '(unnamed)')} "
                f"[{r.get('status', '?')}{fraction}] versionCodes {codes}"
            )
    return lines or ["  no tracks"]


def cmd_status(service: Any, out: TextIO = sys.stdout) -> None:
    edits = service.edits()
    edit_id = edits.insert(packageName=PACKAGE, body={}).execute()["id"]
    try:
        tracks = edits.tracks().list(packageName=PACKAGE, editId=edit_id).execute()
        listings = edits.listings().list(packageName=PACKAGE, editId=edit_id).execute()
        print(f"{PACKAGE} — tracks (Console 'Closed testing' is API track 'alpha')", file=out)
        for line in describe_tracks(tracks):
            print(line, file=out)
        print("listings", file=out)
        for listing in listings.get("listings", []) or []:
            print(
                f"  {listing.get('language')}: {listing.get('title', '')!r} — "
                f"short {len(listing.get('shortDescription', ''))} chars, "
                f"full {len(listing.get('fullDescription', ''))} chars",
                file=out,
            )
    finally:
        edits.delete(packageName=PACKAGE, editId=edit_id).execute()


@dataclass
class PublishOptions:
    track: str
    rollout: float = DEFAULT_ROLLOUT
    draft: bool = False
    listing: bool = False
    graphics: bool = False
    commit: bool = False
    aab: Path = Path(DEFAULT_AAB)


def cmd_publish(
    service: Any,
    root: Path,
    opts: PublishOptions,
    media: Callable[[Path, str], Any] = media_upload,
    out: TextIO = sys.stdout,
) -> None:
    if opts.track not in TRACKS:
        raise PublishError(f"track must be one of {', '.join(TRACKS)}")
    if not 0 < opts.rollout < 1:
        raise PublishError(f"rollout must be strictly between 0 and 1, got {opts.rollout}")
    version, code = read_version(root)
    # Read and check every local file before opening an edit.
    notes = read_release_notes(root, version)
    listings = read_listing(root) if opts.listing else {}
    feature, shots = graphics_files(root) if opts.graphics else (None, [])
    release = build_release(version, code, notes, opts.track, opts.draft, opts.rollout)
    api_track = TRACKS[opts.track]

    edits = service.edits()
    edit_id = edits.insert(packageName=PACKAGE, body={}).execute()["id"]
    committed = False
    try:
        highest, where = max_version_code(service, edit_id)
        if code <= highest:
            raise PublishError(
                f"versionCode {code} (pubspec.yaml) is not above {highest}, already on track "
                f"'{where}'. Bump `version:` in pubspec.yaml and rebuild."
            )
        uploaded = (
            edits.bundles()
            .upload(
                packageName=PACKAGE,
                editId=edit_id,
                media_body=media(opts.aab, "application/octet-stream"),
            )
            .execute()
        )
        if int(uploaded.get("versionCode", -1)) != code:
            raise PublishError(
                f"Play read versionCode {uploaded.get('versionCode')} from the bundle, "
                f"pubspec.yaml says {code}: rebuild the bundle"
            )
        print(f"uploaded {opts.aab} — versionCode {code}", file=out)

        edits.tracks().update(
            packageName=PACKAGE,
            editId=edit_id,
            track=api_track,
            body={"track": api_track, "releases": [release]},
        ).execute()
        fraction = f" {release['userFraction']:.0%}" if "userFraction" in release else ""
        print(f"track {api_track}: {release['name']} [{release['status']}{fraction}]", file=out)

        for locale, body in listings.items():
            edits.listings().update(
                packageName=PACKAGE, editId=edit_id, language=locale, body=body
            ).execute()
            print(f"listing {locale} updated", file=out)

        if feature is not None:
            for locale in LOCALES:
                images = edits.images()
                for image_type, files in (("featureGraphic", [feature]), ("phoneScreenshots", shots)):
                    images.deleteall(
                        packageName=PACKAGE, editId=edit_id, language=locale, imageType=image_type
                    ).execute()
                    for f in files:
                        images.upload(
                            packageName=PACKAGE,
                            editId=edit_id,
                            language=locale,
                            imageType=image_type,
                            media_body=media(f, "image/png"),
                        ).execute()
                print(f"graphics {locale}: feature graphic + {len(shots)} phone screenshots", file=out)

        edits.validate(packageName=PACKAGE, editId=edit_id).execute()
        print("edits.validate OK", file=out)

        if not opts.commit:
            print("validated, nothing published (rerun with --commit to publish)", file=out)
            return
        try:
            edits.commit(packageName=PACKAGE, editId=edit_id).execute()
        except Exception as err:  # googleapiclient.errors.HttpError
            if "changesNotSentForReview" in str(err):
                raise PublishError(
                    "Play refused the commit and asks for changesNotSentForReview: this app's "
                    "changes are sent for review from the Console (Publishing overview), not "
                    "automatically. Nothing was published. Google's answer:\n"
                    f"{err}"
                ) from err
            raise
        committed = True
        print(f"committed: {release['name']} on {api_track}", file=out)
    finally:
        if not committed:
            try:
                edits.delete(packageName=PACKAGE, editId=edit_id).execute()
            except Exception as err:  # the edit expires on its own; never mask the real error
                print(f"warning: could not delete edit {edit_id}: {err}", file=sys.stderr)


# ----------------------------------------------------------------- entry point


def verify_aab(root: Path, aab: Path) -> None:
    script = Path(__file__).resolve().with_name("verify_aab.sh")
    if subprocess.run([str(script), str(aab)], cwd=root).returncode != 0:
        raise PublishError("verify_aab.sh failed — nothing was sent to Play")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("status", help="read-only: releases per track and the current listings")
    pub = sub.add_parser("publish", help="upload the bundle to a track, validate, and commit on --commit")
    pub.add_argument("--track", required=True, choices=sorted(TRACKS))
    pub.add_argument("--rollout", type=float, help=f"production only, default {DEFAULT_ROLLOUT}")
    pub.add_argument("--draft", action="store_true", help="create the release as a draft")
    pub.add_argument("--listing", action="store_true", help="update title and descriptions")
    pub.add_argument("--graphics", action="store_true", help="replace feature graphic and phone screenshots")
    pub.add_argument("--commit", action="store_true", help="publish the edit; without it, validate only")
    pub.add_argument("--aab", type=Path, default=None, help=f"default {DEFAULT_AAB}")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    root = repo_root()
    try:
        if args.command == "status":
            cmd_status(build_service(read_service_account_path(root)))
            return 0
        if args.rollout is not None and args.track != "production":
            raise PublishError("--rollout applies to --track production only")
        aab = args.aab or root / DEFAULT_AAB
        opts = PublishOptions(
            track=args.track,
            rollout=DEFAULT_ROLLOUT if args.rollout is None else args.rollout,
            draft=args.draft,
            listing=args.listing,
            graphics=args.graphics,
            commit=args.commit,
            aab=aab,
        )
        if not 0 < opts.rollout < 1:
            raise PublishError(f"rollout must be strictly between 0 and 1, got {opts.rollout}")
        key = read_service_account_path(root)
        verify_aab(root, aab)
        cmd_publish(build_service(key), root, opts)
        return 0
    except PublishError as err:
        print(f"error: {err}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
