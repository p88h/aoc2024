# toy encoder to change images into day 14 inputs
# can also generate QR code images automatically

from PIL import Image
from random import randint
from sys import argv
import qrcode

if len(argv)<2:
    print("Usage: encode.py [ <filename.png> | URL ]")
    exit(0)
if argv[1].endswith(".png"):
    img = Image.open(argv[1])
else:
    # This config produces "easy" images. 
    # You could also set version to 2, box to 4, and border to 0 
    # for 100x100 images that are "hard" (can't be decoded with variance decoder )
    qr = qrcode.QRCode(
        version=3,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=3,
        border=1,
    )
    qr.add_data(argv[1])
    qr.make(fit=True)
    img = qr.make_image(fill_color="black",back_color="white")

ofs = randint(4000,8000)
px = img.load()
w,h = img.size
# print(w,h)
for y in range(h):
    for x in range(w):
        # print(px[y,x])
        if (px[y,x] == 0 or px[y,x] == (0,0,0)):
            dx = randint(-100,100)
            dy = randint(-100,100)
            fx = (x + 1 + dx * ofs) % 101
            fy = (y + 1 + dy * ofs) % 103
            print(f"p={fx},{fy} v={dx},{dy}")

            
        