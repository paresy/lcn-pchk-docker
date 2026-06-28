# LCN PCHK for Docker

This repo focuses on creating an ARM64 (aarch64) compatible container that can be run side by side with Symcon.
By using a wiringPi shim, the container is not dependend on a Raspberry Pi hardware platform.

## Usage (Simple)

```
docker run \
  --device=/dev/ttyUSB0 \
  --name lcnpchk \
  --publish 4114:4114 \
  --publish 4220:4220 \
  ghcr.io/paresy/lcn-pchk-docker:arm64
```

Use the Windows PCHK Monitor:
- Connect using "Computer in Network"
- Set the license (You need to buy one, if you have none!)
- Set the Port to **ttyUSB0**

**Username:** lcn  
**Password:** test123

## Usage (Advanced)

You can also use your own **lcnpchk.xml** if you already have one. Just bind the path directly into the container. In this example we assume the lcnpchk.xml is in the same path as you run the docker run command.

```
docker run \
  --name lcnpchk \
  --device=/dev/ttyUSB0 \
  --publish 4114:4114 \
  --publish 4220:4220 \
  --volume $(pwd)/lcnpchk.xml:/home/lcnpchk.xml \
  ghcr.io/paresy/lcn-pchk-docker:arm64
```

## Running on a Raspberry Pi 5
When using a Raspberry Pi 5 the Raspberry Pi OS uses a 16k PageSize instead of the default 4k PageSize. LCHK is not compatible with a 16k PageSize. Luckily we can revert Raspberry Pi OS in using a 4k PageSize even on the Raspberry Pi 5. Ask your favorite AI how to accomplish this.

## Debugging

When in doubt, you can use strace to see what files are being accessed by the binary. Ensure that the container is runing in "--privileged" mode to allow strace to work properly. strace does only work on Linux. It does not work on Docker Desktop for Windows/MacOS.

```
apt install -y strace
strace -f ./lcnpchk
```