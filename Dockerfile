FROM arm64v8/debian:bookworm

# This is the default port that the lcnpchk service listens on for incoming connections
EXPOSE 4114

# This is the management port that the lcnpchk service listens on for incoming connections
EXPOSE 4220

WORKDIR /home

# We need to set the licensee and licensekey on every start as lcnpchk encrypts it on each start
ENV LICENSEE=""
ENV LICENSEKEY=""

# We need armhf libraries to run the lcnpchk binary, as it is compiled for the armhf architecture
RUN dpkg --add-architecture armhf

# Install all dependencies for lcnpchk
RUN apt update &&\
    apt install -y \
      wget \
      procps \
      xmlstarlet \
      libc6:armhf \
      libstdc++6:armhf \
      libcrypt1:armhf

# On a Raspberry Pi, you can install WiringPi with the following command
# But we want to make the PCHK work everywhere wihout Raspberry Pi specific dependencies
# RUN wget https://github.com/WiringPi/WiringPi/releases/download/3.2/wiringpi_3.2-bullseye_armhf.deb
# RUN dpkg -i wiringpi_3.2-bullseye_armhf.deb

# We need to build a shared library that implements the WiringPi functions that lcnpchk uses
ADD wiringPi.c /home/wiringPi.c

# We need to install the armhf cross compiler and build the shared library for armhf
# Afterwards, we can remove the cross compiler to keep the image small
RUN apt install -y gcc-arm-linux-gnueabihf libc6-dev-armhf-cross &&\
    arm-linux-gnueabihf-gcc -shared -fPIC -o /usr/lib/libwiringPi.so /home/wiringPi.c -ldl &&\
    apt purge -y gcc-arm-linux-gnueabihf libc6-dev-armhf-cross

# Download PCHK from the official website and extract it
RUN cd /home/ &&\
    wget -O lcnpchk.tar.gz https://www.lcn.eu/en/?wpdmdl=8088 &&\
    tar xzf lcnpchk.tar.gz &&\
    rm lcnpchk.tar.gz

# Initially we want to change the Windows default fron COM1 to ttyUSB0, as this is the default on Linux systems
RUN xmlstarlet ed -L \
      -u "/LcnPchkConfiguration/Communication/LCNPort" \
      -v "ttyUSB0" \
      lcnpchk.xml

# We need to add an entrypoint script that will start the lcnpchk service and set the licensee and licensekey
ADD entrypoint.sh /home/entrypoint.sh
RUN chmod +x /home/entrypoint.sh

# Run our entrypoint script that will start the lcnpchk service
ENTRYPOINT ["/home/entrypoint.sh"]