#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
LINK_NAME="${LINK_NAME:-claude-sandbox}"

_info()  { echo "[install] $*"; }
_warn()  { echo "[install] warning: $*" >&2; }
_error() { echo "[install] error: $*" >&2; exit 1; }

# ── Dependency checks ─────────────────────────────────────────────────────────

_check_docker() {
    if ! command -v docker &>/dev/null; then
        _error "docker is not installed. See https://docs.docker.com/get-docker/"
    fi
    if ! docker info &>/dev/null; then
        _error "docker daemon is not running or you lack permission. Try: sudo systemctl start docker"
    fi
    _info "docker: ok"
}

_check_docker_compose() {
    if docker compose version &>/dev/null 2>&1; then
        _info "docker compose plugin: ok"
    elif command -v docker-compose &>/dev/null; then
        _warn "using legacy docker-compose — upgrade to the compose plugin for best results"
    else
        _error "docker compose is not available. Install the Docker Compose plugin."
    fi
}

_check_jq() {
    if ! command -v jq &>/dev/null; then
        _error "jq is required but not installed. Install it with your package manager (e.g. apt install jq / brew install jq)."
    fi
    _info "jq: ok"
}

# ── Auth check ────────────────────────────────────────────────────────────────

_check_auth() {
    local has_oauth=false has_api_key=false
    [[ -f "$HOME/.claude.json" || -f "$HOME/.claude/.credentials.json" ]] && has_oauth=true
    [[ -n "${ANTHROPIC_API_KEY:-}" ]] && has_api_key=true

    if $has_oauth; then
        _info "auth: Claude OAuth credentials found"
    elif $has_api_key; then
        _info "auth: ANTHROPIC_API_KEY found in environment"
    else
        _warn "no auth found — set ANTHROPIC_API_KEY or run 'claude login' on the host first"
    fi
}

# ── Script setup ──────────────────────────────────────────────────────────────

_make_executable() {
    chmod +x "$SCRIPT_DIR/sandbox"
    _info "sandbox script is executable"
}

_install_link() {
    if [[ "${1:-}" == "--no-link" ]]; then
        _info "skipping PATH symlink (--no-link)"
        return
    fi

    if [[ ! -d "$INSTALL_DIR" ]]; then
        _warn "$INSTALL_DIR does not exist; skipping symlink. Use INSTALL_DIR=<dir> to override."
        return
    fi

    local target="$INSTALL_DIR/$LINK_NAME"
    _info "installing symlink: $target -> $SCRIPT_DIR/sandbox"

    if ln -sf "$SCRIPT_DIR/sandbox" "$target" 2>/dev/null; then
        _info "you can now run: $LINK_NAME"
    elif command -v sudo &>/dev/null; then
        _info "$INSTALL_DIR is not writable, retrying with sudo..."
        sudo ln -sf "$SCRIPT_DIR/sandbox" "$target"
        _info "you can now run: $LINK_NAME"
    else
        _warn "could not write to $INSTALL_DIR and sudo is unavailable"
        _info "add $SCRIPT_DIR to your PATH, or run: sudo ln -sf $SCRIPT_DIR/sandbox $target"
    fi
}

# ── Build ─────────────────────────────────────────────────────────────────────

_build_image() {
    if [[ "${1:-}" == "--no-build" ]]; then
        _info "skipping image build (--no-build)"
        return
    fi

    _info "building sandbox Docker image..."
    (cd "$SCRIPT_DIR" && docker compose build --no-cache )
    _info "image built successfully"
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    local no_link=false no_build=false

    for arg in "$@"; do
        case "$arg" in
            --no-link)  no_link=true ;;
            --no-build) no_build=true ;;
            --help|-h)
                cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --no-link    Skip creating a symlink in $INSTALL_DIR
  --no-build   Skip building the Docker image
  --help       Show this help

Environment:
  INSTALL_DIR  Directory for the symlink  (default: /usr/local/bin)
  LINK_NAME    Name of the symlink         (default: claude-sandbox)
EOF
                exit 0 ;;
            *)
                _error "unknown option: $arg (use --help for usage)" ;;
        esac
    done

    _info "checking dependencies..."
    _check_docker
    _check_docker_compose
    _check_jq

    _check_auth
    _make_executable

    $no_link  && _install_link --no-link  || _install_link
    $no_build && _build_image  --no-build || _build_image

    echo
    _info "installation complete."
    _info "run './sandbox' or '$LINK_NAME' to start a Claude session."
}

main "$@"
