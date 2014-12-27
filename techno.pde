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

#define buttonA 12
#define buttonB 13
#define buttonC 14
#define buttonD 4

enum pixel_macro {
  NONE      = 0,
  FADE_TO   = 1,
  FADE_OUT  = 2
};

typedef struct {
  unsigned long color;
  unsigned long target;
  pixel_macro macro;
} 
NeoPixel;

NeoPixel pixel_state[NUMPIXELS];
unsigned long bands[NUMPIXELS];
int pixel_offset = 0;
unsigned long techno_delay = 200;
uint32 last_techno = 0;
int loop_delay_ms = 1;

Servo tail;

void new_colors() {
  for (int x=0; x<NUMPIXELS; x++) {
    if (x == 0) {
      bands[x] = random(0xffffff);
    } 
    else {
      bands[x] = 0;
    }
  }
}

void techno_turtle() {
  pixel_offset = (pixel_offset + 1) % NUMPIXELS;

  for (int x=0; x<NUMPIXELS; x++) {
    pixel_state[x].color = bands[(x + pixel_offset) % NUMPIXELS];
  }
  update_pixels();
}

/* Used to update pixel, do not call within 50uS of returning.
 Needs blanking time.*/
void update_pixels(){
  systick_disable();
  noInterrupts();
  for (int i=0; i<NUMPIXELS; i++){
    unsigned long color = pixel_state[i].color;
    // write color bit by bit to the gpio
    for (int j=0; j<24; j++) {
      if (color & (0x800000 >> j)) {
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
  tail.write(80);
  delay(100);
  tail.write(140);
  delay(140);
}

void setup(){
  pinMode(PIN, OUTPUT);
  pinMode(buttonA, INPUT_PULLDOWN);
  pinMode(buttonB, INPUT_PULLDOWN);
  pinMode(buttonC, INPUT_PULLDOWN);
  pinMode(buttonD, INPUT_PULLDOWN);

  new_colors();
  last_techno = 0;
  
  tail.attach(7);
  tail_wiggle();
}

void loop() {
  if (digitalRead(buttonA) == HIGH && techno_delay > 10) {
    techno_delay -= 1;
  }
  if (digitalRead(buttonB) == HIGH) {
    tail_wiggle();
  }
  if (digitalRead(buttonC) == HIGH && techno_delay < 10000) {
    techno_delay += 1;
  }
  if (digitalRead(buttonD) == HIGH) {
    new_colors();
  }

  if (millis() - last_techno > techno_delay) {
    techno_turtle();
    last_techno = millis();
  }

  delay(loop_delay_ms);
}

