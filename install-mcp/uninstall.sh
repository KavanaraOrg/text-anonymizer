#!/usr/bin/env bash
#
# Text Anonymizer — uninstaller for macOS.
# Stops/removes the container, removes the Claude Desktop MCP entry, and
# (optionally) deletes the cached-model volume and the built image.
#
# Usage:
#   ./uninstall.sh             # remove container + MCP entry (keep model cache + image)
#   ./uninstall.sh --purge     # also delete the model volume and the image
#
set -euo pipefail

CONTAINER_NAME="text-anonymizer"
IMAGE_NAME="text-anonymizer:mcp"
MODEL_VOLUME="text-anonymizer-models"
MCP_NAME="text-anonymizer"
CLAUDE_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

c_green="\033[1;32m"; c_yellow="\033[1;33m"; c_off="\033[0m"
ok()   { echo -e "${c_green}  ✓${c_off} $*"; }
warn() { echo -e "${c_yellow}  !${c_off} $*"; }

echo "==> Removing container"
if docker info >/dev/null 2>&1; then
  if [ -n "$(docker ps -aq -f name="^${CONTAINER_NAME}$")" ]; then
    docker rm -f "$CONTAINER_NAME" >/dev/null && ok "Container removed"
  else
    warn "Container not present"
  fi
  if [ "$PURGE" = "1" ]; then
    docker volume rm "$MODEL_VOLUME" >/dev/null 2>&1 && ok "Model volume removed" || warn "Model volume not present"
    docker image rm "$IMAGE_NAME" >/dev/null 2>&1 && ok "Image removed" || warn "Image not present"
  fi
else
  warn "Docker daemon not running — skipped container/volume/image cleanup"
fi

echo "==> Removing MCP entry from Claude Desktop"
if [ -f "$CLAUDE_CONFIG" ]; then
  python3 - "$CLAUDE_CONFIG" "$MCP_NAME" <<'PY'
import json, os, sys, shutil, datetime
config, name = sys.argv[1:3]
bak = f"{config}.bak-{datetime.datetime.now():%Y%m%d-%H%M%S}"
shutil.copy2(config, bak); print(f"  backup: {bak}")
with open(config) as f:
    data = json.load(f)
servers = data.get("mcpServers", {})
if servers.pop(name, None) is not None:
    with open(config, "w") as f:
        json.dump(data, f, indent=2)
    print(f"  removed '{name}'. Remaining: {', '.join(sorted(servers)) or '(none)'}")
else:
    print(f"  '{name}' was not present")
PY
  ok "Claude Desktop config updated"
else
  warn "No Claude Desktop config found"
fi

echo -e "\n${c_green}Done.${c_off} Restart Claude Desktop to drop the connector."
[ "$PURGE" = "0" ] && echo "  (model cache + image kept — re-run install.sh to restore quickly; use --purge to delete them)"
