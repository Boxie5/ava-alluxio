#!/bin/bash

######################################################################
# worker node list:
# jq90 jq104 jq107
######################################################################

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export GROUP=juewa
export NODE_LIST="jq90 jq104 jq107"

${DIR}/../template/worker.sh "$@"
