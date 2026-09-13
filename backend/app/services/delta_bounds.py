"""Value bounds for the entities a client may write through ``POST /sync/push``.

``DeltaIn.payload`` is a free-form ``dict[str, Any]``: the sync apply path filters out
unknown columns and coerces types, but until now nothing checked what the numbers
actually were. A client could push a score of 10**30 or a negative round number and only
find out when Postgres rejected the 32-bit column — as a raw driver error, mid-batch.

The bounds are deliberately generous. They are not gameplay rules; they exist so that a
malformed or hostile payload is refused cleanly, as a ``rejected`` delta, at the API
boundary rather than deep inside a transaction.
"""

from __future__ import annotations

from typing import Any

from app.models.player import PLAYER_NAME_MAX_LENGTH, is_valid_player_name

_COLOR_MAX = 0xFFFFFFFF  # ARGB, as Flutter's Color.value
_UNICODE_MAX = 0x10FFFF  # highest valid code point, for icon_code_point
_SCORE_ABS_MAX = 1_000_000

# entity_type → field → (min, max), both inclusive.
NUMERIC_BOUNDS: dict[str, dict[str, tuple[int, int]]] = {
    "score": {"value": (-_SCORE_ABS_MAX, _SCORE_ABS_MAX)},
    "round": {"round_number": (0, 10_000)},
    "player": {"color_value": (0, _COLOR_MAX)},
    "game_player": {
        "order_index": (0, 64),
        "color_value": (0, _COLOR_MAX),
    },
    "game_type": {
        "icon_code_point": (0, _UNICODE_MAX),
        "card_color_value": (0, _COLOR_MAX),
        "player_dead_threshold": (-_SCORE_ABS_MAX, _SCORE_ABS_MAX),
        "game_over_threshold": (-_SCORE_ABS_MAX, _SCORE_ABS_MAX),
    },
}

# entity_type → field → max length. Mirrors the max_length on the SQLModel fields.
STRING_MAX_LENGTHS: dict[str, dict[str, int]] = {
    "player": {"name": PLAYER_NAME_MAX_LENGTH, "name_normalized": PLAYER_NAME_MAX_LENGTH},
    "game": {"name": 64},
    "game_type": {
        "name": 64,
        "player_dead_condition_type": 16,
        "game_over_condition_type": 32,
    },
}


def check_payload(entity_type: str, payload: dict[str, Any]) -> str | None:
    """Return a rejection reason, or None when the payload is acceptable.

    Only fields actually present are checked; a delta carrying a partial payload stays
    valid, which is what per-field last-writer-wins needs.
    """
    for field, (low, high) in NUMERIC_BOUNDS.get(entity_type, {}).items():
        value = payload.get(field)
        if value is None:
            continue
        # bool is an int subclass; a boolean here means the client sent the wrong shape.
        if not isinstance(value, int) or isinstance(value, bool):
            return f"{field} must be an integer"
        if not low <= value <= high:
            return f"{field} out of bounds ({low}..{high})"

    for field, max_length in STRING_MAX_LENGTHS.get(entity_type, {}).items():
        value = payload.get(field)
        if value is None:
            continue
        if not isinstance(value, str):
            return f"{field} must be a string"
        if len(value) > max_length:
            return f"{field} longer than {max_length} characters"

    # Player names reach the LLM prompt, so they carry an allow-list on top of length.
    if entity_type == "player":
        name = payload.get("name")
        if name is not None and not is_valid_player_name(name):
            return "name contains disallowed characters"

    return None
