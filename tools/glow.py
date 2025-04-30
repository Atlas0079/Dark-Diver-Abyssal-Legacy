import numpy as np
from PIL import Image
from scipy.ndimage import distance_transform_edt
import os

def create_glow_map_with_padding(input_path, output_path, glow_distance=30, glow_intensity_factor=1.0, padding_safety_margin=10):
    """
    为输入的圆角矩形PNG生成辉光贴图（RGBA格式），辉光强度存储在Alpha通道。
    自动扩展画布以容纳辉光，并将内部区域设为透明。

    Args:
        input_path (str): 输入的圆角矩形PNG文件路径。
        output_path (str): 输出的辉光贴图RGBA PNG文件路径。
        glow_distance (float): 辉光向外延伸的最大距离（像素）。
        glow_intensity_factor (float): 辉光整体亮度调整因子。
        padding_safety_margin (int): 额外边距。
    """
    # --- 1. 加载原始图片 ---
    if not os.path.exists(input_path):
        print(f"错误：输入文件不存在！ {input_path}")
        return
    try:
        img_orig = Image.open(input_path).convert("RGBA")
        w_orig, h_orig = img_orig.size
    except Exception as e:
        print(f"错误：无法打开或处理图像 {input_path}。错误信息：{e}")
        return

    # --- 2. 计算扩展画布尺寸并创建 ---
    padding = int(glow_distance + padding_safety_margin)
    if padding < 0: padding = 0
    new_width = w_orig + 2 * padding
    new_height = h_orig + 2 * padding
    img_padded = Image.new('RGBA', (new_width, new_height), (0, 0, 0, 0))

    # --- 3. 将原始图像居中粘贴到新画布 ---
    paste_x = padding
    paste_y = padding
    img_padded.paste(img_orig, (paste_x, paste_y), img_orig)

    # --- 4. 在扩展画布上提取 Alpha 并计算距离场 ---
    padded_array = np.array(img_padded)
    alpha_padded = padded_array[:, :, 3]
    binary_mask_padded = (alpha_padded > 128).astype(np.uint8)
    inverted_mask_padded = 1 - binary_mask_padded
    distance_map_padded = distance_transform_edt(inverted_mask_padded)

    # --- 5. 生成辉光强度 (0-1范围) ---
    glow_intensity_float = np.clip(1.0 - (distance_map_padded / glow_distance), 0, 1)
    glow_intensity_float *= glow_intensity_factor
    glow_intensity_float = np.clip(glow_intensity_float, 0, 1)

    # --- 6. 映射到 Alpha 值 (0-255) 并确保内部为0 ---
    # 将浮点强度 [0, 1] 映射到 Alpha 值 [0, 255]
    alpha_glow_channel = (glow_intensity_float * 255).astype(np.uint8)

    # 关键：将原始形状区域的 Alpha 强制设为 0 (透明)
    alpha_glow_channel[binary_mask_padded == 1] = 0

    # --- 7. 创建 RGBA 辉光图并输出 ---
    # 创建一个4通道的 NumPy 数组 (Height, Width, 4)
    rgba_glow_map_array = np.zeros((new_height, new_width, 4), dtype=np.uint8)

    # 设置 RGB 通道为白色 (255, 255, 255)
    # 你可以改成其他颜色，但在Godot中用白色 Tint 最方便
    rgba_glow_map_array[:, :, 0] = 255  # Red
    rgba_glow_map_array[:, :, 1] = 255  # Green
    rgba_glow_map_array[:, :, 2] = 255  # Blue

    # 将计算出的辉光强度作为 Alpha 通道
    rgba_glow_map_array[:, :, 3] = alpha_glow_channel

    # 将 NumPy 数组转换回 PIL 图像 ('RGBA'模式)
    glow_map_image = Image.fromarray(rgba_glow_map_array, mode='RGBA')

    # 保存 RGBA 图像
    try:
        glow_map_image.save(output_path)
        print(f"RGBA 辉光贴图 (Alpha通道包含辉光) 已成功保存到: {output_path}")
        print(f"辉光图尺寸: {glow_map_image.size}")
    except Exception as e:
        print(f"错误：无法保存 RGBA 辉光贴图到 {output_path}。错误信息：{e}")

# --- 模糊方法的RGBA版本 ---
def create_glow_map_blur_with_padding_rgba(input_path, output_path, blur_radius=15, padding_safety_margin=10):
    """
    使用高斯模糊生成RGBA辉光贴图，辉光在Alpha通道，内部透明。
    """
    try:
        from PIL import Image, ImageFilter
        # 1. 加载原图
        img_orig = Image.open(input_path).convert("RGBA")
        w_orig, h_orig = img_orig.size
        alpha_orig = img_orig.split()[-1]

        # 2. 计算Padding和新画布
        padding = int(blur_radius * 3 + padding_safety_margin)
        if padding < 0: padding = 0
        new_width = w_orig + 2 * padding
        new_height = h_orig + 2 * padding
        paste_x = padding
        paste_y = padding

        # 3. 创建带Padding的形状剪影 (白色形状，黑色背景)
        silhouette_padded = Image.new('L', (new_width, new_height), 0)
        silhouette_padded.paste(255, (paste_x, paste_y), alpha_orig)

        # 4. 应用高斯模糊 (结果是灰度图)
        blurred_silhouette = silhouette_padded.filter(ImageFilter.GaussianBlur(radius=blur_radius))
        blurred_array = np.array(blurred_silhouette) # 辉光强度灰度图

        # 5. 创建原始形状的蒙版 (在扩展画布上)
        original_mask_padded = Image.new('L', (new_width, new_height), 0)
        original_mask_padded.paste(255, (paste_x, paste_y), alpha_orig)
        original_mask_padded_array = np.array(original_mask_padded) > 128

        # 6. 将原始形状内部的辉光强度设为0
        blurred_array[original_mask_padded_array] = 0

        # --- 7. 创建 RGBA 辉光图 ---
        rgba_glow_map_array = np.zeros((new_height, new_width, 4), dtype=np.uint8)
        rgba_glow_map_array[:, :, 0:3] = 255 # RGB = White
        rgba_glow_map_array[:, :, 3] = blurred_array # Alpha = Blurred intensity

        # 转换并保存
        glow_map_image_blur = Image.fromarray(rgba_glow_map_array, mode='RGBA')
        glow_map_image_blur.save(output_path)
        print(f"带边距的 RGBA 辉光贴图 (模糊法) 已成功保存到: {output_path}")
        print(f"辉光图尺寸 (模糊法): {glow_map_image_blur.size}")

    except ImportError:
        print("\n提示：使用模糊法需要 Pillow 库。")
    except Exception as e:
        print(f"\n使用模糊法生成 RGBA 辉光贴图时出错: {e}")


# --- 使用示例 ---
if __name__ == "__main__":
    input_image_path = 'E:\\MyProgram\\Dark-Diver-Abyssal-Legacy\\Assets\\NiNard\\Cards\\H0003.png'
    # 修改输出文件名以反映其为 RGBA 格式
    output_glow_map_path_rgba = 'glow_map_rgba.png'

    # 检查输入文件是否存在，如果不存在则尝试创建示例
    if not os.path.exists(input_image_path):
        print(f"警告：输入文件 '{input_image_path}' 不存在。将创建一个用于测试的示例图像。")
        try:
            from PIL import Image, ImageDraw
            img_size = (200, 100)
            radius = 20
            img_test = Image.new('RGBA', img_size, (0, 0, 0, 0)) # 透明背景
            draw = ImageDraw.Draw(img_test)
            draw.rounded_rectangle( (0, 0, img_size[0]-1, img_size[1]-1), radius=radius, fill=(255, 255, 255, 255))
            img_test.save(input_image_path)
            print(f"已创建示例输入文件：'{input_image_path}'")
        except ImportError:
             print("错误：无法创建示例图像，因为缺少Pillow库。请确保Pillow已安装。")
             exit()
        except Exception as e:
             print(f"创建示例图像时出错：{e}")
             exit()

    glow_distance = 40
    intensity = 1.0
    padding_margin = 5

    # 调用生成 RGBA 辉光图的函数
    create_glow_map_with_padding(
        input_image_path,
        output_glow_map_path_rgba, # 使用新的输出文件名
        glow_distance,
        intensity,
        padding_margin
    )

    # (可选) 调用生成 RGBA 辉光图的模糊方法
    # output_glow_map_blur_path_rgba = 'glow_map_blur_rgba.png'
    # blur_radius_value = 20
    # create_glow_map_blur_with_padding_rgba(input_image_path, output_glow_map_blur_path_rgba, blur_radius_value)