#!/bin/bash
# vim: ts=2:et:tw=80
#
# This script is a bash library that provides environment variables and functions
# for the common csi sequence. The csi sequence is the control sequence introducer
# that is used to control the terminal.

export BLACK=0
export RED=1
export GREEN=2
export YELLOW=3
export BLUE=4
export MAGENTA=5
export CYAN=6
export WHITE=7
export BRIGHT=60

fg() {
  color 30 "$@"
}

bg() {
  color 40 "$@"
}

# color offset code
# color offset 256 code
# color offset "rgb" red green blue
color() {
  local offset opt
  offset=$1
  opt=$2
  shift 2
  
  case $opt in
    256)
      printf "\033[%d;5;%dm" $((offset+8)) "$1"
      ;;
    "rgb")
      printf "\033[%d;2;%d;%d;%dm" $((offset+8)) "$1" "$2" "$3"
      ;;
    *)
      attr $((offset+opt))
      ;;
  esac
}

export RESET=9
export BOLD=1
export DIM=2
export UNDERLINE=4
export BLINK=5
export INVERT=7
export HIDDEN=8

attr() {
  printf "\033[%dm" "$1"
}

reset() {
  printf "\033[m"
}

export DEFAULT=DEFAULT
export BLOCK=BLOCK
export UNDERLINE=UNDERLINE
export BAR=BAR

# caret_style [style:DEFAULT] [is_blink:0]
# style: BLOCK, UNDERLINE, BAR, DEFAULT
caret_style() {
  local style is_blink
  style=${1:-$DEFAULT}
  is_blink=${2:-0}

  case $style in
    "$DEFAULT")
      printf "\033[ q"
      return 0
      ;;
    "$BLOCK") style=1 ;;
    "$UNDERLINE") style=3 ;;
    "$BAR") style=5 ;;
    *)
      >&2 echo "caret_style: invalid style \"$style\""
      return 1
      ;;
  esac

  printf "\033[ %d q" $((style+is_blink))
}

export MODE_ON=h
export MODE_OFF=l

export ALTERNATE_SCREEN=1049
export LINE_WRAP=7

# mode kind is_on
# kind: ALTERNATE_SCREEN, LINE_WRAP
mode() {
  local kind is_on
  kind=$1
  is_on=$2
  printf "\033[?%d%s" "$kind" "$is_on"
}

export CHAR=CHAR
export TAB=TAB
export BACKTAB=BACKTAB
export LINE=LINE
export BLANK=BLANK
export DISPLAY=DISPLAY

# input kind [moves:1]
# kind: TAB, BACKTAB, LINE, BLANK
input() {
  local kind moves
  kind=$1
  case $kind in
    "$TAB") kind=I ;;
    "$BACKTAB") kind=Z ;;
    "$LINE") kind=L ;;
    "$BLANK") kind=@ ;;
  esac
  moves=${2:-1}
  printf "\033[%d%s" "$moves" "$kind"
}

export BACKWARD=1
export FORWARD=
export BOTH=2
export PURGE=3

# erase kind [moves:FOWARD]
# kind: DISPLAY, LINE, CHAR
erase() {
  local kind moves
  kind=$1
  moves=$2
  case $kind in
    "$DISPLAY") kind=J ;;
    "$LINE") kind=K ;;
    "$CHAR") kind=X ;;
  esac
  if [ -z "$moves" ]; then
    printf "\033[%s" "$kind"
    return 0
  fi
  printf "\033[%d%s" "$moves" "$kind"
}

# delete kind [moves:1]
# kind: CHAR, LINE
delete() {
  local kind moves
  kind=$1
  moves=${2:-1}
  case $kind in
    "$CHAR") kind=P ;;
    "$LINE") kind=M ;;
  esac
  printf "\033[%d%s" "$moves" "$kind"
}

export UP=UP
export DOWN=DOWN
export RIGHT=RIGHT
export LEFT=LEFT
export NEXT=NEXT
export PREV=PREV
export COLUMN=COLUMN
export ROW=ROW
export TO=TO
export SAVE=SAVE
export SHOW=SHOW
export HIDE=HIDE
export RESTORE=RESTORE
export POSITION=POSITION

# cursor kind [...args]
# kind: UP, DOWN, RIGHT, LEFT, NEXT, PREV, COLUMN,
#       ROW, TO, SAVE, RESTORE, POSITION
# VARARGS:
#   UP, DOWN, RIGHT, LEFT, NEXT, PREV, COLUMN, ROW: moves
#   TO: row col
#   SAVE, RESTORE, SHOW, HIDE: -
#   POSITION: -
cursor() {
  local kind kind0 kind1 kind2
  kind=$1

  case $kind in
    "$UP") kind1=A ;;
    "$DOWN") kind1=B ;;
    "$RIGHT") kind1=C ;;
    "$LEFT") kind1=D ;;
    "$NEXT") kind1=E ;;
    "$PREV") kind1=F ;;
    "$COLUMN") kind1=G ;;
    "$ROW") kind1=d ;;
    "$TO") kind2=H ;;
    "$SAVE") kind0=7 ;;
    "$RESTORE") kind0=8 ;;
    "$SHOW") kind0="?25h" ;;
    "$HIDE") kind0="?25l" ;;
    "$POSITION")
      printf "\033[6n"
      # shellcheck disable=SC2034
      read -rsd R
      echo "${REPLY#*[}"
      return 0
  esac

  if [ -n "$kind0" ]; then
    printf "\033[%s" "$kind0"
    return 0
  fi

  if [ -n "$kind1" ]; then
    printf "\033[%d%s" "$2" "$kind1"
    return 0
  fi

  if [ -n "$kind2" ]; then
    printf "\033[%d;%d%s" "$2" "$3" "$kind2"
    return 0
  fi
}

LOG_LEVEL=${LOG_LEVEL:-INFO}

log_level() {
  case ${1^^} in
    "DEBUG") echo 0 ;;
    "INFO") echo 1 ;;
    "WARN") echo 2 ;;
    "ERROR") echo 3 ;;
    "PANIC") echo 4 ;;
    *)
      >&2 echo "log_level: invalid log level \"$1\""
      echo -1
      return 1
  esac
}

_log() {
  local func depth
  if [ "$(log_level "$LEVEL")" -lt "$(log_level "$LOG_LEVEL")" ]; then
    return 0
  fi
  >&2 echo -en "$(bg "$PRIMARY")$(fg "$SECONDARY") $(printf "%-5s" "$LEVEL") $(reset) "
  case ${FUNCNAME[1]} in
    debug|info|warn|error|panic) depth=2 ;;
    *) depth=1 ;;
  esac

  func=${FUNCNAME[$depth]}
  # if func is a private function, prepend the parent function name
  # parent->_private
  while [[ "$func" == _* ]]; do
    depth=$((depth+1))
    func="${FUNCNAME[$depth]}->$func"
  done

  >&2 echo -e "$(fg "$PRIMARY")${func:-root}$(reset) $*"
}

debug() {
  LEVEL="DEBUG" PRIMARY=$((BLACK+BRIGHT)) SECONDARY=$WHITE _log "$*"
}

info() {
  LEVEL="INFO" PRIMARY=$GREEN SECONDARY=$WHITE _log "$*"
}

warn() {
  LEVEL="WARN" PRIMARY=$YELLOW SECONDARY=$BLACK _log "$*"
}

error() {
  LEVEL="ERROR" PRIMARY=$RED SECONDARY=$BLACK _log "$*"
}

export PANIC_CODE=6

panic() {
  LEVEL="PANIC" PRIMARY=$((BLACK+BRIGHT)) SECONDARY=$RED _log "$*"
  exit $PANIC_CODE
}

alias unreachable="panic 'unreachable code reached'"

join() {
  local IFS=$1
  shift
  echo "$*"
}

index_of() {
  local i haystack needle
  needle=$1
  shift
  haystack=("$@")
  for i in "${!haystack[@]}"; do
    if [ "${haystack[$i]}" == "$needle" ]; then
      echo "$i"
      return 0
    fi
  done
  return 1
}
