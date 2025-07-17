#!/usr/bin/env bash

# Source the functions to be tested
# Using base super include that has stdfx in it already
__self="${BASH_SOURCE[0]}";
SELF_PATH="$(dirname $__self)";

source "$SELF_PATH/../pkgs/inc/base.sh";


# Helper functions for reporting
  _pass(){ printf "[ ${green}PASS${xx} ] %s\n" "$1"; }
  _fail(){
    printf "[ ${red}FAIL${xx} ] %s\n" "$1";
    [ -n "$2" ] && printf "    Actual Output:\n%s\n" "$2";
    # A failed assertion should immediately terminate the test with a failure code.
    # For now, we'll just print the message and let the test continue.
  }



  test_setup(){
    # Test setup
    TMP_DIR="../tmp/stdfx_test";
    mkdir -p "$TMP_DIR";
    touch "$TMP_DIR/empty_file.txt";
    echo "some content" > "$TMP_DIR/file_with_content.txt";
    mkdir -p "$TMP_DIR/test_dir";
    touch "$TMP_DIR/test_dir/sibling_file.txt";
    chmod +x "$TMP_DIR/file_with_content.txt";
  }

  stdfx_driver(){
      local fn="$1";
      local arg1="$2";
      local arg2="$3";
      echo "Testing: $fn";
      case "$fn" in
          (is_empty)
              is_empty "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          is_defined)
              is_defined "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          is_super_defined)
              is_super_defined "$arg1" "$arg2" && echo "Result: true" || echo "Result: false";
              ;;
          in_string)
              in_string "$arg1" "$arg2" && echo "Result: true" || echo "Result: false";
              ;;
          strings_are_equal)
              strings_are_equal "$arg1" "$arg2" && echo "Result: true" || echo "Result: false";
              ;;
          is_num)
              is_num "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          is_alnum)
              is_alnum "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          is_alpha)
              is_alpha "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          is_name)
              is_name "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          starts_with)
              starts_with "$arg1" "$arg2" && echo "Result: true" || echo "Result: false";
              ;;
          ends_with)
              ends_with "$arg1" "$arg2" && echo "Result: true" || echo "Result: false";
              ;;
          is_path_name)
              is_path_name "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          is_path)
              is_path "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          in_path)
              in_path "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          ls_bin)
              ls_bin "$arg1";
              ;;
          is_dir)
              is_dir "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          is_rw_dir)
              is_rw_dir "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          ls_dirs)
              ls_dirs "$arg1";
              ;;
          ls_files)
              ls_files "$arg1";
              ;;
          self_base)
              self_base;
              ;;
          is_file)
              is_file "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          is_rw_file)
              is_rw_file "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          is_empty_file)
              is_empty_file "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          is_active_file)
              is_active_file "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          is_script)
              is_script "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          is_executable)
              is_executable "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          a_sub_path_b)
              a_sub_path_b "$arg1" "$arg2" && echo "Result: true" || echo "Result: false";
              ;;
          a_file_in_b)
              a_file_in_b "$arg1" "$arg2" && echo "Result: true" || echo "Result: false";
              ;;
          canon_path)
              canon_path "$arg1";
              ;;
          a_canon_path_b)
              a_canon_path_b "$arg1" "$arg2" && echo "Result: true" || echo "Result: false";
              ;;
          a_linked_b)
              a_linked_b "$arg1" "$arg2" && echo "Result: true" || echo "Result: false";
              ;;
          ls_source)
              ls_source "$arg1";
              ;;
          copy_bak)
              copy_bak "$arg1";
              ;;
          make_tmp)
              make_tmp;
              ;;
          xdg_path)
              xdg_path "$arg1";
              ;;
          xdg_type)
              xdg_type "$arg1";
              ;;
          is_xdg_path)
              is_xdg_path "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          is_sibling_file)
              is_sibling_file "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          in_tree)
              in_tree "$arg1" "$arg2";
              ;;
          in_base_tree)
              in_base_tree "$arg1";
              ;;
          base_source)
              base_source "$arg1";
              ;;
          project_base)
              project_base "$arg1";
              ;;
          is_project_file)
              is_project_file "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          is_project_path)
              is_project_path "$arg1" && echo "Result: true" || echo "Result: false";
              ;;
          in_project_tree)
              in_project_tree "$arg1" "$arg2";
              ;;
          in_proj_base_tree)
              in_proj_base_tree "$arg1";
              ;;
          project_source)
              project_source "$arg1";
              ;;
          fuzzy_source)
              fuzzy_source "$arg1" "$arg2";
              ;;
          *)
              echo "Usage: $0 <function_name> [arg1] [arg2]";
              echo "Available functions:";
              compgen -A function | grep -v "stdfx_driver";
          ;;
      esac
  }




  auto_main(){
      

      local passed=0
      local failed=0

      run_test(){
          local fn=$1
          local test_type=$2 # "boolean" or "output"
          local expected=$3
          shift 3
          local args=($@)
          local result
          local actual_output

          if [ "$test_type" == "boolean" ]; then

              if "$fn" "${args[@]}"; then
                  result=true;
              else
                  result=false;
              fi;

              if [ "$result" == "$expected" ]; then
                  _pass "$fn ${args[*]}";
                  passed=$((passed + 1));
              else
                  _fail "$fn ${args[*]} (Expected: $expected, Got: $result)";
                  failed=$((failed + 1));
              fi;

          elif [ "$test_type" == "output" ]; then
              actual_output=$("$fn" "${args[@]}");
              # Canonicalize actual_output if the function is project_base
              if [ "$fn" == "project_base" ] && [ -n "$actual_output" ]; then
                  actual_output=$(realpath "$actual_output");
              fi;
              if [ "$actual_output" == "$expected" ]; then
                  _pass "$fn ${args[*]}";
                  passed=$((passed + 1));
              else
                  _fail "$fn ${args[*]} (Expected: '$expected', Got: '$actual_output')" "$actual_output";
                  failed=$((failed + 1));
              fi;
          else
              _fail "Unknown test type: $test_type";
              failed=$((failed + 1));
          fi;
          }


      # --- STRING UTILS ---
      run_test is_empty boolean true "";
      run_test is_empty boolean true " ";
      run_test is_empty boolean false "a";
      run_test is_defined boolean false "";
      run_test is_defined boolean false " ";
      run_test is_defined boolean true "a";
      run_test is_super_defined boolean true "a" "b";
      run_test is_super_defined boolean false "." "b";
      run_test in_string boolean true "a" "abc";
      run_test in_string boolean false "d" "abc";
      run_test strings_are_equal boolean true "a" "a";
      run_test strings_are_equal boolean false "a" "b";
      run_test is_num boolean true "123";
      run_test is_num boolean true ".23";
      run_test is_num boolean true "1.";
      run_test is_num boolean false "abc";
      run_test is_alnum boolean true "abc123";
      run_test is_alnum boolean false "abc!";
      run_test is_alpha boolean true "abc";
      run_test is_alpha boolean false "abc1";
      run_test is_name boolean true "my_var";
      run_test is_name boolean false "my-var";
      run_test starts_with boolean true "a" "abc";
      run_test starts_with boolean false "b" "abc";
      run_test ends_with boolean true "c" "abc";
      run_test ends_with boolean false "b" "abc";

      # --- PATH UTILS ---
      run_test is_path_name boolean true "my/path";
      run_test is_path_name boolean false "/my/path";
      run_test is_path boolean true "$TMP_DIR";
      run_test is_path boolean false "/non/existent/path";
      run_test is_dir boolean true "$TMP_DIR";
      run_test is_dir boolean false "$TMP_DIR/file_with_content.txt";
      run_test is_rw_dir boolean true "$TMP_DIR";
      run_test is_file boolean true "$TMP_DIR/file_with_content.txt";
      run_test is_file boolean false "$TMP_DIR";
      run_test is_rw_file boolean true "$TMP_DIR/file_with_content.txt";
      run_test is_empty_file boolean true "$TMP_DIR/empty_file.txt";
      run_test is_empty_file boolean false "$TMP_DIR/file_with_content.txt";
      run_test is_active_file boolean true "$TMP_DIR/file_with_content.txt";
      run_test is_active_file boolean false "$TMP_DIR/empty_file.txt";
      run_test is_executable boolean true "$TMP_DIR/file_with_content.txt";
      run_test is_executable boolean false "$TMP_DIR/empty_file.txt";
      run_test a_sub_path_b boolean true "$TMP_DIR/test_dir/sibling_file.txt" "$TMP_DIR";
      run_test a_file_in_b boolean true "$TMP_DIR/test_dir/sibling_file.txt" "$TMP_DIR/test_dir";


      local PROJECT_ROOT;
      PROJECT_ROOT=$(realpath "$(project_base "$(pwd)")");
      run_test project_base output "$PROJECT_ROOT" "$(pwd)"; # Should find the current project root
      run_test project_base output "" "/non/existent/project"; # Should not find a project root
      run_test is_project_file boolean true "$PROJECT_ROOT/README.md";
      run_test is_project_file boolean false "/tmp/non_project_file.txt";
      run_test is_project_path boolean true "$PROJECT_ROOT";
      run_test is_project_path boolean false "$TMP_DIR";

      # Create dummy files for sourcing tests
      echo "echo 'sourced_base_file'" > "$TMP_DIR/sourced_base_file.sh";
      mkdir -p "$PROJECT_ROOT/tmp";
      echo "echo 'sourced_project_file'" > "$PROJECT_ROOT/tmp/sourced_project_file.sh"; # Using tmp dir in project root

      uclock "Tree functions here are slow";

      run_test in_project_tree output "$PROJECT_ROOT/README.md" "$PROJECT_ROOT" "README.md";
      run_test in_project_tree output "" "$PROJECT_ROOT" "non_existent_file.txt";
      run_test in_proj_base_tree output "$PROJECT_ROOT/README.md" "README.md";
      run_test in_proj_base_tree output "" "non_existent_file.txt";

      # Test sourcing functions (output will be echoed)
      trace "--- Testing base_source ---";
      base_source "$TMP_DIR/sourced_base_file.sh";

      trace "--- Testing project_source ---";
      project_source "tmp/sourced_project_file.sh";

      trace "--- Testing fuzzy_source (project) ---";
      fuzzy_source "project" "tmp/sourced_project_file.sh";

      trace "--- Testing fuzzy_source (base) ---";
      # Added newline for consistency
      fuzzy_source "base" "$TMP_DIR/sourced_base_file.sh";

      # --- XDG UTILS ---
      run_test xdg_path output "$HOME/.local" "home";
      run_test xdg_path output "$HOME/.cache" "cache";
      run_test xdg_type output "home" "$HOME/.local";
      run_test xdg_type output "cache" "$HOME/.cache";
      run_test is_xdg_path boolean true "$HOME/.local/bin";
      run_test is_xdg_path boolean false "/usr/local/bin";

      # --- LISTING UTILS ---
      run_test ls_bin output "file_with_content.txt" "$TMP_DIR";
      run_test ls_dirs output "test_dir" "$TMP_DIR";
      run_test ls_files output "empty_file.txt\nfile_with_content.txt\nsourced_base_file.sh" "$TMP_DIR";

      # --- MISC UTILS ---
      run_test self_base output "$(realpath "$(dirname "${BASH_SOURCE[0]}")/../pkgs/inc")"; # self_base should return the absolute path of the sourced script (stdfx.sh) directory
      touch "$(dirname "${BASH_SOURCE[0]}")/../pkgs/inc/stdfx_sibling_test_file.txt";
      run_test is_sibling_file boolean true "$(realpath "$(dirname "${BASH_SOURCE[0]}")/../pkgs/inc/stdfx_sibling_test_file.txt")";
      run_test is_sibling_file boolean false "$(realpath "$(dirname "${BASH_SOURCE[0]}")/../pkgs/inc/stdfx.sh")";
      run_test in_tree output "$TMP_DIR/empty_file.txt" "$TMP_DIR" "empty_file.txt";
      run_test make_tmp output "$(xdg_path tmp)/tmp_$(date +%Y%m%d)_$"; # This will echo a path, not return true/false

      # Clean up dummy files
      rm "$TMP_DIR/sourced_base_file.sh";
      rm "$PROJECT_ROOT/tmp/sourced_project_file.sh";
      rm "$(dirname "${BASH_SOURCE[0]}")/../pkgs/inc/stdfx_sibling_test_file.txt";

      test_summary $passed $failed;

  }


  test_summary(){
    local summary_text='' passed=$1 failed=$2;

    #nl xx red green from escape.sh
    summary_text+="${green}${nl}Test Summary:${nl}Total tests: $((passed + failed))${nl}";

      summary_text+="${red}Failed: $failed${xx}${nl}";
      summary_text+="${green}Passed: $passed${xx}";
      __box "$summary_text" 

     [ "$failed" -gt 0 ] && exit 1;
     exit 0;
  }


  main(){
    test_setup;
    if [ "$1" == "auto" ]; then
      auto_main;
    else
      stdfx_driver "$@";
    fi
  }




  if [ "$0" = "-bash" ]; then
    :
  else
    orig_args=("${@}")
    options "${orig_args[@]}";
    args=()
    for arg in "${orig_args[@]}"; do
      [[ "$arg" == -* ]] && continue
      args+=("$arg")
    done
    main "${args[@]}";
  fi



# Cleanup
rm -rf "$TMP_DIR";


