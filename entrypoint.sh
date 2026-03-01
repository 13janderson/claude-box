#!/bin/bash
set -e

HOST_CONFIG=/home/sandbox/.claude.json.host

# If a host .claude.json was mounted (OAuth login flow), merge its auth tokens
# into a fresh container config that has the sandbox project settings applied.
# This 
if [ -f "$HOST_CONFIG" ]; then
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
    ' "$HOST_CONFIG" > /home/sandbox/.claude.json
fi

exec "$@"
