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
} KEYS;

KEYS keys;

void update_keys();
void setup_keys();
