/*
original commit is by Shaun Meehan. APRGL

subsequent work is by Jesse Andrews - who hasn't written embedded code before...
so please don't run this code blindedly

*/

#include <Servo.h>

// tool to flash without hitting the reset button
// http://forums.leaflabs.com/topic.php?id=74283#post-105284
#define SCB_AIRCR ((volatile uint32*) (0xE000ED00 + 0x0C))
#define SCB_AIRCR_SYSRESETREQ (1 << 2)
#define SCB_AIRCR_RESET ((0x05FA0000) | SCB_AIRCR_SYSRESETREQ)

#define PIN_PORT GPIOA
#define PIN_BIT 10
#define NUMPIXELS 24
#define PIN 8

#define buttonAMBER 12
#define buttonGREEN 13
#define buttonBLUE 14
#define buttonSHELL 4

#define MIN_AGE 5000
#define AGE_MORE 5000

typedef struct {
  float hue;
  float saturation;
  float lightness;
}
HSL;

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
}
APPENDAGES;

APPENDAGES appendages;
KEYS keys;

typedef struct {
  uint32 birth_ms;
  uint32 lifespan_ms;
  HSL hsl;
  uint32 rgb;
}
Firework;

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

/* Used to update pixel, do not call within 50uS of returning.
 Needs blanking time.*/
void draw_fires() {
  uint32 color;

  systick_disable();
  noInterrupts();
  for (int i=0; i<NUMPIXELS; i++){
    if (i < num_fires)
      color = fires[i].rgb;
    else
      color = 0;

    // write color bit by bit to the gpio
    for (uint32 mask=0x800000; mask; mask=mask>>1) {
      if (color & mask) {
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
  pinMode(PIN, OUTPUT);
  pinMode(buttonAMBER, INPUT_PULLDOWN);
  pinMode(buttonGREEN, INPUT_PULLDOWN);
  pinMode(buttonBLUE, INPUT_PULLDOWN);
  pinMode(buttonSHELL, INPUT_PULLDOWN);

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
    *(SCB_AIRCR) = SCB_AIRCR_RESET;
  }

  num_fires = constrain(num_fires, 1, 24);

  techno_turtle(ts);

  delay(loop_delay_ms);
}

// convert HSL color to a RGB
uint32 HSL2RGB(float hue, float saturation, float lightness) {
  uint32 r, g, b;
  float q, p;

  if (saturation == 0.0f)
    r = g = b = uint32(lightness * 255.0f);
  else {
    if (lightness < 0.5f)
      q = lightness * (1.0f + saturation);
    else
      q = lightness + saturation - (lightness * saturation);
    p = 2.0f * lightness - q;
    r = HueToRgb(p, q, hue + 1.0f / 3.0f);
    g = HueToRgb(p, q, hue);
    b = HueToRgb(p, q, hue - 1.0f / 3.0f);
  }

  return (r << 16) + (g << 8) + b;
}

uint32 HueToRgb(float p, float q, float t) {
  if (t < 0.0f) t += 1.0f;
  if (t > 1.0f) t -= 1.0f;
  if (t < 1.0f / 6.0f) return uint32((p + (q - p) * 6.0f * t) * 255.0f);
  if (t < 1.0f / 2.0f) return uint32(q);
  if (t < 2.0f / 3.0f) return uint32((p + (q - p) * (2.0f / 3.0f - t) * 6.0f) * 255.0f);
  return uint32(p * 255.0f);
}
