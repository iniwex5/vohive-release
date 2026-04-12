#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
PURGE=0
KEEP_CONFIG=0

ROOT_DIR="/opt/vohive"
BIN_PATH="${ROOT_DIR}/bin/vohive"
BACKUP_PATH="${ROOT_DIR}/bin/vohive.bak"
SERVICE_PATH="/etc/systemd/system/vohive.service"
CONFIG_DIR="${ROOT_DIR}/config"
DATA_DIR="${ROOT_DIR}/data"
LOG_DIR="${ROOT_DIR}/logs"

log() { printf '[vohive-uninstall] %s\n' "$*"; }
err() { printf '[vohive-uninstall] ERROR: %s\n' "$*" >&2; }

usage() {
  cat <<USAGE
Usage: uninstall.sh [options]
  --purge
  --keep-config
  --dry-run
USAGE
}

run_root() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '[dry-run] %q' "$1"
    shift
    for arg in "$@"; do printf ' %q' "$arg"; done
    printf '\n'
    return 0
  fi

  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    err "Root privileges are required"
    exit 1
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --purge)
        PURGE=1
        shift
        ;;
      --keep-config)
        KEEP_CONFIG=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        err "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done
}

main() {
  parse_args "$@"

  if command -v systemctl >/dev/null 2>&1; then
    run_root systemctl stop vohive || true
    run_root systemctl disable vohive || true
    run_root rm -f "${SERVICE_PATH}"
    run_root systemctl daemon-reload || true
  fi

  run_root rm -f "${BIN_PATH}" "${BACKUP_PATH}"

  if [[ "${PURGE}" == "1" ]]; then
    if [[ "${KEEP_CONFIG}" == "0" ]]; then
      run_root rm -rf "${CONFIG_DIR}"
    fi
    run_root rm -rf "${DATA_DIR}"
    run_root rm -rf "${LOG_DIR}"
    run_root rmdir "${ROOT_DIR}/bin" 2>/dev/null || true
    run_root rmdir "${ROOT_DIR}" 2>/dev/null || true
  fi

  log "Uninstall complete"
}

main "$@"
