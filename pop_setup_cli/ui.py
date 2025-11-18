from __future__ import annotations

from typing import Dict, List, Sequence

from .models import ExecutionResult, Script


def prompt_main_menu() -> str:
    print("\nPop Setup")
    print("1) Install all")
    print("2) Install selected")
    print("3) Check system status")
    print("q) Quit")
    return input("Select an option: ").strip().lower()


def prompt_install_mode() -> str:
    choice = input("Install mode [developer/project] (default: developer): ").strip().lower()
    if choice.startswith("p"):
        return "project_pc"
    return "developer_pc"


def prompt_script_selection(scripts: Sequence[Script]) -> List[str]:
    print("\nAvailable scripts:")
    for index, script in enumerate(scripts, start=1):
        print(f"{index}) {script.name} - {script.description}")
    while True:
        raw = input("Select scripts (comma-separated numbers, blank to cancel): ").strip()
        if not raw:
            return []
        tokens = [token.strip() for token in raw.split(",") if token.strip()]
        selected: List[str] = []
        valid = True
        for token in tokens:
            if not token.isdigit():
                valid = False
                break
            idx = int(token) - 1
            if idx < 0 or idx >= len(scripts):
                valid = False
                break
            script_id = scripts[idx].id
            if script_id not in selected:
                selected.append(script_id)
        if valid and selected:
            return selected
        print("Invalid selection, try again.")


def display_results(results: Sequence[ExecutionResult], heading: str | None = None) -> None:
    if heading:
        print(f"\n{heading}")
        print("-" * len(heading))
    for result in results:
        tag = result.status.upper()
        phase = result.phase
        message = f" - {result.message}" if result.message else ""
        print(f"[{tag}] {result.script_name} ({phase}){message}")


def print_run_summary(results: Sequence[ExecutionResult]) -> None:
    latest: Dict[str, ExecutionResult] = {}
    for result in results:
        latest[result.script_id] = result
    successes = sum(1 for r in latest.values() if r.status in {"OK", "DONE"})
    failures = sum(1 for r in latest.values() if r.status == "FAIL")
    print(f"\nSummary: {successes} success, {failures} failed")


def print_check_summary(results: Sequence[ExecutionResult]) -> None:
    installed = sum(1 for r in results if r.status == "OK")
    missing = sum(1 for r in results if r.status != "OK")
    print(f"\nSystem status: {installed} installed, {missing} missing/unknown")
