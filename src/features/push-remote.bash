#!/usr/bin/env bash

# ---------------------------------------------------------------------------- #
# Parse arguments
# ---------------------------------------------------------------------------- #

VERBOSE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shitf
      ;;
    -*)
      printf 'Illegal option %s\n' "$1"
      exit 1
      ;;
    *)
      if [[ "$1" != "" ]]; then
        ARGS+=("$1")
      fi
      shift
      ;;
  esac
done

if [[ ${#ARGS[@]} -gt 1 ]]; then
  printf 'Too many arguments, expected 1\n'
  exit 1
fi

if [[ ${#ARGS[@]} -eq 0 ]]; then
  printf 'Argument is required\n'
  exit 1
fi

if [[ ${#ARGS[@]} -eq 1 ]]; then
  REMOTE_NAME=${ARGS[0]}
  shift
fi

# ---------------------------------------------------------------------------- #
# Get path of the directory this script is included
# ---------------------------------------------------------------------------- #

get_script_path () {
  local SOURCE
  local SCRIPT_PATH
  SOURCE=${BASH_SOURCE[0]}
  # resolve $SOURCE until the file is no longer a symlink
  while [ -L "$SOURCE" ]; do 
    SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
    SOURCE=$(readlink "$SOURCE")
    # if $SOURCE was a relative symlink, resolve it relative to it
    [[ $SOURCE != /* ]] && SOURCE=$SCRIPT_PATH/$SOURCE 
  done
  SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  echo "$SCRIPT_PATH"
}

SCRIPT_PATH=$(get_script_path)
COMPARE_REMOTE=$(readlink -f "$SCRIPT_PATH/compare-remote.bash")

# ---------------------------------------------------------------------------- #
# Get WIP commits that are on local but aren't on remote
# ---------------------------------------------------------------------------- #

if COMPARE_REMOTE_RESULT_STRING=$("$COMPARE_REMOTE" "$REMOTE_NAME"); then
  readarray -t COMPARE_REMOTE_RESULT_ARRAY <<< "$COMPARE_REMOTE_RESULT_STRING"
  read -r -a UNIQUE_LOCAL <<< "${COMPARE_REMOTE_RESULT_ARRAY[0]}"
  # read -r -a UNIQUE_REMOTE <<< "${COMPARE_REMOTE_RESULT_ARRAY[1]}"
  # read -r -a COMMON <<< "${COMPARE_REMOTE_RESULT_ARRAY[2]}"
else
  exit 1
fi

# ---------------------------------------------------------------------------- #
# Push
# ---------------------------------------------------------------------------- #

if [[ "${#UNIQUE_LOCAL[@]}" -gt 0 ]]; then
  UNIQUE_LOCAL_TAG_INTERPOLATED=$(printf 'tag %s ' "${UNIQUE_LOCAL[@]}")
else
  printf 'Remote %s has all the WIP tags that are locally present' "$LOCAL_WIP_TAGS_STRING"
fi

PUSH_COMMAND="git push $REMOTE_NAME $UNIQUE_LOCAL_TAG_INTERPOLATED"
if ! eval "$PUSH_COMMAND"; then
  printf 'Failed while pushing WIP tags to %s\n' "$REMOTE_NAME"
  exit 1
fi

exit 0
