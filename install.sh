#!/usr/bin/env bash
set -euo pipefail

REPO="${VOHIVE_RELEASE_REPO:-iniwex5/vohive-release}"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/master"
CHANNEL="stable"
VERSION=""
NO_SYSTEMD=0
DRY_RUN=0
FORCE=0

ROOT_DIR="/opt/vohive"
INSTALL_DIR="${ROOT_DIR}/bin"
CONFIG_DIR="${ROOT_DIR}/config"
DATA_DIR="${ROOT_DIR}/data"
LOG_DIR="${ROOT_DIR}/logs"
BIN_PATH="${INSTALL_DIR}/vohive"
BACKUP_PATH="${INSTALL_DIR}/vohive.bak"
SERVICE_PATH="/etc/systemd/system/vohive.service"

log() { printf '[vohive-install] %s\n' "$*"; }
err() { printf '[vohive-install] ERROR: %s\n' "$*" >&2; }

usage() {
  cat <<USAGE
Usage: install.sh [options]
  --version <vX.Y.Z|latest|stable>
  --channel <stable|latest>
  --no-systemd
  --dry-run
  --force
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
    err "Root privileges are required (run as root or install sudo)."
    exit 1
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "Missing command: $1"
    exit 1
  }
}

extract_json_value() {
  local key="$1"
  sed -n "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n1
}

resolve_version() {
  local v="$1"
  if [[ -n "${v}" && "${v}" != "latest" && "${v}" != "stable" ]]; then
    printf '%s\n' "${v}"
    return 0
  fi

  local idx
  idx="$(curl -fsSL "${RAW_BASE}/versions.json")"
  local key="${CHANNEL}"
  if [[ "${v}" == "latest" || "${CHANNEL}" == "latest" ]]; then
    key="latest"
  fi

  local resolved
  resolved="$(printf '%s\n' "${idx}" | extract_json_value "${key}")"
  if [[ -z "${resolved}" ]]; then
    err "Cannot resolve version from versions.json (key=${key})."
    exit 1
  fi
  printf '%s\n' "${resolved}"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --version)
        VERSION="${2:-}"
        shift 2
        ;;
      --channel)
        CHANNEL="${2:-}"
        shift 2
        ;;
      --no-systemd)
        NO_SYSTEMD=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --force)
        FORCE=1
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

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    *)
      err "Unsupported architecture: $(uname -m)"
      exit 1
      ;;
  esac
}

install_default_config() {
  run_root mkdir -p "${INSTALL_DIR}" "${CONFIG_DIR}" "${DATA_DIR}" "${LOG_DIR}"
  if [[ "${DRY_RUN}" == "1" ]]; then
    return 0
  fi
  if [[ ! -f "${CONFIG_DIR}/config.yaml" || "${FORCE}" == "1" ]]; then
    run_root tee "${CONFIG_DIR}/config.yaml" >/dev/null <<CFG
server:
  port: ":7575"
  debug: false

web:
  username: "admin"
  password: "admin"
CFG
  fi
}

install_systemd() {
  local tmp_unit="$1"
  cat > "${tmp_unit}" <<UNIT
[Unit]
Description=VoHive Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=${DATA_DIR}
ExecStart=${BIN_PATH} -c ${CONFIG_DIR}/config.yaml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
UNIT

  run_root install -m 0644 "${tmp_unit}" "${SERVICE_PATH}"
  run_root systemctl daemon-reload
  run_root systemctl enable vohive
  run_root systemctl restart vohive
  run_root systemctl is-active --quiet vohive
}

main() {
  parse_args "$@"

  need_cmd curl
  need_cmd tar
  need_cmd uname

  local os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  if [[ "${os}" != "linux" ]]; then
    err "Unsupported OS: ${os}"
    exit 1
  fi

  local arch
  arch="$(detect_arch)"
  local resolved_version
  resolved_version="$(resolve_version "${VERSION}")"

  local asset="vohive_${resolved_version}_linux_${arch}.tar.gz"
  local base="https://github.com/${REPO}/releases/download/${resolved_version}"

  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' EXIT

  local tarball="${tmp}/${asset}"

  log "Resolved version: ${resolved_version}"
  log "Downloading artifacts from ${base}"

  curl -fsSL "${base}/${asset}" -o "${tarball}"

  tar -xzf "${tarball}" -C "${tmp}"
  local extracted
  extracted="$(find "${tmp}" -maxdepth 1 -type f -name "vohive_${resolved_version}_linux_${arch}" | head -n1)"
  if [[ -z "${extracted}" ]]; then
    err "Extracted binary not found in package"
    exit 1
  fi

  if [[ -x "${BIN_PATH}" ]]; then
    log "Backing up existing binary to ${BACKUP_PATH}"
    run_root cp -f "${BIN_PATH}" "${BACKUP_PATH}"
  fi

  local rollback_needed=0
  rollback() {
    if [[ "${rollback_needed}" == "1" && -f "${BACKUP_PATH}" ]]; then
      err "Rolling back to previous binary"
      run_root cp -f "${BACKUP_PATH}" "${BIN_PATH}" || true
      if [[ "${NO_SYSTEMD}" == "0" && -x "$(command -v systemctl || true)" ]]; then
        run_root systemctl restart vohive || true
      fi
    fi
  }

  install_default_config
  rollback_needed=1
  run_root install -m 0755 "${extracted}" "${BIN_PATH}"

  if [[ "${NO_SYSTEMD}" == "0" ]]; then
    need_cmd systemctl
    local unit_tmp="${tmp}/vohive.service"
    if ! install_systemd "${unit_tmp}"; then
      rollback
      err "systemd installation/start failed"
      exit 1
    fi
  fi

  rollback_needed=0
  log "Install complete: ${BIN_PATH} (${resolved_version})"
}

main "$@"
