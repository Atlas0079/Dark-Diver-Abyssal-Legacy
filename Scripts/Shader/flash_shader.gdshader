shader_type canvas_item;

// 使用小写 uniform 名称，并保持正确的提示语法
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 1.0; // 模糊强度，可在检查器中调整

void fragment() {
    vec2 uv = SCREEN_UV; // SCREEN_UV 仍然有效，用于获取屏幕纹理坐标
    vec4 color = vec4(0.0);
    vec2 pixel_size = SCREEN_PIXEL_SIZE; // SCREEN_PIXEL_SIZE 仍然有效

    // 定义模糊核心的大小 (例如3x3)
    int kernel_size = 3;
    int half_kernel = kernel_size / 2;

    // 累加周围像素的颜色
    for (int i = -half_kernel; i <= half_kernel; i++) {
        for (int j = -half_kernel; j <= half_kernel; j++) {
            // 使用小写的 screen_texture uniform 进行纹理查找
            color += texture(screen_texture, uv + vec2(float(i), float(j)) * pixel_size * blur_amount);
        }
    }

    // 计算平均颜色
    color /= float(kernel_size * kernel_size);

    // 输出最终的模糊颜色
    COLOR = color;
}