# --*-- encoding:utf-8 --*--
with open('all.txt', 'r', encoding='utf-8') as fs:
    all = fs.read().splitlines()
name = all

with open('all.r.txt', 'w', encoding='utf-8') as fs:
    for i in name: #循环三次，次数是字符数
        by = bytes(i,encoding='utf8')#将每个字符转换为3个字节,返回一个字节对象

        int_array = [0,0,0]
        bin_array = [0,0,0]
        hex_array = [0,0,0]
        k = 0
        for j in by:#循环字节对象，循环三次（每个字节三个字符）
            int_array[k] = str(j)
            bin_array[k] = bin(j)[2:]
            hex_array[k] = hex(j)[2:]
            k = k + 1
            # s = '{} {} {} '.format(j,bin(j)[2:],hex(j)[2:])
            # fs.write(s)#输出10进制，bin(j)输出2进制,hex(j)输出16进制
        line = ' '.join([i, str(by), ' '.join(int_array), ' '.join(bin_array), ' '.join(hex_array)]) + '\n'
        fs.write(line)