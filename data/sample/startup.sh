#!/usr/bin/env bash
# startup.sh – Start the full myapp development stack
# Usage:  ./startup.sh [--backend-only | --frontend-only | --services-only]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[startup]${NC} $*"; }
warn() { echo -e "${YELLOW}[startup]${NC} $*"; }
err()  { echo -e "${RED}[startup] ERROR:${NC} $*" >&2; exit 1; }

# ── Prerequisites ──────────────────────────────────────────────────────────────
command -v docker   >/dev/null || err "Docker is not installed."
command -v node     >/dev/null || err "Node.js is not installed."
command -v python3  >/dev/null || err "Python 3 is not installed."

# ── .env setup ─────────────────────────────────────────────────────────────────
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    warn ".env not found – copying from .env.example"
    cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
fi
source "$PROJECT_ROOT/.env"

# ── Parse args ─────────────────────────────────────────────────────────────────
MODE="${1:-all}"

start_services() {
    log "Starting Docker services (postgres, redis, nginx) …"
    docker-compose up -d postgres redis nginx
    log "Waiting for PostgreSQL to be ready …"
    until docker exec myapp_postgres pg_isready -U myuser -d mydb &>/dev/null; do
        sleep 1
    done
    log "PostgreSQL is ready."
}

start_backend() {
    log "Activating Python virtual environment …"
    cd "$PROJECT_ROOT/backend"
    if [ ! -d ".venv" ]; then
        python3 -m venv .venv
        source .venv/bin/activate
        pip install -r requirements.txt --quiet
    else
        source .venv/bin/activate
    fi

    log "Running database migrations …"
    alembic upgrade head

    log "Starting FastAPI backend on port 8000 …"
    uvicorn main:app --reload --host 0.0.0.0 --port 8000 &
    BACKEND_PID=$!
    echo $BACKEND_PID > /tmp/myapp_backend.pid
    log "Backend PID: $BACKEND_PID"
}

start_frontend() {
    log "Installing frontend dependencies …"
    cd "$PROJECT_ROOT/frontend"
    npm install --silent

    log "Starting Vite dev server on port 3000 …"
    npm run dev -- --host 0.0.0.0 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > /tmp/myapp_frontend.pid
    log "Frontend PID: $FRONTEND_PID"
}

# ── Run ────────────────────────────────────────────────────────────────────────
case "$MODE" in
    --services-only)  start_services ;;
    --backend-only)   start_services; start_backend ;;
    --frontend-only)  start_frontend ;;
    all|*)
        start_services
        start_backend
        start_frontend
        ;;
esac

log ""
log "🚀 myapp is running!"
log "   Frontend : http://localhost:3000"
log "   Backend  : http://localhost:8000"
log "   API docs : http://localhost:8000/docs"
log "   Nginx    : http://localhost:80"
log ""
log "Press Ctrl-C to stop all processes."

# Wait and clean up
trap 'log "Shutting down …"; docker-compose down; kill 0' EXIT
wait
