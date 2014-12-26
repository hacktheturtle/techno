#define PIN_PORT GPIOA
#define PIN_BIT 10
#define NUMPIXELS 24
#define PIN 8

int techno_delay = 1000000;

enum pixel_macro{
  NONE      = 0,
  FADE_TO   = 1,
  FADE_OUT  = 2
};

typedef struct {
  unsigned long color;
  unsigned long target;
  pixel_macro macro;
} NeoPixel;

NeoPixel pixel_state[NUMPIXELS];

void techno_turtle(){
  for (int x=0; x<24; x++) {
    if (random(3) == 0) {
      pixel_state[x].color = random(0xffffff);
    } else {
      pixel_state[x].color = 0;
    }
  }
  update_pixels();
  delay_us(techno_delay);
}

/* Used to update pixel, do not call within 50uS of returning.
 Needs blanking time.*/
void update_pixels(){
  systick_disable();
  noInterrupts();
  for(int i=0; i<24; i++){
    unsigned long color = pixel_state[i].color;
    for(int j=0; j<24; j++){
      if(color & (0x800000 >> j)){
        gpio_write_bit(PIN_PORT, PIN_BIT, HIGH);
        gpio_write_bit(PIN_PORT, PIN_BIT, HIGH);
        gpio_write_bit(PIN_PORT, PIN_BIT, HIGH);
        gpio_write_bit(PIN_PORT, PIN_BIT, LOW);
        gpio_write_bit(PIN_PORT, PIN_BIT, LOW);
        gpio_write_bit(PIN_PORT, PIN_BIT, LOW);
      } else {
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

void setup(){
  pinMode(PIN, OUTPUT);
}

void loop() {
  techno_turtle();
}

