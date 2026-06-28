#!/bin/bash

# Fail fast
set -e

# Escape XML special characters. 
# For the license key only & to &amp; is relevant
# And we need to remove all - which the AutoKey feature requires
LICENSEE_ESCAPED="${LICENSEE//&/&amp;}"
LICENSEKEY_CLEAN="${LICENSEKEY//-/}"
LICENSEKEY_ESCAPED="${LICENSEKEY_CLEAN//&/&amp;}"

# We need to check if the kernels pagesize is 4k
# If not, we need to immediate exit, as lcnpchk will not work properly
PAGESIZE=$(getconf PAGESIZE)
if [ "$PAGESIZE" -ne 4096 ]; then
    echo "Error: Kernel page size is not 4k, but $PAGESIZE. Exiting."
    exit 1
fi

# We need to patch the xml file to have it licensed automatically
# PCHK converts the LicenseKey (AutoKey) to a ProductKey on first start and saves it in the lcnpchk.xml file.
# But it is somehow locked to the machine and after each reboot will it be invalid. So we need to set the LicenseKey
# on each start, and let PCHK convert it to a ProductKey during startup to keep it happy and valid.
xmlstarlet ed -L \
  -u "/LcnPchkConfiguration/LicenseInformation/Licensee" \
  -v "$LICENSEE_ESCAPED" \
  lcnpchk.xml

xmlstarlet ed -L \
  -d "/LcnPchkConfiguration/LicenseInformation/LicenseKeys/LicenseKey" \
  -s "/LcnPchkConfiguration/LicenseInformation/LicenseKeys" -t elem -n "LicenseKey" -v "$LICENSEKEY_ESCAPED" \
  -i "/LcnPchkConfiguration/LicenseInformation/LicenseKeys/LicenseKey" -t attr -n "xsi:type" -v "AutoKey" \
  lcnpchk.xml

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