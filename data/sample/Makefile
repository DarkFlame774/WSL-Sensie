# Makefile – myapp project task runner
# Usage: make <target>
# Run 'make help' for a list of all targets.

.PHONY: help install build test lint clean dev deploy

# ── Variables ──────────────────────────────────────────────────────────────────
PYTHON     := python3
VENV       := .venv
ACTIVATE   := source $(VENV)/bin/activate
BACKEND    := ./backend
FRONTEND   := ./frontend
PORT       := 8000
UI_PORT    := 3000

# ── Help ───────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  myapp – Available Make targets"
	@echo "  ────────────────────────────────────────────────"
	@echo "  make install      Install all dependencies"
	@echo "  make dev          Start full dev stack (backend + frontend + services)"
	@echo "  make backend      Start only the FastAPI backend on port $(PORT)"
	@echo "  make frontend     Start only the Vite frontend on port $(UI_PORT)"
	@echo "  make services     Start Docker services (postgres, redis)"
	@echo "  make build        Build production frontend bundle"
	@echo "  make test         Run all tests"
	@echo "  make lint         Run linters (ruff, eslint)"
	@echo "  make migrate      Run database migrations"
	@echo "  make clean        Remove build artefacts and caches"
	@echo "  make deploy       Deploy to production"
	@echo ""

# ── Install ────────────────────────────────────────────────────────────────────
install:
	@echo "→ Setting up Python virtual environment …"
	$(PYTHON) -m venv $(VENV)
	$(ACTIVATE) && pip install -r $(BACKEND)/requirements.txt
	@echo "→ Installing frontend dependencies …"
	cd $(FRONTEND) && npm install
	@echo "✓ Installation complete."

# ── Development ────────────────────────────────────────────────────────────────
services:
	docker-compose up -d postgres redis

dev: services
	@echo "→ Starting backend on port $(PORT) …"
	$(ACTIVATE) && uvicorn main:app --reload --host 0.0.0.0 --port $(PORT) &
	@echo "→ Starting frontend on port $(UI_PORT) …"
	cd $(FRONTEND) && npm run dev -- --port $(UI_PORT) &
	@echo ""
	@echo "  Backend  : http://localhost:$(PORT)"
	@echo "  Frontend : http://localhost:$(UI_PORT)"
	@echo "  API docs : http://localhost:$(PORT)/docs"
	@echo ""
	@echo "Press Ctrl-C to stop."
	@wait

backend: services
	$(ACTIVATE) && uvicorn main:app --reload --host 0.0.0.0 --port $(PORT)

frontend:
	cd $(FRONTEND) && npm run dev -- --port $(UI_PORT)

# ── Build ──────────────────────────────────────────────────────────────────────
build:
	@echo "→ Building frontend …"
	cd $(FRONTEND) && npm run build
	@echo "✓ Frontend built to $(FRONTEND)/dist"

# ── Test ───────────────────────────────────────────────────────────────────────
test:
	@echo "→ Running Python tests …"
	$(ACTIVATE) && pytest $(BACKEND)/tests -v --tb=short
	@echo "→ Running frontend tests …"
	cd $(FRONTEND) && npm test -- --watchAll=false

# ── Lint ───────────────────────────────────────────────────────────────────────
lint:
	$(ACTIVATE) && ruff check $(BACKEND)
	cd $(FRONTEND) && npx eslint src --ext .js,.jsx,.ts,.tsx

# ── Database ───────────────────────────────────────────────────────────────────
migrate:
	$(ACTIVATE) && alembic upgrade head

rollback:
	$(ACTIVATE) && alembic downgrade -1

# ── Clean ──────────────────────────────────────────────────────────────────────
clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	rm -rf $(FRONTEND)/dist $(FRONTEND)/node_modules/.cache
	@echo "✓ Clean complete."

# ── Deploy ─────────────────────────────────────────────────────────────────────
deploy: build
	@echo "→ Deploying to production …"
	rsync -avz $(FRONTEND)/dist/ user@prod-server:/var/www/myapp/
	ssh user@prod-server "cd /opt/myapp && git pull && pip install -r requirements.txt && systemctl restart myapp"
	@echo "✓ Deployment complete."
