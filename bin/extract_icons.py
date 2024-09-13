# --*-- encoding:utf-8 --*--

# python3 -m pip install Pillow numpy scipy fire

from PIL import Image
import numpy as np
import os

def extract_icons(image_path, output_folder=None):
    image_path = os.path.abspath(os.path.expanduser(image_path))
    if output_folder == None:
        output_folder = image_path + '-output_folder'
    else:
        output_folder = os.path.abspath(os.path.expanduser(str(output_folder)))

    # 打开图像
    img = Image.open(image_path)
    
    # 确保图像有alpha通道
    if img.mode != 'RGBA':
        raise ValueError("输入图像必须是带有alpha通道的PNG格式")
    
    # 转换为numpy数组
    img_array = np.array(img)
    
    # 获取alpha通道
    alpha = img_array[:,:,3]
    
    # 对alpha通道进行二值化
    binary = (alpha > 0).astype(np.uint8) * 255
    
    # 查找连通区域
    from scipy import ndimage
    labeled, num_features = ndimage.label(binary)
    
    # 确保输出文件夹存在
    os.makedirs(output_folder, exist_ok=True)
    
    # 遍历每个连通区域
    for i in range(1, num_features + 1):
        # 获取这个连通区域的边界框
        points = np.argwhere(labeled == i)
        top, left = points.min(axis=0)
        bottom, right = points.max(axis=0)
        
        # 如果区域太小，跳过（可以根据需要调整阈值）
        if (bottom - top) * (right - left) < 100:
            continue
        
        # 提取这个区域
        icon = img.crop((left, top, right+1, bottom+1))
        
        # 保存图像
        icon.save(os.path.join(output_folder, f"icon_{i}.png"))
    
    print(f"提取完成! 图标已保存到 {output_folder} 文件夹中。")
    

if __name__ == '__main__':
    import fire
    fire.Fire(extract_icons)