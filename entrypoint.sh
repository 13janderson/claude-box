#!/bin/bash
set -euo pipefail

HOST_CONFIG=/home/sandbox/.claude.json.host
CONTAINER_CONFIG=/home/sandbox/.claude.json

# If a host .claude.json was mounted (OAuth login flow), sync auth tokens into
# the container config. Two cases:
#
#   First run  – container config doesn't exist yet: build it from the host
#                config with sandbox project settings applied.
#   Subsequent – container config already exists: only refresh auth-related
#                fields from host, preserving everything Claude has written
#                (conversation history references, numStartups, etc.) so that
#                `--continue` can find previous sessions.
#
# When no host config is present (API key auth) the baked-in config is used as-is.
if [ -f "$HOST_CONFIG" ]; then
    if [ -f "$CONTAINER_CONFIG" ]; then
        # Refresh only: overlay host fields (auth tokens, account info) onto the
        # existing container config, but keep the container's own projects map and
        # numStartups so Claude Code's session state is not lost between invocations.
        jq --slurpfile host "$HOST_CONFIG" \
            '. + ($host[0] | del(.projects, .numStartups))' \
            "$CONTAINER_CONFIG" > /tmp/.claude.json.tmp \
            && mv /tmp/.claude.json.tmp "$CONTAINER_CONFIG"
    else
        # First initialization: derive config from host with sandbox project settings.
        jq '
            .hasCompletedOnboarding = true |
            .projects["/home/sandbox"] = {
                "allowedTools": [],
                "mcpContextUris": [],
                "mcpServers": {},
                "enabledMcpjsonServers": [],
                "disabledMcpjsonServers": [],
                "hasTrustDialogAccepted": true,
                "projectOnboardingSeenCount": 1,
                "hasClaudeMdExternalIncludesApproved": false,
                "hasClaudeMdExternalIncludesWarningShown": false
            } |
            .projects["/home/sandbox/project"] = {
                "allowedTools": [],
                "mcpContextUris": [],
                "mcpServers": {},
                "enabledMcpjsonServers": [],
                "disabledMcpjsonServers": [],
                "hasTrustDialogAccepted": true,
                "projectOnboardingSeenCount": 1,
                "hasClaudeMdExternalIncludesApproved": false,
                "hasClaudeMdExternalIncludesWarningShown": false
            }
        ' "$HOST_CONFIG" > "$CONTAINER_CONFIG"
    fi
fi

exec "$@"
