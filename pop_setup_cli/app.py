from __future__ import annotations

from pathlib import Path

from .config_loader import load_configs
from .executor import Executor
from . import ui


def main() -> None:
    base_path = Path(__file__).resolve().parent.parent
    scripts, profiles = load_configs(base_path)
    executor = Executor(scripts, profiles, base_path)

    while True:
        choice = ui.prompt_main_menu()
        try:
            if choice == "1":
                ui.clear_screen()
                profile_id = ui.prompt_install_mode()
                if profile_id is None:
                    ui.show_message("Install cancelled.", "yellow")
                    ui.wait_for_enter()
                    continue
                profile = profiles.get(profile_id)
                if not profile:
                    ui.show_message("Unknown profile selection.", "red")
                    ui.wait_for_enter()
                    continue
                hardware_state = executor.refresh_hardware_state()
                ui.show_hardware_summary(hardware_state)
                ui.show_status(f"Running profile: {profile.description or profile.id}")
                heading = f"Install all ({profile.description or profile.id})"
                scripts_to_run = profile.scripts
                script_objects = [scripts[sid] for sid in scripts_to_run if sid in scripts]
                with ui.install_progress(script_objects) as tracker:
                    hook = tracker.hook if tracker else None
                    results = executor.run_profile(profile_id, progress_hook=hook)
                ui.display_results(results, heading)
                ui.print_run_summary(results)
                ui.wait_for_enter()
            elif choice == "2":
                ui.clear_screen()
                selection = ui.prompt_script_selection(list(scripts.values()))
                if selection is None:
                    ui.show_message("Selection cancelled.", "yellow")
                    ui.wait_for_enter()
                    continue
                if not selection:
                    ui.show_message("No scripts selected.", "yellow")
                    ui.wait_for_enter()
                    continue
                hardware_state = executor.refresh_hardware_state()
                ui.show_hardware_summary(hardware_state)
                ui.show_status("Running selected scripts")
                script_objects = [scripts[sid] for sid in selection if sid in scripts]
                with ui.install_progress(script_objects) as tracker:
                    hook = tracker.hook if tracker else None
                    results = executor.run_scripts(selection, progress_hook=hook)
                ui.display_results(results, "Install selected")
                ui.print_run_summary(results)
                ui.wait_for_enter()
            elif choice == "3":
                ui.clear_screen()
                hardware_state = executor.refresh_hardware_state()
                ui.show_hardware_summary(hardware_state)
                ui.show_status("Gathering system status")
                results = executor.run_all_checks()
                ui.display_results(results, "System status")
                ui.print_check_summary(results)
                ui.wait_for_enter()
            elif choice == "q":
                ui.show_message("Goodbye.", "cyan")
                break
            else:
                ui.show_message("Invalid choice.", "red")
                ui.wait_for_enter()
        except KeyboardInterrupt:
            ui.show_message("\n[yellow]Interrupted. Returning to menu.[/yellow]")
            ui.wait_for_enter()


if __name__ == "__main__":
    main()
