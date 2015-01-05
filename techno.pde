/*
  original commit is by Shaun Meehan. APRGL

  subsequent work is by Jesse Andrews - who hasn't written embedded code before...
  so please don't run this code blindedly
*/

#include <Servo.h>

#include "turtle.h"
#include "color.h"
#include "keys.h"

#define MIN_AGE 5000
#define AGE_MORE 5000

typedef struct {
    uint32 tail_loc; // where the tail is
    uint32 tail_ms;  // when the tail is available
} APPENDAGES;

APPENDAGES appendages;

typedef struct {
    uint32 birth_ms;
    uint32 lifespan_ms;
    HSL hsl;
    uint32 rgb;
} Firework;

Firework fires[NUMPIXELS];

int num_fires = 4;
int loop_delay_ms = 10;

uint32 the_color = 0x001010;

Servo tail;

void init_fire(int p, uint32 ts) {
    fires[p].hsl.saturation = 1.0;
    fires[p].hsl.hue = float(random(1000)) / 1000.0f;
    fires[p].hsl.lightness = 0.5;
    fires[p].birth_ms = ts;
    fires[p].lifespan_ms = MIN_AGE + random(AGE_MORE);
}

void update_fire(int p, uint32 ts) {

    // re-init any fires that are dead
    if (ts > fires[p].birth_ms + fires[p].lifespan_ms) {
        init_fire(p, ts);
    }

    // calculate the RGB value based on how old the fire is
    // for the first half of life it goes from 0% to 100%, then
    // it starts going from 100% back down to 0%.  linearly scale
    float scale = (float)(ts - fires[p].birth_ms) / (float)fires[p].lifespan_ms;

    if (scale < 0.5)
        scale = scale * 2.0;
    else
        scale = (1.0 - scale) * 2.0;

    fires[p].rgb = HSL2RGB(fires[p].hsl.hue, fires[p].hsl.saturation, fires[p].hsl.lightness*scale);
}

void turtle_fires(uint32 ts) {
    if (keys.blue_pressed) init_all_fires();
    if (keys.green_released) num_fires++;
    if (keys.amber_released) num_fires--;
    
    num_fires = constrain(num_fires, 1, 24);
        
    for (int p=0; p<num_fires; p++) {
        update_fire(p, ts);
    }
    
    draw_fires();
}

void draw_fires() {
    for (int i=0; i<NUMPIXELS; i++) {
        if (i < num_fires) {
            set_pixel(i, fires[i].rgb);
        } else {
            set_pixel(i, 0);
        }
    }
}

void tail_wiggle(uint32 ts) {
    if (ts < appendages.tail_ms)
        return;

    if (appendages.tail_loc == 80) {
        appendages.tail_loc = 140;
        appendages.tail_ms = ts + 140;
    }
    else {
        appendages.tail_loc = 80;
        appendages.tail_ms = ts + 100;
    }

    tail.write(appendages.tail_loc);
}

void setup(){
    setup_turtle_hw();
    setup_keys();
  
    tail.attach(7);
    init_all_fires();

    appendages.tail_loc = 0;
    appendages.tail_ms = 0;

    tail_wiggle(0);
}

void init_all_fires() {
    for (int p=0; p<NUMPIXELS; p++)
        init_fire(p, 0);
}

uint32 last_random_walk = 0;
int current_pixel = 0;

void turtle_random_walk(uint32 ts, boolean blank) {
    if (ts < last_random_walk + 50)
        return;
    
    int band = random(3);
    uint32 val = (the_color>>(8*band)) & 0xff;
    if (val == 0) {
        the_color += 1 << (8*band);
    }
    else if (val == 0x20) {
        the_color -= 1 << (8*band);
    }
    else if (random(2)) {
        the_color += 1 << (8*band);
    }
    else {
        the_color -= 1 << (8*band);
    }

    if (blank) {
        set_pixel((current_pixel+NUMPIXELS-1) % NUMPIXELS, 0);
        current_pixel = (current_pixel + 1) % NUMPIXELS;
    }
    else {
        current_pixel = random(NUMPIXELS);
    }
        
    set_pixel(current_pixel, the_color);
    last_random_walk = ts;
}    

int mode = 0;

void loop() {
    uint32 ts = millis();
    update_keys();

    if (keys.shell_down) {
        tail_wiggle(ts);
    }
    if (keys.shell_released) {
        mode = (mode + 1) % 3;
    }
    if (keys.amber_pressed) {
        SerialUSB.println("amber pressed!");
    }
    if (keys.shell_down && keys.green_down) {
        reset();
    }

    switch (mode) {
    case 0:
        turtle_fires(ts);
        break;
    case 1:
        turtle_random_walk(ts, false);
        break;
    case 2:
        turtle_random_walk(ts, true);
        break;
    }
    
    draw_pixels();
    delay(loop_delay_ms);
}
