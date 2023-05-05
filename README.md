# Template RPi-Pico-Project
This a pre-configured template project for building firmware for the rp2040
with a picoprobe as an swd programmer/debugger in vscode

## Installation
To get start simply run

```bash
scripts/pico_setup.sh
```

If you need the docs local then run
```bash
scripts/download_docs.sh
```

## Development
All your sources and pio files go into the src folder.
You need your source files to the CMakeLists.txt under `# Source Files` and PIO is registered under `# PIO Files`

Flashing is done with the `flash` cmake-task

The Debugger is already configured and can be started by pressing F5
(-> Shortcut for cmake-debug)