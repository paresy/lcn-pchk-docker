#!/bin/bash

# Fail fast
set -e

# Escape XML special characters. 
# For the license key only & to &amp; is relevant
# And we need to remove all - which the AutoKey feature requires
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

if ([ -z "$LICENSEE" ] || [ -z "$LICENSEKEY" ]); then
    echo "Error: LICENSEE or LICENSEKEY is not set. PCHK will not be licensed and will not work properly."
    exit 1
fi

xmlstarlet ed -L \
  -u "/LcnPchkConfiguration/LicenseInformation/Licensee" \
  -v "$LICENSEE" \
  lcnpchk.xml

xmlstarlet ed -L \
  -d "/LcnPchkConfiguration/LicenseInformation/LicenseKeys/LicenseKey" \
  lcnpchk.xml

xmlstarlet ed -L \
  -s "/LcnPchkConfiguration/LicenseInformation/LicenseKeys" -t elem -n "LicenseKey" -v "$LICENSEKEY_ESCAPED" \
  -i "/LcnPchkConfiguration/LicenseInformation/LicenseKeys/LicenseKey[last()]" -t attr -n "xsi:type" -v "AutoKey" \
  lcnpchk.xml

# Set an UpgradeKey if available. This is optional to e.g. get more usable channels
if [ -n "$UPGRADEKEY" ]; then
    UPGRADEKEY_CLEAN="${UPGRADEKEY//-/}"
    UPGRADEKEY_ESCAPED="${UPGRADEKEY_CLEAN//&/&amp;}"
    xmlstarlet ed -L \
      -s "/LcnPchkConfiguration/LicenseInformation/LicenseKeys" -t elem -n "LicenseKey" -v "$UPGRADEKEY_ESCAPED" \
      -i "/LcnPchkConfiguration/LicenseInformation/LicenseKeys/LicenseKey[last()]" -t attr -n "xsi:type" -v "AutoKey" \
      lcnpchk.xml
fi

# Set username / password if provided via environment variables
if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
    PASSWORD_MD5=$(printf '%s' "$PASSWORD" | md5sum | awk '{print $1}')
    xmlstarlet ed -L \
      -u "/LcnPchkConfiguration/Communication/User" \
      -v "$USERNAME:$PASSWORD_MD5" \
      lcnpchk.xml
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