# CountScore Backend

Backend FastAPI pour CountScore : groupes, sync delta-log offline-first, API commentaires Claude.

Voir `../.llmwiki/INDEX.md` pour la conception complète (notamment `Architecture.md`, `Sync.md`, `LlmProviders.md`).

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

## Déploiement production (NAS Synology + Web Station)

La prod tourne sur un NAS Synology via un registre Docker local. **Synology Web Station**
gère le reverse-proxy + TLS pour l'URL publique — il n'y a donc plus de Caddy. L'API est
publiée sur `127.0.0.1:8087` (voir `docker-compose.prod.yml`), accessible uniquement par
Web Station.

L'hôte, le registre et l'alias SSH ne sont **pas** dans le dépôt : ils vivent dans
`scripts/deploy.env` (gitignoré, template `scripts/deploy.env.example`), que
`scripts/deploy_nas.sh` lit au démarrage. Les exemples ci-dessous utilisent les variables
qu'il définit.

**Mise en place initiale (une fois) :** poser le `.env` de prod sur le NAS (les secrets
restent hors dépôt) :

```bash
# Remplir un .env local avec les valeurs de prod :
#   POSTGRES_PASSWORD, CORS_ORIGINS=$PUBLIC_URL,
#   LLM_PROVIDER=mistral (+ MISTRAL_API_KEY) — ou le provider voulu.
source scripts/deploy.env
cat .env | ssh "$NAS_SSH" "cat > $NAS_DEPLOY_DIR/.env"
```

**Déployer** (build → push registre → compose up → migrations) :

```bash
./scripts/deploy_nas.sh                 # déploie HEAD
./scripts/deploy_nas.sh --rollback <git-sha>   # revient à une version
```

**Configurer Web Station** (Panneau de configuration → Portail des applications →
Reverse Proxy) :
- Source : votre URL publique, celle de `PUBLIC_URL` (port 443, HSTS activé)
- Destination : `http://localhost:8087`
- **Activer le support WebSocket** (onglet « En-tête personnalisé » → WebSocket) pour
  l'endpoint temps réel `/sync/stream`.
- Créer le certificat Let's Encrypt pour ce domaine une fois le proxy en place.

**Vérification :** `curl "$PUBLIC_URL/health"`.

> Pour un test full-stack local (db + api + backup, sans Caddy) : `docker compose up -d`
> puis `curl http://localhost:8000/health`.

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
| POST | `/sync/ws-ticket` | Ticket à usage unique (60 s) pour le stream |
| WS | `/sync/stream?ticket=...` | Signal temps réel (new_seq) |

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
providers (mêmes `temperature=0.4`, `top_p=0.9`, `max_tokens=8192`) — seul l'appel API change,
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
- `CORS_ORIGINS` : whitelist des origines (jamais `*` — rejeté au démarrage). En prod,
  l'origine qui sert le client — et, si vous hébergez le backend pour d'autres, chacune des
  origines qui doivent pouvoir l'appeler
- `IP_RL_PER_MINUTE` / `IP_RL_PER_HOUR` : plafond par IP des endpoints LLM non authentifiés

## Sécurité

Voir `../.llmwiki/Security.md`. Points critiques :
- `device_token` stocké hashé argon2
- 5 couches de défense prompt injection
- Rate limit device + budget groupe
- **Rate limit par IP** sur les endpoints LLM non authentifiés (`/comments/mvp`,
  `/comments/zapzap-analysis`) — garde-fou anti-abus de coût (lit `X-Forwarded-For`)
- **Cap de taille de requête** (413 au-delà de `MAX_BODY_BYTES`, 256 Kio par défaut)
- CORS verrouillé (refus de `*`)
- TLS géré par Synology Web Station (Let's Encrypt)
- Backups quotidiens (sidecar)

### Mesures ajoutées le 2026-09-09
- **WebSocket** : le `device_token` ne transite plus en query string. `POST /sync/ws-ticket`
  échange le token (en en-tête `Authorization`) contre un ticket à usage unique valable
  60 s, redeemé *avant* l'acceptation du handshake.
- **Rate limit par IP sur `POST /groups` et `/groups/join`** (`GROUP_RL_*`), dans un bucket
  distinct de celui des endpoints LLM. Borne aussi le grindage de `share_token` sur `/join`.
- **`share_token`** n'est plus renvoyé par `GET /groups/me` ni `PATCH /groups/me/settings` —
  seulement par create, join et rotate.
- **Bornes de validation** sur les valeurs poussées via `/sync/push`
  (`app/services/delta_bounds.py`), y compris la liste blanche de caractères des noms de
  joueurs.
- **En-têtes de sécurité** posés par l'application (`X-Content-Type-Options`,
  `X-Frame-Options`, `Referrer-Policy`, `Cross-Origin-Opener-Policy`, CSP), HSTS derrière
  `HSTS_ENABLED`. Web Station reste le terminateur TLS.

### Dette sécurité restante
- Les deux endpoints `/comments` sans authentification restent protégés par le seul
  limiteur par IP en mémoire — d'où le worker unique en production.
- La vérification argon2 reste en O(N) sur les devices pour chaque requête HTTP authentifiée.
- Aucun rôle propriétaire sur `Device` : tout appareil du groupe peut révoquer les autres.

Détail et arbitrages : `.llmwiki/Security.md`.
