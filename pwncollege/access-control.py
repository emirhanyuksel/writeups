from pwn import *

p = process("/challenge/run")

p.readuntil("In this challenge, your goal is to answer ")
num_questions = int(p.readuntil(" "))

level_map = {"TS": 4, "S": 3, "C": 2, "UC": 1}
cat_map = ["UFO", "NATO", "NUC", "ACE"]

questionnum = 1

try:
    for i in range(num_questions):
        p.recvuntil(b"Subject with level ")
        level_s = p.recvuntil(" ").decode().strip()

        p.recvuntil(b" categories {")
        cat_s = p.readuntil("} ").decode().strip().strip("}").replace(",", "")
        scat_s = set(cat_s.split())

        op_byte = p.read(1).decode().strip()
        print(op_byte)

        p.recvuntil(b"an Object with level ")
        level_o = p.readuntil(" ").decode().strip()

        p.recvuntil(b"{")
        cat_o = p.readuntil("}?").decode().strip().strip("}?").replace(",", "")
        scat_o = set(cat_o.split())

        print(cat_s, level_s, cat_o, level_o)

        if op_byte == "r":
            if level_map[level_s] >= level_map[level_o] and scat_o.issubset(scat_s):
                allowed = True
            else:
                allowed = False
        elif op_byte == "w":
            if level_map[level_s] <= level_map[level_o] and scat_s.issubset(scat_o):
                allowed = True
            else:
                allowed = False

        if allowed:
            p.writeline(b"yes")
        else:
            p.writeline(b"no")
        questionnum += 1
except EOFError:
    p.interactive()


print(p.recvall())
