from __future__ import annotations

from contextlib import contextmanager
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Sequence

from rich.console import Console, Group
from rich.live import Live
from rich.panel import Panel
from rich.progress import (
    BarColumn,
    Progress,
    SpinnerColumn,
    TaskID,
    TextColumn,
    TimeElapsedColumn,
    TimeRemainingColumn,
)
from rich.table import Table

from .hardware import HardwareState
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


def show_hardware_summary(state: HardwareState) -> None:
    gpu_line = (
        f"[green]NVIDIA GPU detected[/green] ({state.gpu_description})"
        if state.has_nvidia_gpu and state.gpu_description
        else (
            "[green]NVIDIA GPU detected[/green]"
            if state.has_nvidia_gpu
            else "[yellow]No NVIDIA GPU detected[/yellow]"
        )
    )
    usb_line = (
        f"[green]USB drive detected[/green]: {state.usb_mount}"
        if state.usb_present
        else "[yellow]USB drive not detected[/yellow]"
    )
    console.print(
        Panel.fit(
            f"{gpu_line}\n{usb_line}",
            border_style="magenta",
            title="Hardware Check",
        )
    )


@dataclass
class InstallProgress:
    progress: Progress
    overall_task: TaskID
    scripts: Sequence[Script]
    statuses: Dict[str, str] = field(default_factory=dict)
    live: Optional[Live] = None

    def __post_init__(self) -> None:
        for script in self.scripts:
            self.statuses[script.id] = "PENDING"

    def hook(
        self,
        event: str,
        index: int,
        total: int,
        script: Script,
        final_status: Optional[str] = None,
    ) -> None:
        if total <= 0:
            return
        if event == "start":
            description = f"[cyan]{script.name}[/cyan] ({index}/{total})"
            self.progress.update(self.overall_task, description=description)
            self._set_status(script.id, "RUN")
        elif event == "end":
            self.progress.advance(self.overall_task)
            resolved_status = final_status or "DONE"
            self._set_status(script.id, resolved_status)
            if index == total:
                self.progress.update(self.overall_task, description="[green]Install complete[/green]")
        elif event == "skip":
            description = f"[yellow]{script.name}[/yellow] ({index}/{total})"
            self.progress.update(self.overall_task, description=description)
            self.progress.advance(self.overall_task)
            self._set_status(script.id, final_status or "SKIP")
            if index == total:
                self.progress.update(self.overall_task, description="[green]Install complete[/green]")
        self.refresh()

    def _set_status(self, script_id: str, status: str) -> None:
        if script_id not in self.statuses:
            return
        self.statuses[script_id] = status.upper()

    def _status_table(self) -> Table:
        table = Table(show_header=True, header_style="bold magenta")
        table.add_column("Script", min_width=24)
        table.add_column("Status", style="bold", width=10)
        for script in self.scripts:
            status = self.statuses.get(script.id, "PENDING")
            style = STATUS_STYLES.get(status.upper(), "white")
            label = f"[{style}]{status}[/{style}]"
            table.add_row(script.name, label)
        return table

    def render(self):
        status_panel = Panel(
            self._status_table(),
            border_style="magenta",
            title="Script Status",
        )
        progress_panel = Panel(
            self.progress,
            border_style="cyan",
            title="Install Progress",
        )
        return Group(progress_panel, status_panel)

    def set_live(self, live: Live) -> None:
        self.live = live
        self.refresh()

    def refresh(self) -> None:
        if self.live:
            self.live.update(self.render())


@contextmanager
def install_progress(scripts_to_run: Sequence[Script]):
    total_scripts = len(scripts_to_run)
    if total_scripts <= 0:
        yield None
        return
    columns = (
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(bar_width=None),
        TextColumn("{task.completed}/{task.total}"),
        TextColumn("{task.percentage:>3.0f}%"),
        TimeElapsedColumn(),
        TimeRemainingColumn(),
    )
    progress = Progress(*columns, console=console, transient=True)
    overall_task = progress.add_task(
        "[cyan]Preparing install[/cyan]",
        total=total_scripts,
    )
    tracker = InstallProgress(progress, overall_task, scripts_to_run)
    with Live(
        tracker.render(),
        console=console,
        refresh_per_second=8,
        transient=True,
    ) as live:
        tracker.set_live(live)
        yield tracker
