#!/bin/bash
# vim: ts=2:et:tw=80

if [ "$0" == "${BASH_SOURCE[0]}" ]; then
  echo "This script must be sourced, not executed."
  exit 1
fi

PSEUDOSH=$(dirname "${BASH_SOURCE[0]}")
declare -A PSEUDOSH_INCLUDE_GUARDS=()

include() {
  local file="$1"
  if [ -z "$file" ]; then
    >&2 echo "Usage: include <file>"
    return 1
  fi

  if [ ! -f "$PSEUDOSH/$file" ]; then
    >&2 echo "File not found: $file"
    return 1
  fi

  if [ -n "${PSEUDOSH_INCLUDE_GUARDS[$file]}" ]; then
    return 0
  fi

  . "$PSEUDOSH/$file"
  PSEUDOSH_INCLUDE_GUARDS[$file]=1
}
