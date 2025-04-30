shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool glow_enabled = false;
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.5;
uniform float glow_size : hint_range(0.0, 20.0) = 10.0;
uniform float border_threshold : hint_range(0.0, 1.0) = 0.4;

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    
    // 获取原始颜色
    vec4 final_color = texture_color;
    
    // 如果发光启用
    if (glow_enabled) {
        // 检测边缘：计算当前像素与周围8个方向的距离
        float alpha = texture_color.a;
        float outline = 0.0;
        
        // 检查周围像素的alpha值，来确定我们是否在边缘
        vec2 size = vec2(1.0) / vec2(textureSize(TEXTURE, 0));
        float a = texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
        float b = texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
        float c = texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
        float d = texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
        float e = texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
        float f = texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
        float g = texture(TEXTURE, UV + vec2(0.0, size.y)).a;
        float h = texture(TEXTURE, UV + vec2(size.x, size.y)).a;
        
        // 如果当前像素有不透明度，但周围至少有一个像素是透明的，则我们在边缘
        if (alpha > 0.0 && (a < alpha || b < alpha || c < alpha || d < alpha || e < alpha || f < alpha || g < alpha || h < alpha)) {
            outline = 1.0;
        }
        
        // 如果我们在边缘附近，添加发光效果
        if (outline > 0.0 || (alpha < border_threshold && alpha > 0.0)) {
            // 应用发光的颜色和强度
            final_color = mix(final_color, glow_color, glow_intensity * (1.0 - alpha));
            
            // 扩散发光
            for (float i = 1.0; i <= glow_size; i += 1.0) {
                float percent = 1.0 - (i / glow_size);
                percent = pow(percent, 2.0);
                
                for (float x = -i; x <= i; x += i) {
                    for (float y = -i; y <= i; y += i) {
                        if (x == 0.0 && y == 0.0) continue;
                        
                        vec2 offset = vec2(x, y) * size;
                        float sample_alpha = texture(TEXTURE, UV + offset).a;
                        
                        if (sample_alpha > 0.0 && alpha == 0.0) {
                            final_color = mix(final_color, glow_color, percent * glow_intensity);
                        }
                    }
                }
            }
        }
    }
    
    COLOR = final_color;
} 