# FX-SYNC(1)

## Bash 3.2+ Script
FX-SYNC(1) bash sync manager using fswatch + rsync. Uses config file to spawn rsync tasks. Pretty janky but works.This repo 
is a temporary home until I move into its final @basfx/fx-xsync home because I was not saving changes! oops.

## Note
Please note that this is only been tested on latest mac os and may not work on other linux systems (atm) for things like sed that 
may have a different implementation. Note that this also requires fswatch (`brew install fswatch`).

Also note that the script will need some major cleanup so consider this a beta if you decide to use it. If you are tinkering around with the script, the flow is `main -> options -> dispatch -> api` for all calls. There may be some redundancies in the code from things I havent cleaned up yet (like the syncx.cache file).

Finally if for some reason commands are not outputting ANY information to console, use the `--trace` flag, that usually works. 

## Install

First specify your `$XSYNC_HOME` prefix which will be the home directory for all files used by XSYNC. Add it to your .profile or current environment.

XSYNC will look for your default config file in `$XSYNC_HOME/config`. You can also use the `--config` command to specify a path. 

Config file format is `SSH_HOST LOCAL_DIR HOST_DIR` one RSYNC entry per line. You can have multiples of the same host in case your 
syncing multiple directories. SSH_HOST is the host entry in your `~/.ssh/config` where you have already setup SSH keys on your local 
and remote server. 

XSYNC has not been tested to handle RSYNC ssh connections without a pre-made ssh key.

## Usage

### xsync (command) [options]

### xsync help
*prints commands and options*

### xsync --trace 
*trace flag shows additional debug msgs level 2*
### xsync --debug
*debug flag prints non essential info level 1*
### xsync --quiet
*shuts off all non-essential outputs and only prints essentials*
### xsync --mirror
*enables deleted file sync on rsync, by default it only syncs writes*
### xsync --config path/to/config
*set a custom path for the config file that should be used*

### xsync run 
*iterates through the config file to start an fswatch and rsync handler for each entry*
### xsync stop
*kills all fswatch and child rsync processes, which just uses PID-1 to find the child*
### xsync pause <N>
*pause the FSWATCH JOB with index N*
### xsync restart <N>
*restart the FSWATCH JOB with index N*
### xsync stat 
*list all watchers and their status*


*there are additional utility commands mostly for debugging, check the dispatch function to see all of them*

## Final Note

Now that I have the basics working it may be a minute before I get around to fully debugging/cleaning up but feel free to toy around 
and if you have any recommendations please let me know. 

Warning -- first make sure you have essential files backed before attempting to use xsync with them; I recommend to test with a set of dummy directories to make sure everything is working ok before running live files. "Works on my machine"
