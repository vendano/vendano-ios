#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./strings_diff.sh en.lproj/Localizable.strings es-US.lproj/Localizable.strings

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <file1.strings> <file2.strings>" >&2
  exit 1
fi

FILE1="$1"
FILE2="$2"

if [[ ! -f "$FILE1" ]]; then
  echo "Error: file not found: $FILE1" >&2
  exit 1
fi
if [[ ! -f "$FILE2" ]]; then
  echo "Error: file not found: $FILE2" >&2
  exit 1
fi

# ANSI colors (Terminal / iTerm)
BOLD=$'\033[1m'
CYAN=$'\033[36m'
YELLOW=$'\033[33m'
MAGENTA=$'\033[35m'
RESET=$'\033[0m'

tmp1="$(mktemp -t strings_keys1.XXXXXX)"
tmp2="$(mktemp -t strings_keys2.XXXXXX)"
trap 'rm -f "$tmp1" "$tmp2"' EXIT

extract_keys() {
  local f="$1"
  /usr/bin/perl -ne '
    s/^\x{FEFF}//;         # strip UTF-8 BOM if present (as Unicode BOM)
    s/^\xEF\xBB\xBF//;     # strip UTF-8 BOM if present (as raw bytes)
    my $t = $_;
    $t =~ s/^\s+//;

    # skip blank lines + common comment styles
    next if $t =~ /^\s*$/;
    next if $t =~ m{^//};
    next if $t =~ m{^/\*};
    next if $t =~ m{^\*};

    # extract key: "KEY" =
    if ($_ =~ /^\s*"([^"]+)"\s*=/) {
      print "$1\n";
    }
  ' "$f" | LC_ALL=C sort -u
}

extract_keys "$FILE1" > "$tmp1"
extract_keys "$FILE2" > "$tmp2"

# Colored / bold filename header
printf "%s%s%s%s\n" "$BOLD" "$CYAN" "$FILE1" "$RESET"

printf "%s%sMissing in file2:%s\n" "$BOLD" "$YELLOW" "$RESET"
comm -23 "$tmp1" "$tmp2" || true

printf "%s%sMissing in file1:%s\n" "$BOLD" "$MAGENTA" "$RESET"
comm -13 "$tmp1" "$tmp2" || true

