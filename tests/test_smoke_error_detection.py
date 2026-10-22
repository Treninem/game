"""Exercise the actual required smoke wrapper with a bounded fake engine."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
BASH = shutil.which("bash")
if os.name == "nt":
    BASH = "C:/Program Files/Git/bin/bash.exe"
assert BASH, "Bash is required to validate the real smoke wrapper"


def shell_path(path):
    text = Path(path).resolve().as_posix()
    return "/" + text[0].lower() + text[2:] if os.name == "nt" else text


def main():
    cases = [
        ("clean", "Fixture completed successfully\n", 0, 0),
        ("ordinary", "ERROR: resource still in use\n", 0, 1),
        ("interleaved", "RefERROR: 1 resources still in use at exit.\n", 0, 1),
        ("script", "stdoutSCRIPT ERROR: invalid call\n", 0, 1),
        ("annotation", "prefix::error title=fixture::failure\n", 0, 1),
        ("engine_exit", "Fixture aborted\n", 7, 7),
    ]
    with tempfile.TemporaryDirectory(prefix="impuls-smoke-filter-") as folder:
        temp = Path(folder)
        engine = temp / "engine.sh"
        engine.write_text('#!/usr/bin/env bash\ncat "$SMOKE_FIXTURE_LOG"\nexit "$SMOKE_FIXTURE_EXIT"\n', encoding="utf-8", newline="\n")
        engine.chmod(0o755)
        scene = temp / "fixture.tscn"
        scene.write_text('[gd_scene format=3]\n', encoding="utf-8")
        log = temp / "engine.log"
        for name, output, engine_exit, expected in cases:
            log.write_text(output, encoding="utf-8")
            env = os.environ.copy()
            env.update(GODOT_BIN=shell_path(engine), SMOKE_FIXTURE_LOG=shell_path(log), SMOKE_FIXTURE_EXIT=str(engine_exit))
            result = subprocess.run([BASH, shell_path(ROOT / "tools/run_godot_smoke.sh"), shell_path(scene), "5"], cwd=ROOT, env=env, capture_output=True, text=True, timeout=15)
            assert result.returncode == expected, (name, result.returncode, result.stdout, result.stderr)
            assert ("GODOT_SMOKE_OK scene=" in result.stdout) == (expected == 0), name
            print("SMOKE_FILTER_CASE", name, "exit=", result.returncode, flush=True)
    print("SMOKE_ERROR_FILTER_OK cases=6 interleaved_errors_rejected=true engine_exit_preserved=true")


if __name__ == "__main__":
    main()
