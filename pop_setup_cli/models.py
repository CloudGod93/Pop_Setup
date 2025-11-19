from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class Script:
    id: str
    name: str
    description: str
    script_path: str
    check_path: Optional[str] = None
    hardware: List[str] = field(default_factory=list)


@dataclass
class Profile:
    id: str
    description: str
    scripts: List[str]


@dataclass
class ExecutionResult:
    script_id: str
    script_name: str
    phase: str
    status: str
    message: str = ""
