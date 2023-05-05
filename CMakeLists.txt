cmake_minimum_required(VERSION 3.12)

# Pull in SDK (must be before project)
include($ENV{PICO_SDK_PATH}/pico_sdk_init.cmake)
include($ENV{PICO_SDK_PATH}/pico_sdk_version.cmake)

project(blink C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

if (PICO_SDK_VERSION_STRING VERSION_LESS "1.3.0")
    message(FATAL_ERROR "Raspberry Pi Pico SDK version 1.3.0 (or later) required. Your version is ${PICO_SDK_VERSION_STRING}")
endif()

add_compile_options(-Wall
        -Wno-format          # int != int32_t as far as the compiler is concerned because gcc has int32_t as long int
        -Wno-unused-function # we have some for the docs that aren't called
        -Wno-maybe-uninitialized
)

# Initialize the SDK
pico_sdk_init()

# Source Files
add_executable(${CMAKE_PROJECT_NAME}
        src/main.c
        )

# PIO Files
pico_generate_pio_header(${CMAKE_PROJECT_NAME} ${CMAKE_CURRENT_LIST_DIR}/src/blink.pio)

# pull in common dependencies
target_link_libraries(${CMAKE_PROJECT_NAME} pico_stdlib hardware_pio)

# create map/bin/hex file etc.
pico_add_extra_outputs(${CMAKE_PROJECT_NAME})

# USB/UART Settings
pico_enable_stdio_usb(${CMAKE_PROJECT_NAME} 0)
pico_enable_stdio_uart(${CMAKE_PROJECT_NAME} 1)

# Flash Target
add_custom_target(flash 
        DEPENDS "blink" "ELF2UF2Build"
        COMMAND bash -c "${PROJECT_SOURCE_DIR}/scripts/flash.sh ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.elf"
)

# Download Docs Target
add_custom_target(download_docs
        COMMAND bash -c "${PROJECT_SOURCE_DIR}/scripts/download_docs.sh ${PROJECT_SOURCE_DIR}/docs"
)
