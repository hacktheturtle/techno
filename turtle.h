// tool to flash without hitting the reset button
// http://forums.leaflabs.com/topic.php?id=74283#post-105284
#define SCB_AIRCR ((volatile uint32*) (0xE000ED00 + 0x0C))
#define SCB_AIRCR_SYSRESETREQ (1 << 2)
#define SCB_AIRCR_RESET ((0x05FA0000) | SCB_AIRCR_SYSRESETREQ)

#define buttonAMBER 12
#define buttonGREEN 13
#define buttonBLUE 14
#define buttonSHELL 4

#define PIN_PORT GPIOA
#define PIN_BIT 10
#define NUMPIXELS 24
#define PIN 8

void reset();
void setup_turtle_hw();

void clear_pixels();
void draw_pixels();
void set_pixel(int idx, uint32 color);
