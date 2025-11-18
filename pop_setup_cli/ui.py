from __future__ import annotations

from contextlib import contextmanager
from dataclasses import dataclass
from typing import Dict, List, Optional, Sequence

from rich.console import Console
from rich.panel import Panel
from rich.progress import (
    BarColumn,
    Progress,
    TaskID,
    TextColumn,
    TimeElapsedColumn,
    TimeRemainingColumn,
)
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


def show_status(message: str) -> None:
    console.print(Panel.fit(message, border_style="cyan"))


@dataclass
class InstallProgress:
    progress: Progress
    overall_task: TaskID
    current_task: TaskID

    def hook(self, event: str, index: int, total: int, script: Script) -> None:
        if total <= 0:
            return
        if event == "start":
            description = f"[cyan]{script.name}[/cyan] ({index}/{total})"
            self.progress.update(
                self.current_task,
                total=1,
                completed=0,
                description=description,
                visible=True,
            )
        elif event == "end":
            self.progress.update(self.current_task, completed=1)
            self.progress.advance(self.overall_task)


@contextmanager
def install_progress(total_scripts: int):
    if total_scripts <= 0:
        yield None
        return
    columns = (
        TextColumn("[progress.description]{task.description}"),
        BarColumn(bar_width=None),
        TextColumn("{task.completed}/{task.total}"),
        TextColumn("{task.percentage:>3.0f}%"),
        TimeElapsedColumn(),
        TimeRemainingColumn(),
    )
    progress = Progress(*columns, console=console, transient=True)
    with progress:
        overall_task = progress.add_task("Overall", total=total_scripts)
        current_task = progress.add_task("Current script", total=1)
        tracker = InstallProgress(progress, overall_task, current_task)
        yield tracker
