#!/usr/bin/env bash
set -euo pipefail

# find_in_receipts.sh — search inside encrypted receipts without decrypting to repo
# Usage:
#   scripts/find_in_receipts.sh [-i] [-n] [-l] <pattern>
# Options:
#   -i  case-insensitive
#   -n  show line numbers
#   -l  list files only (suppress matching lines)
#
# Requires: bw (Bitwarden CLI), gpg, pdftotext (poppler), unzip
# Env: BW_SESSION must be set (from `bw unlock`)

usage() { sed -n '2,25p' "$0"; exit 1; }

INSENSITIVE=""
LINENUM=""
FILES_ONLY=""
while getopts ":inl" opt; do
  case "$opt" in
    i) INSENSITIVE="-i" ;;
    n) LINENUM="-n" ;;
    l) FILES_ONLY="-l" ;;
    *) usage ;;
  esac
  }
done
shift $((OPTIND-1))

[[ $# -ge 1 ]] || usage
PATTERN="$*"

# Guardrails
command -v bw >/dev/null || { echo "bw CLI not found"; exit 1; }
command -v gpg >/dev/null || { echo "gpg not found"; exit 1; }
command -v pdftotext >/dev/null || { echo "pdftotext not found (brew install poppler)"; exit 1; }
command -v unzip >/dev/null || { echo "unzip not found"; exit 1; }
[[ -n "${BW_SESSION:-}" ]] || { echo "BW_SESSION not set. Run: bw unlock"; exit 1; }

TMPDIR="$(mktemp -d -t receiptsgrep.XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

# Grep helper that respects flags
gogrep() {
  local file="$1"
  if [[ -n "$FILES_ONLY" ]]; then
    # print the path if any match exists
    if grep -q $INSENSITIVE -- "$PATTERN" "$file"; then
      echo "$file"
    fi
  else
    grep $INSENSITIVE $LINENUM --color=never -- "$PATTERN" "$file" || true
  fi
}

# Decrypt a .gpg to a temp file via Bitwarden passphrase
decrypt_to_tmp() {
  local gpgpath="$1"
  local out="$2"
  bw get password "GPG Passphrase" --session "$BW_SESSION" \
    | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 \
          -o "$out" -d "$gpgpath" >/dev/null
}

# Walk all encrypted receipts
find receipts -type f -name "*.gpg" -print0 | while IFS= read -r -d '' enc; do
  base="${enc%.gpg}"                # without .gpg
  ext="${base##*.}"                 # original extension: pdf/html/zip/...
  stem="$(basename "$base")"
  work="$TMPDIR/$stem"

  # Try decrypt; skip on failure but keep going
  if ! decrypt_to_tmp "$enc" "$work"; then
    echo "WARN: failed to decrypt: $enc" >&2
    continue
  fi

  case "$ext" in
    pdf)
      # Convert PDF → text and grep
      txt="$work.txt"
      # pdftotext input file then output to stdout
      if pdftotext "$work" - 2>/dev/null > "$txt"; then
        if [[ -z "$FILES_ONLY" ]]; then echo "== $enc =="; fi
        gogrep "$txt"
      else
        echo "WARN: pdftotext failed for $enc" >&2
      fi
      ;;
    html|htm|txt|md)
      if [[ -z "$FILES_ONLY" ]]; then echo "== $enc =="; fi
      gogrep "$work"
      ;;
    zip)
      # Search inside zip members: .txt/.html directly; .pdf via pdftotext
      # List all entries
      mapfile -t members < <(unzip -Z1 "$work" 2>/dev/null || true)
      match_printed=0
      for m in "${members[@]}"; do
        case "$m" in
          *.txt|*.html|*.htm|*.md)
            tmpm="$TMPDIR/$(basename "$m")"
            if unzip -p "$work" "$m" > "$tmpm" 2>/dev/null; then
              if [[ -z "$FILES_ONLY" ]]; then echo "== $enc :: $m =="; fi
              gogrep "$tmpm"
              match_printed=1
            fi
            ;;
          *.pdf)
            tmpm_pdf="$TMPDIR/$(basename "$m")"
            tmpm_txt="$tmpm_pdf.txt"
            if unzip -p "$work" "$m" 2>/dev/null | pdftotext - - > "$tmpm_txt" 2>/dev/null; then
              if [[ -z "$FILES_ONLY" ]]; then echo "== $enc :: $m =="; fi
              gogrep "$tmpm_txt"
              match_printed=1
            fi
            ;;
        esac
      done
      if [[ "$FILES_ONLY" == "-l" && "$match_printed" -eq 0 ]]; then
        : # no-op; nothing matched
      fi
      ;;
    *)
      # Unknown type: try plain grep on bytes (best-effort)
      if [[ -z "$FILES_ONLY" ]]; then echo "== $enc =="; fi
      gogrep "$work"
      ;;
  esac
done

