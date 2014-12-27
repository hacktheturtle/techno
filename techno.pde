/*
original commit is by Shaun Meehan. APRGL
 
 subsequent work is by Jesse Andrews - who hasn't written embedded code before...
 so please don't run this code blindedly
 
 */

#include <Servo.h>

#define PIN_PORT GPIOA
#define PIN_BIT 10
#define NUMPIXELS 24
#define PIN 8

#define buttonAMBER 12
#define buttonGREEN 13
#define buttonBLUE 14
#define buttonSHELL 4

#define MIN_AGE 2500
#define AGE_MORE 2500

typedef struct {
  float hue;
  float saturation;
  float lightness;
} 
HSL;

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
  float scale;

  systick_disable();
  noInterrupts();
  for (int i=0; i<NUMPIXELS; i++){
    if (i < num_fires) {
      color = fires[i].rgb;
    } 
    else {
      color = 0;
    }

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

void tail_wiggle() {
  // FIXME(ja): delays break the loop logic...
  tail.write(80);
  delay(100);
  tail.write(140);
  delay(140);
}

void setup(){
  pinMode(PIN, OUTPUT);
  pinMode(buttonAMBER, INPUT_PULLDOWN);
  pinMode(buttonGREEN, INPUT_PULLDOWN);
  pinMode(buttonBLUE, INPUT_PULLDOWN);
  pinMode(buttonSHELL, INPUT_PULLDOWN);

  tail.attach(7);
  for (int p=0; p<NUMPIXELS; p++) {
    init_fire(p, 0);
  }
  tail_wiggle();
}

void loop() {
  uint32 ts = millis();

  if (digitalRead(buttonSHELL) == HIGH) {
    tail_wiggle();
  }

  if (digitalRead(buttonBLUE) == HIGH) {
    for (int p=0; p<NUMPIXELS; p++) {
      init_fire(p, ts);
    }
  }

  if (digitalRead(buttonAMBER) == HIGH) {
    while (digitalRead(buttonAMBER) == HIGH) delay(10); // FIXME(ja): delay breaks loop logic
    num_fires = constrain(num_fires+1, 1, 24);
  }
  if (digitalRead(buttonGREEN) == HIGH) {
    while (digitalRead(buttonGREEN) == HIGH) delay(10); // FIXME(ja): delay breaks loop logic
    num_fires = constrain(num_fires-1, 1, 24);
  }

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



