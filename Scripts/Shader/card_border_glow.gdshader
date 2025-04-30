shader_type canvas_item;

// 是否启用顺子效果（绿色）
uniform bool is_straight = false;
// 是否启用同花效果（蓝色）
uniform bool is_flush = false;
// 边框宽度
uniform float border_width : hint_range(0.0, 0.1) = 0.03;
// 边框发光强度
uniform float glow_intensity : hint_range(0.0, 2.0) = 1.2;

void fragment() {
    // 获取纹理中的颜色
    vec4 texture_color = texture(TEXTURE, UV);

    // 计算到边缘的距离
    float dist_from_edge_x = min(UV.x, 1.0 - UV.x);
    float dist_from_edge_y = min(UV.y, 1.0 - UV.y);
    float dist_from_edge = min(dist_from_edge_x, dist_from_edge_y);

    // 确定边框区域
    bool is_border = dist_from_edge < border_width;

    // 如果在边框区域内
    if (is_border) {
        // 根据顺子和同花状态决定边框颜色
        vec3 border_color;

        if (is_straight && is_flush) {
            // 紫色 (红+蓝)
            border_color = vec3(0.7, 0.0, 1.0) * glow_intensity;
        } else if (is_straight) {
            // 绿色
            border_color = vec3(0.0, 1.0, 0.0) * glow_intensity;
        } else if (is_flush) {
            // 蓝色
            border_color = vec3(0.0, 0.5, 1.0) * glow_intensity;
        } else {
            // 默认无效果
            COLOR = texture_color;
            return;
        }

        // 边框渐变效果（从边缘向内部淡出）
        float edge_factor = 1.0 - dist_from_edge / border_width;
        edge_factor = pow(edge_factor, 2.0); // 使渐变更明显

        // 只在边框区域应用颜色，并保持原有的alpha通道
        vec4 border_effect = vec4(border_color * edge_factor, texture_color.a);

        // 如果原始纹理有颜色（不透明），则与边框效果混合
        if (texture_color.a > 0.0) {
            COLOR = texture_color + border_effect * (1.0 - texture_color.rgb);
        } else {
            // 如果是透明区域，只显示边框效果
            COLOR = border_effect;
        }
    } else {
        // 不在边框区域，使用原始纹理颜色
        COLOR = texture_color;
    }
}