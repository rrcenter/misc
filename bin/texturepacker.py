

# https://github.com/rrcenter/PyTexturePacker#usage
# python3 -m pip install fire
# python3 -m pip install git+https://github.com/rrcenter/PyTexturePacker.git@master
#
from PyTexturePacker import Packer

def TexturePacker(folder, filename):
    # create a MaxRectsBinPacker
    # packer = Packer.create(max_width=2048, max_height=2048, bg_color=0xffffff00)
    # pack texture images under directory "test_case/" and name the output images as "test_case".
    # "%d" in output file name "test_case%d" is a placeholder, which is a multipack index, starting with 0.
    # packer.pack("test_case/", "test_case%d")

    packer = Packer.create(max_width=2048, max_height=2048)
    packer.pack(folder, filename)


if __name__ == '__main__':
    import fire
    fire.Fire(TexturePacker)