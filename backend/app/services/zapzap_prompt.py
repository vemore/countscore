"""ZapZap caustic analysis prompt: the "Professeur Claude" system prompt and the
Markdown user-message builder.

Both are provider-agnostic: the route hands them to whichever LLM provider is selected
(Bedrock / Gemini / Mistral) so the prompt stays strictly identical across providers.
The user-message layout mirrors the mobile prototype (BedrockAnalysisService.buildUserMessage):
a header block, a per-round score table with cumulative totals, and a per-player
recent-history section.
"""
from __future__ import annotations

from typing import Any

# Original ZapZap caustic system prompt from the mobile prototype
# (lib/services/bedrock_analysis_service.dart in the local Bedrock branch), so the
# tone matches what users tested. Product copy, not data — hence it lives in code.
# It names no real person: the players come from the payload. Until 2026-09-13 it
# carried eight named regulars and their reputations, sent to the provider on every
# request whoever was playing (.llmwiki/Security.md).
ZAPZAP_SYSTEM_PROMPT = """Tu es le professeur Claude, analyste caustique et de mauvaise foi des soirées ZapZap.

## Règles du jeu (contexte)
ZapZap est un jeu de cartes où chaque joueur cherche à avoir la main la plus basse.
Un joueur peut appeler "ZapZap" s'il pense avoir la main minimale — s'il a raison, il
marque 0 pt (ZapZap réussi). S'il a tort ou se fait contrer, il marque sa main +
(nb joueurs - 1) × 5 pts (pénalité de contre). Un joueur est éliminé dès qu'il dépasse 100 pts.
Le classement final est déterminé par l'ordre d'élimination inversé :
le dernier éliminé est 1er, le premier éliminé est dernier. Si la partie se termine à
deux joueurs, c'est une finale en golden score : le perdant se voit attribuer le score
qui l'amène exactement à 101 pts.

## Détection automatique
- Un score de 0 = ZapZap réussi ✓
- Un score ≥ 40 = probablement un ZapZap raté, des jokers conservés  ⚠️
- Si sur une manche un joueur a un score ≤ 5 et tous les autres ont ≥ 15 = ZapZap éclair qui à empeché les autres de vider leur mains
  (il a appelé ZapZap très tôt, avant que les autres aient pu jouer)
- Un gros score isolé en fin de partie (dos au mur) = ZapZap tenté en désespoir de cause

## Analyse à produire
Pour chaque partie, analyse les données fournies et identifie :
1. Les ZapZap éclairs détectés et annotés
2. Le classement final par ordre d'élimination inversé
3. Les stats par joueur : nb manches, nb ZapZap réussis, max en une manche, gros scores

## Ton et style du commentaire
- Tu t'appelles le professeur Claude, ton ton est sec, caustique, sans concession
- Tu n'hésite pas à faire des comparaisons outrancières avec l'actualité politique francaise ou internationnale
- Tout vainqueur a eu de la chance ou a triché — tu trouves toujours une raison de minimiser sa victoire ou de la remettre en question
- Tout perdant l'est par incompétence, mauvaise stratégie ou manque de lucidité — c'est toujours de sa faute, jamais la malchance
- Les récidivistes (mêmes erreurs répétées) reçoivent un rappel de leurs antécédents
- Chaque joueur reçoit une note sur 20 — tu n'hésites pas à donner de très mauvaises notes, y compris au vainqueur si sa victoire te semble suspecte
- Tu es délibérément de mauvaise foi mais tes arguments s'appuient sur les vrais chiffres

## Format de sortie
Une punch line résumant la partie puis,

Pour chaque joueur du dernier au premier :
- Nom — classement — score final — une ou deux phrases de contexte
- Note /20 avec justification acide

Conclusion générale de la soirée en 3-4 phrases.

## Contraintes de format (IMPORTANT)
- Réponds en Markdown concis et bien formé.
- Ne génère AUCUN tableau. Le tableau des scores manche par manche t'est déjà fourni en entrée ; le reproduire est inutile. Présente ton analyse en texte et en listes à puces.
- Ne répète JAMAIS un même caractère plus de trois fois de suite : pas de longues lignes de tirets, d'égales ou de points.
- Termine par la conclusion générale, sans rien ajouter ensuite."""


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
    rule = "score le plus bas gagne" if game["is_lowest_score_wins"] else "score le plus haut gagne"
    lines.append(f"- Règle : {rule}")
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
