#!/bin/sh

set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$REPO_ROOT"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌ Missing required command: $1" >&2
    exit 1
  fi
}

require_command docker
require_command pnpm
require_command node

if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker is not running. Start Docker Desktop/daemon and try again." >&2
  exit 1
fi

if docker compose version >/dev/null 2>&1; then
  compose() {
    docker compose "$@"
  }
elif command -v docker-compose >/dev/null 2>&1; then
  compose() {
    docker-compose "$@"
  }
else
  echo "❌ Docker Compose is required (docker compose or docker-compose)." >&2
  exit 1
fi

node_version=$(node -v | sed 's/^v//')
node_major=$(printf '%s' "$node_version" | cut -d. -f1)
if [ "$node_major" -lt 20 ]; then
  echo "❌ Node.js 20+ is required. Found v$node_version" >&2
  exit 1
fi

if [ ! -f .env.local ]; then
  cp .env.example .env.local
  echo "✅ Created .env.local from .env.example"
else
  echo "ℹ️  Using existing .env.local"
fi

echo "🚀 Starting PostgreSQL and Redis with Docker Compose..."
compose up -d postgres redis

postgres_container_id=$(compose ps -q postgres)
if [ -z "$postgres_container_id" ]; then
  echo "❌ Could not find postgres container after startup." >&2
  exit 1
fi

echo "⏳ Waiting for PostgreSQL to become healthy..."
attempt=1
max_attempts=60
while [ "$attempt" -le "$max_attempts" ]; do
  postgres_status=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$postgres_container_id" 2>/dev/null || true)

  if [ "$postgres_status" = "healthy" ]; then
    break
  fi

  if [ "$postgres_status" = "exited" ] || [ "$postgres_status" = "dead" ]; then
    echo "❌ PostgreSQL container exited before becoming healthy." >&2
    exit 1
  fi

  sleep 2
  attempt=$((attempt + 1))
done

if [ "$postgres_status" != "healthy" ]; then
  echo "❌ Timed out waiting for PostgreSQL health check." >&2
  echo "   Run compose logs for the postgres service for details." >&2
  exit 1
fi

echo "🗄️  Running database migrations..."
pnpm db:migrate

echo ""
echo "✅ Local setup complete."
echo "Next steps:"
echo "  1) Start the app: pnpm dev"
echo "  2) Open: http://localhost:3000"
echo "  3) Stop services when done: pnpm dev:down"
