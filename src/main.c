#include <stdio.h>
#include "pico/stdlib.h"
#include "hardware/pio.h"

#include "blink.pio.h"

static inline void blink_program_init(PIO pio, uint sm, uint offset, uint pin) {
    pio_sm_config c = blink_program_get_default_config(offset);

    sm_config_set_out_pins(&c, pin, 1);
    pio_gpio_init(pio, pin);
    pio_sm_set_consecutive_pindirs(pio, sm, pin, 1, true);
    pio_sm_init(pio, sm, offset, &c);
    pio_sm_set_enabled(pio, sm, true);
}

int main() {
    stdio_init_all();
    printf("Hello world, from your RPi-Pico!\n");

    PIO pio = pio0;
    uint offset = pio_add_program(pio, &blink_program);
    uint sm = pio_claim_unused_sm(pio, true);
    blink_program_init(pio, sm, offset, PICO_DEFAULT_LED_PIN);

    while (true) {
        pio_sm_put_blocking(pio, sm, 1);
        sleep_ms(500);
        pio_sm_put_blocking(pio, sm, 0);
        sleep_ms(500);
    }
}