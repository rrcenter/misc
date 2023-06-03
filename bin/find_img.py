
# // http://www.bdsdk.com/?p=16
# python3 -m pip install numpy opencv-python
import os
import sys
import cv2
import numpy as np


def unixpath(path):
    path = os.path.expanduser(path)
    path = os.path.abspath(path)
    path = path.replace('\\', '/')
    return path


def scan(*dirs, **kwargs):
    files = []
    extensions = kwargs['extensions'] if 'extensions' in kwargs else None
    excludes = kwargs['excludes'] if 'excludes' in kwargs else []
    for top in dirs:
        for root, dirnames, filenames in os.walk(top):
            # dirnames = [i for i in dirnames if i in excludes]
            for ed in excludes:
                if ed in dirnames:
                    dirnames.remove(ed)
          
        for f in filenames:
            if f in excludes:
                continue
            ext = os.path.splitext(f)[1].lower()
            if extensions is None or ext in extensions:
                files.append(os.path.join(root, f))
    files = sorted(files)
    return files
  
def contains_image2(small, big):


    # 这个3.png是大图，需要在这张图片中寻找目标的
    img_rgb = cv2.imread(big)
    # 这个1.png是小图，是图中的目标
    template = cv2.imread(small)
    # Perform match operations.
    result_t  = cv2.matchTemplate(img_rgb,template,cv2.TM_CCOEFF_NORMED)
    # 筛选大于一定匹配值的点
    val,result = cv2.threshold(result_t,0.9,1.0,cv2.THRESH_BINARY)
    # print(val, result)
    match_locs = cv2.findNonZero(result)
    

    found = False
    # print('match_locs:\n',type(match_locs))
    if type(match_locs) != type(None):
        found = True

    print('{} {}'.format('[yes]' if found else "[no]", big))
    return found


def contains_image(small, big, debug = False):

    small = unixpath(small)
    big = unixpath(big)

    # 这个3.png是大图，需要在这张图片中寻找目标的
    img_rgb = cv2.imread(big)
    # Convert it to grayscale
    img_gray = cv2.cvtColor(img_rgb, cv2.COLOR_BGR2GRAY)
    # 这个1.png是小图，是图中的目标
    template = cv2.imread(small,0)
    # Store width and heigth of template in w and h
    w, h = template.shape[::-1]
    # Perform match operations.
    res = cv2.matchTemplate(img_gray,template,cv2.TM_CCOEFF_NORMED)
    # print('res', res, type(res))
    # Specify a threshold
    # 这里的0.7表示匹配度
    threshold = 0.7
    # Store the coordinates of matched area in a numpy array
    loc = np.where(res >= threshold)
    x = loc[0]
    y = loc[1]

    found = False
    # Draw a rectangle around the matched region.
    if len(x) and len(y):
        found = True
        for pt in zip(*loc[::-1]):
            # 这里会把匹配到的位置用矩形框给框选出来
            if debug:
                output = big + '.debug.png'
                print('debug image:', output)
                cv2.rectangle(img_rgb, pt, (pt[0] + w, pt[1] + h), (0,255,255), 2)
                cv2.imwrite(output, img_rgb)

    print('{} {}'.format('[yes]' if found else "[no]", big))
    return found

def find_image(img, folder):
    files = scan(folder)
    for file in files:
        contains_image(img, file)

if __name__ == '__main__':
    import fire
    fire.Fire(find_image)