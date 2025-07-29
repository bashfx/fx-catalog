# MARK(1) v0.6

Bash bookmarking utility (OSX/BSD compatible using CoreUtils)

## Overview

This bad boy needs some cleanup but works up to Bash 5.

What you'll need:
  * The linux-standard realpath command
  * Local Bin ($HOME/.local/bin) directory to store your user scripts

At present the script doesnt support custom installation paths, but if you know what you're doing it's easy enough to
update yourself.

## Quick Install (Advanced Users)

 1. `brew install coreutils`
 2. `which realpath`
 3. `mkdir -p $HOME/.local/bin`
 4. `printf "PATH=\"$PATH:$HOME/.local/bin\" << ~/.bash_profile`
 5. `source .bash_profile`
 6. `cp ./markman $HOME/.local/bin/mark`
 7. `chmod +x  $HOME/.local/bin/mark`
 8. `$(which mark) && mark --ez || :`

## Installation

On macOS make sure you have the installed/updated [homebrew](https://brew.sh/), and follow these steps:

### 1. Install Core Utils

`brew install coreutils`

Once this is done check for realpath:

`which realpath`

## EZ Install

### 2. Automated (using local markman)
From within the repo you checked out, you can directly call the pre-install script "markman" with the "--ez" flag.

`./markman --ez`

 This will install the JUMP, REM and LAST functions/aliases. It will also copy the MARK(1) script into your user bin directory.
 From this point just source your profile to enable the aliases.

## Manual Install

### 3.  Add Local Bin to PATH (if you have not already setup a .local/bin)

**3.1.** Create a local bin directory if you don't already have one:

	mkdir -p $HOME/.local/bin`

**3.2.** Open `~/.bash_profile` (macOS) in your favorite GUI, or terminal editor (create it if it doesn't exist):

	nano ~/.bash_profile`

**3.3.** Append the local bin path to any previously existing PATH reference in your profile.

	export PATH="$PATH:$HOME/.local/.bin"`

**Note:** : *Alternatively, you may also consider adding an environment variable for it in your profile*:

	export MY_BIN="$HOME/.local/bin";
	export PATH="$PATH:$MY_BIN"

**3.4.** Once you're happy with your changes, save it and either restart your terminal session or source your profile for the changes to take affect:

	source .bash_profile

**Note**: *It may be better to start a new terminal session because subsequent sourcing of your profile will cause the PATH variable to explode.*

In a refreshed terminal, check this by doing:
`echo $PATH`

### 4.  Copy the MARKMAN Executable to MARK
**4.1.** Copy the `markman` script from the cloned repo directory to your local bin directory.

	cp ./markman  $HOME/.local/bin/mark

Check that your system can find the script:

	which mark

If nothing is returned check the executable permission for the file and add it if it's missing:

	chmod +x mark

Then try `which` again. If nothing is returned either your PATH variable is wrong or your terminal still needs to be refreshed.



## Usage

To bookmark the current directory with a label: `mark [label]`

All bookmarks must be *unique*, and only one *canonical* bookmark path can be stored (with the exception of the #LAST label.)

On the first use `mark` will create the `$HOME/.mark` to store all your bookmarks. These bookmarks are persisted even after you close your terminal session.

**Note**: Because the first argument to `mark` can be any bookmark name, all executable commands are mapped to flags. (Example `mark --help` instead of `mark help`, the latter will create a bookmark called help).

## Parameters

### 1. Bookmarks (Labels)
A label is the name of a particular bookmark that maps to an *absolute canonical path* on your filesystem. Bookmarks allow you to maintain a list of your favorite and frequently access directories to make traversal your directory tree from the command line, easier.

##### 1.1 Naming Bookmarks
You can *technically* use any Unicode character for your bookmarks, but to reduce the possibility of errors, its strongly recommended you stick to the set of alpha-numeric characters [ a-z ] [ 0-9 ] and a small subset of special characters [ _-. ].


##### 1.2 Bookmark Collisions
By design, all bookmarks must be unique; that is, you cannot have more than one bookmark with the same name. Attempting to add a duplicate bookmark would only overwrite the previous one, and so overwriting bookmarks is not allowed, except when explicitly requested via the --edit flag. Without  the --edit flag, name collisions will throw an error and prevent any changes.

##### 1.3 Bookmark Persistence
Because MARK(1)

### 2. Paths
Paths can be referenced in two ways, (1) implicitly, using the current working sirectory ($CD/$PWD), or (2) explicitly with a relative or absoute path. Bookmarked paths are limited to directories (e.g. you can't bookmark a file).

## API

### Help ( -h --help )
`mark --help ` or `mark -h` will print the available flags

### List  ( -l --ls )
`mark --ls` or `mark -l` to print the current list of bookmarks

### Get Symlink (-s --link)
`mark -s [label]` to return the path mapped to the bookmark

### Get Time (-t --time)
`mark -t [label]` to return the datetime when the bookmark was created.

### Add Mark
`mark [label]` to automatically set a bookmark for the current directory. You can only use a label once, and you can only use a canonical path once, except in the case of LAST.

### Add Mark for  Path ( -a --add )
`mark --add [label] [path]` to set an explicit path for a label (instead of current directory). *Path can be relative as `realpath` will conver to absolute path.*

### Edit Mark
`mark --edit [label]` to overwrite the pre-xisting label with the new current working directory. This flag allows you to change where a pre-existing label points to. It can also be used with the Add Mark for Path flag.

### Remove Mark
`mark --rm [label]` to remove a specific bookmark

### Remove All
`mark --clr` to remove all bookmarks

### Uninstall Mark
`mark --reset` to uninstall mark; it will create a backup of your bookmarks with .bak in case you want to save them for later.

## Addons
When using EZ Install (	`--ez`), mark will embed the JUMP, REM and LAST addons to your profile.

### JUMP
`jump [label]` will jump you to the link indicated by the label. Use this command whenever you want to change directories using your boomarks

### REM
`rem` will store the path of the current directory under the LAST label. (Rem is a special alias to `mark`)

### LAST
`last` will jump you to to the link indicated by the LAST label. (Last is a special alias to `jump`)

