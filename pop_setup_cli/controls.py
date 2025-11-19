from __future__ import annotations

import select
import sys
import threading
from queue import SimpleQueue, Empty
from typing import Optional, TYPE_CHECKING

from rich.console import Console

if TYPE_CHECKING:
    from .ui import InstallProgress


class InstallController:
    def __init__(self, console: Console) -> None:
        self.console = console
        self._actions: SimpleQueue[str] = SimpleQueue()
        self._stop_event = threading.Event()
        self._thread: Optional[threading.Thread] = None
        self._tracker: Optional["InstallProgress"] = None

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

    def set_tracker(self, tracker: "InstallProgress") -> None:
        self._tracker = tracker

    def consume_action(self) -> Optional[str]:
        try:
            return self._actions.get_nowait()
        except Empty:
            return None

    def _enqueue_action(self, action: str) -> None:
        self._actions.put(action)

    def _prompt_loop(self) -> None:
        self.console.print(
            "\n[dim]Controls active. Type 1 (status), 2 (skip), or 3 (cancel) and press Enter.[/dim]"
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
            if action == "status":
                tracker = self._tracker
                if tracker:
                    tracker.show_log_view()
                continue
            if action == "skip":
                self.console.print(
                    "[yellow]Skip requested. Attempting to skip current script...[/yellow]"
                )
            elif action == "cancel":
                self.console.print("[red]Cancel requested. Stopping as soon as possible.[/red]")
            self._enqueue_action(action)

    @staticmethod
    def _parse_action(value: str) -> Optional[str]:
        if value in {"1", "status"}:
            return "status"
        if value in {"2", "s", "skip"}:
            return "skip"
        if value in {"3", "c", "cancel"}:
            return "cancel"
        return None
