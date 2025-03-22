shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1, 1, 1, 1);
uniform float outline_width : hint_range(0, 10) = 1.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    vec2 ps = TEXTURE_PIXEL_SIZE;
    
    float a;
    float maxa = col.a;
    
    for(float x = -outline_width; x <= outline_width; x++) {
        for(float y = -outline_width; y <= outline_width; y++) {
            vec2 offset = vec2(x, y) * ps;
            a = texture(TEXTURE, UV + offset).a;
            maxa = max(a, maxa);
        }
    }
    
    vec4 final_color = mix(outline_color, col, col.a);
    COLOR = mix(vec4(0.0), final_color, maxa);
}