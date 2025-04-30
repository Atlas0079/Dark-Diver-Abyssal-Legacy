import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter
import math

def create_halo_asset(
    size=256,           # 图像尺寸 (正方形)
    ring_radius=80,     # 光环中心半径
    ring_thickness=20,  # 光环基础厚度
    glow_sigma=15,      # 辉光模糊程度 (值越大越模糊)
    color=(255, 220, 50), # 光环颜色 (RGB)
    max_alpha=180       # 最大不透明度 (0-255, <255 实现半透明)
    ):
    """
    生成一个半透明的光环辉光游戏素材。

    Args:
        size (int): 输出图像的边长（像素）。
        ring_radius (int): 光环中心到图像中心的距离（像素）。
        ring_thickness (int): 光环的初始线条宽度（像素）。
        glow_sigma (float): 高斯模糊的标准差，控制辉光扩散程度。
        color (tuple): 光环的 RGB 颜色 (0-255)。
        max_alpha (int): 光环最亮部分的最大 Alpha 值 (0-255)。

    Returns:
        PIL.Image.Image: 生成的带有半透明光环的 PIL 图像对象。
    """
    if max_alpha < 0 or max_alpha > 255:
        raise ValueError("max_alpha 必须在 0 到 255 之间")

    # 1. 创建 Alpha 通道画布 (用浮点数进行计算更精确)
    alpha_channel = np.zeros((size, size), dtype=np.float64)
    center = size / 2

    # 计算每个像素到中心的距离
    y, x = np.ogrid[:size, :size]
    dist_from_center = np.sqrt((x - center)**2 + (y - center)**2)

    # 2. 绘制光环形状 (设置初始 Alpha)
    # 定义环的内、外半径
    inner_radius = ring_radius - ring_thickness / 2
    outer_radius = ring_radius + ring_thickness / 2

    # 创建一个环形区域的掩码
    ring_mask = (dist_from_center >= inner_radius) & (dist_from_center <= outer_radius)

    # 在环形区域应用最大 Alpha 值
    alpha_channel[ring_mask] = max_alpha

    # ----- 可选：添加一个平滑的内边缘衰减 (让环内侧更柔和) -----
    # fade_width = ring_thickness * 0.5 # 内侧衰减宽度
    # inner_fade_mask = (dist_from_center >= inner_radius - fade_width) & (dist_from_center < inner_radius)
    # if np.any(inner_fade_mask):
    #     fade_factor = (dist_from_center[inner_fade_mask] - (inner_radius - fade_width)) / fade_width
    #     alpha_channel[inner_fade_mask] = max_alpha * fade_factor * fade_factor # 平方衰减

    # 3. 应用高斯模糊产生辉光效果
    # sigma 值控制模糊/辉光的范围
    blurred_alpha = gaussian_filter(alpha_channel, sigma=glow_sigma)

    # 4. 归一化和调整 Alpha
    # 模糊会降低峰值，如果希望最亮处接近 max_alpha，可以重新缩放
    max_blurred = np.max(blurred_alpha)
    if max_blurred > 0:
        # 重新缩放，使模糊后的最大值再次接近 max_alpha
        # 注意：如果模糊范围很大，这可能导致中心区域比原始 max_alpha 更亮一点点
        # 可以选择性地裁剪回 max_alpha
        blurred_alpha = (blurred_alpha / max_blurred) * max_alpha

    # 确保 Alpha 值在 0-255 范围内，并转换为整数类型
    blurred_alpha = np.clip(blurred_alpha, 0, 255).astype(np.uint8)

    # 5. 创建最终的 RGBA 图像
    # 创建一个全黑的 RGBA 图像数组
    image_array = np.zeros((size, size, 4), dtype=np.uint8)

    # 将颜色应用到 RGB 通道
    image_array[..., 0] = color[0]
    image_array[..., 1] = color[1]
    image_array[..., 2] = color[2]

    # 将计算好的辉光 Alpha 应用到 Alpha 通道
    image_array[..., 3] = blurred_alpha

    # 6. 从 NumPy 数组创建 PIL 图像对象
    halo_image = Image.fromarray(image_array, 'RGBA')

    return halo_image

# --- 使用示例 ---
if __name__ == "__main__":
    # --- 自定义参数 ---
    image_size = 512        # 画布大小
    halo_radius = 150       # 光环半径
    halo_thickness = 30     # 光环基础厚度
    glow_amount = 15        # 辉光强度/模糊度
    halo_color = (92, 179, 56)
    opacity = 190           # 最大不透明度 (0-255, <255 为半透明)

    # 生成光环图像
    generated_halo = create_halo_asset(
        size=image_size,
        ring_radius=halo_radius,
        ring_thickness=halo_thickness,
        glow_sigma=glow_amount,
        color=halo_color,
        max_alpha=opacity
    )

    # 保存图像
    output_filename = "semi_transparent_halo.png"
    generated_halo.save(output_filename)

    print(f"光环图像已保存为: {output_filename}")

    # (可选) 显示图像预览
    try:
        generated_halo.show()
    except Exception as e:
        print(f"无法显示图像预览: {e}")
        print("请在文件浏览器中查看生成的 PNG 文件。")