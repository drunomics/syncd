#!/bin/bash
# (c) Wolfgang Ziegler // fago
#
# Inotify script to trigger a command on file changes.
#
# The script triggers the command as soon as a file event occurs. Events
# occurring during command execution are aggregated and trigger a single command
# execution only.
#
# Usage example: Trigger rsync for synchronizing file changes.
# ./watch.sh rsync -Cra --out-format='[%t]--%n' --delete SOURCE TARGET
#
# ./watch.sh rsync -Cra --out-format='[%t]--%n' --include core \
#  --WATCH_EXCLUDE=sites/default/files --delete ../web/ vagrant@d8.local:/var/www

######### Configuration #########

EVENTS="CREATE,CLOSE_WRITE,DELETE,MODIFY,MOVED_FROM,MOVED_TO"
COMMAND="$@"

## The directory to watch.
if [ -z "WATCH_DIR" ]; then
  WATCH_DIR=.
fi

## WATCH_EXCLUDE Git and temporary files from PHPstorm from watching.
if [ -z "$WATCH_EXCLUDE" ]; then
  WATCH_EXCLUDE='(\.git|___jb_)'
fi

## Whether to enable verbosity. If enabled, change events are output.
if [ -z "WATCH_VERBOSE" ]; then
  WATCH_VERBOSE=0
fi

##################################

if [ -z "$1" ]; then
 echo "Usage: $0 Command"
 exit 1;
fi

##
## Setup pipes. For usage with read we need to assign them to file descriptors.
##
RUN=$(mktemp -u)
mkfifo "$RUN"
exec 3<>$RUN

RESULT=$(mktemp -u)
mkfifo "$RESULT"
exec 4<>$RESULT

clean_up () {
  ## Cleanup pipes.
  rm $RUN
  rm $RESULT
}

## Execute "clean_up" on exit.
trap "clean_up" EXIT


##
## Run inotifywait in a loop that is not blocked on command execution and ignore
## irrelevant events.
##

inotifywait -m -q -r -e $EVENTS --exclude $WATCH_EXCLUDE --format '%w%f' $WATCH_DIR | \
  while read FILE
  do
    if [ $WATCH_VERBOSE -ne 0 ]; then
      echo [CHANGE] $FILE
    fi

    ## Clear $PID if the last command has finished.
    if [ ! -z "$PID" ] && ( ! ps -p $PID > /dev/null ); then
      PID=""
    fi

    ## If no command is being executed, execute one.
    ## Else, wait for the command to finish and then execute again.
    if [ -z "$PID" ]; then
      ## Execute the following as background process.
      ## It runs the command once and repeats if we tell him so.
	  (eval "$COMMAND"; while read -t0.001 -u3 LINE; do
	    echo running >&4
	    eval "$COMMAND"
	  done)&

      PID=$!
      WAITING=0
    else
      ## If a previous waiting command has been executed, reset the variable.
      if [ $WAITING -eq 1 ] && read -t0.001 -u4; then
        WAITING=0
      fi

      ## Tell the subprocess to execute the command again if it is not waiting
      ## for repeated execution already.
      if [ $WAITING -eq 0 ]; then
        echo "run" >&3
        WAITING=1
      fi

      ## If we are already waiting, there is nothing todo.
    fi
done
