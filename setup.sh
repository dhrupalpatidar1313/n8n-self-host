#!/usr/bin/env bash
# Creates .env from .env.example and replaces every CHANGE_ME with a random secret.
# Safe to re-run: refuses to overwrite an existing .env.
set -euo pipefail
cd "$(dirname "$0")"

if [ -e .env ]; then
	echo ".env already exists, leaving it untouched." >&2
	exit 1
fi

gen_secret() {
	if command -v openssl >/dev/null 2>&1; then
		openssl rand -hex 24
	else
		head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n'
	fi
}

# Secrets that must appear twice (API side and client side) share one value.
sandbox_api_key="$(gen_secret)"
registration_token="$(gen_secret)"
runner_key="$(gen_secret)"

umask 077
while IFS= read -r line; do
	case "$line" in
	SANDBOX_API_KEYS=CHANGE_ME | N8N_SANDBOX_SERVICE_API_KEY=CHANGE_ME)
		line="${line%%=*}=${sandbox_api_key}" ;;
	SANDBOX_API_RUNNER_REGISTRATION_TOKEN=CHANGE_ME | SANDBOX_RUNNER_REGISTRATION_TOKEN=CHANGE_ME)
		line="${line%%=*}=${registration_token}" ;;
	SANDBOX_API_RUNNER_API_KEY=CHANGE_ME | SANDBOX_RUNNER_API_KEYS=CHANGE_ME)
		line="${line%%=*}=${runner_key}" ;;
	*=CHANGE_ME)
		line="${line%%=*}=$(gen_secret)" ;;
	esac
	printf '%s\n' "$line"
done <.env.example >.env

echo "Created .env with generated secrets."
echo "Edit N8N_HOST, WEBHOOK_URL, N8N_BIND_ADDRESS (and COMPOSE_PROFILES) as needed, then run:"
echo "  docker compose up -d"
