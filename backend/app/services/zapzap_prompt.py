"""User-message builder for the ZapZap caustic analysis endpoint.

Mirrors the Markdown layout from the mobile prototype (BedrockAnalysisService.buildUserMessage):
a header block, a per-round score table with cumulative totals, and a per-player
recent-history section. The output is rendered straight into the Llama-3 user turn.
"""
from __future__ import annotations

from typing import Any


def build_zapzap_user_message(payload: dict[str, Any]) -> str:
    """Compose the Markdown user message from the mobile JSON payload.

    Payload shape (matches GameAnalysisScreen._generate in lib/screens/game_analysis_screen.dart):
        {
          "game": {"id", "name", "is_lowest_score_wins", "created_at"},
          "game_type": str | None,
          "players": [{"id", "name"}],
          "rounds": [{"id", "number", "comment", "scores": [{"player_id", "value"}]}],
          "history_by_player_name": {"<name>": [history_entry, ...]},
        }
    """
    game = payload["game"]
    players = payload["players"]
    rounds = payload["rounds"]
    history = payload.get("history_by_player_name", {})

    lines: list[str] = []
    lines.append("# Partie à analyser")
    lines.append("")
    lines.append(f"- Nom : {game['name']}")
    lines.append(f"- Date : {game['created_at']}")
    lines.append(f"- Type de jeu : {payload.get('game_type') or 'inconnu'}")
    lines.append(
        f"- Règle : {'score le plus bas gagne' if game['is_lowest_score_wins'] else 'score le plus haut gagne'}"
    )
    lines.append(f"- Nombre de joueurs : {len(players)}")
    lines.append("")

    lines.append("## Joueurs")
    for p in players:
        lines.append(f"- {p['name']}")
    lines.append("")

    lines.append("## Manches")
    if not rounds:
        lines.append("Aucune manche enregistrée.")
    else:
        header = "| Manche |" + "".join(f" {p['name']} |" for p in players) + " Commentaire |"
        sep = "|---|" + "---|" * len(players) + "---|"
        lines.append(header)
        lines.append(sep)

        cumul: dict[int, int] = {p["id"]: 0 for p in players}
        for r in rounds:
            row = f"| {r['number']} |"
            scores_by_pid = {s["player_id"]: s["value"] for s in r["scores"]}
            for p in players:
                v = scores_by_pid.get(p["id"])
                if v is None:
                    row += " — |"
                else:
                    cumul[p["id"]] += v
                    row += f" {v} ({cumul[p['id']]}) |"
            row += f" {r.get('comment') or ''} |"
            lines.append(row)

        lines.append("")
        lines.append("### Totaux finaux")
        for p in players:
            lines.append(f"- {p['name']} : {cumul.get(p['id'], 0)} pts")
    lines.append("")

    lines.append("## Historique récent par joueur (10 dernières parties hors partie courante)")
    for p in players:
        lines.append("")
        lines.append(f"### {p['name']}")
        hist = history.get(p["name"]) or []
        if not hist:
            lines.append("Aucun historique disponible.")
            continue
        for h in hist:
            rank = h.get("rank")
            total_players = h.get("totalPlayers")
            mark = "🏆 " if h.get("didWin") else ""
            lines.append(
                f"- {mark}{h.get('createdAt') or h.get('date') or ''} — "
                f"{h.get('gameName')} ({h.get('gameType')}) : "
                f"rang {rank}/{total_players}, score {h.get('finalScore')}"
            )

    return "\n".join(lines)
