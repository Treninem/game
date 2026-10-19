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

runtime_args=(--headless --verbose --audio-driver Dummy)
if [[ "${GODOT_SMOKE_GRAPHICAL:-0}" == 1 ]]; then
  runtime_args=(--rendering-method gl_compatibility --verbose --audio-driver Dummy)
fi
if [[ -n "${GODOT_SMOKE_PACK:-}" ]]; then
  if [[ ! -f "$GODOT_SMOKE_PACK" ]]; then
    echo "::error title=Exported package missing::$GODOT_SMOKE_PACK does not exist"
    exit 2
  fi
  runtime_args+=(--main-pack "$(realpath "$GODOT_SMOKE_PACK")")
fi
if [[ "$SCENE" == *.gd ]]; then
  runtime_args+=(--script "$(realpath "$SCENE")")
else
  runtime_args+=("$SCENE")
fi

echo "GODOT_SMOKE_START scene=$SCENE timeout=${TIMEOUT_SECONDS}s"
output_log="$(mktemp)"
trap 'rm -f "$output_log"' EXIT
set +e
timeout --signal=TERM --kill-after=15s "${TIMEOUT_SECONDS}s" \
  "$GODOT_BIN" --path . "${runtime_args[@]}" 2>&1 | tee "$output_log"
statuses=("${PIPESTATUS[@]}")
status="${statuses[0]}"
set -e

if [[ $status -eq 124 || $status -eq 137 ]]; then
  echo "::error title=Godot smoke timed out::$SCENE did not terminate within ${TIMEOUT_SECONDS}s"
  exit 124
fi

if [[ $status -ne 0 ]]; then
  echo "::error title=Godot smoke failed::$SCENE exited with code $status"
  exit "$status"
fi

if [[ ${statuses[1]} -ne 0 ]]; then
  echo "::error title=Godot smoke log failed::Could not capture output for $SCENE"
  exit 1
fi

# Godot can exit zero after parse/runtime errors if the test later calls quit(0).
# Such a run does not prove that the scene or its dependencies are healthy.
if grep -Eq '(^|[[:space:]])(SCRIPT ERROR:|ERROR:|::error)' "$output_log"; then
  echo "::error title=Godot runtime error::$SCENE emitted errors despite exiting zero"
  exit 1
fi

echo "GODOT_SMOKE_OK scene=$SCENE"
