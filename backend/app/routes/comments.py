"""Comment generation endpoints.

Two endpoints:
- ``POST /comments/mvp``       — stateless MVP (Jalon 4). Accepts a full game payload
                                  inline. No groups, no memory, no budget, no rate limit
                                  beyond a basic per-IP throttle. This is what the mobile
                                  app calls before groups exist.
- ``POST /groups/me/games/{game_id}/comments``  — full version (Jalon 7) with memory,
                                  rate-limit, budget, prompt caching. Wired to authed
                                  groups.
"""
from __future__ import annotations

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import AuthContext, require_device
from app.config import get_settings
from app.db import get_session
from app.models import Comment, Game, GamePlayer, Player, Round, Score
from app.schemas.comments import (
    CommentPayload,
    CommentStyle,
    GenerateCommentRequest,
    MvpCommentResponse,
    MvpGamePayload,
)
from app.services.anthropic_client import get_anthropic_client
from app.services.bedrock_client import get_bedrock_client
from app.services.budget import charge_budget, check_budget
from app.services.prompt_builder import (
    GameForPrompt,
    PastCommentSummary,
    build_system_prompt,
    build_user_message,
    compute_prompt_hash,
    compute_scores_hash,
)
from app.services.rate_limiter import check_and_increment
from app.services.zapzap_prompt import build_zapzap_user_message

router = APIRouter(tags=["comments"])


# ---------------------------------------------------------------------------
# MVP endpoint — stateless
# ---------------------------------------------------------------------------

@router.post("/comments/mvp", response_model=MvpCommentResponse)
async def generate_mvp_comment(body: MvpGamePayload) -> MvpCommentResponse:
    """Stateless comment generation — see Jalon 4 in ARCHITECTURE.md §11.

    No persistence, no quota check, no auth. Intended for early validation of the
    Claude integration before the full group/sync stack is wired up on a device.
    Deployed alongside the rest of the API for convenience.

    Future hardening (when this endpoint stays in prod): add per-IP rate limit.
    """
    client = get_anthropic_client()
    if not client.available:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Anthropic API not configured")

    game = GameForPrompt(
        name=body.game_name,
        game_type=body.game_type,
        is_lowest_score_wins=body.is_lowest_score_wins,
        players=[(p.uuid, p.name) for p in body.players],
        rounds=[
            (r.n, [(s.player_uuid, s.value) for s in r.scores]) for r in body.rounds
        ],
    )
    system_blocks = build_system_prompt(body.style, body.language, past_comments=[])
    user_message = build_user_message(game)

    try:
        result = await client.generate_comment(system_blocks, user_message)
    except Exception as e:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY, f"upstream Anthropic error: {type(e).__name__}"
        ) from e

    return MvpCommentResponse(
        content=result.content,
        model=result.model,
        tokens_in=result.tokens_in,
        tokens_out=result.tokens_out,
    )


# ---------------------------------------------------------------------------
# ZapZap analysis — stateless, AWS Bedrock (Llama-3) caustic commentator
# ---------------------------------------------------------------------------


@router.post("/comments/zapzap-analysis")
async def generate_zapzap_analysis(body: dict) -> dict:
    """Caustic ZapZap game analysis powered by AWS Bedrock (Llama-3).

    Stateless: no persistence, no auth, no budget. The mobile app caches the
    response locally in its game_analyses table. Auth and quotas will be added
    once the multi-device groups stack is wired into the mobile app.
    """
    client = get_bedrock_client()
    if not client.available:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE,
            "Bedrock not configured (AWS credentials missing)",
        )

    try:
        user_message = build_zapzap_user_message(body)
    except (KeyError, TypeError) as e:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY, f"invalid payload: {e}"
        ) from e

    try:
        result = await client.analyze_zapzap(user_message)
    except Exception as e:
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY,
            f"upstream Bedrock error: {type(e).__name__}: {e}",
        ) from e

    return {
        "content": result.content,
        "model": result.model,
        "tokens_in": result.tokens_in,
        "tokens_out": result.tokens_out,
    }


# ---------------------------------------------------------------------------
# Full endpoint — group-scoped
# ---------------------------------------------------------------------------


async def _load_game_for_prompt(
    session: AsyncSession, game_id: uuid.UUID, group_id: uuid.UUID
) -> GameForPrompt:
    game = await session.get(Game, game_id)
    if game is None or game.group_id != group_id or game.deleted_at is not None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "game not found")

    # Players in this game
    gp_rows = await session.execute(
        select(GamePlayer, Player)
        .join(Player, GamePlayer.player_id == Player.id)
        .where(GamePlayer.game_id == game.id)
        .order_by(GamePlayer.order_index.asc())
    )
    players: list[tuple[str, str]] = []
    for _gp, p in gp_rows.all():
        if p.deleted_at is None:
            players.append((str(p.id), p.name))

    # Rounds + scores
    rounds_rows = await session.execute(
        select(Round)
        .where(Round.game_id == game.id, Round.deleted_at.is_(None))
        .order_by(Round.round_number.asc())
    )
    rounds_data: list[tuple[int, list[tuple[str, int]]]] = []
    for r in rounds_rows.scalars().all():
        scores_rows = await session.execute(
            select(Score).where(Score.round_id == r.id, Score.deleted_at.is_(None))
        )
        scores = [(str(s.player_id), s.value) for s in scores_rows.scalars().all()]
        rounds_data.append((r.round_number, scores))

    if not rounds_data:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "game has no rounds yet")

    # Resolve game_type name (best effort)
    game_type_name = "Unknown"
    if game.game_type_id is not None:
        from app.models import GameType
        gt = await session.get(GameType, game.game_type_id)
        if gt is not None:
            game_type_name = gt.name

    return GameForPrompt(
        name=game.name,
        game_type=game_type_name,
        is_lowest_score_wins=game.is_lowest_score_wins,
        players=players,
        rounds=rounds_data,
    )


async def _load_past_comments(
    session: AsyncSession, group_id: uuid.UUID, limit: int
) -> list[PastCommentSummary]:
    rows = await session.execute(
        select(Comment, Game)
        .join(Game, Comment.game_id == Game.id)
        .where(Comment.group_id == group_id)
        .order_by(Comment.created_at.desc())
        .limit(limit)
    )
    summaries: list[PastCommentSummary] = []
    for c, g in rows.all():
        summaries.append(
            PastCommentSummary(
                game_name=g.name,
                style=c.style,
                winner_name=None,  # could be computed; left None for token economy
                content=c.content,
            )
        )
    summaries.reverse()  # oldest first, most recent last → cleaner reading order
    return summaries


@router.post(
    "/groups/me/games/{game_id}/comments",
    response_model=CommentPayload,
    status_code=status.HTTP_201_CREATED,
)
async def generate_comment(
    game_id: uuid.UUID,
    body: GenerateCommentRequest,
    response: Response,
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> CommentPayload:
    settings = get_settings()
    client = get_anthropic_client()
    if not client.available:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "Anthropic API not configured")

    # 1. Rate-limit check (per device)
    rl = await check_and_increment(session, auth.device.id)
    if not rl.allowed:
        response.headers["Retry-After"] = str(rl.retry_after_seconds)
        raise HTTPException(
            status.HTTP_429_TOO_MANY_REQUESTS,
            f"rate-limited at {rl.scope} scope",
        )

    # 2. Budget check (per group)
    budget = await check_budget(session, auth.group.id)
    if not budget.allowed:
        await session.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"monthly budget exhausted ({budget.used_cents}/{budget.budget_cents}¢)",
        )

    # 3. Load data
    game = await _load_game_for_prompt(session, game_id, auth.group.id)
    past = await _load_past_comments(session, auth.group.id, settings.comment_memory_size)

    # 4. Build prompt
    style: CommentStyle = body.style_override or auth.group.comment_style  # type: ignore[assignment]
    system_blocks = build_system_prompt(style, auth.group.comment_language, past)
    user_message = build_user_message(game)
    scores_hash = compute_scores_hash(game)
    prompt_hash = compute_prompt_hash(system_blocks, user_message)

    # 5. Call Claude
    try:
        result = await client.generate_comment(system_blocks, user_message)
    except Exception as e:
        await session.rollback()
        raise HTTPException(
            status.HTTP_502_BAD_GATEWAY, f"upstream Anthropic error: {type(e).__name__}"
        ) from e

    # 6. Persist + charge budget
    comment = Comment(
        group_id=auth.group.id,
        game_id=game_id,
        created_by_device_id=auth.device.id,
        content=result.content,
        style=style,
        language=auth.group.comment_language,
        scores_hash=scores_hash,
        prompt_hash=prompt_hash,
        model=result.model,
        tokens_in=result.tokens_in,
        tokens_out=result.tokens_out,
        cost_cents=result.cost_cents,
    )
    session.add(comment)
    await charge_budget(session, auth.group.id, result.cost_cents)
    await session.commit()
    await session.refresh(comment)

    return CommentPayload(
        id=comment.id,
        game_id=comment.game_id,
        content=comment.content,
        style=comment.style,  # type: ignore[arg-type]
        language=comment.language,
        model=comment.model,
        scores_hash=comment.scores_hash,
        tokens_in=comment.tokens_in,
        tokens_out=comment.tokens_out,
        cost_cents=comment.cost_cents,
        created_at=comment.created_at,
    )


@router.get(
    "/groups/me/games/{game_id}/comments",
    response_model=list[CommentPayload],
)
async def list_comments(
    game_id: uuid.UUID,
    limit: int = 10,
    auth: AuthContext = Depends(require_device),
    session: AsyncSession = Depends(get_session),
) -> list[CommentPayload]:
    # Verify the game belongs to the group
    game = await session.get(Game, game_id)
    if game is None or game.group_id != auth.group.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "game not found")

    rows = await session.execute(
        select(Comment)
        .where(Comment.game_id == game_id)
        .order_by(Comment.created_at.desc())
        .limit(limit)
    )
    out = []
    for c in rows.scalars().all():
        out.append(
            CommentPayload(
                id=c.id,
                game_id=c.game_id,
                content=c.content,
                style=c.style,  # type: ignore[arg-type]
                language=c.language,
                model=c.model,
                scores_hash=c.scores_hash,
                tokens_in=c.tokens_in,
                tokens_out=c.tokens_out,
                cost_cents=c.cost_cents,
                created_at=c.created_at,
            )
        )
    return out


# Silence the unused-import warning
_ = datetime, timezone  # noqa: B007
