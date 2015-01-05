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

void setup_keys() {
    keys.green_down = false;
    keys.amber_down = false;
    keys.blue_down = false;
    keys.shell_down = false;
}
