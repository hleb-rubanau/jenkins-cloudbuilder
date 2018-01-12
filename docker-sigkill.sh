#!/bin/sh

set -e 

function usage() {
    cat >&2 <<USAGE
Usage: $(basename $0) SIGNAL FILTER
    SIGNAL: HUP, TERM, man kill...
    FILTER: as in 'docker ps', e.g. label=SERVICE_NAME=nginx
USAGE
    exit 1
}

if [ "$1" = "--help" ]; then usage; exit 0 ; fi
if [ -z "$*" ]; then usage ; exit 1; fi

SIGNAL="$1" ; shift
FILTER="$*"

if [ -z "$FILTER" ]; then usage; exit 1; fi

nameslist="$( docker ps --filter $FILTER --format '{{.Names}}' | xargs )"

if [ -z "$nameslist" ]; then
  echo "No containers found with: --filter $FILTER"
  exit
fi

set -x
docker kill -s $SIGNAL $nameslist
