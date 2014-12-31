typedef struct {
    float hue;
    float saturation;
    float lightness;
} HSL;

uint32 HSL2RGB(float hue, float saturation, float lightness);
uint32 HueToRgb(float p, float q, float t);
