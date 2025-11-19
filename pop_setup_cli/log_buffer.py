from __future__ import annotations

from collections import deque
from threading import Lock
from typing import Deque, List


class LogBuffer:
    def __init__(self, max_lines: int = 2000) -> None:
        self.max_lines = max_lines
        self._buffer: Deque[str] = deque(maxlen=max_lines)
        self._lock = Lock()

    def append(self, line: str) -> None:
        with self._lock:
            self._buffer.append(line)

    def clear(self) -> None:
        with self._lock:
            self._buffer.clear()

    def tail(self, count: int = 50) -> List[str]:
        with self._lock:
            if count <= 0:
                return []
            return list(self._buffer)[-count:]
