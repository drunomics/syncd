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
#------------------------------------------------------------
# edited by Ross Ivantsiv to support OSX+fswatch (Darwin)
# (c) DataSyntax PE, ross [at] datasyntax.ua

######### Configuration #########

COMMAND="$@"

## Whether to enable verbosity. If enabled, change events are output.
if [ -z "VERBOSE" ]; then
  VERBOSE=0
fi

##################################

if [ -z "$1" ]; then
 echo "Usage: $0 Command"
 exit 1;
fi

##
## Setup pipes. For usage with read we need to assign them to file descriptors.
##
RUN=$(mktemp -u /tmp/watch.run.pipe.XXXXX)
mkfifo "$RUN"
exec 3<>$RUN

RESULT=$(mktemp -u /tmp/watch.result.pipe.XXXXX)
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

eval $WATCHCOMMAND | \
  while read FILE
  do
    if [ $VERBOSE -ne 0 ]; then
      now=`date +'%Y-%m-%d'`
      echo "----" >> $LOGFILE
      echo $now [CHANGE] $FILE >> $LOGFILE
    else
      LOGFILE="/dev/null"
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
      (eval $COMMAND >> $LOGFILE 2>&1; while read -t1 -u3 LINE; do
        echo running >&4
        eval $COMMAND >> $LOGFILE 2>&1
      done)&

      PID=$!
      WAITING=0
    else
      ## If a previous waiting command has been executed, reset the variable.
      if [ $WAITING -eq 1 ] && read -t1 -u4; then
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
