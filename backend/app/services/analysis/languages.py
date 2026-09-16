"""The ten output languages, and how a client's locale tag resolves to one.

The app is localised into ten languages (.llmwiki/I18n.md) but the analysis used to
answer in French whatever the phone was set to. The persona blocks stay in English and
the output language is this parameter, so adding a language costs one row here.

``directive`` is the only prose written *in* the target language. ``builder.py`` emits it
twice — right after the role line and as the very last line of the system prompt —
because sandwiching it measurably improves compliance for ar, hi, ja and zh.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class Language:
    code: str
    english_name: str
    directive: str


LANGUAGES: dict[str, Language] = {
    "ar": Language("ar", "Arabic", "أجب بالكامل باللغة العربية."),
    "de": Language("de", "German", "Antworte vollständig auf Deutsch."),
    "en": Language("en", "English", "Reply entirely in English."),
    "es": Language("es", "Spanish", "Responde íntegramente en español."),
    "fr": Language("fr", "French", "Réponds intégralement en français."),
    "hi": Language("hi", "Hindi", "पूरी तरह से हिन्दी में उत्तर दीजिए।"),
    "ja": Language("ja", "Japanese", "すべて日本語で回答してください。"),
    "pt": Language("pt", "Portuguese", "Responda inteiramente em português."),
    "ru": Language("ru", "Russian", "Отвечай полностью на русском языке."),
    "zh": Language("zh", "Chinese", "请全部用简体中文回答。"),
}

# English, because it is what an unsupported locale falls back to in the app too
# (lib/main.dart localeResolutionCallback).
FALLBACK_LANGUAGE = LANGUAGES["en"]


def resolve_language(tag: object) -> Language:
    """Resolve a BCP-47-ish tag to a supported language.

    Only the primary subtag matters: ``pt-BR``, ``pt_BR`` and ``PT`` all land on
    Portuguese, ``zh-Hant-TW`` on Chinese. Anything unknown, empty or not a string falls
    back to English rather than raising — same reasoning as ``resolve_persona``.
    """
    if not isinstance(tag, str):
        return FALLBACK_LANGUAGE
    primary = tag.strip().lower().replace("_", "-").split("-", 1)[0]
    return LANGUAGES.get(primary, FALLBACK_LANGUAGE)
