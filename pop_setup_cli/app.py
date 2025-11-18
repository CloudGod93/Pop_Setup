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
        if choice == "1":
            profile_id = ui.prompt_install_mode()
            profile = profiles.get(profile_id)
            if not profile:
                print("Unknown profile selection.")
                continue
            heading = f"Install all ({profile.description or profile.id})"
            results = executor.run_profile(profile_id)
            ui.display_results(results, heading)
            ui.print_run_summary(results)
        elif choice == "2":
            selection = ui.prompt_script_selection(list(scripts.values()))
            if not selection:
                continue
            results = executor.run_scripts(selection)
            ui.display_results(results, "Install selected")
            ui.print_run_summary(results)
        elif choice == "3":
            results = executor.run_all_checks()
            ui.display_results(results, "System status")
            ui.print_check_summary(results)
        elif choice == "q":
            print("Goodbye.")
            break
        else:
            print("Invalid choice.")


if __name__ == "__main__":
    main()
