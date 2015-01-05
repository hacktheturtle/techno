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
    if (t < 1.0f / 6.0f)
        return uint32((p + (q - p) * 6.0f * t) * 255.0f);
    if (t < 1.0f / 2.0f)
        return uint32(q);
    if (t < 2.0f / 3.0f)
        return uint32((p + (q - p) * (2.0f / 3.0f - t) * 6.0f) * 255.0f);
    return uint32(p * 255.0f);
}
