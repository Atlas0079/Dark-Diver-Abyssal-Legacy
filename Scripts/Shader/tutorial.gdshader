shader_type canvas_item;

// 显式声明屏幕纹理 uniform，并使用 filter_linear_mipmap 以获得更平滑的模糊效果
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
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
            // 使用我们显式声明的 SCREEN_TEXTURE uniform 进行纹理查找
            color += texture(SCREEN_TEXTURE, uv + vec2(float(i), float(j)) * pixel_size * blur_amount);
        }
    }

    // 计算平均颜色
    color /= float(kernel_size * kernel_size);

    // 输出最终的模糊颜色
    COLOR = color;
}