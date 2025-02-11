shader_type spatial;
render_mode unshaded, blend_mix; // blend_mix 是关键

uniform sampler2D texture : hint_albedo; // 纹理
uniform float intensity : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    vec4 tex_color = texture(texture, UV); // 读取纹理颜色
    ALBEDO = tex_color.rgb * intensity; // 将强度应用到 RGB 通道
    ALPHA = tex_color.a; // 将纹理的 Alpha 通道赋值给输出的 Alpha
}