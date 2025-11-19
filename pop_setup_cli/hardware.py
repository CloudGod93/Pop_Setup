from __future__ import annotations

import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Sequence, Tuple


@dataclass
class HardwareState:
    has_nvidia_gpu: bool
    gpu_description: str = ""
    usb_mount: Optional[Path] = None

    @property
    def usb_present(self) -> bool:
        return self.usb_mount is not None


class HardwareDetector:
    def __init__(self, usb_candidates: Optional[Sequence[str | Path]] = None) -> None:
        env_path = os.environ.get("USB_DRIVE_PATH")
        default_candidates: List[Path] = []
        if env_path:
            default_candidates.append(Path(env_path))
        default_candidates.append(Path("/media/Samsung_USB"))
        if usb_candidates:
            default_candidates.extend(Path(path) for path in usb_candidates)
        # Stabilize order and drop duplicates
        seen = set()
        self.usb_candidates = []
        for candidate in default_candidates:
            resolved = candidate
            key = resolved.resolve()
            if key in seen:
                continue
            seen.add(key)
            self.usb_candidates.append(resolved)

    def detect(self) -> HardwareState:
        has_gpu, description = self._detect_gpu()
        usb_mount = self._detect_usb_mount()
        return HardwareState(
            has_nvidia_gpu=has_gpu,
            gpu_description=description,
            usb_mount=usb_mount,
        )

    def _detect_gpu(self) -> Tuple[bool, str]:
        description = ""
        try:
            result = subprocess.run(
                ["lspci"],
                capture_output=True,
                text=True,
                check=False,
            )
            if result.returncode == 0:
                for line in result.stdout.splitlines():
                    if "nvidia" in line.lower():
                        description = line.strip()
                        return True, description
        except FileNotFoundError:
            pass

        try:
            result = subprocess.run(
                ["nvidia-smi", "-L"],
                capture_output=True,
                text=True,
                check=False,
            )
            if result.returncode == 0 and result.stdout.strip():
                return True, result.stdout.strip().splitlines()[0]
        except FileNotFoundError:
            pass

        return False, description

    def _detect_usb_mount(self) -> Optional[Path]:
        for candidate in self.usb_candidates:
            if candidate.exists():
                return candidate
        return None
