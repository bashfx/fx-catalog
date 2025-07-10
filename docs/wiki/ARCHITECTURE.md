### Part I: The Guiding Philosophy

This document is less a style guide and more a collection of strongly-held opinions, forged from years of seeing software do stupid things. It's the blueprint for a personal toolkit obsessed with a simple, yet elusive, goal: to be powerful without being rude.

#### **1. The Principles**

These are the established conventions. They are not divine law, but ignoring them has a tendency to lead to long, unpleasant nights of debugging.

- **Principle of Predictability (The Guest Oath):** Any app, script, tool, library, etc. that intends to be a useful guest on a host system must:
    
    - **Self-Contained (Regarding $HOME):** All installation artifacts (libraries, configurations, binaries) must reside within a single, predictable root directory (e.g., ~/.local). Don't make a mess in my home. This rule governs the installer's behavior, not the runtime actions of a user-directed script.
        
    - **Invisible:** Don't throw your junk everywhere. No new dotfiles in $HOME. A good tool is heard from when called upon, and silent otherwise.
        
    - **Rewindable:** Do no harm. Every action must have a clear and effective undo. An install without an uninstall is just graffiti.
        
    - **Confidable:** Don't phone home. Don't leak secrets. Trust is a non-renewable resource.
        
    - **Friendly:** Follow the rules of engagement. Be proactive in communicating your state and use tasteful visual cues (color, symbols) for those of us who think with our eyes.
        
- **Principle of Self-Reliance (The Zero-Dependency Mandate):** A BashFX tool should not require a trip to the package manager for its core function. We build with what's already on the floor: bash, sed, awk, grep. This isn't asceticism; it's a pragmatic commitment to portability and longevity.
    
- **Principle of Transparency Over Magic:** The system should be inspectable. A clever one-liner is admirable, but a black box is a liability. Favor clear, explicit actions over solutions that hide their intent, however elegant they may seem.

-----

### Part II: The Architectural Patterns

These are the conventions and patterns that define how BashFX scripts are constructed. Adherence is not mandatory, but a deep understanding of them is required to contribute effectively.

#### **2.A: Naming, Scoping & The Standard Interface**

This section covers the low-level "grammar" of a BashFX script: how things are named, how scope is implied, and the expected skeleton of a "Proper Script."

- **1. Respect for "Known" Globals:** A concerted effort is made to respect community-accepted global variables (DEBUG, NO_COLOR, etc.). This is a goal we work towards for better cross-system standardization.
    
- **2. Variable Case by Scope:** The casing of a variable implies its scope.
    
    - `ALL_CAPS_VARIABLES`: Represent one of two things: either a configuration value inherited from a session/setting file, or a pseudo-constant.
        
    - `lowercase_variables`: Imply a more ephemeral scope, such as variables passed as arguments or those declared locally within a function.
        
    - Example: `OPT_DEBUG` and `opt_debug` may exist concurrently. OPT_DEBUG would be a framework-level or inherited setting, while opt_debug would be the function-local state variable derived from a command-line flag.
        
- **3. Namespacing:**
    
    - **Proper (Vanity) Namespaces:** While an ideal, every "proper" application should have its own vanity namespace to prevent clobbering (e.g., FX_/fx_, MARK_/mark_). These are often tied to the "Thisness" context.
        
    - **Standard Prefixes:**

        - `fxi_/FXI_`: For the setup/installer context.
            
        - `fx_/FX_`: For the user runtime context.
            
        - `opt_`: For argument flag states.
            
        - `THIS_/this_`: For the "Thisness" context pattern.
            
        - `dev_`: For internal/testing/destructive functions.
            
        - `_name`: A single underscore prefix denotes a local, internal, or short-term throwaway.
            
        - `___name`: A double underscore prefix denotes a pseudo-private subroutine.
            
        - `__NAME__`: A double-bound underscore denotes a template or sentinel value.
            
        - `____`: The underbar blank often denotes a "poorman's this" or the immediate context.

            
- **4. Standard Interface:** All BashFX-compliant functions should adhere to this interface.
    
    - **Return Status:** Always return 1 (failure, implied default) or 0 (success, explicit). It is good practice to initialize `local ret=1;`.
        
    - **Standard Stream Usage:** Use the stderr stream (`>&2`) for all human-readable messaging. Use the stdout stream only for passing calculated values that can be captured by $(...).
        
    - **Predictable Local Variables ("Lazy" Naming):** A predictable set of local variable names is consistently used for common tasks.
        
        > I'm lazy and naming things is hard.
        
        - `ret` (status), `res` (value/result)
            
        - `str, msg, lbl` (strings)
            
        - `src, dest, path` (paths)
            
        - `arr, grp, list` (iterables)
            
        - `this, that, ref, self` (identity)
            
        - `i, j, k, curr, next, prev` (cursors/loops)
            

*   **5. Function Compatibility:** A "Proper Script" is a self-contained application built from a predictable set of standard functions.

    *   **`options()`:** The argument parser. Its sole responsibility is to iterate through command-line flags (e.g., `-f`, `--force`) and set corresponding `opt_*` state variables. This is the primary mechanism for controlling script behavior at runtime.
        *   **Standard Flags & Behavior:**
            *   `opt_debug` (`-d`): Enables the first level of messages from `stderr.sh` (`info`, `warn`, `okay`). 
            *   `opt_trace` (`-t`): Enables the second level of log messages (`trace`, `think`). This flag often enables `opt_debug` as well.
            *   `opt_quiet` (`-q`): Silences all output except `error` and `fatal` messages, overriding other logging flags.
            *   `opt_force` (`-f`): Used to bypass safety guards or non-critical error checks.
            *   `opt_yes` (`-y`): Automatically answers "yes" to all user confirmation prompts.
            *   `opt_dev` (`-D`): A master developer flag, often used as a shortcut to enable multiple other flags like `opt_debug` and `opt_trace`.
        *   *Notes*: 
	        * Current implementations do not support combo flags like `-df` and avoid external parsers like `argparse`. Instead capital case flags can be used to flip multiple other flags like in the case of `-D`. Use of other similar patterns is dependent on needs and may vary.
	          
	        * BashFX's `stderr.sh` library and `options()` pattern standarizes the following assumptions (more details are provided in the explicae of the stderr functions):
	          
		        * Semi-Quiet. By default if no flag is set by `options()`, only error and fatal messages may be visible when they occur. No other status messages are provided for at this base level. This may be an unexpected consequence and thus using the minimal `-d` flag is required to see first level output, and `-t` for second level.
		          
		        * Forced Output. `-f` can be used to override an inherited quiet mode setting, and most of the log messages support a force parameter in cases where you want to quiet everything else, but are looking for a specific output. Force has other utilities but is automatic in the log message system.
		          
		        * Dev Mode. the `-D` flag is used in conjuction with the `dev_required` guard, displays any `dev()` output which represents a third log level.
		          
		        * All message levels above the first are designed to be independently invoked unless overriden by the Dev Mode implementation for `options()`
		        

    *   **`dispatch()`:** The command router. Typically a `case` block that takes a command string as input (e.g., `install`, `verify`) and executes the corresponding internal function (e.g., `do_install`, `fx_verify_all`), passing along any remaining arguments.

    *   **`main()`:** The primary entrypoint for the script. It orchestrates the core lifecycle: calling `options()` to parse arguments, performing any necessary setup, and finally, handing control to `dispatch()`.

    *   **`usage()`:** The function that displays detailed help text to the user. It typically finds and prints a "Block Hack" (e.g., a `#### usage ####` block) from within the script's own source code.

    *   **`inspect()`:** A pragmatic self-analysis tool. When a full `usage()` is not yet written, this function parses the script's source to list available commands, often by finding functions that match a `do_*` or `fx_*` pattern.

    *   **`dev_*()`:** A dedicated namespace for functions intended for development and testing. These are used to test specific sub-features, run diagnostics, or gate access to potentially destructive operations not meant for general use.

	- **6. Printing**. All functions bias towards using *stderr* for the developer/user messages and *stdout* output for capturing calculated values.
	  
		- **Output UX**. a suite of standardized printing utilitties, escapes and functions has historically been embedded into legacy standalone  scripts and is now being standardized into libraries: *stderr.sh* and *escape.sh* 
		  
		- *Functionality*. The mainline functions of *stderr.sh* include a simple `stderr()` function, a suite of log-level like functions wrapping the stderr stream via printf, and other UX visualization like borders lines and boxes, and confirmation prompts. *escape.sh* features a curated set of 256-color escape codes and glyphs for use with the various printer symbology. 
			
		  Log level like functions include:
			- Baseline (default level)
				- *error* - a state guard was triggered.
				- *fatal* - similar to error but calls exit 1.
				  
			- Standard Set (first level `-d`)
				- *warn* - imperfect state but trivial or auto recoverable.
				- *info* - usually a sub-state change message.
				- *okay*  - main path success message.
				- *recover* - the expected step failed but a recovery branch was available. Acts as recovery success message.

			- Extended Set (second level `-t`)
				- *trace* - for tracing state progressing or function output
				- *think* - for tracing function calls
				  
			- Extended Set (third level `-s`)
				- *silly* - for ridiculous log flagging and dumping of files when things arent working as expected.
				  
			- Dev Mode Set (fourth level `-D`)
				- *dev* - dev only messages used in conjuction with `dev_required()`.

			- Additional custom loggers can be created and attached to the  level-specific option flag.
				  
			- The first level and above follow typical loglevel usage, but currently only supports on/off gating with opt_debug and opt_quiet. Error messages can never be silenced.
			  
			- The second level and above set must be enabled explicitly, via `opt_trace`, `opt_silly` and `opt_dev`. 
			  
			- All of the loglevel messages are colored with a glyph prefix. If no styling is desired use the `stderr()`
			  
		- Standardized `NO_COLOR` global var is slowly being integrated for portability.

*   **7. Standard Patterns:** 
	* **Proper Script**. A fully self-contained script that implements the BashFX Standard Interface (set of functions), and supports the Standard Patterns (especially XDG+), as needed. As the library and standard patterns are further cleaned up, the definition of proper script may expand. Proper here implying that a script is fully featured and compatible with the BashFX framework. 

	* **Dynamic Pathing**. Most pathing invocations start from a relative root usually `$SOMETHING_ROOT` or `$SOMETHING_HOME`, from which all other subpaths derive, this is in line with BashFX's principle of self-containment because it contains everything downstream. Historically most paths have been relative to `$HOME`, but are now using the XDG root which IMHO is `$HOME/.local`. You'll see how XDG breaks this BashFX standard, but we find partial compatibility with it anyway.
	  	  
	- **XDG+ Compliance**. BashFX follows the XDG standard for local directory tree, but in SUPER_BASHX_STANDARDS_MODE deviates slightly. 
	  
		- **Minimum Respect to XDG**. BashFX will respect other libraries that wish to use the standard XDG pathing in not clobbering them, and will (eventually) support using the full XDG spec. Meanwhile...
		  
		- **Super Bashfx Deviation**. Due to XDG's violation of BashFX principles of no-pollution, self-containment and DFWH in its inclusion of the weird `$HOME/.config` and `$HOME/.cache` directories, while also dropping everything else into `$HOME/share` and providing no clean name space for standard conventions like `etc` `lib` and `data`, BashFX only supports the use of `$HOME/.local` as a means of cleaning up the `$HOME` directory, and uses it thusly:
			- `$HOME/.local/lib` - script and library packages installed by BashFX are stored in the lib under their app namespace
			- `$HOME/.local/etc` - configuration files go here ceremoniously because I often forget that `.config` even exists, and so I refuse to use it.
			- `$HOME/.local/data` - meant for data libaries like db files, dictionaries, reference jsons, which has a different usecase than `.cache`.
			- `$HOME/.local/bin` - a script is considered installed if its alias-ly linked to a location in the local
			- I'm not entirely convinced yet that ./local/state is different than .local/etc, so I have not adapted or ignored the use of XDG state yet.
			  
	- **Embedded Docs**. I refer to as comment hacks.  A super pattern of BashFX is to direclty include inert meta information, templates, and documentation within the comments of a script, either as a lined sentinel or a block denoted by senintel pairs. As comments, these sections are out-of-scope unless the activating scripts are applied to them. In limited situations they may invoke a dangerous `eval`, but only with filters and escaping for security. This is to prevent errant rimraf all type commands from executing. Otherwise simple `sed` and `awk` parsing pull out the important bits.
	
		- Some variants: 
	  
			* Logo Hack - in a proper script commented lines under the shebang often feature some sort of branding or ascii art. The line numbers are globbed and the comment prefis stripped and latered printed to screen as an intro.
			  
			- Meta Hack - key value pairs embedded in a comment like ` # key: value `, used for things like naming, versioning, and other meta stuffs.
			  
			- Line Hack - dropping a commented line that sources another file into an active file. 
			  
			- Block Hack - sentinel bound scriplet, usually use to print the `usage()` documentation or the state saving rcfile. I think I started using this method for usage because I hated the way heredocs would never allow you to indent the block of text. Block sentinentls usually look like ` #### label ####` or have an html-like open and close tag.
			  
	 This is an old pattern I was so proud of myself to have discovered in mastering sed and awk finally, and its been hard to let go of. Eventually when I get into flesing out regular man pages and mature the packaging system this may be faded out. For now at least it explains an otherwise obtuse feature. 

	- **RC Files**. BashFX uses  rcfiles (*.rc*) to indicate state or demark a session.
	  
		- **Stateful**. Rcfiles are treated as mini sub profiles that switches a user into a branched sub-session by setting certain environment variables, defining aliases and functions or writing other state files. The presence or lack of an rcfile indicate a start or end state respectively, and any set of variables within the rcfile can indicate other interstitial states.
		  
		- **Linking**. Rather than writing data directly to a users .profile, BashFX uses a linking system (link, unlink, haslink) via sed or awk to link its master rcfile (.fxrc);any additional linking by its packaged scripts can treat .fxrc as the master session and be enabled (link) or disabled (unlik) simply by removing their link lines, usually indicated by a label.
		  
		- **Canoncial Profile**. The true location of a users profile may vary but only so many locations are viable. Since the main profile acts as the source of state truth (via linking), its important to map the correct one, and alternatively allow for virtual profiles for testing.
		  
	- **Thisness.** new to BashFX, pseudo this/self functionality mimicks scope sharing with generalized functions. A mainline script can call its own `[namespace]_this_context` to define a set of THIS_* prefixed variables for use in shared libary scripts. Well-defined functions dont have to be included everytime just to accomodate a different namespace, enabling another degree of code-reuse. Using thisness is only ideal in a single script context, where THIS_* values are unlikely to be clobbered. Library functions leveage thisness by derefencing any THIS prefixed values they need to read from.
