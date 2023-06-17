#!/usr/bin/bash
cd $1
rm -rf *.pdf*
wget https://datasheets.raspberrypi.com/rp2040/rp2040-datasheet.pdf
wget https://datasheets.raspberrypi.com/pico/pico-datasheet.pdf
wget https://datasheets.raspberrypi.com/pico/getting-started-with-pico.pdf
wget https://datasheets.raspberrypi.com/pico/raspberry-pi-pico-c-sdk.pdf
wget https://datasheets.raspberrypi.com/rp2040/hardware-design-with-rp2040.pdf