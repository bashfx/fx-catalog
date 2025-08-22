#!/usr/bin/env bash
#===============================================================================
##                            __
##                           /\ \
##   ___ ___      __     _ __\ \ \/'\
## /' __` __`\  /'__`\  /\`'__\ \ , <
## /\ \/\ \/\ \/\ \L\.\_\ \ \/ \ \ \\`\
## \ \_\ \_\ \_\ \__/.\_\\ \_\  \ \_\ \_\
##  \/_/\/_/\/_/\/__/\/_/ \/_/   \/_/\/_/
##
#===============================================================================

# #[BASHFX] 5.2.1: Major Script Structure - meta section
# name: markman
# author: qodeninja
# version: 3.2.1

# #[BASHFX] 5.2.1: Major Script Structure - portable section
# portable: realpath, find, sort, basename, readlink, sed, tput, date, mkdir, ln, rm, cp, grep, awk
# builtins: printf, local, case, if, for, while, read, unset, cd

# #[BASHFX] 5.2.1: Major Script Structure - readonly section
readonly SELF_NAME="markman"
readonly REGEX_MARK_ID="^([@\_\.]{0,1}[[:alnum:]]+[-\_\.]{0,1}[[:alnum:]]*)+$"
readonly SENTINEL_TAG="FX_MARKMAN"
readonly LEGACY_SENTINEL_TAG="fx:markman"

# #[BASHFX] 5.2.1: Major Script Structure - config section
# XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/data}"
# XDG_LIB_HOME="${XDG_LIB_HOME:-$HOME/.local/lib}"
# XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
# readonly XDG_ETC_HOME="${XDG_ETC_HOME:-$HOME/.local/etc}"

FX_BIN_DIR="${XDG_BIN_HOME}/fx"

readonly MARK_ETC_DIR="${XDG_ETC_HOME}/fx/${SELF_NAME}"
readonly MARK_RC_FILE="${MARK_ETC_DIR}/${SELF_NAME}.rc"

readonly MARK_BIN_PATH="${FX_BIN_DIR}/mark"
readonly MARK_LIB_DIR="${XDG_LIB_HOME}/fx/${SELF_NAME}"
readonly MARK_DATA_DIR="${XDG_DATA_HOME}/fx/${SELF_NAME}"
readonly MARK_BACKUP_DIR="${MARK_DATA_DIR}/backups"


# Configuration for options()
opt_force=1; opt_quiet=1; opt_dev=1; opt_yes=1
logo_printed=1 # 1=not printed, 0=printed
migration_in_progress=1 # 1=false, 0=true

#===============================================================================
# SECTION: STDERR & ESCAPES
#===============================================================================

_load_escapes() {
    readonly  red=$'\x1B[31m'; orange=$'\x1B[38;5;214m'; green=$'\x1B[32m';
    readonly  blue=$'\x1B[38;5;39m'; purple=$'\x1B[38;5;213m'; grey=$'\x1B[38;5;244m';
    readonly  bld=$'\x1B[1m'; x=$'\x1B[0m';
    readonly  IMARK=$'\u274D'; pass=$'\u2713'; fail=$'\u2715'; sect=$'\u00A7'; utri=$'\u25B3';
}
info()  { [[ "$opt_quiet" -eq 1 ]] && printf "${blue}${sect} %s${x}\n" "$@" >&2; }
okay()  { [[ "$opt_quiet" -eq 1 ]] && printf "${green}${pass} %s${x}\n" "$@" >&2; }
warn()  { [[ "$opt_quiet" -eq 1 ]] && printf "${orange}${utri} %s${x}\n" "$@" >&2; }
error() { printf "${red}${fail} %s${x}\n" "$@" >&2; }
fatal() { error "$@"; exit 1; }

#===============================================================================
# SECTION: HELPERS
#===============================================================================

is_dev() { [[ -n "$DEV_MODE" || "$opt_dev" -eq 0 ]]; }

__get_pwd()     { pwd -L; }
__is_mark()     { [[ -L "${MARK_DATA_DIR}/$1" ]]; }
__is_valid_id() { [[ "$1" =~ $REGEX_MARK_ID ]]; }

_list_mark_names() {
    find "$MARK_DATA_DIR" -maxdepth 1 -type l -exec basename {} ';' 2>/dev/null | sort
}
_read_mark_path() {
    local mark_path="${MARK_DATA_DIR}/$1"
    if __is_mark "$1"; then readlink "$mark_path"; return 0; fi
    return 1
}
_link_mark() {
    ln -s "$2" "${MARK_DATA_DIR}/$1"
    return $?
}
_unlink_mark() {
    rm -f "${MARK_DATA_DIR}/$1"
    return $?
}
_confirm_action() {
    if [[ "$opt_yes" -eq 0 ]]; then return 0; fi
    local prompt="$1"
    read -p "${prompt} [y/N]: " -n 1 -r
    echo >&2
    [[ "$REPLY" =~ ^[Yy]$ ]]
}
_delete_old_system() {
    local old_dir="$HOME/.my/etc/fx/markman"
    if [[ -d "$old_dir" ]]; then info "Deleting legacy markman directory: ${old_dir}"; rm -rf "$old_dir"; fi
}
_pretty_path() {
    sed "s|^${HOME}|~|"
}
_print_logo() {
    if [[ "$logo_printed" -eq 1 ]]; then
        printf "\n" >&2
        grep '^##' "$0" | sed 's/^##//' | printf "${purple}%s${x}\n" "$(cat)" >&2
        printf "\n" >&2
        logo_printed=0
    fi
}
_get_shell_profile() {
    if [[ -n "$XDG_RC_HOOK_FILE" && -f "$XDG_RC_HOOK_FILE" ]]; then printf "%s" "$XDG_RC_HOOK_FILE"; return 0; fi
    for profile in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.bash_profile"; do
        if [[ -f "$profile" ]]; then printf "%s" "$profile"; return 0; fi
    done
    fatal "Could not find a valid shell profile (.bashrc, .profile) to modify."
}

__write_rc_file() {
    local ret=1
    info "Writing shell functions to ${MARK_RC_FILE}..."
    mkdir -p "$(dirname "$MARK_RC_FILE")" || return 1
    
    # Use <<-EOF to allow the heredoc to be indented with TABS.
    cat <<-EOF > "$MARK_RC_FILE"
			#### START ${SENTINEL_TAG} ####
				if [ -n "\$(which mark)" ]; then
					jump(){
						local this=\$(mark link \$1); # -s command changed
						[ -d "\$this" ] && { cd -L "\$this"; echo -e "\\\\n[${green}#\$1${x}] \$this\\\\n"; ls -la; }
					}
					alias marks='mark @';
					alias rem='mark -e last';
					alias lastuser=\$(which last); # /usr/bin/last last logged in user 
					alias last='clear; jump last';
					alias j='jump';
					alias m='mark';
				fi
			#### END ${SENTINEL_TAG} #### # ${SENTINEL_TAG}
		EOF

    ret=$?
    if [[ "$ret" -eq 0 ]]; then
        okay "Successfully wrote rc file."
    else
        error "Failed to write rc file."
    fi
    return "$ret"
}


_link_to_profile() {
    local profile ret=1
    profile=$(_get_shell_profile)
    
    local source_line="source \"${MARK_RC_FILE}\""
    local sentinel_line="${source_line} # ${SENTINEL_TAG}"

    if ! grep -q "# ${SENTINEL_TAG}" "$profile"; then
        info "Linking ${SELF_NAME} rc file to ${profile}..."
        printf "\n%s\n" "$sentinel_line" >> "$profile"
        okay "Installation complete. Please run 'source ~/.bashrc' or restart your shell."
        ret=0
    else 
        warn "Markman functions already found in profile. Run 'mark reset' then 'mark install' to apply updates."
    fi
    return "$ret"

}


_unlink_from_profile() {
    local profile
    profile=$(_get_shell_profile)

    # First, check for the modern line sentinel.
    if grep -q "# ${SENTINEL_TAG}" "$profile"; then
        info "Removing markman source line from ${profile}..."
        
        # Use sed to delete only the line containing our sentinel.
        sed -i.bak "/# ${SENTINEL_TAG}/d" "$profile"
        
        rm -f "${profile}.bak"
        okay "Modern source line removed."

    # As a fallback, check for the old legacy block sentinel.
    elif grep -q "#### ${LEGACY_SENTINEL_TAG} ####" "$profile"; then
        info "Removing LEGACY markman function block from ${profile}..."
        
        # Use the block-deletion pattern for the old style.
        sed -i.bak "/#### ${LEGACY_SENTINEL_TAG} ####/,/########/d" "$profile"
        
        rm -f "${profile}.bak"
        okay "Legacy function block removed."
    else
        info "Markman functions not found in profile. Nothing to do."
    fi
}

#===============================================================================
# SECTION: API FUNCTIONS (DISPATCHABLE)
#===============================================================================


do_show_path() {
    local ret=1 name="$1" path
    if ! __is_valid_id "$name"; then return 1; fi # Silently fail on invalid id
    
    if path=$(_read_mark_path "$name"); then
        printf "%s" "$path"
        ret=0
    fi
    return "$ret"
}

dev_list_paths() {
    if ! is_dev; then fatal "This is a developer-only command. Use -D to enable."; fi
    info "Listing all raw bookmark paths..."
    for name in $(_list_mark_names); do
        _read_mark_path "$name"
    done
}

dev_find_path() {
    if ! is_dev; then fatal "This is a developer-only command. Use -D to enable."; fi
    local path="$1"
    [[ -z "$path" ]] && fatal "Path argument is required."
    
    info "Checking if path is bookmarked: ${path}"
    local marks
    marks=$(_find_marks_by_path "$path")

    if [[ -n "$marks" ]]; then
        okay "Path is bookmarked by: ${marks}"
        return 0
    else
        warn "Path is not bookmarked."
        return 1
    fi
}

_find_marks_by_path() {
    local path="$1" names=() mark_name mark_path
    for mark_name in $(_list_mark_names); do
        mark_path=$(_read_mark_path "$mark_name")
        [[ "$mark_path" == "$path" ]] && names+=("$mark_name")
    done
    printf "%s" "${names[*]}"
}

do_edit() {
    local ret=1 name="$1" path="$2"
    if ! __is_valid_id "$name"; then error "Invalid bookmark name: '$name'."; return 1; fi
    if [[ -z "$path" ]]; then path=$(__get_pwd); fi

    # This is the key difference: it must already exist to be edited.
    if ! __is_mark "$name"; then
        error "Bookmark '${name}' does not exist and cannot be edited."
        info "To create it, use 'mark add ${name}'"
        return 1
    fi

    # Unlink and relink to perform the update.
    _unlink_mark "$name"
    if _link_mark "$name" "$path"; then
        okay "Bookmark '${name}' updated to new path '${path}'."
        ret=0
    else
        error "Failed to update bookmark '${name}'."
    fi
    return "$ret"
}

do_go() {
    local ret=1 name="$1" path
    if ! __is_valid_id "$name"; then error "Invalid bookmark name: '$name'."; return 1; fi
    if path=$(_read_mark_path "$name"); then printf "%s" "$path"; ret=0
    else
        info "Bookmark '${name}' not found. Creating it for current directory."
        if do_add "$name" "$(__get_pwd)"; then printf "%s" "$(__get_pwd)"; ret=0; fi
    fi
    return "$ret"
}

do_add() {
    local ret=1 name="$1" path="$2"
    if ! __is_valid_id "$name"; then error "Invalid bookmark name: '$name'."; return 1; fi
    [[ -z "$path" ]] && path=$(__get_pwd)
    if __is_mark "$name"; then
        if [[ "$opt_force" -eq 0 ]]; then _unlink_mark "$name"
        else error "Bookmark '$name' already exists. Use -f to overwrite."; return 1; fi
    fi
    if _link_mark "$name" "$path"; then okay "Bookmark '${name}' saved for path '${path}'."; ret=0
    else error "Failed to create bookmark '${name}'."; fi
    return "$ret"
}

do_delete() {
    local ret=1 name="$1"
    if ! __is_valid_id "$name"; then error "Invalid bookmark name: '$name'."; return 1; fi
    if __is_mark "$name"; then
        if _unlink_mark "$name"; then okay "Bookmark '${name}' deleted."; ret=0
        else error "Failed to delete bookmark '${name}'."; fi
    else warn "Bookmark '${name}' not found."; fi
    return "$ret"
}

do_list() {
    _print_logo
    local marks=() name path
    marks=($(_list_mark_names))
    if [[ ${#marks[@]} -eq 0 ]]; then info "No bookmarks found."; return 0; fi
    info "${bld}Available bookmarks (${#marks[@]}):${x}"
    for name in "${marks[@]}"; do
        path=$(_read_mark_path "$name" | _pretty_path)
        printf "  ${orange}${IMARK} %-15s${x} ${blue}==> %s${x}\n" "$name" "$path"
    done
    return 0
}

do_install() {
    _print_logo
    
    local script_source_path
    script_source_path=$(realpath "$0")
    
    if [[ "$script_source_path" == "$(realpath "${MARK_LIB_DIR}/${SELF_NAME}.sh")" ]]; then
        okay "${SELF_NAME} is already installed and up-to-date."
        info "To apply updates to shell functions, run 'mark reset' then 'mark install'."
        return 0
    fi

    local old_dir="$HOME/.my/etc/fx/markman"
    if [[ -d "$old_dir" && "$migration_in_progress" -eq 1 ]]; then
        if _confirm_action "${orange}${utri} Legacy markman data found. Would you like to migrate it now?${x}"; then
            do_migrate || return 1
        else
            warn "Skipping migration. Legacy data will not be available."
        fi
    fi

    info "Installing ${SELF_NAME} from ${script_source_path}..."
    # Ensure ALL necessary directories exist, including the one for the RC file.
    mkdir -p "$MARK_LIB_DIR" "$MARK_DATA_DIR" "$MARK_ETC_DIR" "$FX_BIN_DIR"
    
    # === THE CRITICAL FIX ===
    # Write the RC file BEFORE linking to it from the profile.
    __write_rc_file || return 1
    # ========================
    
    cp "$script_source_path" "${MARK_LIB_DIR}/${SELF_NAME}.sh"
    chmod +x "${MARK_LIB_DIR}/${SELF_NAME}.sh"
    ln -sf "$(realpath "${MARK_LIB_DIR}/${SELF_NAME}.sh")" "$MARK_BIN_PATH"
    
    _link_to_profile
    
    okay "${SELF_NAME} installed successfully to ${MARK_BIN_PATH}."
    return 0
}


do_reset() {
    _print_logo
    local backup_file
    if ! _confirm_action "${red}${fail} This will remove application data and uninstall ${SELF_NAME}. Are you sure?${x}"; then
        info "Reset cancelled."; return 1;
    fi
    if [[ "$opt_yes" -ne 0 ]]; then
        local confirmation
        read -p "${orange}${utri} This is your final warning. Type 'reset' to confirm: ${x}" confirmation
        if [[ "$confirmation" != "reset" ]]; then info "Confirmation failed. Reset cancelled."; return 1; fi
    fi
    
    mkdir -p "$MARK_BACKUP_DIR"
    backup_file="${MARK_BACKUP_DIR}/markman.fx.bak.reset.$(date +%s)"
    info "Action confirmed. Creating a final backup..."
    do_export_raw > "$backup_file" || { fatal "Backup failed. Aborting reset."; }
    okay "Backup complete. Your data is safe at: ${backup_file}"

    # #[BASHFX-SAFETY-NET] Surgically remove data, preserving the backups directory.
    info "Removing application data (bookmarks)..."
    find "$MARK_DATA_DIR" -mindepth 1 -maxdepth 1 ! -name "backups" -exec rm -rf {} +
    
    info "Removing library files: ${MARK_LIB_DIR}" && rm -rf "$MARK_LIB_DIR"
    info "Removing binary link: ${MARK_BIN_PATH}" && rm -f "$MARK_BIN_PATH"
    _unlink_from_profile
    
    warn "The backups directory has been preserved at: ${MARK_BACKUP_DIR}"
    okay "${SELF_NAME} has been completely reset."
    return 0
}


do_version() {
    grep "^# version:" "$0" | awk '{print $3}'
    return 0
}

do_export_raw() {
    #if [[ "$#" -eq 0 ]]; then _print_logo; fi
    local name path
    for name in $(_list_mark_names); do
        path=$(_read_mark_path "$name")
        printf "%s=%s\n" "$name" "$path"
    done
}

do_export() {
    _print_logo
    local backup_file
    
    if [[ -n "$opt_export_file" ]]; then
        # User specified a file via the --file flag.
        backup_file="$opt_export_file"
        info "Exporting all bookmarks to specified file..."
        mkdir -p "$(dirname "$backup_file")" || fatal "Could not create directory for export file."
    else
        # Default behavior: create a smart backup in the standard location.
        mkdir -p "$MARK_BACKUP_DIR"
        backup_file="${MARK_BACKUP_DIR}/markman.fx.bak.export.$(date +%s)"
        info "Exporting all bookmarks to a new backup file..."
    fi
    
    # Call the raw function and redirect its output to the chosen file.
    do_export_raw > "$backup_file" || { fatal "Export failed."; }

    okay "Export complete. Your backup is located at:"
    printf "  ${green}%s${x}\n" "$backup_file" >&2
    
    return 0
}


do_import() {
    _print_logo
    local ret=0 line name path count=0 skipped=0
    info "Importing marks from stdin..."
    while read -r line; do
        [[ -z "$line" ]] && continue
        name="${line%%=*}"; path="${line#*=}"
        if __is_mark "$name" && [[ "$opt_force" -eq 1 ]]; then skipped=$((skipped + 1)); continue; fi
        _unlink_mark "$name"; _link_mark "$name" "$path"; count=$((count + 1))
    done
    okay "Import complete. Added/updated ${count} marks. Skipped ${skipped} duplicates."
    return "$ret"
}


do_migrate() {
    migration_in_progress=0 # Set the flag to prevent recursion
    _print_logo
    local old_dir="$HOME/.my/etc/fx/markman" name path count=0 broken_count=0 backup_file
    info "Checking for old markman data at ${old_dir}..."
    if [[ ! -d "$old_dir" ]]; then info "Old markman directory not found. Nothing to migrate."; return 0; fi
    if [[ -n "$(_list_mark_names)" ]]; then error "New bookmark directory is not empty. Aborting migration."; return 1; fi
    info "Migrating bookmarks from old location (preserving logical paths)..."
    for link in "${old_dir}"/*; do
        [[ -L "$link" ]] || continue
        name=$(basename "$link"); path=$(readlink "$link")
        if [[ "$path" != /* ]]; then path="$(cd "$(dirname "$link")" && pwd -L)/$path"; fi
        if [[ ! -e "$path" ]]; then
            warn "Legacy mark '${name}' points to a non-existent path. Migrating as a broken link."
            broken_count=$((broken_count + 1))
        fi
        if _link_mark "$name" "$path"; then count=$((count + 1)); fi
    done
    okay "Migration complete. Migrated ${count} bookmarks."
    if [[ "$broken_count" -gt 0 ]]; then warn "Found and migrated ${broken_count} broken bookmarks."; fi
    if [[ "$count" -gt 0 ]]; then
        mkdir -p "$MARK_BACKUP_DIR"
        backup_file="${MARK_BACKUP_DIR}/markman.fx.bak.migrate.$(date +%s)"
        info "Creating an immediate backup of new data..."
        do_export_raw "" > "$backup_file"
        okay "Backup created successfully. Your data is safe at: ${backup_file}"
    fi
    warn "You may now safely remove the old directory: ${old_dir}"
    if _confirm_action "${green}${pass} Data migration is complete. Would you like to install the new mark command now?${x}"; then
        do_install
    else
        info "Okay. You can run 'mark install' at any time to complete the setup."
    fi
    return 0
}


do_migrate_resolve() {
    _print_logo
    if ! _confirm_action "${red}${fail} This will MIGRATE old data, DELETE the old system, and INSTALL the new one. This is a one-way trip. Proceed?${x}"; then
        info "Resolve cancelled."; return 1;
    fi
    info "Beginning migration and resolve process..."
    do_migrate || { fatal "Migration failed. Aborting resolve."; }
    _delete_old_system
    _unlink_from_profile
    do_install || { fatal "Installation failed during resolve."; }
    okay "Migration and resolve complete. The new markman is fully active."
    return 0
}

do_backups() {
    _print_logo
    info "Listing all available backups in:"
    printf "  ${grey}%s${x}\n" "$MARK_BACKUP_DIR" >&2
    
    # #[BASHFX-BUGFIX] Use a robust file count instead of a brittle string check.
    local count=0
    if [[ -d "$MARK_BACKUP_DIR" ]]; then
        # Count only files (-type f) to be precise.
        count=$(find "$MARK_BACKUP_DIR" -name "*.bak" -type f 2>/dev/null | wc -l)
    fi

    if [[ "$count" -eq 0 ]]; then
        okay "No backups found."
        return 0
    fi
    
    printf "\n" >&2
    printf "  ${bld}%-22s %-10s %s${x}\n" "DATE CREATED" "SIZE" "FILENAME" >&2

    local hr1 hr2 hr3
    hr1=$(printf '%.0s-' {1..22})
    hr2=$(printf '%.0s-' {1..10})
    hr3=$(printf '%.0s-' {1..37})
    printf "  ${grey}%-22s %-10s %s${x}\n" "$hr1" "$hr2" "$hr3" >&2

    # Use find and a loop for robust file handling
    find "$MARK_BACKUP_DIR" -name "*.bak" -type f | while read -r file; do
        local timestamp size filename
        timestamp=$(date -r "$file" "+%Y-%m-%d %H:%M:%S")
        size=$(du -h "$file" | cut -f1)
        filename=$(basename "$file")
        printf "  ${blue}%-22s${x} ${orange}%-10s${x} ${green}%s${x}\n" "$timestamp" "$size" "$filename" >&2
    done

    return 0
}




do_info() {
    _print_logo
    local ver author
    ver=$(grep "^# version:" "$0" | awk '{print $3}')
    author=$(grep "^# author:" "$0" | sed 's/^# author: //')

    printf "  ${bld}${SELF_NAME} v%s${x} - ${purple}A BashFX Utility${x}\n" "$ver" >&2
    printf "${grey}  --------------------------------------------------${x}\n" >&2
    printf "  Copyright (c) 2025, %s\n" "$author" >&2
    printf "  All rights reserved.\n" >&2
    printf "\n" >&2
    printf "  Licensed under the Apache License, Version 2.0.\n" >&2
    printf "  Use this tool at your own risk.\n" >&2

    return 0
}


  do_inspect(){
    declare -F | grep 'do_' | awk '{print $3}'
    _content=$(sed -n -E "s/[[:space:]]+([^)]+)\)[[:space:]]+cmd[[:space:]]*=[\'\"]([^\'\"]+)[\'\"].*/\1 \2/p" "$0")

    while IFS= read -r line; do
      echo "$line"
    done <<< "$_content"

  }
#===============================================================================
# SECTION: SUPER-ORDINAL FUNCTIONS
#===============================================================================

dispatch() {
    # If there are no positional args at all, default to 'list'.
    if [[ $# -eq 0 ]]; then
        do_list
        return $?
    fi

    local cmd="$1"; shift
    case "$cmd" in
        add)                 do_add "$@" ;;
        delete|rm)           do_delete "$@" ;;
        list|ls)             do_list "$@" ;;
        install)             do_install "$@" ;;
        reset)               do_reset "$@" ;;
        version)             do_version ;;
        export)              do_export "$@" ;;
        export-raw)          do_export_raw ;;
        import)              do_import "$@" ;;
        backups)             do_backups "$@" ;;
        migrate)             do_migrate "$@" ;;
        mresolve)    				 do_migrate_resolve "$@" ;;
        link)                do_show_path "$@" ;;
        lp)              		 dev_list_paths "$@" ;; # <-- ADD THIS
        fp)              		 dev_find_path "$@" ;;  # <-- ADD THIS
        fm)              		 _find_marks_by_path "$@" ;; # <-- ADD THIS
        help)                usage ;;
        info|--info)         do_info ;;
        +|--add)             do_add "$@" ;;
        -|--delete)          do_delete "$@" ;;
        @|*|?|--list)        do_list "$@" ;;
        version|--version)   do_version ;;
        *)
            # THE CRITICAL FIX: If the command is not a known command, it MUST
            # be a bookmark name. We call do_go with the original command as the
            # first argument.
            do_go "$cmd" "$@"
            ;;
    esac
    return $?
}

usage() {
    _print_logo
    local usage_text
    # #[BASHFX-FIX] Correctly strips the leading '# ' from each line.
    usage_text=$(sed -n '/^# DOC_USAGE_START/,/^# DOC_USAGE_END/p' "$0" | sed 's/^#\s*//' | sed '1d;$d')
    eval "printf \"%s\n\" \"${usage_text}\"" >&2
}

options() {
    # Initialize all option-related variables
    opt_force=1; opt_quiet=1; opt_dev=1; opt_yes=1
    opt_export_file=""

    local temp_args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            # Global flags
            -f|--force) opt_force=0; shift ;;
            -q|--quiet) opt_quiet=0; shift ;;
            -D|--dev)   opt_dev=0; shift ;;
            -y|--yes)   opt_yes=0; shift ;;
            
            # Command-specific flags
            --file)
                [[ -n "$2" ]] || fatal "Option --file requires a path"
                opt_export_file="$2"
                shift 2
                ;;

            # Not a flag, so it's a positional argument (like a command).
            *) temp_args+=("$1"); shift ;;
        esac
    done
    
    # Restore the positional arguments.
    POSITIONAL_ARGS=("${temp_args[@]}")
    
    # Apply quiet mode override
    if [[ "$opt_quiet" -eq 1 ]]; then opt_debug=0; opt_trace=0; fi
}

main() {
	_load_escapes
	mkdir -p "$MARK_DATA_DIR"
	
	# options() handles all flags and populates POSITIONAL_ARGS
	options "$@"

	# The main function's only job is to hand off control to the dispatcher.
	# It no longer makes any decisions about default commands.
	dispatch "${POSITIONAL_ARGS[@]}"

	return $?
}

main "$@"

#===============================================================================
# #[BASHFX] 4.2: Embedded Docs (Block Hack)
#===============================================================================
# DOC_USAGE_START
#
#   ${bld}${SELF_NAME}${x} - A bookmarking tool for your shell.
#
#   ${orange}${utri}${x} ${bld}USAGE:${x}
#   ${blue}mark ${grey}<name>${x}                ${grey}Go to bookmark, or create it if it doesn't exist.${x}
#   ${blue}mark ${grey}<command> [args...]${x}
#
#   ${orange}${utri}${x} ${bld}COMMANDS:${x}
#   ${green}list, ls, @, *, ?${x}      ${grey}List all available bookmarks.${x}
#   ${green}add, + ${grey}<name> [path]${x}   ${grey}Add or update a bookmark. Defaults to current directory.${x}
#   ${green}delete, rm, - ${grey}<name>${x}   ${grey}Delete a bookmark.${x}
#
#   ${orange}${utri}${x} ${bld}DATA MANAGEMENT:${x}
#   ${green}export [--file <path>]${x} ${grey}Create a backup. Defaults to the backup dir, or saves to a specific file.${x}
#   ${green}export-raw${x}             ${grey}Dump raw bookmark data to stdout for piping.${x}
#
#   ${green}import${x}                 ${grey}Import bookmarks from stdin (e.g., 'mark import < marks.bak').${x}
#   ${green}backups${x}                ${grey}List all automatic backups created by 'migrate' or 'reset'.${x}
#   ${green}migrate${x}                ${grey}Safely migrate from a legacy installation, with automatic backup.${x}
#   ${green}migrate-resolve${x}        ${grey}A destructive one-way migration, cleanup, and install.${x}
#
#   ${orange}${utri}${x} ${bld}ADMINISTRATION:${x}
#   ${green}install${x}                ${grey}Install the 'jump'/'j'/'marks' shell functions and aliases.${x}
#   ${red}reset${x}                    ${grey}Remove all bookmarks and uninstall shell functions.${x}
#   ${green}version, --version${x}     ${grey}Display the script version.${x}
#   ${green}info, --info${x}    			 ${grey}Display the script version.${x}
#   ${green}help${x}                   ${grey}Show license info.${x}
#
#   ${orange}${utri}${x} ${bld}FLAGS:${x}
#   ${green}--file <path>${x}           ${grey}Specify a custom output file for the 'export' command.${x}
#   ${green}-f, --force${x}             ${grey}Overwrite existing bookmarks when using 'add' or 'import'.${x}
#   ${green}-y, --yes${x}               ${grey}Answer 'yes' to all confirmation prompts.${x}
#   ${green}-D, --dev${x}               ${grey}Enable developer-only commands and output.${x}
#
# DOC_USAGE_END


# bin=/home/nulltron/.local/bin
# book=/home/nulltron/.repos/rust/rustadex/bookdb
# cargo=/home/nulltron/.local/lib/rust/cargo
# dot=/home/nulltron/.repos/shell/dotfiles
# envs=/home/nulltron/.my/etc/env/profile.d
# err=/home/nulltron/.repos/rust/rustadex/stderr
# flag=/home/nulltron/.repos/bashfx/fx-catalog/pkgs/fx/flagbase
# fx=/home/nulltron/.repos/shell/bashfx/fx-catalog
# graph=/home/nulltron/.repos/rust/rustadex/graphite
# hyper=/home/nulltron/.repos/rust/rustadex/hyperclock
# img=/home/nulltron/.repos/labs/sunny/imgbud
# lab=/home/nulltron/.repos/qodeninja/reactlab
# last=/home/nulltron/.repos/rust/oxidex
# manifest=/home/nulltron/.config/fx/etc
# mybin=/home/nulltron/.my/bin
# notes=/home/nulltron/.repos/markdown/notes
# ox=/home/nulltron/.repos/rust/oxidex
# pkg=/home/nulltron/.repos/shell/bashfx/fx-package
# prof=/home/nulltron/.repos/qodeninja/profman
# rdx=/home/nulltron/.local/lib/my/repos/rust/rustadex
# repos=/home/nulltron/.repos
# rsb=/home/nulltron/.repos/rust/oxidex/rebel-rsb
# rust=/home/nulltron/.repos/rust/rustadex
# shell=/home/nulltron/.repos/shell
# tempo=/home/nulltron/.repos/rust/rustadex/tempo
