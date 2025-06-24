# FX-FLAGBASE(1)

FX-FLAGBASE is a versatile utility designed for managing key-value pairs within environment profiles, using the filesystem as the primary storage medium. It allows for dynamic editing of environment variables, separate from the execution context, and supports both session-specific and global (locked) keyfiles.

## Features

- **Keyfile Management:** Handle key-value pairs where filenames are keys and file contents are values.
- **Session Contexts:** Manage different sets of variables within isolated sessions.
- **Locked Keys:** Global, session-independent variables that are accessible across sessions.
- **Dynamic Environment Editing:** Edit variables in real-time without restarting the execution context.
- **Extensive Command Set:** Rich set of commands for comprehensive environment and keyfile management.

## Installation

Set up FX-FLAGBASE by configuring the following environment variables in your `.profile` or `.bash_profile`:

```bash
export FLAGX_HOME=<your_flagx_home_directory>  # The home directory for FLAGBASE files
export FLAGX_CURSOR_HOME=$HOME/.flagx          # Location for the active session cursor file
export FLAGX_EXPORT_PATH=$HOME/exports         # Export path for the script outputs
```

Move the FX-FLAGBASE script to a local bin directory or create a symlink to it, for example:

```bash
ln -s /path/to/fx-flagbase /usr/local/bin/kvfb
```

## Usage
Invoke FX-FLAGBASE commands using the kvfb command:

```bash
kvfb [options] [command] <arguments...>
```

###  Session Commands
- `kvfb new|n <session>`: Start a new session with a specified or random name.
- `kvfb switch|sw <session>`: Switch to an existing session.
- `kvfb lss|@`: List all available sessions.
- `kvfb curr <session>`: Return the ID of the active session.
- `kvfb reset|RRR`: Delete the active session.
- `kvfb nuke|nukeall|NNN`: Delete the entire filebase and start anew.
- `kvfb clean|CCC`: Remove all temporary keys from the session.

### Keyfile Commands
- `kvfb write|w <key> <value>`: Create a new key-value record in the active session.
- `kvfb write_safe|ws <key> <value>`: Create a new record only if the key does not exist; otherwise, rotate the old key.
- `kvfb new_key|key`: Create an empty keyfile placeholder.
- `kvfb read|r <key>`: Read the value of a key in the current session.
- `kvfb hist|h <key>`: Print the history of changes to a write-safe keyfile.
- `kvfb delete|rm <key>`: Delete a key from the current session.
- `kvfb toggle|tog <key>`: Toggle the boolean value of a key.
- `kvfb ls`: List all keyfiles in the current session.

### Locked (Protected) Keyfile Commands
- `kvfb write_lock|pw <key> <value>`: Write to a locked keyfile.
- `kvfb write_safe_lock|pws <key> <value>`: Write-safe operation for locked keyfiles.
- `kvfb new_lock|lock <key>`: Create a new locked keyfile.
- `kvfb read_lock|pr <key>`: Read a locked keyfile.
- `kvfb hist_lock|ph <key>`: History of a locked keyfile.
- `kvfb delete_lock|prm <key>`: Delete a locked keyfile.
- `kvfb toggle_lock|ptog <key>`: Toggle a locked keyfile boolean value.
- `kvfb ls_lock|pls`: List all locked keyfiles.
- `kvfb promote <key> [--admin]`: Promote a session keyfile to global.
- `kvfb demote <key> [--admin]`: Demote a global keyfile to session-specific.

### Utility Commands
- `kvfb export [--envfile|-E]`: Export sessions and global keys.
- `kvfb import <filepath>`: Import a valid flagbase file.
- `kvfb autoclean`: Set to automatically remove temporary keyfiles.

## Options
--admin, -A: For administrative commands.
--debug, -d: Enable debug output.
--envfile, -E: For handling locked keyfiles during export/import.

## Contributing

Contributions to FX-FLAGBASE are welcome. Please read the contributing guidelines before submitting pull requests.

## License
FX-FLAGBASE is licensed under the MIT License.
