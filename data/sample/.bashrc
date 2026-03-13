# Sample .bashrc – demonstrates typical WSL developer configuration

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# ── History settings ───────────────────────────────────────────────────────────
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
HISTTIMEFORMAT="%F %T "
shopt -s histappend

# ── Prompt ─────────────────────────────────────────────────────────────────────
# Show git branch in prompt
parse_git_branch() {
    git branch 2>/dev/null | sed -n 's/* \(.*\)/ (\1)/p'
}
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(parse_git_branch)\[\033[00m\]\$ '

# ── Aliases ────────────────────────────────────────────────────────────────────
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline -10'
alias dc='docker-compose'
alias dcu='docker-compose up -d'
alias dcd='docker-compose down'
alias dcl='docker logs -f'

# ── WSL-specific ───────────────────────────────────────────────────────────────
# Open Windows Explorer in current directory
alias explore='explorer.exe .'
# Open VS Code
alias code='/mnt/c/Users/myuser/AppData/Local/Programs/Microsoft\ VS\ Code/bin/code'
# Access Windows drives
alias c='cd /mnt/c'

# ── Project shortcuts ──────────────────────────────────────────────────────────
alias myapp='cd ~/projects/my-app'
alias start='bash ~/projects/my-app/startup.sh'
alias devapi='cd ~/projects/my-app && uvicorn main:app --reload --port 8000'
alias devui='cd ~/projects/my-app/frontend && npm run dev'

# ── Environment variables ──────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

export EDITOR=nano
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# Docker host for WSL2
export DOCKER_HOST=unix:///var/run/docker.sock

# ── Functions ──────────────────────────────────────────────────────────────────

# Kill whatever is running on a given port
killport() {
    local port="${1:?Usage: killport <port>}"
    local pid
    pid=$(lsof -t -i ":$port" 2>/dev/null)
    if [ -n "$pid" ]; then
        kill -9 $pid
        echo "Killed process $pid on port $port"
    else
        echo "No process found on port $port"
    fi
}

# Quick project start
devstart() {
    cd ~/projects/my-app
    docker-compose up -d postgres redis
    uvicorn main:app --reload --port 8000 &
    npm --prefix frontend run dev &
    echo "Dev stack started. Backend: 8000, Frontend: 3000"
}

# Install Python dependencies + activate venv
pysetup() {
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -r requirements.txt
    echo "Virtual environment activated and dependencies installed."
}

# Load .env file into current shell
loadenv() {
    if [ -f .env ]; then
        export $(grep -v '^#' .env | xargs)
        echo "Loaded .env"
    else
        echo ".env not found"
    fi
}
