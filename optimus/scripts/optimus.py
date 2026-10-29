"""Project controls for instruction-driven Optimus; no shell interception."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


def project_root(directory):
    path = Path(directory).resolve(strict=True)
    if not path.is_dir():
        raise ValueError("Project must be a directory")
    for candidate in (path, *path.parents):
        if (candidate / ".git").exists():
            return candidate
    return path


def rtk_binary():
    found = shutil.which("rtk")
    if found:
        return found
    local = os.environ.get("LOCALAPPDATA")
    if local:
        candidate = Path(local) / "Microsoft/WinGet/Links/rtk.exe"
        if candidate.is_file():
            return str(candidate)
    raise FileNotFoundError("RTK unavailable; commands remain normal")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("on", "off", "status", "gain"))
    parser.add_argument("--project", default=os.getcwd())
    parser.add_argument("--state-dir", help="Override state directory for isolated checks")
    args = parser.parse_args()
    root = project_root(args.project)
    default = (Path(os.environ["LOCALAPPDATA"]) / "Optimus/projects"
               if os.environ.get("LOCALAPPDATA") else
               Path.home() / ".local/state/optimus/projects")
    state_dir = Path(args.state_dir) if args.state_dir else default
    key = hashlib.sha256(os.path.normcase(str(root)).encode()).hexdigest()
    state_file = state_dir / (key + ".json")
    enabled = False
    if state_file.exists():
        record = json.loads(state_file.read_text(encoding="utf-8"))
        if record.get("project") != str(root) or type(record.get("enabled")) is not bool:
            raise ValueError("Invalid project state; refusing to assume activation")
        enabled = record["enabled"]
    if args.action == "on":
        binary = rtk_binary()
        subprocess.run([binary, "--version"], check=True, capture_output=True, text=True)
        siblings = Path(__file__).resolve().parents[2]
        for name in ("ultracave", "ponytail"):
            if not (siblings / name / "SKILL.md").is_file():
                raise FileNotFoundError("Missing sibling skill: " + name)
    if args.action in ("on", "off"):
        enabled = args.action == "on"
        state_dir.mkdir(parents=True, exist_ok=True)
        import tempfile
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=state_dir,
                                         delete=False, suffix=".tmp") as handle:
            json.dump({"project": str(root), "enabled": enabled}, handle)
            temporary = Path(handle.name)
        try:
            os.replace(temporary, state_file)
        finally:
            temporary.unlink(missing_ok=True)
    if args.action == "gain":
        return subprocess.run([rtk_binary(), "gain", "--project"], cwd=root).returncode
    print(json.dumps({"project": str(root), "enabled": enabled,
                      "rtk_mode": "agent-instructions" if enabled else "off",
                      "ultracave": enabled, "ponytail": "full" if enabled else "off",
                      "state_file": str(state_file)}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print("Optimus error: " + str(error), file=sys.stderr)
        sys.exit(1)
