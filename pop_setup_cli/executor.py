from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Dict, List, Sequence

from .models import ExecutionResult, Profile, Script


class Executor:
    def __init__(
        self,
        scripts: Dict[str, Script],
        profiles: Dict[str, Profile],
        base_path: Path,
    ) -> None:
        self.scripts = scripts
        self.profiles = profiles
        self.base_path = base_path

    def run_profile(self, profile_id: str) -> List[ExecutionResult]:
        if profile_id not in self.profiles:
            raise ValueError(f"Unknown profile '{profile_id}'")
        profile = self.profiles[profile_id]
        return self.run_scripts(profile.scripts)

    def run_scripts(self, script_ids: Sequence[str]) -> List[ExecutionResult]:
        results: List[ExecutionResult] = []
        for script_id in script_ids:
            script = self.scripts.get(script_id)
            if not script:
                raise ValueError(f"Unknown script '{script_id}'")
            results.extend(self._run_install_flow(script))
        return results

    def run_all_checks(self) -> List[ExecutionResult]:
        results: List[ExecutionResult] = []
        for script in self.scripts.values():
            results.append(self._run_check(script))
        return results

    def _run_install_flow(self, script: Script) -> List[ExecutionResult]:
        results: List[ExecutionResult] = []
        check_result = self._run_check(script)
        results.append(check_result)
        if check_result.status == "OK":
            return results
        results.append(
            ExecutionResult(
                script_id=script.id,
                script_name=script.name,
                phase="install",
                status="RUN",
                message="Running install script",
            )
        )
        exec_result = self._run_path(script.script_path)
        results.append(
            ExecutionResult(
                script_id=script.id,
                script_name=script.name,
                phase="install",
                status="DONE" if exec_result[0] == 0 else "FAIL",
                message=self._format_message(exec_result[1], exec_result[2])
                if exec_result[0] != 0
                else exec_result[1].strip() or "Completed",
            )
        )
        return results

    def _run_check(self, script: Script) -> ExecutionResult:
        if not script.check_path:
            return ExecutionResult(
                script_id=script.id,
                script_name=script.name,
                phase="check",
                status="SKIP",
                message="No check defined",
            )
        exec_result = self._run_path(script.check_path)
        status = "OK" if exec_result[0] == 0 else "FAIL"
        message = exec_result[1].strip() or self._format_message(exec_result[1], exec_result[2])
        if status == "FAIL" and not message:
            message = "Check failed"
        return ExecutionResult(
            script_id=script.id,
            script_name=script.name,
            phase="check",
            status=status,
            message=message,
        )

    def _run_path(self, relative_path: str) -> tuple[int, str, str]:
        path = (self.base_path / relative_path).resolve()
        if not path.exists():
            return 1, "", f"Script not found: {path}"
        cmd = self._build_command(path)
        result = subprocess.run(
            cmd,
            cwd=self.base_path,
            capture_output=True,
            text=True,
            check=False,
        )
        return result.returncode, result.stdout, result.stderr

    @staticmethod
    def _build_command(path: Path) -> List[str]:
        if path.suffix == ".py":
            return ["python3", str(path)]
        return ["bash", str(path)]

    @staticmethod
    def _format_message(stdout: str, stderr: str) -> str:
        output = stderr.strip() or stdout.strip()
        return output or ""
