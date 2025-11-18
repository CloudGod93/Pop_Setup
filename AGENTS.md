# PopSetupCLI – Codex Agent Instructions

## Project Overview

This repository contains a Python terminal application that orchestrates system setup tasks for Pop!_OS machines.

The goals:

- Provide a **single CLI entrypoint** that opens a "Pop_Setup" style terminal UI.
- Allow the user to:
  - **Install all** dependencies for a machine, with two modes:
    - `developer` PC (default)
    - `project` PC
  - **Install selected** items from the available install scripts.
  - **Check system state** and compare against what should be installed, showing a status/summary in the terminal.
- Keep individual install steps as **separate scripts** in a dedicated directory, referenced via configuration, so new steps can be added without modifying the core app.
- Run inside a **small conda environment** (mini-conda) and avoid unnecessary dependencies.

The existing `pop_setup.sh` script lives in the repo root **locally** as a legacy reference and **must not be modified**. It is not intended to be committed to git.

## Tech & Style

- Language: **Python 3**.
- CLI / TUI:
  - Use a simple CLI entrypoint (e.g. `python -m pop_setup_cli` or `pop-setup` installed via console_scripts later).
  - For output styling, prefer **`rich`** if needed for colored/status output.
  - Avoid heavy/full-screen TUI frameworks unless explicitly requested.
- Configuration:
  - Use **YAML** (preferred) or JSON in `configs/` for:
    - Script metadata (`scripts.yml`)
    - Profiles / bundles (`profiles.yml`)
- Scripts:
  - Individual install/check steps live in `scripts/` as separate files (`.sh` or `.py`), referenced by config.
  - Keep things **DRY** and data-driven: adding a new script should be possible by:
    1. Dropping the file into `scripts/`
    2. Adding a config entry
    3. Optionally attaching it to a profile

### Code Style

- Python style: PEP 8, 4-space indents.
- Comments: **minimal** and practical, only where it improves clarity.
- No tutorial-style comments or verbose logging.
- Keep terminal output **clean and readable**, not noisy.

## High-Level Behavior

The Python app should provide a menu-driven flow like:

1. **Main Menu**
   - `1) Install all`
   - `2) Install selected`
   - `3) Check system status`
   - `q) Quit`

2. **Install All**
   - Prompt: "Install mode: [developer / project] (default: developer)"
   - Based on mode, load the configured profile from `configs/profiles.yml` and run the corresponding scripts.
   - Show a concise status for each script:
     - `[OK]` if already satisfied
     - `[RUN]` while running
     - `[DONE]` if install succeeds
     - `[FAIL]` if script exits non-zero (with a short error summary)

3. **Install Selected**
   - Load the list of scripts from `configs/scripts.yml`.
   - Show them with numbers and short descriptions.
   - Allow selecting one or more scripts to run (e.g. comma-separated indices, or simple repeated prompts).
   - Use the same status visuals as "Install all".

4. **Check System Status**
   - For each script (or each defined "check" entry), run a **check-only** function or command defined in config.
   - Summarize:
     - Which components are installed
     - Which are missing
   - Display a final summary (e.g. "10 checks passed, 3 missing").

### Profiles & Config

Suggested YAML structure for `configs/scripts.yml`:

```yaml
scripts:
  - id: git
    name: "Git"
    description: "Install and configure Git"
    script: "scripts/install_git.sh"
    check: "scripts/check_git.sh"
  - id: docker
    name: "Docker"
    description: "Install Docker and add user to docker group"
    script: "scripts/install_docker.sh"
    check: "scripts/check_docker.sh"
  - id: nvidia_driver
    name: "NVIDIA Drivers"
    description: "Install NVIDIA drivers for GPU workloads"
    script: "scripts/install_nvidia_driver.sh"
    check: "scripts/check_nvidia_driver.sh"
Suggested YAML structure for configs/profiles.yml:

yaml
Copy code
profiles:
  developer_pc:
    description: "Full developer workstation"
    scripts:
      - git
      - docker
      - nvidia_driver
      - conda
      - vscode
      - rustdesk
  project_pc:
    description: "Minimal runtime machine for a specific project"
    scripts:
      - git
      - docker
      - nvidia_driver
      - project_specific_runtime
When updating or generating code, honor the config format above (or its current variant in the repo) instead of hardcoding lists in Python. The Python app should treat config as the source of truth.

Repository Structure
Preferred layout for this project:

text
Copy code
.
├─ AGENTS.md                 # This file (Codex prompt)
├─ README.md
├─ pop_setup_cli/
│  ├─ __init__.py
│  ├─ app.py                 # CLI entrypoint
│  ├─ config_loader.py       # YAML loading utilities
│  ├─ executor.py            # Logic for running scripts and checks
│  ├─ models.py              # Dataclasses for Script, Profile, etc.
│  └─ ui.py                  # Menu rendering and status formatting
├─ configs/
│  ├─ scripts.yml
│  └─ profiles.yml
├─ scripts/
│  ├─ install_*.sh           # Individual install scripts
│  └─ check_*.sh             # Optional check scripts
└─ pop_setup.sh              # Legacy script, reference-only, not committed
Rules for pop_setup.sh
Treat pop_setup.sh as reference-only.

Do not rewrite, reformat, or "improve" it.

Do not copy its logic verbatim into new code; instead:

Extract patterns from it

Turn those into separate scripts and config entries

Implementation Guidance for Codex
When writing or modifying code in this repo:

Prefer small, focused modules:

app.py for CLI argument parsing and main menu orchestration.

config_loader.py for reading YAML configs.

executor.py to handle running scripts, aggregating results, and returning simple status objects.

ui.py to print menus and nicely formatted status messages (optionally using rich).

Keep functions pure-ish where possible:

Separate "determine what to run" from "run it in a shell".

Use subprocess.run (or similar) to call .sh scripts, with:

check=False

Capture return code and minimal stderr for summary output.

Avoid interactive prompts inside the scripts themselves; keep interaction in Python.

Keep comments and logging minimal and practical.

Non-Goals
No full-screen TUI framework unless explicitly requested.

No heavy dependency chains beyond what’s needed for:

CLI

YAML parsing

Optional nicer terminal output