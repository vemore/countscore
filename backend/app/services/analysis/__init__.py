"""Prompt construction for the game analysis (POST /comments/game-analysis).

One analysis is a persona, a language and a game type composed over a shared editorial
contract. See .llmwiki/LlmProviders.md.
"""

from .builder import build_analysis_prompt, build_system_prompt, build_user_message
from .languages import LANGUAGES, Language, resolve_language
from .personas import DEFAULT_PERSONA, PERSONA_KEYS, PERSONAS, PersonaKey, resolve_persona

__all__ = [
    "DEFAULT_PERSONA",
    "LANGUAGES",
    "PERSONAS",
    "PERSONA_KEYS",
    "Language",
    "PersonaKey",
    "build_analysis_prompt",
    "build_system_prompt",
    "build_user_message",
    "resolve_language",
    "resolve_persona",
]
