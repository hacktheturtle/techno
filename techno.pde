#define PIN_PORT GPIOA
#define PIN_BIT 10
#define NUMPIXELS 24
#define PIN 8

int techno_delay = 100000;

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
  clear_pixels();
  for(int x=0; x<5; x++){
    set_pixel(random(24), random(0xffffff));
  }
  update_pixel_state();
  delay_us(techno_delay);
}


void set_pixel(int pixel, unsigned long color){
  pixel_state[pixel].color = color;
}

void clear_pixels(){
  for(int i=0; i<NUMPIXELS; i++){
    pixel_state[i].color = 0;
    pixel_state[i].target = 0;
    pixel_state[i].macro = NONE;
  }
  update_pixels();
}

/* Used to update pixel, do not call within 50uS of returning.
Needs blanking time.*/
void update_pixels(){
  systick_disable();
  noInterrupts();
  for(int i=0; i<24; i++){
    unsigned long color = pixel_state[i].color;
    for(int j=0; j<24; j++){
      if (color & (0x800000 >> j)) {
        gpio_write_bit(PIN_PORT, PIN_BIT, HIGH);
        gpio_write_bit(PIN_PORT, PIN_BIT, HIGH);
        gpio_write_bit(PIN_PORT, PIN_BIT, HIGH);
        gpio_write_bit(PIN_PORT, PIN_BIT, LOW);
        gpio_write_bit(PIN_PORT, PIN_BIT, LOW);
        gpio_write_bit(PIN_PORT, PIN_BIT, LOW);
      }else{
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

void update_pixel_state(){
  for(int i=0; i<24; i++){
    if(pixel_state[i].macro == FADE_TO){
      if(((pixel_state[i].color) & 0xff0000) < ((pixel_state[i].target) & 0xff0000)){
        pixel_state[i].color += 0x010000;
      }
      if(((pixel_state[i].color) & 0x00ff00) < ((pixel_state[i].target) & 0x00ff00)){
        pixel_state[i].color += 0x000100;
      }
      if(((pixel_state[i].color) & 0x0000ff) < ((pixel_state[i].target) & 0x0000ff)){
        pixel_state[i].color += 0x000001;
      }
      if(((pixel_state[i].color) & 0xff0000) > ((pixel_state[i].target) & 0xff0000)){
        pixel_state[i].color -= 0x010000;
      }
      if(((pixel_state[i].color) & 0x00ff00) > ((pixel_state[i].target) & 0x00ff00)){
        pixel_state[i].color -= 0x000100;
      }
      if(((pixel_state[i].color) & 0x0000ff) > ((pixel_state[i].target) & 0x0000ff)){
        pixel_state[i].color -= 0x000001;
      }
      if(pixel_state[i].color == pixel_state[i].target){
        pixel_state[i].macro = NONE;
      }
    }
  }
  update_pixels();
}

void setup(){
  pinMode(PIN, OUTPUT);
  clear_pixels();
}

void loop() {
  techno_turtle();
}
