# 🚀 Pop Setup CLI

A streamlined terminal companion for provisioning Pop!_OS developer and project machines. Powered by Python and simple shell scripts, Pop Setup CLI centralizes install flows, checks, and configuration in one ergonomic menu.

![Pop Setup CLI screenshot](https://dummyimage.com/1200x380/1a1a1a/09f/&text=Pop+Setup+CLI+preview)

## ✨ Highlights
- **Single entrypoint** – run `python -m pop_setup_cli` for a guided menu.
- **Profile-aware installs** – switch between `developer_pc` and `project_pc` bundles from YAML config.
- **Composable scripts** – add install/check steps by dropping shell scripts into `scripts/` and registering them in config.
- **Status-first UX** – concise `[OK]`, `[RUN]`, `[DONE]`, `[FAIL]` tags across install and check flows.
- **Safe placeholders** – sample git/docker/runtime scripts demonstrate the pattern without touching real packages.

## ⚡ Fresh Machine Setup
The bootstrap script handles everything for a brand-new Pop!_OS 22.04 machine:

```bash
git clone <repo>
cd Pop_Setup
bash bootstrap_pop_setup.sh
```

It verifies `python3`, installs `python3-venv` and `python3-pip` if needed, creates `.venv`, installs `requirements.txt`, and launches the CLI.

## 🧰 Manual install without bootstrap
Prefer manual control? Use standard `venv` and pip:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m pop_setup_cli
```

## 🧩 Project Layout
```
.
├─ pop_setup_cli/
│  ├─ app.py              # main loop + CLI entry
│  ├─ config_loader.py    # YAML parsing & validation
│  ├─ executor.py         # run checks/installs via subprocess
│  ├─ models.py           # dataclasses for Script/Profile/Result
│  └─ ui.py               # menus, prompts, formatted output
├─ configs/
│  ├─ scripts.yml         # install/check metadata
│  └─ profiles.yml        # profile definitions (developer/project)
├─ scripts/               # individual install/check scripts
│  ├─ install_*.sh
│  └─ check_*.sh
├─ bootstrap_pop_setup.sh # venv bootstrap + CLI launcher
└─ pop_setup.sh           # legacy reference (do not modify)
```

## 🖥️ CLI Overview
```
Pop Setup
1) Install all
2) Install selected
3) Check system status
q) Quit
```

- **Install all** prompts for `developer` (default) or `project` mode and runs the respective profile.
- **Install selected** lists every script from `configs/scripts.yml` for ad-hoc execution.
- **Check system status** executes only check scripts and summarizes installed vs missing.

## 🛠️ Configuration Model
`configs/scripts.yml`:
```yaml
scripts:
  - id: git
    name: "Git"
    description: "Install and configure Git"
    script: "scripts/install_git.sh"
    check: "scripts/check_git.sh"
```

`configs/profiles.yml`:
```yaml
profiles:
  developer_pc:
    description: "Full developer workstation"
    scripts:
      - system_prep
      - docker
      - nodejs
  project_pc:
    description: "Project runtime machine"
    scripts:
      - system_prep
      - docker
```

Add a new component by:
1. Writing `scripts/install_<name>.sh` (and optional `scripts/check_<name>.sh`).
2. Adding an entry to `configs/scripts.yml`.
3. Referencing its `id` in any profile inside `configs/profiles.yml`.

## 📜 Sample Scripts
The repo ships with placeholder scripts for Git, Docker, runtimes, desktop apps, and more. Each script is bash-based with safe `echo`/`sleep` commands so you can observe the CLI flow without changing your system. Replace them with real install logic once you’re ready.

## 🧪 Development Notes
- Python 3.x, 4-space indentation, minimal comments per project guidelines.
- Execution uses `subprocess.run(..., check=False)` to stream concise success/failure markers.
- `pop_setup.sh` is legacy reference only—leave it untouched.
- Optional dependencies like `rich` can enhance console styling if desired.

## 🤝 Contributing
1. Fork & branch.
2. Keep new install/check logic modular—one script per task.
3. Update configs and profiles as needed.
4. Run the CLI (`python -m pop_setup_cli`) to validate UX before pushing.

## 📄 License
Add your preferred license information here.

Happy provisioning! 🛠️
