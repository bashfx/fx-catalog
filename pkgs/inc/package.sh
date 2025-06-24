#!/usr/bin/env bash
#===============================================================================
#-----------------------------><-----------------------------#
#$ name:package
#$ author:qodeninja
#$ desc:
#-----------------------------><-----------------------------#
#=====================================code!=====================================


  #TODO: Review
  _install_core_libs() {
    info "Installing core libraries..."
    local src_dir="$FXI_INC_DIR";
    local dst_dir="$FX_INC_DIR";

    if [ ! -d "$src_dir" ]; then
      error "Source library directory not found: $src_dir"
      return 1
    fi

    mkdir -p "$dst_dir" || { error "Failed to create destination: $dst_dir"; return 1; }

    # Use a standard `cp` command to recursively copy all files from the source directory.
    # The `-R` flag handles recursion portably, and the `/.` ensures all contents are copied.
    if cp -R "$src_dir/." "$dst_dir/"; then
      okay "Core libraries installed to $dst_dir"
      return 0
    else
      error "Failed to copy libraries to $dst_dir"
      return 1
    fi

    okay "Core libraries installed to $dst_dir"
    return 0
  }


#-------------------------------------------------------------------------------
# API
#-------------------------------------------------------------------------------


  do_list_pkgs(){
    local this="$1"
    local pkg_root="$FX_INIT_PKGS"
    local pkg_path pkg

    case "$this" in
      (*[:.]*) group="${this%%[:.]*}"; pkg="${this#*[:.]}" ;;
      (*) group="$this";;
    esac

    if [[ -z "$pkg_root" || ! -d "$pkg_root" ]]; then
      error "[PKG] Invalid or unset FX_INIT_PKGS: $pkg_root"
      return 1
    fi

    if [ -n "$group" ]; then
      # List packages within a specific group
      if [ ! -d "$pkg_root/$group" ]; then
        error "[PKG] Group '$group' not found under $pkg_root"
        return 1
      fi

      if [ -n "$pkg" ]; then

        if [ ! -d "$pkg_root/$group/$pkg" ]; then
          error "[PKG] Package '$pkg' not found under $group"
          return 1
        else
          echo "$group.$pkg";
        fi

      else

        # Use the helper function to avoid code duplication
        _list_packages_in_group "$group" "$pkg_root/$group"

      fi
    else
      # List all group.pkg pairs
      for group_path in "$pkg_root"/*; do
        [ -d "$group_path" ] || continue
        group=$(basename "$group_path")

        # Use the helper function to avoid code duplication
        _list_packages_in_group "$group" "$group_path"

      done
    fi
  }



  # Helper function: Lists packages within a given group directory
  # This generalizes the common logic for iterating and printing group.pkg.
  # Arguments:
  #   $1: group_name (e.g., "core", "util")
  #   $2: group_dir (absolute path to the group's directory)
  _list_packages_in_group() {
    local group_name="$1"
    local group_dir="$2"
    local pkg_path pkg

    for pkg_path in "$group_dir"/*; do
      [ -d "$pkg_path" ] || continue # Skip non-directories
      pkg=$(basename "$pkg_path")
      echo "$group_name.$pkg"
    done
  }



  do_check_pkg(){
    local ret=1
    is_valid_pkg "$1";
    ret=$?
    [ $ret -eq 0 ] && { okay "Valid Package ($1)"; } 
    [ $ret -eq 1 ] && { error "Invalid Package ($1)"; }
    return $ret
  }


  is_valid_pkg(){
    local this="$1" path ret=1;
    path=$(get_pkg_path $this); ret=$?;
    if [ $ret -eq 0 ]; then
      info "Package found at ($path)";
      echo -e "$path";
    fi
    return $ret;
  }


  get_pkg_path(){
    trace "[PKG] checking for valid package name ($1)"
    local this="$1"
    local group pkg base group_path path

    if [ ! -d "$FX_INIT_PKGS" ]; then
      error "Source directory is missing, cannot check packages";
      return 1;
    else
      info "Pkg root found ($FX_INIT_PKGS)";
    fi

    base="${FX_INIT_PKGS}" #require path

    case "$this" in
      (*[:.]*) group="${this%%[:.]*}"; pkg="${this#*[:.]}" ;;
      (*) group="$this"; pkg="all" ;;
    esac

    group_path="$base/$group"


    if [ -z "$pkg" ] || [ "$pkg" = "all" ]; then
      path="$group_path"
      warn "All package contents requested. Not implemented ($path)";
    elif [ -d "$group_path/$pkg" ]; then
      path="$group_path/$pkg";
    fi

    if [ -d $path ]; then
      echo -e "$path";
      return 0;
    fi

    return 1;
  }


  is_installed_pkg(){
    trace "checking if package ($1) is installed"
    local pkg_id="$1" group pkg_name
    case "$pkg_id" in
      (*[:.]*) group="${pkg_id%%[:.]*}"; pkg_name="${pkg_id#*[:.]}" ;;
      (*) error "Invalid package format for check. Use 'group.name'."; return 1 ;;
    esac
    # A package is considered installed if its symlink exists in the bin directory.
    if [ -L "$FX_BIN/$pkg_name" ]; then
      info "Package '$pkg_name' is installed (symlink found)."
      return 0 # 0 for true in shell
    fi

    # As a fallback, check if the directory exists in lib.
    if [ -d "$FX_LIB/$group/$pkg_name" ]; then
        warn "Package '$pkg_name' files found, but it is not linked."
        return 2 # A different non-zero for "partially installed"
    fi

    trace "Package '$pkg_name' is not installed."
    return 1 # 1 for false
  }





  do_install_pkg(){
    local pkg_id="$1" group pkg_name src_path dst_path

    [ -z "$pkg_id" ] && { error "No package specified for installation."; return 1; }

    # 1. Check if already installed
    is_installed_pkg "$pkg_id"
    [ $? -eq 0 ] && { okay "Package '$pkg_id' is already installed."; return 0; }

    # 2. Validate package and get its source path
    src_path=$(get_pkg_path "$pkg_id")
    [ $? -ne 0 ] && { error "Package '$pkg_id' not found or invalid."; return 1; }
    info "Found package source at: $src_path"

    # 3. Parse group and name
    case "$pkg_id" in
      (*[:.]*) group="${pkg_id%%[:.]*}"; pkg_name="${pkg_id#*[:.]}" ;;
      (*) error "Invalid package format. Use 'group.name'."; return 1 ;;
    esac

    # 4. Define destination and copy files
    local dst_group_path="$FX_LIB/$group"
    dst_path="$dst_group_path/$pkg_name"

    info "Installing '$pkg_id' to '$dst_path'..."
    mkdir -p "$dst_group_path" || { error "Failed to create destination group directory."; return 1; }

    cp -R "$src_path/." "$dst_path/" || { error "Failed to copy package files."; return 1; }
    okay "Package files copied successfully."

    # 5. Link the executable
    _link_pkg_executable "$group" "$pkg_name"
  }

  _link_pkg_executable() {
    local group="$1" pkg_name="$2"
    local installed_exec="$FX_LIB/$group/$pkg_name/pkg.sh"
    local bin_link="$FX_BIN/$pkg_name"

  
    if [ ! -f "$installed_exec" ]; then
      note "Package '$pkg_name' has no executable (pkg.sh). Nothing to link."
      return 0
    fi

    # Create symlink in bin/
    info "Linking executable: $bin_link -> $installed_exec"
    ln -s "$installed_exec" "$bin_link" || {
      error "Failed to link $bin_link -> $installed_exec";
      return 1
    }

    okay "Package '$pkg_name' is now available in your PATH."
  }


