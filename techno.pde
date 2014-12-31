/*
original commit is by Shaun Meehan. APRGL

subsequent work is by Jesse Andrews - who hasn't written embedded code before...
so please don't run this code blindedly

*/

#include <Servo.h>

#include "turtle.h"
#include "color.h"

#define MIN_AGE 5000
#define AGE_MORE 5000

// pressed means the button is down but last time it was up
// down means the button is down
// released means the button is up but last time it was down
typedef struct {
  boolean amber_down;
  boolean amber_pressed;
  boolean amber_released;
  boolean green_down;
  boolean green_pressed;
  boolean green_released;
  boolean blue_down;
  boolean blue_pressed;
  boolean blue_released;
  boolean shell_down;
  boolean shell_pressed;
  boolean shell_released;
}
KEYS;

typedef struct {
  uint32 tail_loc; // where the tail is
  uint32 tail_ms;  // when the tail is available
} APPENDAGES;

APPENDAGES appendages;
KEYS keys;

typedef struct {
  uint32 birth_ms;
  uint32 lifespan_ms;
  HSL hsl;
  uint32 rgb;
} Firework;

Firework fires[NUMPIXELS];

int num_fires = 4;
int loop_delay_ms = 10;

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

void techno_turtle(uint32 ts) {
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
  
  tail.attach(7);
  init_all_fires();

  appendages.tail_loc = 0;
  appendages.tail_ms = 0;

  tail_wiggle(0);

  keys.green_down = false;
  keys.amber_down = false;
  keys.blue_down = false;
  keys.shell_down = false;
}

void init_all_fires() {
  for (int p=0; p<NUMPIXELS; p++)
    init_fire(p, 0);
}

void update_keys() {
  boolean green = digitalRead(buttonGREEN) == HIGH;
  boolean blue = digitalRead(buttonBLUE) == HIGH;
  boolean amber = digitalRead(buttonAMBER) == HIGH;
  boolean shell = digitalRead(buttonSHELL) == HIGH;

  keys.green_pressed = green && !keys.green_down;
  keys.green_released = !green && keys.green_down;
  keys.green_down = green;

  keys.blue_pressed = blue && !keys.blue_down;
  keys.blue_released = !blue && keys.blue_down;
  keys.blue_down = blue;

  keys.amber_pressed = amber && !keys.amber_down;
  keys.amber_released = !amber && keys.amber_down;
  keys.amber_down = amber;

  keys.shell_pressed = shell && !keys.shell_down;
  keys.shell_released = !shell && keys.shell_down;
  keys.shell_down = shell;
}

void loop() {
  uint32 ts = millis();
  update_keys();

  if (keys.shell_down) tail_wiggle(ts);

  if (keys.blue_pressed) init_all_fires();
  if (keys.green_released) num_fires++;
  if (keys.amber_released) num_fires--;

  if (keys.amber_pressed) {
    SerialUSB.println("amber pressed!");
  }

  if (keys.shell_down && keys.green_down) {
    reset();
  }

  num_fires = constrain(num_fires, 1, 24);

  techno_turtle(ts);
  draw_pixels();

  delay(loop_delay_ms);
}
