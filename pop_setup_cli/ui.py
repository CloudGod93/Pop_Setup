from __future__ import annotations

from typing import Dict, List, Optional, Sequence

from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from .models import ExecutionResult, Script

console = Console()

STATUS_STYLES = {
    "OK": "green",
    "DONE": "green",
    "RUN": "cyan",
    "FAIL": "red",
    "SKIP": "yellow",
}


def _read_input(prompt: str) -> Optional[str]:
    try:
        return console.input(prompt)
    except (KeyboardInterrupt, EOFError):
        console.print("\n[yellow]Input cancelled. Returning to menu.[/yellow]")
        return None


def clear_screen() -> None:
    console.clear()


def prompt_main_menu() -> str:
    console.clear()
    console.print(Panel.fit("[bold cyan]Pop Setup[/bold cyan]", border_style="cyan"))
    console.print("1) Install all", style="bold")
    console.print("2) Install selected", style="bold")
    console.print("3) Check system status", style="bold")
    console.print("q) Quit", style="bold")
    value = _read_input("\n[bold]Select an option:[/bold] ")
    if value is None:
        return "q"
    return value.strip().lower()


def prompt_install_mode() -> Optional[str]:
    console.print(Panel.fit("[bold cyan]Select Install Mode[/bold cyan]", border_style="cyan"))
    console.print("1) Developer PC (default)", style="bold")
    console.print("2) Project PC", style="bold")
    while True:
        choice = _read_input("\n[bold]Choose 1 or 2 (Enter for default):[/bold] ")
        if choice is None:
            return None
        choice = choice.strip().lower()
        if not choice or choice == "1" or choice.startswith("d"):
            return "developer_pc"
        if choice == "2" or choice.startswith("p"):
            return "project_pc"
        console.print("[red]Invalid selection. Use 1 or 2.[/red]")


def prompt_script_selection(scripts: Sequence[Script]) -> Optional[List[str]]:
    console.print("\n[bold]Available scripts:[/bold]")
    for index, script in enumerate(scripts, start=1):
        console.print(f"{index}) [cyan]{script.name}[/cyan] - {script.description}")
    while True:
        raw = _read_input(
            "\nSelect scripts (comma-separated numbers, blank to cancel): "
        )
        if raw is None:
            return None
        raw = raw.strip()
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
        console.print("[red]Invalid selection, try again.[/red]")


def display_results(results: Sequence[ExecutionResult], heading: str | None = None) -> None:
    if heading:
        console.print(f"\n[bold]{heading}[/bold]")
        console.rule()
    table = Table(show_header=True, header_style="bold magenta")
    table.add_column("Status", style="bold")
    table.add_column("Script", min_width=24)
    table.add_column("Phase", style="cyan")
    table.add_column("Details", overflow="fold")
    for result in results:
        status = result.status.upper()
        style = STATUS_STYLES.get(status, "white")
        message = " ".join(result.message.split()) if result.message else ""
        table.add_row(
            f"[{style}]{status}[/{style}]",
            result.script_name,
            result.phase,
            message,
        )
    console.print(table)


def print_run_summary(results: Sequence[ExecutionResult]) -> None:
    latest: Dict[str, ExecutionResult] = {}
    for result in results:
        latest[result.script_id] = result
    successes = sum(1 for r in latest.values() if r.status in {"OK", "DONE"})
    failures = sum(1 for r in latest.values() if r.status == "FAIL")
    console.print(f"\n[bold green]Summary:[/bold green] {successes} success, {failures} failed")


def print_check_summary(results: Sequence[ExecutionResult]) -> None:
    installed = sum(1 for r in results if r.status == "OK")
    missing = sum(1 for r in results if r.status != "OK")
    console.print(
        f"\n[bold green]System status:[/bold green] {installed} installed, {missing} missing/unknown"
    )


def wait_for_enter() -> None:
    _read_input("\n[dim]Press Enter to return to the main menu...[/dim]")


def show_message(message: str, style: str | None = None) -> None:
    if style:
        console.print(f"[{style}]{message}[/{style}]")
    else:
        console.print(message)
