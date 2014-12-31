#include "turtle.h";

// helper function to restart turtle allowing you to flash it
void reset() {
    *(SCB_AIRCR) = SCB_AIRCR_RESET;
}

// configure the hardware during setup
void setup_turtle_hw() {
    pinMode(buttonAMBER, INPUT_PULLDOWN);
    pinMode(buttonGREEN, INPUT_PULLDOWN);
    pinMode(buttonBLUE, INPUT_PULLDOWN);
    pinMode(buttonSHELL, INPUT_PULLDOWN);
    pinMode(PIN, OUTPUT);

    clear_pixels();
}


uint32 pixels[NUMPIXELS];
boolean pixels_dirty;

// reset framebuffer to black for all neopixels
void clear_pixels() {
    for (int i=0; i<NUMPIXELS; i++) {
        set_pixel(i, 0);
    }
    pixels_dirty = true;
}

// update pixel idx to a given color, if changed mark dirty
void set_pixel(int idx, uint32 color) {
    if (color != pixels[idx]) {
        pixels[idx] = color;
        pixels_dirty = true;
    }
}

/* Used to update pixel, do not call within 50uS of returning.
   Needs blanking time.*/
void draw_pixels() {
    if (!pixels_dirty) {
        return;
    }
    
    systick_disable();
    noInterrupts();
    for (int i=0; i<NUMPIXELS; i++){
        // write color bit by bit to the gpio
        for (uint32 mask=0x800000; mask; mask=mask>>1) {
            if (pixels[i] & mask) {
                gpio_write_bit(PIN_PORT, PIN_BIT, HIGH);
                gpio_write_bit(PIN_PORT, PIN_BIT, HIGH);
                gpio_write_bit(PIN_PORT, PIN_BIT, HIGH);
                gpio_write_bit(PIN_PORT, PIN_BIT, LOW);
                gpio_write_bit(PIN_PORT, PIN_BIT, LOW);
                gpio_write_bit(PIN_PORT, PIN_BIT, LOW);
            }
            else {
                gpio_write_bit(PIN_PORT, PIN_BIT, HIGH);
                gpio_write_bit(PIN_PORT, PIN_BIT, LOW);
                gpio_write_bit(PIN_PORT, PIN_BIT, LOW);
                gpio_write_bit(PIN_PORT, PIN_BIT, LOW);
                gpio_write_bit(PIN_PORT, PIN_BIT, LOW);
            }
        }
    }
    systick_enable();
    interrupts();
    
    pixels_dirty = false;
}
