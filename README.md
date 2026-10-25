# n8n Docker Compose: self-hosting for enterprises

Clone, run one command, get a production-style [n8n](https://n8n.io/) install. It follows the
[official Docker Compose setup](https://docs.n8n.io/deploy/host-n8n/install-options/install-using-docker-compose)
and every setting (versions, URLs, ports, network, credentials, resource limits) is configured in `.env`.

## Quick start

```bash
git clone https://github.com/dhrupalpatidar1313/n8n-compose-n8n.git
cd n8n-compose-n8n
./setup.sh              # creates .env with generated secrets
# edit .env: N8N_HOST, WEBHOOK_URL, N8N_BIND_ADDRESS, ...
docker compose up -d
```

Open the URL from `WEBHOOK_URL` (default `http://localhost:5678`) and create the owner account.
Requires Docker Engine with Compose v2.20+.

## What runs

| Service | Purpose |
|---|---|
| `postgres` | PostgreSQL 18 database, data in a local folder |
| `n8n` | n8n, connecting to Postgres as a non-admin user |
| `runners` | External task runner for Code node (JS/Python) execution |
| `sandbox-api`, `sandbox-runner-1`, `sandbox-certs` | Sandbox service for the n8n AI assistant (mTLS between components) |
| `searxng` | Web search for the AI assistant |
| `traefik` *(profile `https`)* | Reverse proxy with automatic Let's Encrypt certificates |
| `ngrok` *(profile `ngrok`)* | Tunnel to a reserved ngrok domain |

Only the n8n port (and Traefik's 80/443 with the `https` profile) is published. Postgres, the runners,
the sandbox and SearXNG are reachable only on the internal Docker network.

## Data and backups

All persistent data is bind-mounted from `DATA_DIR` (default `./data`):

```
data/postgres   database
data/n8n        n8n config, encryption key file
data/files      files for workflows (visible in n8n as /home/node/.n8n-files)
```

Point `DATA_DIR` at a dedicated disk, for example `/srv/n8n`, and back that folder up.
Also back up `.env`: **`N8N_ENCRYPTION_KEY` is required to decrypt stored credentials and must
never change.** Folders are created and given the right ownership automatically on first start.

## Configuration (`.env`)

See [`.env.example`](.env.example); every variable is documented there. The common ones:

| Need | Variables |
|---|---|
| Public address | `N8N_HOST`, `N8N_PROTOCOL`, `WEBHOOK_URL`, `N8N_SECURE_COOKIE` |
| Who can reach n8n | `N8N_BIND_ADDRESS` (`0.0.0.0` network, `127.0.0.1` local/proxy only), `N8N_HOST_PORT` |
| Docker network | `DOCKER_NETWORK_NAME`, `DOCKER_NETWORK_SUBNET` |
| Versions | `N8N_VERSION`, `N8N_SANDBOX_VERSION`, `N8N_IMAGE`, `POSTGRES_IMAGE` |
| Database | `POSTGRES_*` |
| Resources and retention | `N8N_MEM_LIMIT`, `N8N_CPU_LIMIT`, `EXECUTIONS_DATA_MAX_AGE` |
| AI assistant | `N8N_INSTANCE_AI_MODEL_API_KEY`, `INSTANCE_AI_BRAVE_SEARCH_API_KEY` |

### HTTPS with Traefik

Point DNS for `N8N_HOST` at the server, then set:

```env
COMPOSE_PROFILES=https
N8N_HOST=n8n.example.com
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.example.com/
N8N_BIND_ADDRESS=127.0.0.1
N8N_PROXY_HOPS=1
N8N_SECURE_COOKIE=true
SSL_EMAIL=admin@example.com
```

Behind your own load balancer instead, skip the profile and set `N8N_BIND_ADDRESS`,
`N8N_PROTOCOL=https`, `N8N_PROXY_HOPS` and `WEBHOOK_URL` to match.

### ngrok

`COMPOSE_PROFILES=ngrok` plus `NGROK_AUTHTOKEN` and `NGROK_DOMAIN`. See [docs/ngrok-setup.md](docs/ngrok-setup.md).

## Operations

```bash
docker compose ps                 # status
docker compose logs -f n8n        # logs
docker compose pull && docker compose up -d   # after changing N8N_VERSION / N8N_SANDBOX_VERSION
docker compose down               # stop (data is kept in DATA_DIR)
```

Postgres major upgrades need a dump and restore (`pg_dumpall`) before changing `POSTGRES_IMAGE`.

## Notes

- The sandbox runner is a privileged Docker-in-Docker container, as required by the upstream sandbox service. Never publish its ports.
- n8n no longer supports `N8N_BASIC_AUTH_*`; users sign in with the owner account created on first visit.
- To add tools such as `ffmpeg` or `yt-dlp`, build `n8n-custom/Dockerfile`, push it, and set `N8N_IMAGE`.

## License

See [LICENSE](LICENSE).
