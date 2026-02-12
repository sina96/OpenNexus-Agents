#!/usr/bin/env bash

# Installs this repo's OpenCode components into a local/global/custom install directory.
#
# High-level flow:
# - Pre-install (interactive only): dependency checks + install location chooser
# - Install: copy components from registry.jsonc into the install destination
# - Post-install (interactive only, optional): providers + MCP detection + model recommendations + project config + gitignore
#
# Notes:
# - Source paths are referenced from registry.jsonc (typically under core/)
# - Safe by default: skips existing files (use --overwrite or --backup to replace)

set -euo pipefail

#------------------------------------------------------------------------------
# Paths and installation directories
#------------------------------------------------------------------------------
# NOTE: This installer supports being executed via `curl ... | bash -s -- ...`.
# In that mode, bash may not populate BASH_SOURCE[0], so we must guard it under
# `set -u` and fall back to downloading from GitHub raw URLs.
SCRIPT_SOURCE="${BASH_SOURCE[0]-}"
if [ -n "${SCRIPT_SOURCE}" ] && [ -e "${SCRIPT_SOURCE}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_SOURCE}")" && pwd)"
  # Local execution: use local files
  RAW_URL=""
else
  # Piped execution (curl | bash): download from GitHub
  SCRIPT_DIR=""
  RAW_URL="${OPENCODE_RAW_URL:-https://raw.githubusercontent.com/sina96/OpenNexus-Agents/main}"
fi

REGISTRY_JSONC_EXPLICIT=false
if [ -n "${REGISTRY_JSONC:-}" ]; then
  REGISTRY_JSONC_EXPLICIT=true
fi

# Set registry source: local file if available, otherwise download from GitHub
if [ -n "${SCRIPT_DIR}" ] && [ -f "${SCRIPT_DIR}/registry.jsonc" ]; then
  REGISTRY_JSONC="${SCRIPT_DIR}/registry.jsonc"
else
  # Download registry to temp file
  REGISTRY_JSONC="$(mktemp -t opencode-registry.XXXXXX.jsonc)"
  if ! curl -fsSL "${RAW_URL}/registry.jsonc" -o "${REGISTRY_JSONC}"; then
    echo "Error: Failed to download registry.jsonc from ${RAW_URL}" >&2
    exit 1
  fi
fi

# Project root directory.
# - Used for project-scoped updates (.gitignore + optional opencode.jsonc)
# - Default: current working directory
# - Override: --into <dir> (must exist) or OPENCODE_TARGET_DIR
CURRENT_DIR="$(pwd)"
TARGET_DIR="${OPENCODE_TARGET_DIR:-$CURRENT_DIR}"

# Optional override for INSTALL_DIR (set by flags / interactive chooser).
INSTALL_DIR_OVERRIDE=""

# Derived install directories (populated by set_install_paths)
INSTALL_DIR=""
PRIMARY_AGENTS_DIR=""
SUBAGENTS_DIR=""
COMMANDS_DIR=""
TOOLS_DIR=""
SKILLS_DIR=""
PLUGINS_DIR=""

set_install_paths() {
  INSTALL_DIR="${INSTALL_DIR_OVERRIDE:-${OPENCODE_INSTALL_DIR:-${TARGET_DIR}/.opencode}}"
  PRIMARY_AGENTS_DIR="${INSTALL_DIR}/agents"
  SUBAGENTS_DIR="${INSTALL_DIR}/agents/subagent"
  COMMANDS_DIR="${INSTALL_DIR}/commands"
  TOOLS_DIR="${INSTALL_DIR}/tools"
  SKILLS_DIR="${INSTALL_DIR}/skills"
  PLUGINS_DIR="${INSTALL_DIR}/plugins"
}


#------------------------------------------------------------------------------
# Runtime state and options
#------------------------------------------------------------------------------
# Strategy when target files exist: skip (default), overwrite, or backup
STRATEGY="skip"

# If STRATEGY=backup, create one backup dir per run.
BACKUP_DIR=""

# Whether to run interactive prompts
INTERACTIVE=false

# Whether to skip post-install prompts/actions (interactive only)
SKIP_POSTINSTALL=false

# Non-interactive install mode:
# - agents: install agents + subagents only
# - all: install agents + subagents + other components
NON_INTERACTIVE_MODE="agents"

# Install destination selection.
# IMPORTANT: TARGET_DIR remains the project root for .gitignore + opencode.jsonc updates.
INSTALL_LOCATION="local"  # local|global
INSTALL_LOCATION_EXPLICIT=false
INSTALL_DIR_EXPLICIT=false

TMP_JSON=""

# MCP recommendation checks (populated from registry.jsonc -> components.mcps)
MCP_RECOMMENDATIONS=()
MCP_CONFIG_FILES=()

#------------------------------------------------------------------------------
# Output styling helpers
#------------------------------------------------------------------------------
# Styling (colors enabled only in interactive TTY sessions)
RED=""; GREEN=""; SUCCESS=""; YELLOW=""; BLUE=""; MAGENTA=""; CYAN=""; BOLD=""; DIM=""; NC=""
COLOR_ENABLED=false

cleanup() {
  if [ -n "${TMP_JSON}" ] && [ -f "${TMP_JSON}" ]; then
    rm -f "${TMP_JSON}" 2>/dev/null || true
  fi

  # Clean up downloaded registry file when running via curl
  if [ -n "${RAW_URL}" ] && [ -n "${REGISTRY_JSONC}" ] && [ -f "${REGISTRY_JSONC}" ]; then
    rm -f "${REGISTRY_JSONC}" 2>/dev/null || true
  fi
}

trap cleanup EXIT

# If the user hits Ctrl+C, abort immediately (after cleanup).
trap 'cleanup; exit 130' INT

# Termination signal: abort (after cleanup).
trap 'cleanup; exit 143' TERM

usage() {
  cat <<'EOF'
Usage: ./install.sh [--skip|--overwrite|--backup] [--into <dir>] [--install-location local|global] [--install-dir <path>] [--skip-postinstall] [--interactive|--non-interactive-all|--non-interactive-agents]

Installs agents and subagents from registry.jsonc into:
  <install>/agents/           (primary agents)
  <install>/agents/subagent/  (subagents)

Options:
  --skip       Do not overwrite existing files (default)
  --overwrite  Overwrite existing files (no backup)
  --backup     Backup colliding files then overwrite
  --into <dir> Set project root (used for .gitignore + opencode.jsonc); directory must exist
  --install-location local|global  Install destination (default: local)
  --install-dir <path>            Install destination directory (custom; overrides --install-location)
  --interactive     Force interactive prompts
  --skip-postinstall Skip all post-install steps (interactive only)
  --non-interactive-all    Do not prompt; install agents + other components (suitable for CI)
  --non-interactive-agents Do not prompt; install agents only (suitable for CI)
  --non-interactive        Alias for --non-interactive-all

Env:
  REGISTRY_JSONC       Path to registry.jsonc (default: ./registry.jsonc)
  OPENCODE_INSTALL_DIR Install destination directory (default: <target>/.opencode)
  OPENCODE_TARGET_DIR  Project root directory (default: cwd)
  OPENCODE_RAW_URL     Base URL for remote file downloads (default: https://raw.githubusercontent.com/sina96/OpenNexus-Agents/main)
EOF
}

global_install_dir() {
  # User-wide install location (kept consistent across platforms).
  if [ -n "${HOME:-}" ]; then
    printf "%s" "${HOME}/.config/opencode"
  else
    # Fallback: avoid a broken path when HOME isn't set.
    printf "%s" "${TARGET_DIR}/.opencode"
  fi
}

expand_install_path() {
  # Best-effort path normalization:
  # - expands leading ~
  # - removes trailing slashes
  # - makes relative paths absolute (from current working directory)
  local p="$1"
  [ -z "${p:-}" ] && printf "%s" "" && return 1

  if [[ "$p" == ~* ]]; then
    p="${HOME:-}${p:1}"
  fi

  while [ "${p%/}" != "$p" ]; do p="${p%/}"; done

  if [[ "$p" != /* ]]; then
    p="$(pwd)/${p}"
  fi

  printf "%s" "$p"
}

init_styles() {
  # Enable ANSI colors only when:
  # - interactive
  # - running in a TTY
  # - terminal isn't dumb
  # - NO_COLOR isn't set
  if [ "${INTERACTIVE}" = true ] && is_tty && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    SUCCESS=$'\033[1;32m'
    YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'
    MAGENTA=$'\033[0;35m'
    CYAN=$'\033[0;36m'
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    NC=$'\033[0m'
    COLOR_ENABLED=true
  fi
}

print_err() {
  if [ "$COLOR_ENABLED" = true ]; then
    printf "%s%sERROR%s %s\n" "$RED" "$BOLD" "$NC" "$*" >&2
  else
    printf "Error: %s\n" "$*" >&2
  fi
}

print_info() {
  if [ "$COLOR_ENABLED" = true ]; then
    printf "%sINFO%s  %s\n" "$BLUE" "$NC" "$*" >&2
  else
    printf "info  %s\n" "$*" >&2
  fi
}

print_success() {
  if [ "$COLOR_ENABLED" = true ]; then
    printf "%s%sOK%s    %s\n" "$SUCCESS" "$BOLD" "$NC" "$*" >&2
  else
    printf "ok    %s\n" "$*" >&2
  fi
}

print_warn() {
  if [ "$COLOR_ENABLED" = true ]; then
    printf "%sWARN%s  %s\n" "$YELLOW" "$NC" "$*" >&2
  else
    printf "warn  %s\n" "$*" >&2
  fi
}

print_step() {
  # print_step "Title"
  echo "" >&2
  if [ "$COLOR_ENABLED" = true ]; then
    printf "%s%s==>%s %s\n" "$MAGENTA" "$BOLD" "$NC" "$1" >&2
  else
    printf "==> %s\n" "$1" >&2
  fi
}

print_header() {
  if [ "$COLOR_ENABLED" = true ]; then
    printf "%s%s============================================================%s\n" "$CYAN" "$BOLD" "$NC" >&2
    printf "%s%sOpenNexus Local Installer%s\n" "$CYAN" "$BOLD" "$NC" >&2
    printf "%sRepo:%s %s\n" "$DIM" "$NC" "$(basename "$SCRIPT_DIR")" >&2
    printf "%sPath:%s %s\n" "$DIM" "$NC" "$SCRIPT_DIR" >&2
    printf "%s%s============================================================%s\n" "$CYAN" "$BOLD" "$NC" >&2
  else
    printf "============================================================\n" >&2
    printf "OpenNexus Local Installer\n" >&2
    printf "Repo: %s\n" "$(basename "$SCRIPT_DIR")" >&2
    printf "Path: %s\n" "$SCRIPT_DIR" >&2
    printf "============================================================\n" >&2
  fi
}

stage_start() {
  # stage_start "Title"
  # Clears the screen (if available) and prints the banner before stage output.
  command -v clear >/dev/null 2>&1 && clear || true
  print_header
  print_step "$1"
}

print_ascii_banner() {
  command -v clear >/dev/null 2>&1 && clear || true
  cat <<'ASCII'
M"""""""`YM M""MMMM""M MP""""""`MM 
M  mmmm.  M M  `MM'  M M  mmmmm..M 
M  MMMMM  M MM.    .MM M.      `YM 
M  MMMMM  M M  .mm.  M MMMMMMM.  M 
M  MMMMM  M M  MMMM  M M. .MMM'  M 
M  MMMMM  M M  MMMM  M Mb.     .dM 
MMMMMMMMMMM MMMMMMMMMM MMMMMMMMMMM 
                                   
    OpenNexus Agents v. 0.1.0                        
ASCII
}

#------------------------------------------------------------------------------
# Dependency checks and JSONC parsing
#------------------------------------------------------------------------------
check_bash_version() {
  if [ -z "${BASH_VERSION:-}" ]; then
    print_err "this installer must be run with bash"
    print_info "try: bash install.sh"
    exit 1
  fi

  # Require bash 3.2+ (macOS default bash is 3.2).
  local major minor
  major="${BASH_VERSINFO[0]:-0}"
  minor="${BASH_VERSINFO[1]:-0}"
  if [ "$major" -lt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -lt 2 ]; }; then
    print_err "bash 3.2+ required (found: ${BASH_VERSION})"
    exit 1
  fi
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    print_err "missing required dependency: $1"
    return 1
  fi
}

check_dependencies() {
  check_bash_version

  local missing=()

  command -v jq >/dev/null 2>&1 || missing+=("jq")
  command -v opencode >/dev/null 2>&1 || missing+=("opencode")

  if [ ${#missing[@]} -ne 0 ]; then
    print_err "missing dependencies: ${missing[*]}"
    echo "" >&2
    echo "Install hints:" >&2
    echo "  - jq: https://jqlang.org/download/" >&2
    echo "  - opencode: https://opencode.ai/docs/" >&2
    echo "" >&2
    exit 1
  fi
}

jsonc_to_json() {
  # Best-effort JSONC -> JSON conversion.
  # Strips // line comments and /* */ blocks outside of strings.
  # Also removes trailing commas (outside of strings).
  local in="$1"
  local out="$2"

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$in" "$out" <<'PY'
import sys

src = open(sys.argv[1], 'r', encoding='utf-8').read()

out = []
i = 0
n = len(src)
in_str = False
esc = False
while i < n:
    c = src[i]
    if in_str:
        out.append(c)
        if esc:
            esc = False
        elif c == '\\':
            esc = True
        elif c == '"':
            in_str = False
        i += 1
        continue

    # not in string
    if c == '"':
        in_str = True
        out.append(c)
        i += 1
        continue

    # line comment
    if c == '/' and i + 1 < n and src[i+1] == '/':
        i += 2
        while i < n and src[i] not in '\r\n':
            i += 1
        continue

    # block comment
    if c == '/' and i + 1 < n and src[i+1] == '*':
        i += 2
        while i + 1 < n and not (src[i] == '*' and src[i+1] == '/'):
            i += 1
        i += 2 if i + 1 < n else 0
        continue

    out.append(c)
    i += 1

no_comments = ''.join(out)

# Remove trailing commas outside of strings: ", ]" or ", }" => "]" / "}"
res = []
i = 0
n = len(no_comments)
in_str = False
esc = False
while i < n:
    c = no_comments[i]
    if in_str:
        res.append(c)
        if esc:
            esc = False
        elif c == '\\':
            esc = True
        elif c == '"':
            in_str = False
        i += 1
        continue

    if c == '"':
        in_str = True
        res.append(c)
        i += 1
        continue

    if c == ',':
        j = i + 1
        while j < n and no_comments[j] in ' \t\r\n':
            j += 1
        if j < n and no_comments[j] in ']}':
            i += 1
            continue

    res.append(c)
    i += 1

open(sys.argv[2], 'w', encoding='utf-8').write(''.join(res))
PY
    return 0
  fi

  if command -v python >/dev/null 2>&1; then
    python - "$in" "$out" <<'PY'
import sys

src = open(sys.argv[1], 'r').read()
out = []
i = 0
n = len(src)
in_str = False
esc = False
while i < n:
    c = src[i]
    if in_str:
        out.append(c)
        if esc:
            esc = False
        elif c == '\\':
            esc = True
        elif c == '"':
            in_str = False
        i += 1
        continue
    if c == '"':
        in_str = True
        out.append(c)
        i += 1
        continue
    if c == '/' and i + 1 < n and src[i+1] == '/':
        i += 2
        while i < n and src[i] not in '\r\n':
            i += 1
        continue
    if c == '/' and i + 1 < n and src[i+1] == '*':
        i += 2
        while i + 1 < n and not (src[i] == '*' and src[i+1] == '/'):
            i += 1
        i += 2 if i + 1 < n else 0
        continue
    out.append(c)
    i += 1
no_comments = ''.join(out)

# Remove trailing commas outside of strings: ", ]" or ", }" => "]" / "}"
res = []
i = 0
n = len(no_comments)
in_str = False
esc = False
while i < n:
    c = no_comments[i]
    if in_str:
        res.append(c)
        if esc:
            esc = False
        elif c == '\\':
            esc = True
        elif c == '"':
            in_str = False
        i += 1
        continue
    if c == '"':
        in_str = True
        res.append(c)
        i += 1
        continue
    if c == ',':
        j = i + 1
        while j < n and no_comments[j] in ' \t\r\n':
            j += 1
        if j < n and no_comments[j] in ']}':
            i += 1
            continue
    res.append(c)
    i += 1

open(sys.argv[2], 'w').write(''.join(res))
PY
    return 0
  fi

  # Fallback: remove full-line // comments only.
  # (This is enough for the current registry.jsonc shape.)
  print_warn "python not found; JSONC support is limited (avoid trailing commas and /* */ block comments)"
  sed -e 's/^[[:space:]]*\/\/.*$//' "$in" > "$out"
}

#------------------------------------------------------------------------------
# CLI argument parsing and interactive prompts
#------------------------------------------------------------------------------
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --skip) STRATEGY="skip" ;;
      --overwrite) STRATEGY="overwrite" ;;
      --backup) STRATEGY="backup" ;;
      --into)
        shift
        if [ $# -eq 0 ] || [ -z "${1:-}" ]; then
          echo "Missing value for --into" >&2
          usage >&2
          exit 2
        fi
        TARGET_DIR="$1"
        ;;
      --install-location)
        shift
        if [ $# -eq 0 ] || [ -z "${1:-}" ]; then
          echo "Missing value for --install-location" >&2
          usage >&2
          exit 2
        fi
        case "$1" in
          local|global)
            INSTALL_LOCATION="$1"
            INSTALL_LOCATION_EXPLICIT=true
            ;;
          *)
            echo "Invalid value for --install-location: $1 (expected: local|global)" >&2
            usage >&2
            exit 2
            ;;
        esac
        ;;
      --install-dir)
        shift
        if [ $# -eq 0 ] || [ -z "${1:-}" ]; then
          echo "Missing value for --install-dir" >&2
          usage >&2
          exit 2
        fi
        INSTALL_DIR_OVERRIDE="$1"
        INSTALL_DIR_EXPLICIT=true
        ;;
      --interactive) INTERACTIVE=true ;;
      --skip-postinstall) SKIP_POSTINSTALL=true ;;
      --non-interactive-all)
        INTERACTIVE=false
        NON_INTERACTIVE_MODE="all"
        ;;
      --non-interactive-agents)
        INTERACTIVE=false
        NON_INTERACTIVE_MODE="agents"
        ;;
      --non-interactive)
        INTERACTIVE=false
        NON_INTERACTIVE_MODE="all"
        ;;
      -h|--help) usage; exit 0 ;;
      *)
        echo "Unknown argument: $1" >&2
        usage >&2
        exit 2
        ;;
    esac
    shift
  done
}

apply_install_location_defaults() {
  # Apply destination selection flags to INSTALL_DIR_OVERRIDE.
  # Precedence:
  # - --install-dir always wins
  # - otherwise, if --install-location is explicitly set, use that
  if [ "$INSTALL_DIR_EXPLICIT" = true ]; then
    INSTALL_DIR_OVERRIDE="$(expand_install_path "$INSTALL_DIR_OVERRIDE")"
    return 0
  fi

  if [ "$INSTALL_LOCATION_EXPLICIT" = true ]; then
    case "$INSTALL_LOCATION" in
      local) INSTALL_DIR_OVERRIDE="${TARGET_DIR}/.opencode" ;;
      global) INSTALL_DIR_OVERRIDE="$(global_install_dir)" ;;
    esac
  fi
}

is_tty() {
  [ -t 0 ] && [ -t 1 ]
}

prompt_yes_no() {
  # prompt_yes_no "Question" "default"(y/n)
  local q="$1"
  local def="${2:-n}"
  local suffix

  if [ "$def" = "y" ]; then
    suffix="[Y/n]"
  else
    suffix="[y/N]"
  fi

  while true; do
    if [ "$COLOR_ENABLED" = true ]; then
      printf "%s%s%s %s " "$BOLD" "$q" "$NC" "$suffix" >&2
    else
      printf "%s %s " "$q" "$suffix" >&2
    fi
    local ans
    IFS= read -r ans || ans=""
    ans="${ans:-}"
    # Ensure subsequent output starts on a new line.
    echo "" >&2
    if [ -z "$ans" ]; then
      [ "$def" = "y" ] && return 0
      return 1
    fi
    case "$ans" in
      y|Y|yes|YES) return 0 ;;
      n|N|no|NO) return 1 ;;
      *) echo "Please answer y or n." >&2 ;;
    esac
  done
}

prompt_choice() {
  # prompt_choice "Question" "1" "2" ...
  local q="$1"
  shift
  local options=("$@")

  while true; do
    if [ "$COLOR_ENABLED" = true ]; then
      printf "%s%s%s\n" "$BOLD" "$q" "$NC" >&2
    else
      printf "%s\n" "$q" >&2
    fi
    local i
    for i in "${!options[@]}"; do
      if [ "$COLOR_ENABLED" = true ]; then
        printf "  %s%2d)%s %s\n" "$CYAN" "$((i+1))" "$NC" "${options[$i]}" >&2
      else
        printf "  %2d) %s\n" "$((i+1))" "${options[$i]}" >&2
      fi
    done
    printf "Enter choice [1-%d] (default: 1): " "${#options[@]}" >&2
    local sel
    IFS= read -r sel || sel=""
    echo "" >&2
    case "$sel" in
      '' )
        echo "1"
        return 0
        ;;
      *[!0-9]* ) ;;
      * )
        if [ "$sel" -ge 1 ] && [ "$sel" -le "${#options[@]}" ]; then
          echo "$sel"
          return 0
        fi
        ;;
    esac
    echo "Invalid selection." >&2
  done
}

#------------------------------------------------------------------------------
# Collision detection and file copy/install helpers
#------------------------------------------------------------------------------
print_collision_group() {
  # print_collision_group "Agents" "path1" "path2" ...
  local label="$1"
  shift
  [ "$#" -eq 0 ] && return 0

  if [ "$COLOR_ENABLED" = true ]; then
    printf "%s  %s (%d):%s\n" "$YELLOW" "$label" "$#" "$NC" >&2
  else
    printf "  %s (%d):\n" "$label" "$#" >&2
  fi

  local p
  for p in "$@"; do
    printf "    - %s\n" "$p" >&2
  done
}

show_collision_report() {
  # show_collision_report "<newline separated absolute paths>"
  local collisions="$1"

  local -a agents=()
  local -a subagents=()
  local -a commands=()
  local -a tools=()
  local -a skills=()
  local -a plugins=()
  local -a other=()

  local p
  while IFS= read -r p; do
    [ -z "${p:-}" ] && continue
    case "$p" in
      "${SUBAGENTS_DIR}/"*) subagents+=("$p") ;;
      "${PRIMARY_AGENTS_DIR}/"*) agents+=("$p") ;;
      "${COMMANDS_DIR}/"*) commands+=("$p") ;;
      "${TOOLS_DIR}/"*) tools+=("$p") ;;
      "${SKILLS_DIR}/"*) skills+=("$p") ;;
      "${PLUGINS_DIR}/"*) plugins+=("$p") ;;
      *) other+=("$p") ;;
    esac
  done <<< "$collisions"

  local total
  total=$(( ${#agents[@]} + ${#subagents[@]} + ${#commands[@]} + ${#tools[@]} + ${#skills[@]} + ${#plugins[@]} + ${#other[@]} ))

  echo "" >&2
  if [ "$COLOR_ENABLED" = true ]; then
    printf "%sExisting files detected (%d collision(s)):%s\n" "$YELLOW" "$total" "$NC" >&2
  else
    printf "Existing files detected (%d collision(s)):\n" "$total" >&2
  fi

  # Guard array expansions under `set -u` even if an array was never set.
  print_collision_group "Agents" "${agents[@]:-}"
  print_collision_group "Subagents" "${subagents[@]:-}"
  print_collision_group "Commands" "${commands[@]:-}"
  print_collision_group "Tools" "${tools[@]:-}"
  print_collision_group "Skills" "${skills[@]:-}"
  print_collision_group "Plugins" "${plugins[@]:-}"
  print_collision_group "Other" "${other[@]:-}"
  echo "" >&2
}

confirm_overwrite_collisions() {
  # Returns 0 only if user types 'yes'.
  echo "" >&2
  print_warn "Overwrite selected: existing files will be replaced."
  printf "Type 'yes' to confirm overwrite: " >&2
  local ans
  IFS= read -r ans || ans=""
  echo "" >&2
  [ "$ans" = "yes" ]
}

collect_targets_for_category() {
  # collect_targets_for_category "commands" "$COMMANDS_DIR"
  # Prints absolute destination paths, one per line.
  local category="$1"
  local dest_dir="$2"

  local lines
  lines="$(jq -r ".components.${category}[]? | \"\\(.id)\\t\\(.path)\"" "$TMP_JSON" 2>/dev/null || true)"
  [ -z "$lines" ] && return 0

  while IFS=$'\t' read -r id path; do
    [ -z "${id:-}" ] && continue
    if [ "$category" = "skills" ]; then
      # Skills install as a directory: <skills>/<id>/SKILL.md
      echo "${dest_dir}/${id}/SKILL.md"
    else
      local ext
      ext="$(path_ext "$path")"
      echo "${dest_dir}/${id}.${ext}"
    fi
  done <<< "$lines"
}

detect_collisions() {
  # detect_collisions <install_other:true|false>
  # Prints colliding absolute file paths, one per line.
  local install_other="$1"

  local targets=()
  local t

  # Agents
  local agent_lines
  agent_lines="$(jq -r '.components.agents[]? | "\(.id)\t\(.path)"' "$TMP_JSON" 2>/dev/null || true)"
  if [ -n "$agent_lines" ]; then
    while IFS=$'\t' read -r id _path; do
      [ -z "${id:-}" ] && continue
      targets+=("${PRIMARY_AGENTS_DIR}/${id}.md")
    done <<< "$agent_lines"
  fi

  local subagent_lines
  subagent_lines="$(jq -r '.components.subagents[]? | "\(.id)\t\(.path)"' "$TMP_JSON" 2>/dev/null || true)"
  if [ -n "$subagent_lines" ]; then
    while IFS=$'\t' read -r id _path; do
      [ -z "${id:-}" ] && continue
      targets+=("${SUBAGENTS_DIR}/${id}.md")
    done <<< "$subagent_lines"
  fi

  if [ "$install_other" = "true" ]; then
    while IFS= read -r t; do [ -n "$t" ] && targets+=("$t"); done < <(collect_targets_for_category "commands" "$COMMANDS_DIR")
    while IFS= read -r t; do [ -n "$t" ] && targets+=("$t"); done < <(collect_targets_for_category "tools" "$TOOLS_DIR")
    while IFS= read -r t; do [ -n "$t" ] && targets+=("$t"); done < <(collect_targets_for_category "skills" "$SKILLS_DIR")
    while IFS= read -r t; do [ -n "$t" ] && targets+=("$t"); done < <(collect_targets_for_category "plugins" "$PLUGINS_DIR")
  fi

  for t in "${targets[@]}"; do
    if [ -f "$t" ]; then
      echo "$t"
    fi
  done
}

copy_one() {
  local src_rel="$1"
  local dest_name="$2"
  local dest_dir="$3"

  local dest_abs="${dest_dir}/${dest_name}"

  if [ -f "$dest_abs" ]; then
    case "$STRATEGY" in
      skip)
        echo "skip  $dest_abs"
        return 0
        ;;
      overwrite)
        :
        ;;
      backup)
        if [ -z "$BACKUP_DIR" ]; then
          local ts
          ts="$(date +%Y%m%d-%H%M%S)"
          BACKUP_DIR="${INSTALL_DIR}/backup-${ts}"
        fi
        local rel_dir
        rel_dir="${dest_dir#${INSTALL_DIR}/}"
        mkdir -p "${BACKUP_DIR}/${rel_dir}"
        cp -p "$dest_abs" "${BACKUP_DIR}/${rel_dir}/$(basename "$dest_abs")"
        echo "backup ${dest_abs} -> ${BACKUP_DIR}/${rel_dir}/$(basename "$dest_abs")"
        ;;
    esac
  fi

  mkdir -p "$(dirname "$dest_abs")"

  # When running via curl | bash, download from GitHub raw URLs
  if [ -n "${RAW_URL}" ]; then
    local url="${RAW_URL}/${src_rel}"
    if ! curl -fsSL "$url" -o "$dest_abs"; then
      echo "Error: failed to download: $url" >&2
      return 1
    fi
  else
    # Local execution: copy from local filesystem
    local src_abs="${SCRIPT_DIR}/${src_rel}"
    if [ ! -f "$src_abs" ]; then
      echo "Error: source file not found: $src_rel" >&2
      return 1
    fi
    cp -p "$src_abs" "$dest_abs"
  fi

  echo "install ${dest_abs}"
}

ensure_dir() {
  mkdir -p "$1"
}

ensure_gitkeep_if_empty() {
  local dir="$1"
  local is_empty="$2"

  ensure_dir "$dir"
  if [ "$is_empty" = "true" ]; then
    # Keep the directory tracked/created even when no components exist yet.
    # If you don't want .gitkeep committed, you can ignore it later.
    : > "${dir}/.gitkeep"
  fi
}

registry_len_is_zero() {
  # registry_len_is_zero ".components.commands"
  local jq_path="$1"
  jq -e "(${jq_path} // []) | length == 0" "$TMP_JSON" >/dev/null 2>&1
}

path_ext() {
  local p="$1"
  if [[ "$p" == *.* ]]; then
    echo "${p##*.}"
  else
    echo "md"
  fi
}

install_category() {
  # install_category "commands" "$COMMANDS_DIR"
  local category="$1"
  local dest_dir="$2"

  local lines
  lines="$(jq -r ".components.${category}[]? | \"\\(.id)\\t\\(.path)\"" "$TMP_JSON")"
  if [ -z "$lines" ]; then
    return 0
  fi

  local installed_any=false
  while IFS=$'\t' read -r id path; do
    [ -z "${id:-}" ] && continue
    local ext
    ext="$(path_ext "$path")"
    copy_one "$path" "${id}.${ext}" "$dest_dir"
    installed_any=true
  done <<< "$lines"

  if [ "$installed_any" = true ]; then
    rm -f "${dest_dir}/.gitkeep" 2>/dev/null || true
  fi
}

install_skills() {
  # Installs skills as directories: .opencode/skills/<id>/...
  # Each registry entry path typically points to: core/skills/<id>/SKILL.md
  local lines
  lines="$(jq -r ".components.skills[]? | \"\\(.id)\\t\\(.path)\"" "$TMP_JSON" 2>/dev/null || true)"
  if [ -z "$lines" ]; then
    return 0
  fi

  local installed_any=false
  local id path
  while IFS=$'\t' read -r id path; do
    [ -z "${id:-}" ] && continue
    [ -z "${path:-}" ] && continue

    local src_dir_rel
    src_dir_rel="${path%/*}"
    local dest_root
    dest_root="${SKILLS_DIR}/${id}"

    if [ -n "${RAW_URL}" ]; then
      # Remote mode: download known skill files (SKILL.md and optional codemaps.md)
      copy_one "${src_dir_rel}/SKILL.md" "SKILL.md" "$dest_root" && installed_any=true
      # Try to download codemaps.md if it exists (best effort)
      curl -fsSL "${RAW_URL}/${src_dir_rel}/codemaps.md" -o "${dest_root}/codemaps.md" 2>/dev/null || true
    else
      # Local mode: copy all files from the skill directory
      local src_dir_abs
      src_dir_abs="${SCRIPT_DIR}/${src_dir_rel}"
      if [ ! -d "$src_dir_abs" ]; then
        print_err "skill source directory not found: ${src_dir_rel}"
        return 1
      fi

      local f rel src_rel dest_dir dest_name
      while IFS= read -r f; do
        [ -z "${f:-}" ] && continue
        rel="${f#${src_dir_abs}/}"
        src_rel="${f#${SCRIPT_DIR}/}"
        dest_dir="${dest_root}/$(dirname "$rel")"
        dest_name="$(basename "$rel")"
        copy_one "$src_rel" "$dest_name" "$dest_dir"
        installed_any=true
      done < <(find "$src_dir_abs" -type f -print)
    fi
  done <<< "$lines"

  if [ "$installed_any" = true ]; then
    rm -f "${SKILLS_DIR}/.gitkeep" 2>/dev/null || true
  fi
}

#------------------------------------------------------------------------------
# Model recommendation validation (interactive only)
#------------------------------------------------------------------------------

# Cached list of known models from models.dev for validation.
# Entry format: <provider>|<model_id>
LATEST_MODELS=()
LATEST_MODELS_READY=false

fetch_latest_models() {
  # Populates LATEST_MODELS from https://models.dev/api.json (best-effort).
  # This is used to detect stale model recommendations in registry.jsonc.
  [ "$LATEST_MODELS_READY" = true ] && return 0

  local api_url="https://models.dev/api.json"
  local api_response=""

  if command -v curl >/dev/null 2>&1; then
    api_response="$(curl -fsSL "$api_url" 2>/dev/null || true)"
  elif command -v python3 >/dev/null 2>&1; then
    api_response="$(python3 - <<'PY' 2>/dev/null || true
import sys, urllib.request
try:
  print(urllib.request.urlopen('https://models.dev/api.json', timeout=10).read().decode('utf-8'))
except Exception:
  pass
PY
    )"
  fi

  if [ -z "$api_response" ]; then
    return 1
  fi

  local providers=("anthropic" "openai" "opencode" "google" "synthetic" "openrouter")
  local provider

  LATEST_MODELS=()
  for provider in "${providers[@]}"; do
    # The API contains many models; store ids for existence checks.
    local ids
    ids="$(printf "%s" "$api_response" | jq -r ".${provider}.models | to_entries[]? | .value.id" 2>/dev/null || true)"
    [ -z "$ids" ] && continue
    local id
    while IFS= read -r id; do
      [ -z "${id:-}" ] && continue
      LATEST_MODELS+=("${provider}|${id}")
    done <<< "$ids"
  done

  if [ "${#LATEST_MODELS[@]}" -eq 0 ]; then
    return 1
  fi

  LATEST_MODELS_READY=true
  return 0
}

model_exists() {
  # model_exists <models_dev_provider> <model_id>
  local provider="$1"
  local model_id="$2"
  local entry
  for entry in "${LATEST_MODELS[@]}"; do
    if [ "$entry" = "${provider}|${model_id}" ]; then
      return 0
    fi
  done
  return 1
}

modelsdev_provider_for() {
  # Map local provider keys (used in registry.jsonc) to models.dev provider ids.
  local provider_key="$1"
  case "$provider_key" in
    claude-pro|claude-max) echo "anthropic" ;;
    openai) echo "openai" ;;
    opencode-zed) echo "opencode" ;;
    opencode) echo "opencode" ;;
    google) echo "google" ;;
    synthetic) echo "synthetic" ;;
    openrouter) echo "openrouter" ;;
    *) echo "" ;;
  esac
}

model_id_from_recommendation() {
  # model_id_from_recommendation "anthropic/claude-..." -> "claude-..."
  local rec="$1"
  if [[ "$rec" == *"/"* ]]; then
    echo "${rec#*/}"
  else
    echo "$rec"
  fi
}

model_provider_from_recommendation() {
  # model_provider_from_recommendation "anthropic/claude-..." -> "anthropic"
  local rec="$1"
  if [[ "$rec" == *"/"* ]]; then
    echo "${rec%%/*}"
  else
    echo ""
  fi
}

modelsdev_provider_for_model_ref() {
  # Maps a provider/model ref prefix to a models.dev provider id.
  local provider="$1"
  case "$provider" in
    anthropic|openai|opencode|google|synthetic|openrouter) echo "$provider" ;;
    *) echo "" ;;
  esac
}

model_ref_exists() {
  # model_ref_exists "opencode/big-pickle" -> checks models.dev for provider/model.
  local rec="$1"
  local provider
  provider="$(model_provider_from_recommendation "$rec")"
  local model_id
  model_id="$(model_id_from_recommendation "$rec")"

  local modelsdev_provider
  modelsdev_provider="$(modelsdev_provider_for_model_ref "$provider")"
  [ -z "$modelsdev_provider" ] && return 2

  model_exists "$modelsdev_provider" "$model_id"
}

warn_unvalidated_model_recommendation() {
  # Keep wording stable for users.
  # Usage: warn_unvalidated_model_recommendation "<recommendation>"
  local rec="$1"
  print_warn "could not validate this model via models.dev could be outdated but we recommend: ${rec}"
}

provider_recommendations_are_current() {
  # provider_recommendations_are_current <provider_key>
  # Returns:
  #  - 0: OK (no stale models detected)
  #  - 1: stale model detected
  #  - 2: nothing to validate (no recommendations set)
  #  - 3: cannot validate (provider not supported by models.dev mapping)
  local provider_key="$1"
  local modelsdev_provider
  modelsdev_provider="$(modelsdev_provider_for "$provider_key")"
  [ -z "$modelsdev_provider" ] && return 3

  local recs
  recs="$(jq -r --arg provider "$provider_key" '.components.agents[]? | (."model-recommendation"[$provider] // "")' "$TMP_JSON" 2>/dev/null | awk 'NF' | sort -u)"
  [ -z "$recs" ] && return 2

  local rec
  while IFS= read -r rec; do
    [ -z "${rec:-}" ] && continue
    local model_id
    model_id="$(model_id_from_recommendation "$rec")"
    if ! model_exists "$modelsdev_provider" "$model_id"; then
      return 1
    fi
  done <<< "$recs"

  return 0
}

show_model_recommendations() {
  # Uses provider selections to print recommended models from registry.jsonc.
  if [ "${#SELECTED_PROVIDERS[@]}" -eq 0 ]; then
    # Provider selection was skipped. Fall back to free model
    # recommendations (if configured) so users still get a runnable baseline.
    echo "" >&2
    echo "Model recommendations: (providers not configured)" >&2

    local can_validate=false
    if fetch_latest_models; then
      can_validate=true
    else
      print_warn "Could not fetch latest models from models.dev; free model recommendations are unvalidated"
    fi

    print_warn "Free model recommendations: use with your own risk (can be used to train data etc)"

    local lines
    # free-model-recommendation supports either:
    # - string: "opencode/minimax-m2.1-free"
    # - object: {"opencode": "minimax-m2.1-free"} or {"opencode": "opencode/minimax-m2.1-free"}
    # Normalize object entries into provider/model string refs for validation.
    lines="$(jq -r '
      .components.agents[]? | .id as $id |
      (."free-model-recommendation" // empty) as $rec |
      if ($rec|type) == "string" then
        "\($id)\t\($rec)"
      elif ($rec|type) == "object" then
        ($rec | to_entries[]? | . as $e |
          "\($id)\t" +
          (if ($e.value|type) == "string" then
             (if ($e.value|test("/")) then $e.value else "\($e.key)/\($e.value)" end)
           else
             ""
           end)
        )
      else
        empty
      end
    ' "$TMP_JSON" 2>/dev/null || true)"
    if [ -z "$lines" ]; then
      echo "  (no free model recommendations found in registry)" >&2
      return 0
    fi

    local any=false
    local id rec
    while IFS=$'\t' read -r id rec; do
      [ -z "${id:-}" ] && continue
      [ -z "${rec:-}" ] && continue

      any=true

      if [ "$can_validate" = true ]; then
        if model_ref_exists "$rec"; then
          echo "  ${id}: ${rec}" >&2
        else
          local rc=$?
          if [ "$rc" -eq 2 ]; then
            warn_unvalidated_model_recommendation "${id}: ${rec}"
          else
            print_warn "Skipping free model for ${id}: recommendation is outdated ('${rec}' not found on models.dev)"
          fi
        fi
      else
        warn_unvalidated_model_recommendation "${id}: ${rec}"
      fi
    done <<< "$lines"

    if [ "$any" = false ]; then
      echo "  (no free model recommendations set)" >&2
      echo "Tip: add 'free-model-recommendation' to each primary agent in registry.jsonc." >&2
    fi

    return 0
  fi

  local can_validate=false
  if fetch_latest_models; then
    can_validate=true
  else
    print_warn "Could not fetch latest models from models.dev; provider recommendations are unvalidated"
  fi

  # Decide which providers to show (skip only if we can prove recommendations are stale).
  local -a providers_to_print=()
  local -a providers_unvalidated=()
  local provider
  for provider in "${SELECTED_PROVIDERS[@]:-}"; do
    if [ "$can_validate" = true ]; then
      local modelsdev_provider
      modelsdev_provider="$(modelsdev_provider_for "$provider")"
      if [ -z "$modelsdev_provider" ]; then
        providers_unvalidated+=("$provider")
        providers_to_print+=("$provider")
        continue
      fi

      if provider_recommendations_are_current "$provider"; then
        providers_to_print+=("$provider")
      else
        local rc=$?
        if [ "$rc" -eq 1 ]; then
          print_warn "Model recommendations are outdated for provider '${provider}'; skipping"
        else
          # rc 2: nothing set; still allow showing (so user sees '(not set)').
          providers_to_print+=("$provider")
        fi
      fi
    else
      providers_unvalidated+=("$provider")
      providers_to_print+=("$provider")
    fi
  done

  if [ "${#providers_to_print[@]}" -eq 0 ]; then
    echo "" >&2
    echo "Model recommendations: (skipped; all selected providers appear outdated)" >&2
    return 0
  fi

  provider_is_unvalidated() {
    local p="$1"
    local x
    for x in "${providers_unvalidated[@]:-}"; do
      [ "$x" = "$p" ] && return 0
    done
    return 1
  }

  echo "" >&2
  echo "Model recommendations (from registry.jsonc):" >&2

  local agent_ids
  agent_ids="$(jq -r '.components.agents[]? | .id' "$TMP_JSON")"
  if [ -z "$agent_ids" ]; then
    echo "  (no agents found in registry)" >&2
    return 0
  fi

  local id
  while IFS= read -r id; do
    [ -z "${id:-}" ] && continue
    echo "  ${id}:" >&2
    for provider in "${providers_to_print[@]}"; do
      local model
      model="$(jq -r ".components.agents[]? | select(.id == \"${id}\") | (.\"model-recommendation\"[\"${provider}\"] // \"\")" "$TMP_JSON")"
      if [ -n "$model" ]; then
        if provider_is_unvalidated "$provider"; then
          warn_unvalidated_model_recommendation "${provider}: ${model}"
        else
          echo "    ${provider}: ${model}" >&2
        fi
      else
        echo "    ${provider}: (not set)" >&2
      fi
    done
  done <<< "$agent_ids"
}

SELECTED_PROVIDERS=()

mcp_var_name() {
  # mcp_var_name "context7" -> MCP_HAS_CONTEXT7
  local id="$1"
  local up
  up="$(printf "%s" "$id" | tr '[:lower:]' '[:upper:]' | sed -e 's/[^A-Z0-9]/_/g')"
  if [[ "$up" =~ ^[0-9] ]]; then
    up="_${up}"
  fi
  echo "MCP_HAS_${up}"
}

init_mcp_recommendation_vars() {
  # Creates global (non-local) variables for each recommended MCP.
  # Example: MCP_HAS_CONTEXT7=false
  MCP_RECOMMENDATIONS=()

  local ids
  ids="$(jq -r '.components.mcps[]?' "$TMP_JSON" 2>/dev/null || true)"
  [ -z "$ids" ] && return 0

  local id
  while IFS= read -r id; do
    [ -z "${id:-}" ] && continue
    MCP_RECOMMENDATIONS+=("$id")
    local var
    var="$(mcp_var_name "$id")"
    printf -v "$var" "%s" "false"
  done <<< "$ids"
}

collect_mcp_config_files() {
  # Local (project) + global config files.
  MCP_CONFIG_FILES=()

  local p
  for p in "${TARGET_DIR}/opencode.json" "${TARGET_DIR}/opencode.jsonc"; do
    [ -f "$p" ] && MCP_CONFIG_FILES+=("$p")
  done

  local home_cfg_dir
  home_cfg_dir="${HOME:-}/.config/opencode"
  for p in "${home_cfg_dir}/opencode.json" "${home_cfg_dir}/opencode.jsonc"; do
    [ -f "$p" ] && MCP_CONFIG_FILES+=("$p")
  done
}

config_has_mcp() {
  # config_has_mcp <json-file> <mcp-id>
  local json_file="$1"
  local mcp_id="$2"
  jq -e --arg id "$mcp_id" '(.mcp? // null) != null and ((.mcp|type) == "object") and (.mcp|has($id))' "$json_file" >/dev/null 2>&1
}

check_installed_mcps() {
  # Sets MCP_HAS_* variables to true if found in local/global config files.
  [ "${#MCP_RECOMMENDATIONS[@]}" -eq 0 ] && return 0

  collect_mcp_config_files
  if [ "${#MCP_CONFIG_FILES[@]}" -eq 0 ]; then
    print_info "No local/global OpenCode config found; skipping MCP detection"
    return 0
  fi

  local cfg
  for cfg in "${MCP_CONFIG_FILES[@]}"; do
    local tmp_cfg
    tmp_cfg="$(mktemp -t opencode-config.XXXXXX.json)"

    # Best-effort JSONC -> JSON for jq.
    # IMPORTANT: MCP detection must never abort the installer.
    local parse_ok=false
    if (set +e; jsonc_to_json "$cfg" "$tmp_cfg") >/dev/null 2>&1; then
      if jq -e '.' "$tmp_cfg" >/dev/null 2>&1; then
        parse_ok=true
      else
        print_warn "Could not parse config as JSON/JSONC: ${cfg}; falling back to text search"
      fi
    else
      print_warn "Could not read/convert config: ${cfg}; falling back to text search"
    fi

    local id
    for id in "${MCP_RECOMMENDATIONS[@]}"; do
      local var
      var="$(mcp_var_name "$id")"

      # If already true from a prior file, keep it true.
      if [ "${!var:-false}" = "true" ]; then
        continue
      fi

      if [ "$parse_ok" = true ]; then
        if config_has_mcp "$tmp_cfg" "$id"; then
          printf -v "$var" "%s" "true"
        fi
      else
        # Text fallback: look for an mcp block and the MCP id as a key.
        if grep -Eqs '"mcp"[[:space:]]*:' "$cfg" && grep -Eqs '"'"$id"'"[[:space:]]*:' "$cfg"; then
          printf -v "$var" "%s" "true"
        fi
      fi
    done

    rm -f "$tmp_cfg" 2>/dev/null || true
  done
}

interactive_mcp_preinstall() {
  # Ask user approval, then check local/global config for recommended MCPs.
  if [ "${#MCP_RECOMMENDATIONS[@]}" -eq 0 ]; then
    return 0
  fi

  echo "" >&2
  if [ "$COLOR_ENABLED" = true ]; then
    printf "%s%sMCP servers%s\n" "$BOLD" "$CYAN" "$NC" >&2
  else
    printf "MCP servers\n" >&2
  fi
  printf "%s\n" "We can check your local/global OpenCode config for recommended MCP servers (used for agent creation & recommendations)." >&2

  if prompt_yes_no "Check installed MCP servers now?" "n"; then
    if ! (set +e; check_installed_mcps); then
      print_warn "MCP detection failed; continuing install"
      return 0
    fi

    echo "" >&2
    print_info "MCP detection results:"
    local id
    for id in "${MCP_RECOMMENDATIONS[@]}"; do
      local var
      var="$(mcp_var_name "$id")"
      if [ "${!var:-false}" = "true" ]; then
        echo "  - ${id}: found" >&2
      else
        echo "  - ${id}: not found" >&2
      fi
    done
  else
    print_info "Skipping MCP detection"
  fi
}

interactive_preinstall() {
  print_ascii_banner
  sleep 1
  stage_start "Pre-install"
  print_info "Checking dependencies"
  check_dependencies

  # Install destination chooser (default: local).
  # If destination flags were provided, apply them and do not prompt.
  apply_install_location_defaults
  if [ "$INSTALL_DIR_EXPLICIT" = true ] || [ "$INSTALL_LOCATION_EXPLICIT" = true ]; then
    set_install_paths
    print_info "Install destination set via flags: ${INSTALL_DIR}"
    print_info "Project root (for .gitignore/opencode.jsonc): ${TARGET_DIR}"
    print_success "Pre-install complete"
    sleep 1
    return 0
  fi

  echo "" >&2
  if [ "$COLOR_ENABLED" = true ]; then
    printf "%s%sInstall location%s\n" "$BOLD" "$CYAN" "$NC" >&2
  else
    printf "Install location\n" >&2
  fi
  printf "%s\n" "Choose where to install OpenCode components." >&2
  printf "%s\n" "(Project root stays ${TARGET_DIR} for .gitignore/opencode.jsonc updates.)" >&2

  local global_path
  global_path="$(global_install_dir)"

  while true; do
    local choice
    choice="$(prompt_choice "Where should components be installed?" \
      "Local (project): ${TARGET_DIR}/.opencode" \
      "Global (user): ${global_path}" \
      "Custom directory" \
      "Cancel")"
    case "$choice" in
      1)
        INSTALL_DIR_OVERRIDE="${TARGET_DIR}/.opencode"
        INSTALL_LOCATION="local"
        INSTALL_LOCATION_EXPLICIT=true
        break
        ;;
      2)
        INSTALL_DIR_OVERRIDE="$global_path"
        INSTALL_LOCATION="global"
        INSTALL_LOCATION_EXPLICIT=true
        break
        ;;
      3)
        echo "" >&2
        printf "Enter install directory path: " >&2
        local custom
        IFS= read -r custom || custom=""
        echo "" >&2

        if [ -z "${custom:-}" ]; then
          print_warn "No path entered"
          continue
        fi

        custom="$(expand_install_path "$custom")"
        if [ -e "$custom" ] && [ ! -d "$custom" ]; then
          print_warn "Path exists and is not a directory: ${custom}"
          continue
        fi

        local parent
        parent="$(dirname "$custom")"
        if [ ! -d "$parent" ]; then
          print_warn "Parent directory does not exist: ${parent}"
          continue
        fi
        if [ ! -w "$parent" ]; then
          print_warn "No write permission in parent directory: ${parent}"
          continue
        fi

        INSTALL_DIR_OVERRIDE="$custom"
        INSTALL_DIR_EXPLICIT=true
        break
        ;;
      4)
        print_info "Cancelled"
        exit 0
        ;;
    esac
  done

  set_install_paths
  print_info "Install destination: ${INSTALL_DIR}"
  print_success "Pre-install complete"
  sleep 1
}

prepare_install_dirs() {
  # Must be called after TMP_JSON is ready + set_install_paths.
  ensure_dir "$INSTALL_DIR"
  ensure_dir "$PRIMARY_AGENTS_DIR"
  ensure_dir "$SUBAGENTS_DIR"
  ensure_dir "$COMMANDS_DIR"
  ensure_dir "$TOOLS_DIR"
  ensure_dir "$SKILLS_DIR"
  ensure_dir "$PLUGINS_DIR"

  # Create placeholder directories for non-MCP components.
  # If a section is empty, create a .gitkeep.
  ensure_gitkeep_if_empty "$COMMANDS_DIR" "$(registry_len_is_zero '.components.commands' && echo true || echo false)"
  ensure_gitkeep_if_empty "$TOOLS_DIR" "$(registry_len_is_zero '.components.tools' && echo true || echo false)"
  ensure_gitkeep_if_empty "$SKILLS_DIR" "$(registry_len_is_zero '.components.skills' && echo true || echo false)"
  ensure_gitkeep_if_empty "$PLUGINS_DIR" "$(registry_len_is_zero '.components.plugins' && echo true || echo false)"
}

interactive_install() {
  stage_start "Install"

  local agents_count subagents_count
  agents_count="$(jq -r '(.components.agents // []) | length' "$TMP_JSON" 2>/dev/null || echo 0)"
  subagents_count="$(jq -r '(.components.subagents // []) | length' "$TMP_JSON" 2>/dev/null || echo 0)"

  if [ "$COLOR_ENABLED" = true ]; then
    printf "%sWill install:%s %s%s agents%s, %s%s subagents%s\n" "$BOLD" "$NC" "$GREEN" "$agents_count" "$NC" "$GREEN" "$subagents_count" "$NC" >&2
  else
    printf "Will install: %s agents, %s subagents\n" "$agents_count" "$subagents_count" >&2
  fi

  local install_other=false
  if prompt_yes_no "Also install other components (commands/tools/skills/plugins)?" "n"; then
    install_other=true
  fi

  # Collision check (selected components only)
  local collisions
  collisions="$(detect_collisions "$install_other")"
  if [ -n "$collisions" ]; then
    show_collision_report "$collisions"

    local choice
    choice="$(prompt_choice "How should the installer handle existing files?" "Skip existing files" "Overwrite existing files" "Backup then overwrite (recommended)" "Cancel")"
    case "$choice" in
      1) STRATEGY="skip" ;;
      2)
        if confirm_overwrite_collisions; then
          STRATEGY="overwrite"
        else
          print_info "Cancelled"
          exit 0
        fi
        ;;
      3) STRATEGY="backup" ;;
      4) print_info "Cancelled"; exit 0 ;;
    esac
  fi

  echo "" >&2
  print_info "Installing"

  # Agents always install
  install_agents

  if [ "$install_other" = true ]; then
    install_other_components
  fi

  print_success "Install complete"
  sleep 1
}

ensure_gitignore_entry() {
  local entry="$1"
  local gitignore_path="${TARGET_DIR}/.gitignore"

  if [ ! -f "$gitignore_path" ]; then
    printf "%s\n" "$entry" > "$gitignore_path"
    return 0
  fi

  if grep -Fqx "$entry" "$gitignore_path"; then
    return 0
  fi

  # Ensure file ends with newline before appending
  if [ -s "$gitignore_path" ]; then
    local last_char
    last_char="$(tail -c 1 "$gitignore_path" 2>/dev/null || true)"
    if [ "$last_char" != $'\n' ]; then
      printf "\n" >> "$gitignore_path"
    fi
  fi
  printf "%s\n" "$entry" >> "$gitignore_path"
}

write_project_config() {
  # Creates opencode.jsonc in project root.
  local cfg="${TARGET_DIR}/opencode.jsonc"
  if [ -f "$cfg" ]; then
    print_warn "opencode.jsonc already exists; leaving it unchanged"
    return 0
  fi

  cat > "$cfg" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  // Project-scoped OpenCode config.
  // Tip: commit this file so your whole team shares the same defaults.
  // Docs: https://opencode.ai/docs/config/#per-project
  "default_agent": "opennexus",
  "agent": {
    "plan": {
      "hidden": true
    },
    "build": {
      "hidden": true
    }
  }
}
EOF
  print_info "Wrote project config: ${cfg}"
}

interactive_provider_postinstall() {
  # Populates SELECTED_PROVIDERS for show_model_recommendations.
  echo "" >&2
  if [ "$COLOR_ENABLED" = true ]; then
    printf "%s%sConnected Providers Configuration%s\n" "$BOLD" "$CYAN" "$NC" >&2
  else
    printf "Provider setup\n" >&2
  fi
  printf "%s\n" "Select providers you have connected in OpenCode." >&2
  printf "%s\n" "(No API key will be used; this is only for agent model recommendations.)" >&2

  # Reset so re-running post-install in the same shell doesn't accumulate.
  SELECTED_PROVIDERS=()

  if prompt_yes_no "Do you want to configure connected providers?" "n"; then
    local providers=("claude-pro" "claude-max" "openai" "opencode-zed" "synthetic" "google" "openrouter")
    local p
    for p in "${providers[@]}"; do
      if prompt_yes_no "Have you connected ${p}?" "n"; then
        SELECTED_PROVIDERS+=("$p")
      fi
    done
  fi
}

interactive_postinstall() {
  stage_start "Post-install"

  echo "" >&2
  printf "%s\n" "Post-install can: providers selection, MCP detection, model recommendations, and optional project config + gitignore updates." >&2
  if ! prompt_yes_no "Proceed with post-install steps?" "y"; then
    print_info "Skipping post-install"
    return 0
  fi

  # Providers + MCP detection happen here so they can be skipped as a single step.
  # Providers must be selected before showing model recommendations.
  interactive_provider_postinstall
  interactive_mcp_preinstall

  # Best-effort: model validation should never break installation.
  if ! (set +e; set +u; show_model_recommendations); then
    print_warn "Post-install: model recommendation display failed; skipping"
  fi

  echo "" >&2
  if [ "$COLOR_ENABLED" = true ]; then
    printf "%s%sOpenCode config%s\n" "$BOLD" "$CYAN" "$NC" >&2
  else
    printf "OpenCode config\n" >&2
  fi
  printf "Per-project config lives at: %s\n" "${TARGET_DIR}/opencode.jsonc" >&2
  printf "Global config lives at: %s\n" "~/.config/opencode/opencode.json" >&2
  printf "Docs: %s\n" "https://opencode.ai/docs/config/#per-project" >&2

  if prompt_yes_no "Create local config file for this project? (opencode.jsonc)" "n"; then
    write_project_config
  else
    print_info "Using global config (or defaults)"
  fi

  echo "" >&2
  if [ "$COLOR_ENABLED" = true ]; then
    printf "%s%sGit ignore%s\n" "$BOLD" "$CYAN" "$NC" >&2
  else
    printf "Git ignore\n" >&2
  fi

  local gitignore_default="y"
  if [ "${INSTALL_DIR}" != "${TARGET_DIR}/.opencode" ]; then
    # Only default to yes when the install destination is local.
    gitignore_default="n"
  fi

  if prompt_yes_no "Add .opencode/ to .gitignore?" "$gitignore_default"; then
    ensure_gitignore_entry ".opencode/"
    print_info "Updated .gitignore"
  else
    print_info "Leaving .gitignore unchanged"
  fi

  print_success "Post-install complete"
}

#------------------------------------------------------------------------------
# Install execution
#------------------------------------------------------------------------------
install_agents() {
  # Install primary agents
  local agent_lines
  agent_lines="$(jq -r '.components.agents[]? | "\(.id)\t\(.path)"' "$TMP_JSON")"
  if [ -n "$agent_lines" ]; then
    while IFS=$'\t' read -r id path; do
      [ -z "${id:-}" ] && continue
      copy_one "$path" "${id}.md" "$PRIMARY_AGENTS_DIR"
    done <<< "$agent_lines"
  fi

  # Install subagents
  local subagent_lines
  subagent_lines="$(jq -r '.components.subagents[]? | "\(.id)\t\(.path)"' "$TMP_JSON")"
  if [ -n "$subagent_lines" ]; then
    while IFS=$'\t' read -r id path; do
      [ -z "${id:-}" ] && continue
      copy_one "$path" "${id}.md" "$SUBAGENTS_DIR"

      # If a subagent file also exists in the primary agents directory, warn about duplicates.
      if [ -f "${PRIMARY_AGENTS_DIR}/${id}.md" ]; then
        echo "warn  duplicate subagent also exists at ${PRIMARY_AGENTS_DIR}/${id}.md (consider removing)" >&2
      fi
    done <<< "$subagent_lines"
  fi
}

install_other_components() {
  install_category "commands" "$COMMANDS_DIR"
  install_category "tools" "$TOOLS_DIR"
  install_skills
  install_category "plugins" "$PLUGINS_DIR"
}

#------------------------------------------------------------------------------
# Entrypoint
#------------------------------------------------------------------------------
main() {
  local argc
  argc=$#
  parse_args "$@"

  if [ ! -d "$TARGET_DIR" ]; then
    print_err "target directory does not exist: ${TARGET_DIR}"
    sleep 1
    exit 1
  fi

  # Default to interactive when invoked with no args in a real terminal.
  if [ "$argc" -eq 0 ] && is_tty; then
    INTERACTIVE=true
  fi

  if [ "$INTERACTIVE" = true ] && ! is_tty; then
    print_err "interactive mode requires a TTY"
    print_info "Tip: run: bash install.sh (not via pipe)"
    exit 1
  fi

  init_styles

  if [ "$INTERACTIVE" != true ]; then
    check_dependencies
  fi

  if [ ! -f "$REGISTRY_JSONC" ]; then
    print_err "registry not found: $REGISTRY_JSONC"
    exit 1
  fi

  TMP_JSON="$(mktemp -t opencode-registry.XXXXXX.json)"
  jsonc_to_json "$REGISTRY_JSONC" "$TMP_JSON"

  # Initialize MCP recommendation variables from registry.jsonc
  init_mcp_recommendation_vars

  if [ "$INTERACTIVE" = true ]; then
    interactive_preinstall

    # Resolve paths and create destination directories after location selection.
    set_install_paths
    prepare_install_dirs

    interactive_install

    if [ "$SKIP_POSTINSTALL" = true ]; then
      print_info "Skipping post-install (--skip-postinstall)"
    else
      if ! (set +e; set +u; interactive_postinstall); then
        print_warn "Post-install step failed; continuing"
      fi
    fi
  else
    # Non-interactive: install destination is selected via flags/env.
    apply_install_location_defaults
    set_install_paths
    prepare_install_dirs

    # Non-interactive: install agents always; optionally install other components.
    install_agents
    if [ "$NON_INTERACTIVE_MODE" = "all" ]; then
      install_other_components
    fi

    # Non-interactive: also create project config file
    write_project_config
  fi

  echo ""
  print_success "Installation complete"
  print_info "OpenCode will load agents from: ${PRIMARY_AGENTS_DIR}"
  print_info "Subagents installed to: ${SUBAGENTS_DIR}"
  print_info "If you want to hide any agents, you can edit the local/global opencode config file and set them as hidden: true"
  print_info "Next: restart OpenCode or reload config." 
}

main "$@"
