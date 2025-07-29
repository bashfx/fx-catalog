key# FX-SEMVER(1) Script for Semantic Versioning and Git Operations

## Overview

FX-SEMVER is a Bash utility that manages semantic version tags and build metadata directly from your Git history. It automates common versioning tasks and provides commands for inspecting repositories, comparing builds and generating release information.

## Installation

Clone this repository and place the `fx-semver` script somewhere in your `PATH`:

```bash
git clone <repo-url>
cd fx-semver
chmod +x fx-semver
cp fx-semver ~/bin/  # or any directory listed in $PATH
```

Run `fx-semver help` at any time to see the full built-in help text.

## Quick Workflow Example

```bash
fx-semver mark1     # tag repo with v0.0.1
# create commits using labels
git commit -m "feat: add feature"
git commit -m "fix: correct bug"
fx-semver bump      # creates v0.1.1 from commit history
```

## Commit Labels

| Prefix | Bump Level |
| ------ | ---------- |
| `brk:` | Major      |
| `feat:`| Minor      |
| `fix:` | Patch      |
| `dev:` | Dev/build |

These labels must prefix commit messages so the `bump` command can determine the next version number.

## Commands

Common commands include:

- `mark1`      – initialize versioning with `v0.0.1`.
- `bump`       – bump to the next major/minor/patch based on labels.
- `pend`       – show commits since the last version tag.
- `tags`       – list repository tags.
- `file <name>` – generate a build information file.
- `info`       – summary of repo status and next version.
- `since`      – display how long since the last commit.
- `snip`       – remove minor tags beyond the latest major.

See `fx-semver help` for the full list.

## Flags

- `--debug` / `-d`  – enable console output (default on).
- `--yes`   / `-y`  – auto-confirm prompts.
- `--dev`   / `-N`  – append `-buildNNN` or `-devN` when dev labels are present.
- `--build` / `-B`  – write build info to a `build/` directory.
- `--trace` / `-t`  – verbose trace of script actions.

## Build File

The `file` command writes a build file containing variables such as `DEV_VERS`, `DEV_BUILD`, and `DEV_DATE`. This can be sourced by other scripts or CI pipelines to track the current build state.

## Customization

Default commit prefixes are defined by environment variables:

```bash
SEMV_MAJ_LABEL="brk"  # breaking changes
SEMV_FEAT_LABEL="feat"
SEMV_FIX_LABEL="fix"
SEMV_DEV_LABEL="dev"
```

Adjust these variables to match your commit conventions.

## Dev Note

A commit labeled `dev:` marks a version chain as dirty. When bumping a version that contains dev commits, the script prompts for confirmation. Using `--dev` allows iterating on dev builds (`-devNNN` or `-buildNNN`) without increasing the semantic version.

