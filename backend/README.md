# CountScore Backend

Backend FastAPI pour CountScore : groupes, sync delta-log offline-first, API commentaires Claude.

Voir `../ARCHITECTURE.md` pour la conception complète.

## Démarrage local (sans Docker)

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
cp .env.example .env  # remplir POSTGRES_PASSWORD, ANTHROPIC_API_KEY

# Postgres local
docker run --rm -d --name countscore-pg \
  -e POSTGRES_USER=countscore -e POSTGRES_PASSWORD=countscore \
  -e POSTGRES_DB=countscore -p 5432:5432 postgres:17-alpine

# Migrations
export DATABASE_URL=postgresql://countscore:countscore@localhost:5432/countscore
alembic upgrade head

# Serveur de dev
export DATABASE_URL=postgresql+asyncpg://countscore:countscore@localhost:5432/countscore
uvicorn app.main:app --reload
```

L'API est sur `http://localhost:8000`. La doc OpenAPI sur `http://localhost:8000/docs`.

## Déploiement production (Docker Compose)

```bash
cp .env.example .env  # IMPORTANT : remplir DOMAIN, ANTHROPIC_API_KEY, POSTGRES_PASSWORD

docker compose up -d
docker compose exec api alembic upgrade head

# Vérification
curl https://<DOMAIN>/health
```

Caddy gère HTTPS automatiquement via Let's Encrypt (le port 80/443 doit être ouvert).

## Tests

```bash
pip install -e ".[dev]"
pytest -v
```

Les tests utilisent SQLite en mémoire pour la rapidité. Les fonctionnalités spécifiques
à Postgres (`pg_notify`, JSONB) sont stubbées dans les tests unitaires. Pour les tests
d'intégration complets, lancer Postgres via docker-compose et pointer `DATABASE_URL`
dessus.

## Endpoints

### Groupes (auth: `Authorization: Bearer <device_token>` sauf `POST /groups` et `/groups/join`)

| Méthode | Route | Description |
|---|---|---|
| POST | `/groups` | Crée un groupe + premier device |
| POST | `/groups/join` | Rejoint un groupe via share_token |
| GET | `/groups/me` | Info du groupe du device authentifié |
| PATCH | `/groups/me/settings` | Modifie style/langue/budget |
| GET | `/groups/me/usage` | Consommation budget mensuelle |
| POST | `/groups/me/devices/{id}/revoke` | Révoque un device |
| POST | `/groups/me/rotate-share-token` | Régénère le share_token |

### Sync

| Méthode | Route | Description |
|---|---|---|
| POST | `/sync/push` | Pousse des deltas (max 500/req) |
| GET | `/sync/pull?since_seq=N` | Récupère les deltas après N |
| WS | `/sync/stream?token=...` | Signal temps réel (new_seq) |

### Commentaires Claude

| Méthode | Route | Description |
|---|---|---|
| POST | `/comments/mvp` | **Stateless** (Jalon 4 MVP) — pas d'auth, pas de persistance |
| POST | `/comments/zapzap-analysis` | **Stateless** — analyse caustique « professeur Claude » (provider configurable) |
| POST | `/groups/me/games/{game_id}/comments` | Génère + persiste un commentaire |
| GET | `/groups/me/games/{game_id}/comments` | Liste les commentaires d'une partie |

## Provider LLM (analyse ZapZap)

L'endpoint `/comments/zapzap-analysis` peut tourner sur trois fournisseurs, sélectionnés
par la variable `LLM_PROVIDER` (défaut `bedrock`) :

| `LLM_PROVIDER` | Clé / config requises | Modèle (défaut, paramétrable) | SDK |
|---|---|---|---|
| `bedrock` | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `BEDROCK_MODEL_ID` | `us.meta.llama3-3-70b-instruct-v1:0` | `boto3` |
| `gemini` | `GEMINI_API_KEY`, `GEMINI_MODEL` | `gemini-2.5-pro` | `openai` (endpoint compatible) |
| `mistral` | `MISTRAL_API_KEY`, `MISTRAL_MODEL` | `mistral-large-latest` | `openai` (endpoint compatible) |

Gemini et Mistral exposent un endpoint **compatible OpenAI** : un seul client `openai`
les gère via `base_url` + clé + modèle. Le **prompt système** (« professeur Claude ») et le
**user-message** (tableau des manches, historique) sont **strictement identiques** entre
providers (mêmes `temperature=0.4`, `top_p=0.9`, `max_tokens=2048`) — seul l'appel API change,
pour une comparaison équitable. Sans la clé du provider sélectionné, l'endpoint retourne `503`.

Pour basculer : `export LLM_PROVIDER=gemini` (ou `mistral`) puis relancer le serveur.

### Comparer les providers sur une vraie partie

```bash
# Renseigner les clés voulues dans .env (GEMINI_API_KEY, MISTRAL_API_KEY, AWS_*)
python scripts/compare_providers.py --payload scripts/sample_payload.json \
  --providers bedrock,gemini,mistral
```

Le script construit le user-message une seule fois, lance chaque provider avec le même
prompt, écrit un fichier par provider dans `out/zapzap_<provider>.md` et affiche un récap
côte à côte (modèle, tokens, durée, statut). Un provider sans clé ou en erreur est reporté
sans interrompre les autres. `--payload` attend le même JSON que celui posté par l'app mobile
(voir `scripts/sample_payload.json`).

## Variables d'environnement

Voir `.env.example`. Critiques :
- `ANTHROPIC_API_KEY` : sans elle, `/comments/mvp` et `/comments/...` (Claude) retournent 503
- `LLM_PROVIDER` + clé du provider choisi : sans elles, `/comments/zapzap-analysis` retourne 503
- `POSTGRES_PASSWORD` : à durcir en production
- `DOMAIN` : utilisé par Caddy pour le certificat TLS
- `CORS_ORIGINS` : whitelist des origines PWA

## Sécurité

Voir `../ARCHITECTURE.md` §10. Points critiques :
- `device_token` stocké hashé argon2
- 5 couches de défense prompt injection
- Rate limit device + budget groupe
- TLS automatique via Caddy + Let's Encrypt
- Backups quotidiens chiffrés (sidecar)
