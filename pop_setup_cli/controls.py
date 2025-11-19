from __future__ import annotations

import select
import sys
import threading
from typing import Optional

from rich.console import Console


class InstallController:
    def __init__(self, console: Console) -> None:
        self.console = console
        self._action: Optional[str] = None
        self._lock = threading.Lock()
        self._stop_event = threading.Event()
        self._thread: Optional[threading.Thread] = None

    def start(self) -> None:
        if self._thread and self._thread.is_alive():
            return
        self._stop_event.clear()
        self._thread = threading.Thread(target=self._prompt_loop, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._stop_event.set()
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=0.2)

    def consume_action(self) -> Optional[str]:
        with self._lock:
            action = self._action
            self._action = None
            return action

    def _set_action(self, action: str) -> None:
        with self._lock:
            self._action = action

    def _prompt_loop(self) -> None:
        self.console.print(
            "\n[dim]Controls active: type 1 (skip) or 2 (cancel) and press Enter.[/dim]"
        )
        while not self._stop_event.is_set():
            ready, _, _ = select.select([sys.stdin], [], [], 0.2)
            if self._stop_event.is_set():
                break
            if not ready:
                continue
            line = sys.stdin.readline()
            if line == "":
                return
            action = self._parse_action(line.strip().lower())
            if not action:
                continue
            self._set_action(action)
            if action == "skip":
                self.console.print(
                    "[yellow]Skip requested. Will skip the next script when safe.[/yellow]"
                )
            elif action == "cancel":
                self.console.print("[red]Cancel requested. Stopping as soon as possible.[/red]")

    @staticmethod
    def _parse_action(value: str) -> Optional[str]:
        if value in {"1", "s", "skip"}:
            return "skip"
        if value in {"2", "c", "cancel"}:
            return "cancel"
        return None
