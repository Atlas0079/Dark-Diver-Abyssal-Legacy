shader_type canvas_item;
render_mode unshaded;

uniform float blur_amount : hint_range(0, 5) = 5;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec4 color = vec4(0.0);
    float blur = blur_amount;
    
    // 多次采样以创建模糊效果
    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-blur, -blur) * SCREEN_PIXEL_SIZE) * 0.0625;
    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-blur, 0.0) * SCREEN_PIXEL_SIZE) * 0.125;
    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-blur, blur) * SCREEN_PIXEL_SIZE) * 0.0625;
    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, -blur) * SCREEN_PIXEL_SIZE) * 0.125;
    color += texture(SCREEN_TEXTURE, SCREEN_UV) * 0.25;
    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, blur) * SCREEN_PIXEL_SIZE) * 0.125;
    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(blur, -blur) * SCREEN_PIXEL_SIZE) * 0.0625;
    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(blur, 0.0) * SCREEN_PIXEL_SIZE) * 0.125;
    color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(blur, blur) * SCREEN_PIXEL_SIZE) * 0.0625;
    
    // 添加半透明黑色覆盖，增强毛玻璃效果
    color = mix(color, vec4(0, 0, 0, 0.3), 0.3);
    
    COLOR = color;
} 