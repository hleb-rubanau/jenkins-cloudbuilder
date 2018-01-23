#!/bin/bash

function say() {  echo "[$0] $*" >&2 ; }
function die() {  say "ERROR: $*" ; exit 1; }

ALLOW_SUDO=${ALLOW_SUDO:-$1}

if  [ -z "${ALLOW_SUDO}" ]; then exit ; fi

# IFS means EITHER comma or space as separator
IFS=', ' read -r -a SCRIPTLIST <<< "$ALLOW_SUDO"

modifications_applied=false

for script in "${SCRIPTLIST[@]}"; do
    scriptpath=$( python -c "import os; print os.path.abspath('${script}');" )

    if [ ! -e $scriptpath ]; then 
        say "WARNING: skipping $scriptpath (not found)"
        continue
    fi

    SUDOERS_FILE=/etc/sudoers    
    sudo_line="jenkins      ALL = (root) NOPASSWD:SETENV:$scriptpath"
    if grep -q "${sudo_line}" $SUDOERS_FILE ; then
        say "Already in sudoers: $sudo_line"
        continue
    fi

    say "Adding to $SUDOERS_FILE: $sudo_line"
    echo "$sudo_line" >> $SUDOERS_FILE
    modifications_applied=true
done

if $modifications_applied ; then
    say "This script is intended for bootstrapping only; removing myself"
    selfpath=$( python -c "import os; print os.path.abspath('${0}');" )
    rm -v "$0"
fi
