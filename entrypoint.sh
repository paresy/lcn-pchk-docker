#!/bin/bash

# Fail fast
set -e

# We need to check if the kernels pagesize is 4k
# If not, we need to immediate exit, as lcnpchk will not work properly
PAGESIZE=$(getconf PAGESIZE)
if [ "$PAGESIZE" -ne 4096 ]; then
    echo "Error: Kernel page size is not 4k, but $PAGESIZE. Exiting."
    exit 1
fi

# PCHK will check all available FDs (Verfied via strace -f ./lcnpchk)
# Limit the number to keep the startup time reasonable. 
ulimit -n 10000

# This will spwan to the background
./lcnpchk

# Wait until process appears
PID=""
while [ -z "$PID" ]; do
    PID=$(pgrep -f lcnpchk)
    sleep 1
done

echo "Found PID $PID"

tail --pid="$PID" -f /dev/null