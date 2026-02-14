#!/bin/bash
set -euo pipefail

source dependencies.sh

BYOND_VERSION="${BYOND_MAJOR}.${BYOND_MINOR}"
BYOND_ROOT="${HOME}/BYOND"
BYOND_BIN_DIR="${BYOND_ROOT}/byond/bin"
BYOND_VERSION_FILE="${BYOND_ROOT}/version.txt"
BYOND_ALLOW_STALE_CACHE="${BYOND_ALLOW_STALE_CACHE:-1}"
BYOND_CURL_RETRIES="${BYOND_CURL_RETRIES:-4}"
declare -a attempted_urls=()

is_exact_cached_install() {
  [ -d "${BYOND_BIN_DIR}" ] \
    && [ -f "${BYOND_VERSION_FILE}" ] \
    && grep -Fxq "${BYOND_VERSION}" "${BYOND_VERSION_FILE}"
}

has_any_cached_install() {
  [ -d "${BYOND_BIN_DIR}" ]
}

get_cached_version() {
  if [ ! -f "${BYOND_VERSION_FILE}" ]; then
    return 1
  fi

  tr -d '[:space:]' < "${BYOND_VERSION_FILE}"
}

is_supported_stale_cache() {
  local cached_version
  cached_version="$(get_cached_version || true)"

  if [[ "${cached_version}" =~ ^([0-9]+)\.[0-9]+$ ]]; then
    [ "${BASH_REMATCH[1]}" = "${BYOND_MAJOR}" ]
    return $?
  fi

  return 1
}

print_attempted_urls() {
  if [ "${#attempted_urls[@]}" -eq 0 ]; then
    return 0
  fi

  echo "Attempted BYOND URLs:" >&2
  for url in "${attempted_urls[@]}"; do
    echo "  - ${url}" >&2
  done
}

download_byond_zip() {
  local output_file="$1"
  local user_agent="BlueMoon-Station/1.0 CI Script"
  local -a urls=(
    "https://www.byond.com/download/build/${BYOND_MAJOR}/${BYOND_VERSION}_byond_linux.zip"
    "http://www.byond.com/download/build/${BYOND_MAJOR}/${BYOND_VERSION}_byond_linux.zip"
    "https://www.byond.com/download/build/${BYOND_MAJOR}/${BYOND_VERSION}_byond.zip"
    "http://www.byond.com/download/build/${BYOND_MAJOR}/${BYOND_VERSION}_byond.zip"
  )

  for url in "${urls[@]}"; do
    attempted_urls+=("${url}")
    echo "Attempting BYOND download: ${url}"
    if curl -L -f \
      --retry "${BYOND_CURL_RETRIES}" \
      --retry-all-errors \
      --retry-delay 2 \
      --connect-timeout 20 \
      --max-time 300 \
      -H "User-Agent: ${user_agent}" \
      "${url}" \
      -o "${output_file}"; then
      return 0
    fi
  done

  return 1
}

swap_install_dir() {
  local ready_dir="$1"
  local backup_dir="${BYOND_ROOT}.backup.$$"

  if [ -d "${BYOND_ROOT}" ]; then
    rm -rf "${backup_dir}"
    mv "${BYOND_ROOT}" "${backup_dir}"
  fi

  if mv "${ready_dir}" "${BYOND_ROOT}"; then
    rm -rf "${backup_dir}"
    return 0
  fi

  echo "Failed to move new BYOND installation into place." >&2
  if [ -d "${backup_dir}" ] && [ ! -d "${BYOND_ROOT}" ]; then
    mv "${backup_dir}" "${BYOND_ROOT}"
  fi

  return 1
}

if is_exact_cached_install; then
  echo "Using cached BYOND ${BYOND_VERSION}."
  exit 0
fi

if has_any_cached_install; then
  echo "Cached BYOND does not match pinned ${BYOND_VERSION}. Attempting reinstall."
else
  echo "Setting up BYOND ${BYOND_VERSION}."
fi

stage_dir="$(mktemp -d "${HOME}/BYOND.stage.XXXXXX")"
trap 'rm -rf "${stage_dir}"' EXIT

zip_file="${stage_dir}/byond.zip"
if download_byond_zip "${zip_file}"; then
  unzip -q "${zip_file}" -d "${stage_dir}"
  rm -f "${zip_file}"

  if [ ! -d "${stage_dir}/byond" ]; then
    echo "Downloaded BYOND archive did not contain expected 'byond' directory." >&2
    exit 1
  fi

  ready_root="${stage_dir}/BYOND"
  mkdir -p "${ready_root}"
  mv "${stage_dir}/byond" "${ready_root}/byond"

  swap_install_dir "${ready_root}"

  # 'make here' embeds absolute paths into byondsetup, so it must run in final location.
  (
    cd "${BYOND_ROOT}/byond"
    make here
  )

  echo "${BYOND_VERSION}" > "${BYOND_VERSION_FILE}"
  trap - EXIT
  rm -rf "${stage_dir}"
  echo "Installed BYOND ${BYOND_VERSION}."
  exit 0
fi

if has_any_cached_install && [ "${BYOND_ALLOW_STALE_CACHE}" != "0" ]; then
  if is_supported_stale_cache; then
    echo "Warning: failed to download pinned BYOND ${BYOND_VERSION}; using existing cached BYOND install." >&2
    echo "Cached BYOND version: $(get_cached_version)" >&2
    print_attempted_urls
    exit 0
  fi

  cached_version="$(get_cached_version || true)"
  echo "Cached BYOND is not valid for fallback. Required major: ${BYOND_MAJOR}, found: ${cached_version:-unknown}." >&2
fi

echo "Failed to install pinned BYOND ${BYOND_VERSION}." >&2
if has_any_cached_install; then
  echo "Cached BYOND exists but strict mode is enabled (BYOND_ALLOW_STALE_CACHE=0)." >&2
fi
print_attempted_urls
exit 1
