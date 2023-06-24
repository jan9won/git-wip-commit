#!/usr/bin/env bash

IFS='.' read -r -a GIT_VER <<< "$(git --version | sed -e 's/[^0-9.]//g')"

MAJOR=1
MINOR=9
PATCH=0

if [[
  ${GIT_VER[0]} -lt $MAJOR ||
  (
    ${GIT_VER[0]} -eq $MAJOR &&
    ${GIT_VER[1]} -lt $MINOR
  ) ||
  (
    ${GIT_VER[0]} -eq $MAJOR &&
    ${GIT_VER[1]} -eq $MINOR &&
    ${GIT_VER[2]} -lt $PATCH
  )
]]; then
  printf 'Git version %d.%d.%d or later is required.\n' "$MAJOR" "$MINOR" "$PATCH"
  printf 'Your current version is %d.%d.%d\n' "${GIT_VER[0]}" "${GIT_VER[1]}" "${GIT_VER[2]}"
  exit 1
  else
  exit 0
fi