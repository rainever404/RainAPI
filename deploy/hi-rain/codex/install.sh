#!/usr/bin/env bash
set -euo pipefail

BASE_URL="https://api.hi-rain.com/v1"
DEFAULT_MODEL="gpt-6-sol"
PROVIDER_NAME="OpenAI"
MANAGED_KEYS="model_provider|model|review_model|model_reasoning_effort|disable_response_storage|network_access|windows_wsl_setup_acknowledged"

log() {
  printf '[rainever-codex] %s\n' "$*"
}

die() {
  printf '[rainever-codex] ERROR: %s\n' "$*" >&2
  exit 1
}

backup_file() {
  local path="$1"
  if [ -f "$path" ]; then
    local stamp
    stamp="$(date '+%Y%m%d%H%M%S')"
    cp -p "$path" "$path.bak.$stamp"
    log "Backed up $path"
  fi
}

trim_trailing_blank_lines() {
  local input="$1"
  local output="$2"
  awk '
    NF {
      for (i = 1; i <= blank_count; i++) print blanks[i]
      blank_count = 0
      print
      next
    }
    {
      blanks[++blank_count] = $0
    }
  ' "$input" > "$output"
}

split_existing_config() {
  local config_file="$1"
  local top_file="$2"
  local rest_file="$3"

  : > "$top_file"
  : > "$rest_file"

  if [ ! -f "$config_file" ]; then
    return
  fi

  awk \
    -v top_file="$top_file" \
    -v rest_file="$rest_file" \
    -v keys="$MANAGED_KEYS" '
      BEGIN {
        before_section = 1
        in_managed_section = 0
        managed_key_pattern = "^[[:space:]]*(" keys ")[[:space:]]*="
      }

      /^\[model_providers\.OpenAI\][[:space:]]*$/ {
        in_managed_section = 1
        before_section = 0
        next
      }

      /^\[/ {
        in_managed_section = 0
        before_section = 0
      }

      {
        if (in_managed_section) {
          next
        }

        if (before_section) {
          if ($0 ~ managed_key_pattern) {
            next
          }
          print > top_file
        } else {
          print > rest_file
        }
      }
    ' "$config_file"
}

json_escape_string() {
  local value="$1"

  if command -v perl >/dev/null 2>&1 && perl -MJSON::PP -e '1' >/dev/null 2>&1; then
    perl -MJSON::PP -e 'print JSON::PP->new->ascii->encode($ARGV[0])' "$value"
    return
  fi

  printf '%s' "$value" | sed 's/\\/\\\\/g; s/"/\\"/g; s/^/"/; s/$/"/'
}

write_auth_json() {
  local auth_file="$1"
  local api_key="$2"

  if command -v perl >/dev/null 2>&1 && perl -MJSON::PP -e '1' >/dev/null 2>&1; then
    AUTH_FILE="$auth_file" API_KEY="$api_key" perl -MJSON::PP -0777 -e '
      use strict;
      use warnings;
      use JSON::PP qw(decode_json);

      my $file = $ENV{"AUTH_FILE"};
      my $key = $ENV{"API_KEY"};
      my $data = {};

      if (-s $file) {
        if (open my $fh, "<:encoding(UTF-8)", $file) {
          local $/;
          my $raw = <$fh>;
          close $fh;
          eval { $data = decode_json($raw); 1 } or $data = {};
          $data = {} if ref($data) ne "HASH";
        }
      }

      $data->{"OPENAI_API_KEY"} = $key;

      open my $out, ">:encoding(UTF-8)", $file or die "Cannot write $file: $!";
      print {$out} JSON::PP->new->canonical(1)->pretty(1)->encode($data);
      close $out;
    '
    return
  fi

  local escaped_key
  escaped_key="$(json_escape_string "$api_key")"
  printf '{\n  "OPENAI_API_KEY": %s\n}\n' "$escaped_key" > "$auth_file"
}

log 'Rainever New API Codex setup'
log "Base URL: $BASE_URL"
log "Default model: $DEFAULT_MODEL"

CODEX_DIR="${HOME}/.codex"
CONFIG_FILE="${CODEX_DIR}/config.toml"
AUTH_FILE="${CODEX_DIR}/auth.json"

mkdir -p "$CODEX_DIR"

api_key="${RAINEVER_API_KEY:-${OPENAI_API_KEY:-}}"
if [ -z "$api_key" ]; then
  if [ ! -r /dev/tty ]; then
    die 'RAINEVER_API_KEY is required when no interactive terminal is available.'
  fi
  printf 'Paste your Rainever/New API token, then press Enter: ' > /dev/tty
  IFS= read -r api_key < /dev/tty
fi

if [ -z "$api_key" ]; then
  die 'API token is empty.'
fi

backup_file "$CONFIG_FILE"
backup_file "$AUTH_FILE"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TOP_PART="${TMP_DIR}/top"
REST_PART="${TMP_DIR}/rest"
TOP_TRIMMED="${TMP_DIR}/top.trimmed"
REST_TRIMMED="${TMP_DIR}/rest.trimmed"
NEW_CONFIG="${TMP_DIR}/config.toml"

split_existing_config "$CONFIG_FILE" "$TOP_PART" "$REST_PART"
trim_trailing_blank_lines "$TOP_PART" "$TOP_TRIMMED"
trim_trailing_blank_lines "$REST_PART" "$REST_TRIMMED"

{
  if [ -s "$TOP_TRIMMED" ]; then
    cat "$TOP_TRIMMED"
    printf '\n\n'
  fi

  cat <<EOF
model_provider = "$PROVIDER_NAME"
model = "$DEFAULT_MODEL"
review_model = "$DEFAULT_MODEL"
model_reasoning_effort = "medium"
disable_response_storage = true
network_access = "enabled"
windows_wsl_setup_acknowledged = true
EOF

  if [ -s "$REST_TRIMMED" ]; then
    printf '\n\n'
    cat "$REST_TRIMMED"
  fi

  cat <<EOF

[model_providers.$PROVIDER_NAME]
name = "$PROVIDER_NAME"
base_url = "$BASE_URL"
wire_api = "responses"
requires_openai_auth = true
EOF
} > "$NEW_CONFIG"

mv "$NEW_CONFIG" "$CONFIG_FILE"
log "Wrote $CONFIG_FILE"

write_auth_json "$AUTH_FILE" "$api_key"
log "Wrote $AUTH_FILE"

log 'Done.'
log 'Fully quit Codex, then open it again.'
log 'If it does not take effect, restore the latest .bak file in ~/.codex.'
