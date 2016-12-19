
Project was originally forked from https://github.com/drunomics/syncd which was designed for Linux systems.

The benefits of our rework is:

1. Support of OSX

2. Very simple config file, which has great flexibility as to what has to be tracked/synced.

syncd
=====

Syncd is a simple bash script that watches for file changes and rsyncs them to a remote machine. It uses OS-proprietary file change notification system (like inotify for Linux, fsevents for OSX) to watch for file system changes and syncs the whole directory to a
remote machine using rsync. The script makes sure to aggregate change events during a running rsync, such that after the initial sync a subsequent sync can be triggered (and so on).

Requirements
------------

Linux
_____
Right now a linux based system with inotify-tools and rsync installed is required, .e.g for ubuntu/debian based systems run
```
apt-get install inotify-tools rsync
```

OSX
___
For OSX https://github.com/emcrisostomo/fswatch seems to be the most advanced tool for monitoring file changes using
fsevents
```
brew tap homebrew/dupes
brew install rsync
brew install fswatch
```

Windows
_______
No bash version of the project exist for Windows. Instead we are developing a C# clone. 


Installation
------------
 * Clone the script in a directory of your choice, e.g.
```
cd ~/opt
git clone git@github.com:DataSyntax/syncd.git
```
 * Best, put syncd in your $PATH, for example by running:
```
cd syncd
sudo ln -s $PWD/syncd /usr/local/bin/syncd
```

Usage
-----
* Copy the syncd.conf file to the directory you want to sync, or in some of its parent directories and adapt it your needs.
* Run "syncd start" in any directory below of the directory holding your syncd.conf file to start the daemon script.
* By default, the script will create a .syncd.pid file for tracking the daemon process ID and a .syncd.log file to which the rsync output will be written.
* Arguments known are the ones known from initd scripts (start,stop,restart,status) as well as "run" for manually triggering a rsync and "log" for checking the rsync output.


Authors
-------
Ross Ivantsiv, ross(-at-)datasyntax.ua, DataSyntax PE
Wolfgang Ziegler, nuppla@zites.net, drunomics GmbH
