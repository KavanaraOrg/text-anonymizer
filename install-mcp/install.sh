#!/usr/bin/env bash
#
# Text Anonymizer — one-shot installer for macOS.
#
# Builds the Docker image (with the in-process MCP server), runs it as a
# long-lived container, and registers it globally in Claude Desktop as an MCP
# connector. Safe to re-run (idempotent).
#
# Usage:
#   ./install.sh                 # full install
#   ./install.sh --no-warmup     # skip pre-downloading the model (~600 MB)
#   ./install.sh --no-mcp        # build + run container only, don't touch Claude config
#
set -euo pipefail

# ---- configuration ----------------------------------------------------------
IMAGE_NAME="text-anonymizer:mcp"
CONTAINER_NAME="text-anonymizer"
HOST_PORT="8000"
MODEL_VOLUME="text-anonymizer-models"
MCP_NAME="text-anonymizer"
MCP_URL="http://localhost:${HOST_PORT}/mcp"
CLAUDE_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

WARMUP=1
REGISTER_MCP=1
for arg in "$@"; do
  case "$arg" in
    --no-warmup) WARMUP=0 ;;
    --no-mcp)    REGISTER_MCP=0 ;;
    -h|--help)   sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_CONTEXT="$SCRIPT_DIR/build-context"

# ---- pretty logging ---------------------------------------------------------
c_blue="\033[1;34m"; c_green="\033[1;32m"; c_yellow="\033[1;33m"; c_red="\033[1;31m"; c_off="\033[0m"
step() { echo -e "\n${c_blue}==>${c_off} $*"; }
ok()   { echo -e "${c_green}  ✓${c_off} $*"; }
warn() { echo -e "${c_yellow}  !${c_off} $*"; }
die()  { echo -e "${c_red}  ✗ $*${c_off}" >&2; exit 1; }

# ---- preflight --------------------------------------------------------------
step "Preflight checks"
[ "$(uname)" = "Darwin" ] || die "This installer targets macOS."
[ -d "$BUILD_CONTEXT" ] || die "build-context/ not found next to install.sh (incomplete package?)."
command -v brew >/dev/null 2>&1 || die "Homebrew not found. Install it from https://brew.sh and re-run."
ok "macOS + Homebrew present"

# ---- Docker CLI -------------------------------------------------------------
step "Ensuring Docker CLI"
if ! command -v docker >/dev/null 2>&1; then
  warn "docker not found — installing via Homebrew…"
  brew install docker
fi
ok "docker: $(command -v docker)"

# ---- Docker daemon ----------------------------------------------------------
step "Ensuring a Docker daemon is running"
wait_for_daemon() { for _ in $(seq 1 60); do docker info >/dev/null 2>&1 && return 0; sleep 2; done; return 1; }
if docker info >/dev/null 2>&1; then
  ok "Docker daemon already running"
elif [ -d "/Applications/Docker.app" ]; then
  warn "Starting Docker Desktop…"; open -a Docker
  wait_for_daemon && ok "Docker Desktop is up" || die "Docker Desktop did not start in time."
else
  warn "No running daemon and Docker Desktop not installed — using Colima (headless daemon)."
  command -v colima >/dev/null 2>&1 || brew install colima
  colima status >/dev/null 2>&1 || colima start
  wait_for_daemon && ok "Colima daemon is up" || die "Could not start a Docker daemon."
fi

# ---- Node / npx (needed by mcp-remote) --------------------------------------
if [ "$REGISTER_MCP" = "1" ]; then
  step "Ensuring Node.js / npx (for the mcp-remote bridge)"
  command -v npx >/dev/null 2>&1 || { warn "node not found — installing…"; brew install node; }
  NPX_BIN="$(command -v npx)"
  ok "npx: $NPX_BIN"
fi

# ---- build image ------------------------------------------------------------
step "Building image $IMAGE_NAME (this can take a few minutes the first time)"
docker build -t "$IMAGE_NAME" "$BUILD_CONTEXT"
ok "Image built"

# ---- (re)create container ---------------------------------------------------
step "Starting container '$CONTAINER_NAME' on port $HOST_PORT"
docker volume create "$MODEL_VOLUME" >/dev/null
if [ -n "$(docker ps -aq -f name="^${CONTAINER_NAME}$")" ]; then
  warn "Removing existing container…"; docker rm -f "$CONTAINER_NAME" >/dev/null
fi
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p "${HOST_PORT}:8000" \
  -v "${MODEL_VOLUME}:/root/.cache/huggingface" \
  "$IMAGE_NAME" >/dev/null
ok "Container running"

# ---- wait for health --------------------------------------------------------
step "Waiting for the service to become healthy"
healthy=0
for _ in $(seq 1 30); do
  if curl -fsS "http://localhost:${HOST_PORT}/health" >/dev/null 2>&1; then healthy=1; break; fi
  sleep 1
done
[ "$healthy" = "1" ] && ok "Service healthy at http://localhost:${HOST_PORT}" || warn "Health check timed out — check 'docker logs $CONTAINER_NAME'."

# ---- warm up model (optional) -----------------------------------------------
if [ "$WARMUP" = "1" ]; then
  step "Pre-loading the PII model (~600 MB on first run; best-effort)"
  if curl -fsS -X POST --max-time 600 "http://localhost:${HOST_PORT}/warmup" >/dev/null 2>&1; then
    ok "Model loaded and cached in volume '$MODEL_VOLUME'"
  else
    warn "Warmup not completed now — the model will download on the first anonymize call."
  fi
fi

# ---- register MCP in Claude Desktop -----------------------------------------
if [ "$REGISTER_MCP" = "1" ]; then
  step "Registering MCP server in Claude Desktop"
  python3 - "$CLAUDE_CONFIG" "$MCP_NAME" "$NPX_BIN" "$MCP_URL" <<'PY'
import json, os, sys, shutil, datetime
config, name, npx, url = sys.argv[1:5]
os.makedirs(os.path.dirname(config), exist_ok=True)
data = {}
if os.path.exists(config):
    bak = f"{config}.bak-{datetime.datetime.now():%Y%m%d-%H%M%S}"
    shutil.copy2(config, bak)
    print(f"  backup: {bak}")
    try:
        with open(config) as f:
            data = json.load(f)
    except Exception as e:
        print(f"  warning: existing config unreadable ({e}); starting fresh")
        data = {}
servers = data.setdefault("mcpServers", {})
servers[name] = {"command": npx, "args": ["-y", "mcp-remote", url]}
with open(config, "w") as f:
    json.dump(data, f, indent=2)
print(f"  servers now: {', '.join(sorted(servers))}")
PY
  ok "Claude Desktop config updated: $CLAUDE_CONFIG"
fi

# ---- done -------------------------------------------------------------------
echo -e "\n${c_green}Done.${c_off}"
echo    "  REST docs : http://localhost:${HOST_PORT}/docs"
echo    "  MCP URL   : ${MCP_URL}"
if [ "$REGISTER_MCP" = "1" ]; then
  echo  "  Next      : Quit and reopen Claude Desktop. The 'text-anonymizer'"
  echo  "              connector with tools anonymize / deanonymize will appear."
fi
echo    "  Manage    : docker logs ${CONTAINER_NAME}   |   docker restart ${CONTAINER_NAME}"
echo    "  Remove    : ./uninstall.sh"
