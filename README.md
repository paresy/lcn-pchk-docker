# LCN PCHK for Docker

This repo focuses on creating an ARM64 (aarch64) compatible container that can be run side by side with Symcon.
By using a wiringPi shim, the container is not dependend on a Raspberry Pi hardware platform.

## Usage

```
docker run \
  --name lcnpchk \
  --publish 4114:4114 \
  --publish 4220:4220 \
  --device=/dev/ttyUSB0 \
  --env LICENSEE='paresy' \
  --env LICENSEKEY='xxxxx-xxxxx-xxxxx-xxxxx-xxxxx-xxx' \
  --env UPGRADEKEY='xxxxx-xxxxx-xxxxx-xxxxx-xxxxx-xxx'
  --env USERNAME='lcn' \
  --env PASSWORD='lcn' \
  ghcr.io/paresy/lcn-pchk-docker:arm64
```

### Further Hints

* **LICENSEE** and **LICENSEKEY** are mandatory. Setting the license through the PCHK Monitor is not supported!
* If your device is not /dev/ttyUSB0 but /dev/ttyUSB5, you need to properly map it e.g.
  * **--device=/dev/ttyUSB5:/dev/ttyUSB0**
* **UPGRADEKEY** is optional and can be left out or empty if not available
* **USERNAME** and **PASSWORD** are optional. When either one is not set, this is the default:
  * **Username:** lcn  
  * **Password:** test123
* Use the Windows PCHK Monitor if you need to change any other configuration option.
  * Connect using "Computer in Network"

## Running on a Raspberry Pi 5

When using a Raspberry Pi 5 the Raspberry Pi OS uses a 16k PageSize instead of the default 4k PageSize. LCHK is not compatible with a 16k PageSize. Luckily we can revert Raspberry Pi OS in using a 4k PageSize even on the Raspberry Pi 5. Ask your favorite AI how to accomplish this.

## Debugging

When in doubt, you can use strace to see what files are being accessed by the binary. Ensure that the container is runing in "--privileged" mode to allow strace to work properly. strace does only work on Linux. It does not work on Docker Desktop for Windows/MacOS.

```
apt install -y strace
strace -f ./lcnpchk
```