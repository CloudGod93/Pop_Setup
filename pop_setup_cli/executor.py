from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Callable, Dict, List, Optional, Sequence, Protocol

from .hardware import HardwareDetector, HardwareState
from .models import ExecutionResult, Profile, Script

ProgressHook = Callable[[str, int, int, Script, Optional[str]], None]


class InstallControl(Protocol):
    def consume_action(self) -> Optional[str]:
        ...


class Executor:
    def __init__(
        self,
        scripts: Dict[str, Script],
        profiles: Dict[str, Profile],
        base_path: Path,
        hardware_detector: Optional[HardwareDetector] = None,
    ) -> None:
        self.scripts = scripts
        self.profiles = profiles
        self.base_path = base_path
        self.hardware_detector = hardware_detector or HardwareDetector()
        self._hardware_state: Optional[HardwareState] = None

    def run_profile(
        self,
        profile_id: str,
        progress_hook: Optional[ProgressHook] = None,
        controller: Optional[InstallControl] = None,
    ) -> List[ExecutionResult]:
        if profile_id not in self.profiles:
            raise ValueError(f"Unknown profile '{profile_id}'")
        profile = self.profiles[profile_id]
        return self.run_scripts(
            profile.scripts,
            progress_hook=progress_hook,
            controller=controller,
        )

    def run_scripts(
        self,
        script_ids: Sequence[str],
        progress_hook: Optional[ProgressHook] = None,
        controller: Optional[InstallControl] = None,
    ) -> List[ExecutionResult]:
        results: List[ExecutionResult] = []
        total = len(script_ids)
        hardware_state = self.get_hardware_state()
        for index, script_id in enumerate(script_ids, start=1):
            script = self.scripts.get(script_id)
            if not script:
                raise ValueError(f"Unknown script '{script_id}'")
            action = self._consume_control_action(controller)
            if action == "cancel":
                cancel_result = self._user_cancel_result(script)
                results.append(cancel_result)
                if progress_hook:
                    progress_hook("cancel", index, total, script, "CANCEL")
                break
            if action == "skip":
                skip_result = self._user_skip_result(script)
                results.append(skip_result)
                if progress_hook:
                    progress_hook("skip", index, total, script, "SKIP")
                continue
            skip_reason = self._hardware_skip_reason(script, hardware_state)
            if skip_reason:
                results.append(self._hardware_skip_result(script, skip_reason))
                if progress_hook:
                    progress_hook("skip", index, total, script, "SKIP")
                continue
            if progress_hook:
                progress_hook("start", index, total, script, None)
            script_results = self._run_install_flow(script)
            results.extend(script_results)
            final_status = script_results[-1].status if script_results else "DONE"
            if progress_hook:
                progress_hook("end", index, total, script, final_status)
        return results

    def run_all_checks(self) -> List[ExecutionResult]:
        results: List[ExecutionResult] = []
        hardware_state = self.get_hardware_state()
        for script in self.scripts.values():
            skip_reason = self._hardware_skip_reason(script, hardware_state)
            if skip_reason:
                results.append(self._hardware_skip_result(script, skip_reason))
                continue
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

    def describe_hardware(self) -> str:
        state = self.get_hardware_state()
        gpu_part = (
            f"NVIDIA GPU detected ({state.gpu_description})"
            if state.has_nvidia_gpu and state.gpu_description
            else ("NVIDIA GPU detected" if state.has_nvidia_gpu else "No NVIDIA GPU detected")
        )
        usb_part = (
            f"USB drive mounted at {state.usb_mount}"
            if state.usb_present
            else "USB drive not detected"
        )
        return f"{gpu_part}; {usb_part}"

    def get_hardware_state(self) -> HardwareState:
        if not self._hardware_state:
            self._hardware_state = self.hardware_detector.detect()
        return self._hardware_state

    def refresh_hardware_state(self) -> HardwareState:
        self._hardware_state = self.hardware_detector.detect()
        return self._hardware_state

    @staticmethod
    def _hardware_skip_result(script: Script, reason: str) -> ExecutionResult:
        return ExecutionResult(
            script_id=script.id,
            script_name=script.name,
            phase="hardware",
            status="SKIP",
            message=reason,
        )

    @staticmethod
    def _hardware_skip_reason(script: Script, state: HardwareState) -> Optional[str]:
        if not script.hardware:
            return None
        requirements = {req.lower() for req in script.hardware}
        if "gpu" in requirements and not state.has_nvidia_gpu:
            return "Skipped: NVIDIA GPU not detected"
        if "usb_drive" in requirements and not state.usb_present:
            return "Skipped: required USB drive not detected"
        return None

    @staticmethod
    def _user_skip_result(script: Script) -> ExecutionResult:
        return ExecutionResult(
            script_id=script.id,
            script_name=script.name,
            phase="install",
            status="SKIP",
            message="Skipped by user",
        )

    @staticmethod
    def _user_cancel_result(script: Script) -> ExecutionResult:
        return ExecutionResult(
            script_id=script.id,
            script_name=script.name,
            phase="install",
            status="CANCEL",
            message="Install cancelled by user",
        )

    @staticmethod
    def _consume_control_action(
        controller: Optional[InstallControl],
    ) -> Optional[str]:
        if not controller:
            return None
        return controller.consume_action()
