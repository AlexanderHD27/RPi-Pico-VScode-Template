#!/bin/bash

# Where will the output go?
OUTDIR="$(pwd)/pico"

echo -e "${YELLOW}Creating Enviroment file${NC}"
ENV_FILE="${HOME}/.bashrc"

# Number of cores when running make
JNUM=8

# Config
SKIP_OPENOCD=0
SKIP_VSCODE=0
SKIP_EXAMPLES=1
REBUILD=1

# Colors
NC='\033[0m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'

# Nuke the pico folder
if [[ "$REBUILD" == 1 ]]; then
    echo -e "${YELLOW}Removed everything from ${OUTDIR}"
    rm -rf ${OUTDIR}/*
fi

# Exit on error
set -e

# Adding permissions
sudo usermod -aG dialout $USER
sudo usermod -aG plugdev $USER

# Checking Platform
if grep -q Raspberry /proc/cpuinfo; then
    echo -e "${YELLOW}Running on a Raspberry Pi${NC}"
    RPI=1
else
    echo -e "${YELLOW}Not running on a Raspberry Pi. Use at your own risk!${NC}"
    RPI=0
fi

# Install dependencies
GIT_DEPS="git"
SDK_DEPS="cmake gcc-arm-none-eabi gcc g++"
OPENOCD_DEPS="gdb-multiarch automake autoconf build-essential texinfo libtool libftdi-dev libusb-1.0-0-dev"
VSCODE_DEPS="code"
UART_DEPS="minicom"
MISC_DEPS="wget"

# Build full list of dependencies
DEPS="$GIT_DEPS $SDK_DEPS $MISC_DEPS"

if [[ "$SKIP_OPENOCD" == 1 ]]; then
    echo -e "${YELLOW}Skipping OpenOCD (debug support)${NC}"
else
    DEPS="$DEPS $OPENOCD_DEPS"
fi

echo -e "${YELLOW}Installing Dependencies${NC}"
sudo apt update
sudo apt install -y $DEPS

echo -e "${YELLOW}Creating $OUTDIR${NC}"
# Create pico directory to put everything in
mkdir -p $OUTDIR
cd $OUTDIR

# Clone sw repos
GITHUB_PREFIX="https://github.com/raspberrypi/"
GITHUB_SUFFIX=".git"
SDK_BRANCH="master"

for REPO in sdk extras playground
do
    if [[REPO == "example"] && [ "$SKIP_EXAMPLES" == 1 ]]; then
        echo -e "${YELLOW}Skipping $DEST${NC}"
        continue
    fi

    DEST="$OUTDIR/pico-$REPO"

    if [ -d $DEST ]; then
        echo -e "${YELLOW}$DEST already exists so skipping${NC}"
    else
        REPO_URL="${GITHUB_PREFIX}pico-${REPO}${GITHUB_SUFFIX}"
        echo -e "${YELLOW}Cloning $REPO_URL${NC}"
        git clone -b $SDK_BRANCH $REPO_URL

        # Any submodules
        cd $DEST
        git submodule update --init
        cd $OUTDIR

        # Define PICO_SDK_PATH in env-file
        VARNAME="PICO_${REPO^^}_PATH"
        echo -e "${YELLOW}Adding $VARNAME to $ENV_FILE${NC}"
        echo "export $VARNAME=$DEST" >> $ENV_FILE
        export ${VARNAME}=$DEST
    fi
done


cd $OUTDIR

# Pick up new variables we just defined
source ~/.bashrc
source $ENV_FILE

# Cloning & Build a couple of examples
if [[ "$SKIP_EXAMPLES" == 0 ]]; then    
    cd "$OUTDIR/pico-examples"
    mkdir build
    cd build
    cmake ../ -DCMAKE_BUILD_TYPE=Debug

    for e in blink hello_world
    do
        echo -e "${YELLOW}Building $e${NC}"
        cd $e
        make -j$JNUM
        cd ..
    done

    cd $OUTDIR
else
    echo -e "${YELLOW}Skipping Examples${NC}"
fi

# Picoprobe and picotool
for REPO in picoprobe picotool
do
    DEST="$OUTDIR/$REPO"
    REPO_URL="${GITHUB_PREFIX}${REPO}${GITHUB_SUFFIX}"
    git clone $REPO_URL

    # Build both
    cd $DEST
    git submodule update --init
    mkdir build
    cd build
    cmake ../
    make -j$JNUM

    if [[ "$REPO" == "picotool" ]]; then
        echo -e "${YELLOW}Installing picotool to /usr/local/bin/picotool${NC}"
        sudo cp picotool /usr/local/bin/
    fi

    cd $OUTDIR
done

# Openocd
if [ -d openocd ]; then
    echo "openocd already exists so skipping"
    SKIP_OPENOCD=1
fi

if [[ "$SKIP_OPENOCD" == 1 ]]; then
    echo -e "${YELLOW}Won't build OpenOCD${NC}"
else
    # Build OpenOCD
    echo -e "${YELLOW}Building OpenOCD${NC}"
    cd $OUTDIR
    # Should we include picoprobe support (which is a Pico acting as a debugger for another Pico)
    INCLUDE_PICOPROBE=1
    OPENOCD_BRANCH="rp2040"
    OPENOCD_CONFIGURE_ARGS="--enable-ftdi --enable-sysfsgpio --enable-bcm2835gpio"
    if [[ "$INCLUDE_PICOPROBE" == 1 ]]; then
        OPENOCD_CONFIGURE_ARGS="$OPENOCD_CONFIGURE_ARGS --enable-picoprobe"
    fi

    git clone "${GITHUB_PREFIX}openocd${GITHUB_SUFFIX}" -b $OPENOCD_BRANCH --depth=1
    cd openocd
    ./bootstrap
    ./configure $OPENOCD_CONFIGURE_ARGS
    make -j$JNUM
    sudo make install
fi

cd $OUTDIR

if [[ "$SKIP_VSCODE" == 1 ]]; then
    echo "${YELLOW}Skipping VSCODE${NC}"
else
    echo "${YELLOW}Installing VSCODE${NC}"
    sudo apt install -y $VSCODE_DEPS

    # Get extensions
    code --install-extension marus25.cortex-debug
    code --install-extension ms-vscode.cmake-tools
    code --install-extension ms-vscode.cpptools
fi

# Enable UART
if [[ "$SKIP_UART" == 1 ]]; then
    echo -e "${YELLOW}Skipping uart configuration${NC}"
else
    sudo apt install -y $UART_DEPS
    
    if [[ "$RPI" == 1 ]]; then
        echo -e "${YELLOW}Disabling Linux serial console (UART) so we can use it for pico${NC}"
        sudo raspi-config nonint do_serial 2
        echo -e "${YELLOW}You must run sudo reboot to finish UART setup${NC}"
    fi
fi
