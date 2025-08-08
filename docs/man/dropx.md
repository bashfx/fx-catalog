# DropX + DropL (FX Edition)

A **simple but powerful** file drop + manifest-based syncing utility for Linux/WSL, designed to work with a `drop` folder and **automatically move, copy, or extract files** to the correct destinations based on fuzzy patterns or aliases.

---

## Overview

DropX is the **worker process** — it watches your drop folder and executes rules from manifest files.

DropL is the **launcher/control script** — it starts/stops DropX in the background, tails logs, nukes watcher processes, and manages configs.

---

## Key Features

- **One-way sync**: From a designated drop folder to various destinations.
- **Manifest-based routing** with fuzzy matching, renaming (alias), and path expansion.
- **Supports**:
  - File moves
  - Directory moves
  - `.zip` extraction
- **Safe mode policies** for Git repositories (`auto`, `true`, `false`).
- **Multiple manifest sources**:
  1. Inside drop folder (`manifest.rc`)
  2. User manifest (`$HOME/.local/etc/fx/drop.conf`)
  3. CLI `-m` argument
- **Config cursor** (`.droprc`) to remember last manifest used.
- **Ignore patterns** in `drop.conf`.
- **Live watcher** using `inotifywait`.
- **3-tier logging system**:
  - **QUIET** (default) — banner + manifests + warnings/errors
  - **INFO** (`DROPX_VERBOSE=1`) — transfers, collisions, git actions
  - **DEBUG** (`DEBUG_MODE=0`) — full trace, globs, skips, poll ticks

---

## Installation

Place both scripts somewhere in your PATH.

```bash
chmod +x dropx dropl
mv dropx ~/.my/bin/dropx
mv dropl ~/.local/bin/dropl
```

Create default config:

```bash
mkdir -p ~/.local/etc/fx ~/.local/var/fx ~/.local/run/fx
cat > ~/.local/etc/fx/drop.conf <<'EOF'
DROPX_BIN="$HOME/.my/bin/dropx"
DROPX_SRC_DIR="/mnt/c/Users/<user>/Desktop/dropoff"
DROPX_LOG_DIR="$HOME/.local/var/fx"
DROPX_RUN_DIR="$HOME/.local/run/fx"
DROPX_VERBOSE=1        # INFO mode
# DEBUG_MODE=0         # uncomment for DEBUG mode
EOF
```

---

## Manifest Syntax

Each line has up to **4 columns**:

```
<pattern> <alias> <destination> [flags]
```

- `<pattern>` — filename glob (case-insensitive). Can be fuzzy (`file*`).
- `<alias>` — `self` to keep original name, or a new name (no extension for zip extracts).
- `<destination>` — target directory (supports `$HOME`, `~`, etc.)
- `[flags]` — `key=val` pairs, e.g.:
  - `policy=auto|true|false`
  - `action=extract|move|copy`

**Example:**
```
some_file*        self        $HOME/repos/some/
other_file*rc     self        $HOME/links/
my_zip_v11.zip    zip_11      $HOME/repos/myproj/   action=extract policy=auto
```

---

## Usage

### Start watching
```bash
dropl start
```
or specify a drop folder:
```bash
dropl start -- -s "/path/to/drop"
```

### Tail logs
```bash
dropl tail
```

### Stop watching
```bash
dropl stop
```

### Kill all DropX/inotify processes
```bash
dropl nuke
```

### Show status
```bash
dropl status
```

---

## Git Safe Mode

If `policy=auto` is set and the destination is a Git repo with uncommitted changes, DropX will automatically `git add` and `git commit -m "fix: auto sync save <timestamp>"` before overwriting.

If `policy=true` — prompt the user (not available in background mode, so will fail).
If `policy=false` or unset — abort the operation if the repo is dirty.

---

## Ignore Patterns

You can define ignore globs in `drop.conf`:
```bash
DROPX_IGNORE[0]="*.Zone.Identifier"
DROPX_IGNORE[1]="Thumbs.db"
```
These files are skipped even if they match a manifest.

---

## Logging Modes

- **QUIET** (default): Only essentials.
- **INFO**: Set `DROPX_VERBOSE=1` in config.
- **DEBUG**: Set `DEBUG_MODE=0`.

Example in config:
```bash
DROPX_VERBOSE=1
DEBUG_MODE=0
```

---

## Tips

- DropX automatically reloads the manifest when it changes — no restart needed.
- If multiple patterns match the same alias+destination, it’s treated as a collision and skipped.
- Fuzzy matches (`file*`) are safe if `alias=self` because each file gets its own unique name.

---

## License

MIT — free to modify and use.

---


### ZIP Merge (`zipmerge`)

For zip files, you can **merge** the archive contents into an existing directory, overwriting files that exist and leaving unrelated files untouched.

- **Flag:** `zipmerge=true`
- **Alias:** used as the **target directory name** inside the destination. If you use `alias=self`, the directory name defaults to the zip base name.

**Examples**
```
# Merge archive contents into $HOME/app/static/ (do not create a new versioned subfolder)
static_assets_v42.zip   static    $HOME/app/    action=extract;zipmerge=true

# Merge using the zip's own base name as the target directory
theme_pack.zip          self      $HOME/app/    action=extract;zipmerge=true
```
