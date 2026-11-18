#!/usr/bin/env bash

# Build a signature string from key=value input.
# The user is always the currently logged-in GitHub CLI user (name and login).
# Nothing needs to be set up per person.
#
# Usage:
#   signature.sh output_format=markdown model="<model>" editor="<editor>"
# Supported output_format values: markdown, JIRA, GitHub
# JIRA output is returned as an ADF paragraph fragment JSON (plain text, no mention).
# Use basis="source, time window, n" when the text rests on measurements, code or documents;
# it is printed as a "Source:" line above the signature.
# Use language=en|no for the fixed phrases (default: en).

set -euo pipefail

OUTPUT_FORMAT="markdown"
MODEL=""
EDITOR=""
LANGUAGE="en"
BASIS=""

function usage() {
  cat <<'EOF'
Usage: signature.sh key=value [key=value ...]

Supported keys:
  output_format=markdown|JIRA|GitHub
  model=...
  editor=...
  language=en|no
  basis=...   data basis of any measurements in the text (source, time window, n)

The user is the logged-in GitHub CLI user (gh auth status).
EOF
}

for arg in "$@"; do
  if [[ "$arg" != *=* ]]; then
    echo "Invalid argument '$arg'. Expected key=value." >&2
    usage >&2
    exit 1
  fi

  key=${arg%%=*}
  value=${arg#*=}

  case "$key" in
    output_format)
      OUTPUT_FORMAT="$value"
      ;;
    model)
      MODEL="$value"
      ;;
    editor)
      EDITOR="$value"
      ;;
    language)
      LANGUAGE="$value"
      ;;
    basis)
      BASIS="$value"
      ;;
    *)
      echo "Unknown key '$key'." >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$OUTPUT_FORMAT" in
  markdown|JIRA|GitHub)
    ;;
  *)
    echo "Invalid output_format '$OUTPUT_FORMAT'." >&2
    usage >&2
    exit 1
    ;;
esac

case "$LANGUAGE" in
  en)
    L_GENERATED="Generated with AI by"
    L_WITH="with"
    L_IN="in"
    L_SOURCE="Source"
    L_UNKNOWN_MODEL="unknown model"
    L_UNKNOWN_EDITOR="unknown editor"
    ;;
  no)
    L_GENERATED="Generert med KI av"
    L_WITH="med"
    L_IN="i"
    L_SOURCE="Kilde"
    L_UNKNOWN_MODEL="ukjent modell"
    L_UNKNOWN_EDITOR="ukjent editor"
    ;;
  *)
    echo "Invalid language '$LANGUAGE'. Use en or no." >&2
    usage >&2
    exit 1
    ;;
esac

[ -n "$MODEL" ] || MODEL="$L_UNKNOWN_MODEL"
[ -n "$EDITOR" ] || EDITOR="$L_UNKNOWN_EDITOR"

function json_escape() {
  printf '%s' "$1" | tr -d '\r\n\t' | sed 's/\\/\\\\/g; s/"/\\"/g'
}

# Hard gate: the signature is always about the logged-in GitHub user.
if ! command -v gh &> /dev/null; then
  echo "Error: the GitHub CLI (gh) is required. Install it and run 'gh auth login'." >&2
  exit 3
fi

GITHUB_LOGIN=$(gh api user --jq '.login' 2>/dev/null || echo "")
if [ -z "$GITHUB_LOGIN" ]; then
  echo "Error: no logged-in GitHub user. Run 'gh auth login' and try again." >&2
  exit 3
fi

FULL_NAME=$(gh api user --jq '.name // ""' 2>/dev/null || echo "")
[ -n "$FULL_NAME" ] || FULL_NAME="$GITHUB_LOGIN"

USER_MARKDOWN="[$FULL_NAME](https://github.com/$GITHUB_LOGIN)"
USER_GITHUB="@$GITHUB_LOGIN"

if [ -z "$BASIS" ]; then
  echo "Tip: if the text rests on measurements, code or documents, pass basis=\"source, time window, n\"." >&2
fi

if [ "${#BASIS}" -gt 200 ]; then
  echo "Tip: basis is ${#BASIS} characters; keep it to about 200." >&2
fi
case "$BASIS" in
  *://*)
    echo "Error: basis contains a URL; do not include internal URLs. Use a system name, file path, time window and count." >&2
    exit 2
    ;;
esac

# Output in requested format
case "$OUTPUT_FORMAT" in
  markdown)
    [ -n "$BASIS" ] && printf '%s: %s\n\n' "$L_SOURCE" "$BASIS"
    echo "🤖 $L_GENERATED $USER_MARKDOWN $L_WITH $MODEL $L_IN $EDITOR"
    ;;
  GitHub)
    [ -n "$BASIS" ] && printf '%s: %s\n\n' "$L_SOURCE" "$BASIS"
    echo "🤖 $L_GENERATED $USER_GITHUB $L_WITH $MODEL $L_IN $EDITOR"
    ;;
  JIRA)
    ESCAPED_MODEL=$(json_escape "$MODEL")
    ESCAPED_EDITOR=$(json_escape "$EDITOR")
    ESCAPED_FULL_NAME=$(json_escape "$FULL_NAME")
    # One paragraph: [Source text, hardBreak,] then the signature, in italics.
    BASIS_NODES=""
    if [ -n "$BASIS" ]; then
      BASIS_NODES="{\"type\":\"text\",\"text\":\"$L_SOURCE: $(json_escape "$BASIS")\"},{\"type\":\"hardBreak\"},"
    fi
    SIGNATURE_NODES="{\"type\":\"text\",\"text\":\"🤖 $L_GENERATED $ESCAPED_FULL_NAME $L_WITH $ESCAPED_MODEL $L_IN $ESCAPED_EDITOR\",\"marks\":[{\"type\":\"em\"}]}"
    echo "{\"type\":\"paragraph\",\"content\":[${BASIS_NODES}${SIGNATURE_NODES}]}"
    ;;
esac
