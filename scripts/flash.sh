#!/usr/bin/bash
openocd \
    -f interface/cmsis-dap.cfg \
    -c "adapter speed 5000" \
    -f target/rp2040.cfg \
    -s tcl \
    -c "program $1 verify reset exit"