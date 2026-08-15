#!/usr/bin/env bash
set -euo pipefail

SCENE="${1:?usage: run_godot_smoke.sh <scene> [timeout-seconds]}"
TIMEOUT_SECONDS="${2:-${GODOT_SMOKE_TIMEOUT_SECONDS:-180}}"
GODOT_BIN="${GODOT_BIN:-./Godot_v4.7.1-stable_linux.x86_64}"

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "::error title=Godot executable missing::$GODOT_BIN is not executable"
  exit 2
fi

if [[ ! -f "$SCENE" ]]; then
  echo "::error title=Smoke scene missing::$SCENE does not exist"
  exit 2
fi

echo "GODOT_SMOKE_START scene=$SCENE timeout=${TIMEOUT_SECONDS}s"
set +e
timeout --signal=TERM --kill-after=15s "${TIMEOUT_SECONDS}s" \
  "$GODOT_BIN" --headless --path . "$SCENE"
status=$?
set -e

if [[ $status -eq 124 || $status -eq 137 ]]; then
  echo "::error title=Godot smoke timed out::$SCENE did not terminate within ${TIMEOUT_SECONDS}s"
  exit 124
fi

if [[ $status -ne 0 ]]; then
  echo "::error title=Godot smoke failed::$SCENE exited with code $status"
  exit "$status"
fi

echo "GODOT_SMOKE_OK scene=$SCENE"
