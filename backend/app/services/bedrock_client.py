"""AWS Bedrock client for the ZapZap caustic analysis endpoint.

Wraps the Llama-3 invoke call. Credentials live in backend env vars (never in the
mobile APK). The system prompt ("Professeur Claude") is intentionally kept here
rather than in the database — it is product copy, not data.
"""
from __future__ import annotations

import asyncio
import json
from dataclasses import dataclass
from typing import Any

import boto3
from botocore.config import Config as BotoConfig

from app.config import get_settings

# Original ZapZap caustic system prompt — kept verbatim from the mobile prototype
# (lib/services/bedrock_analysis_service.dart in the local Bedrock branch) so the
# tone matches what users tested.
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
Pour chaque partie, extrais les données SQLite et affiche :
1. Un tableau manche par manche avec score individuel et cumul (score(cumul))
2. Les ZapZap éclairs détectés et annotés
3. Le classement final par ordre d'élimination inversé
4. Les stats par joueur : nb manches, nb ZapZap réussis, max en une manche, gros scores

## Ton et style du commentaire
- Tu t'appelles le professeur Claude, ton ton est sec, caustique, sans concession
- Tu n'hésite pas à faire des comparaisons outrancières avec l'actualité politique francaise ou internationnale
- Nadia est la chouchou du professeur — tu lui es systématiquement indulgent
- Tout vainqueur a eu de la chance ou a triché — tu trouves toujours une raison de minimiser sa victoire ou de la remettre en question
- Tout perdant l'est par incompétence, mauvaise stratégie ou manque de lucidité — c'est toujours de sa faute, jamais la malchance
- Les récidivistes (mêmes erreurs répétées) reçoivent un rappel de leurs antécédents
- Chaque joueur reçoit une note sur 20 — tu n'hésites pas à donner de très mauvaises notes, y compris au vainqueur si sa victoire te semble suspecte
- Tu es délibérément de mauvaise foi mais tes arguments s'appuient sur les vrais chiffres

## Joueurs récurrents et leur réputation établie
- Thibaut : ancien dominant (p133-p140), en déclin depuis, accumulateur de zéro ZapZap
- Vincent : en forte progression depuis janvier 2026, 6 victoires sur les 10 dernières parties
- Lionel : l'inconstant — brillant une semaine, fantomatique la suivante
- Laurent : spécialiste des catastrophes ponctuelles (record : 93 pts en une manche, les 3 jokers en p151 ; 70 pts en manche 1 en p152)
- Guillaume : solide sans éclat, s'effondre en fin de partie sous pression
- Simon : opportuniste, gagne par séries de ZapZap en fin de partie quand les autres sont épuisés
- Nadia : la chouchou, joueuse rigoureuse, toujours traitée avec bienveillance
- Ben : petit nouveau depuis p156, encore en phase d'apprentissage

## Format de sortie
Une punch line résumant la partie puis,

Pour chaque joueur du dernier au premier :
- Nom — classement — score final — une ou deux phrases de contexte
- Note /20 avec justification acide

Conclusion générale de la soirée en 3-4 phrases."""


@dataclass(slots=True)
class BedrockResult:
    content: str
    model: str
    tokens_in: int
    tokens_out: int


class BedrockClient:
    """Sync boto3 client wrapped for async usage via asyncio.to_thread."""

    def __init__(self) -> None:
        settings = get_settings()
        self.region = settings.aws_region
        self.model_id = settings.bedrock_model_id
        self._client = None
        if settings.aws_access_key_id and settings.aws_secret_access_key:
            self._client = boto3.client(
                "bedrock-runtime",
                region_name=settings.aws_region,
                aws_access_key_id=settings.aws_access_key_id,
                aws_secret_access_key=settings.aws_secret_access_key,
                aws_session_token=settings.aws_session_token,
                config=BotoConfig(read_timeout=90, retries={"max_attempts": 0}),
            )

    @property
    def available(self) -> bool:
        return self._client is not None

    def _invoke_sync(self, user_message: str, max_gen_len: int) -> dict[str, Any]:
        # Llama-3 chat format: a single completion-style prompt with role markers
        prompt = (
            "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n"
            f"{ZAPZAP_SYSTEM_PROMPT}<|eot_id|>"
            "<|start_header_id|>user<|end_header_id|>\n\n"
            f"{user_message}<|eot_id|>"
            "<|start_header_id|>assistant<|end_header_id|>\n\n"
        )
        body = json.dumps(
            {
                "prompt": prompt,
                "max_gen_len": max_gen_len,
                "temperature": 0.4,
                "top_p": 0.9,
            }
        )
        response = self._client.invoke_model(  # type: ignore[union-attr]
            modelId=self.model_id,
            contentType="application/json",
            accept="application/json",
            body=body,
        )
        return json.loads(response["body"].read())

    async def analyze_zapzap(
        self, user_message: str, max_gen_len: int = 2048
    ) -> BedrockResult:
        if self._client is None:
            raise RuntimeError(
                "Bedrock client not configured (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY missing)"
            )
        payload = await asyncio.to_thread(self._invoke_sync, user_message, max_gen_len)

        content = (payload.get("generation") or "").strip()
        tokens_in = int(payload.get("prompt_token_count") or 0)
        tokens_out = int(payload.get("generation_token_count") or 0)
        return BedrockResult(
            content=content,
            model=self.model_id,
            tokens_in=tokens_in,
            tokens_out=tokens_out,
        )


_singleton: BedrockClient | None = None


def get_bedrock_client() -> BedrockClient:
    global _singleton
    if _singleton is None:
        _singleton = BedrockClient()
    return _singleton
