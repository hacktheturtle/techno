#define PIN_PORT GPIOA
#define PIN_BIT 10
#define NUMPIXELS 24
#define PIN 8


int techno_delay = 200000;

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
unsigned long bands[NUMPIXELS];
int pixel_offset = 0;

void new_colors() {
  for (int x=0; x<NUMPIXELS; x++) {
    if (random(4) == 0) {
      bands[x] = random(0xffffff);
    } else {
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
  new_colors();
}

void loop() {
  techno_turtle();
}

