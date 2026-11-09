#!/usr/bin/env python3
"""Generate legacy iPhone app icons for M3gaEmojiVault."""
from PIL import Image, ImageDraw
from pathlib import Path
import math

def make_icon(size, output):
    scale = 4
    n = size * scale
    im = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    px = im.load()
    # Soft rainbow edge and warm lemon center.
    stops = [(255, 117, 175), (255, 211, 95), (150, 230, 145), (105, 190, 255), (195, 145, 255)]
    for y in range(n):
        for x in range(n):
            t = (x + y) / max(1, 2 * (n - 1))
            k = min(3, int(t * 4))
            q = t * 4 - k
            a, b = stops[k], stops[k + 1]
            edge = tuple(int(a[i] * (1-q) + b[i] * q) for i in range(3))
            cx, cy = (n-1)/2, (n-1)/2
            d = math.sqrt(((x-cx)/(n*.72))**2 + ((y-cy)/(n*.72))**2)
            blend = max(0, min(1, (d-.34)/.34))
            lemon = (255, 250, 168)
            px[x,y] = tuple(int(lemon[i]*(1-blend)+edge[i]*blend) for i in range(3)) + (255,)
    d = ImageDraw.Draw(im)
    # Silver beveled frame.
    margin = int(n*.035)
    d.rounded_rectangle((margin, margin, n-margin, n-margin), radius=int(n*.22),
                        outline=(255,255,255,255), width=int(n*.025))
    # Crown.
    gold=(194,119,20,255); bright=(255,204,48,255)
    crown=[(n*.28,n*.34),(n*.24,n*.19),(n*.38,n*.28),(n*.50,n*.13),
           (n*.62,n*.28),(n*.76,n*.19),(n*.72,n*.36)]
    d.polygon(crown, fill=bright, outline=gold)
    for x,y in [(n*.24,n*.19),(n*.50,n*.13),(n*.76,n*.19)]:
        r=n*.035
        d.ellipse((x-r,y-r,x+r,y+r),fill=(255,225,92,255),outline=gold,width=max(1,int(n*.012)))
    # Smiley face.
    box=(n*.19,n*.29,n*.81,n*.86)
    d.ellipse(box,fill=(255,190,25,255),outline=(175,99,0,255),width=int(n*.035))
    d.ellipse((n*.34,n*.48,n*.42,n*.62),fill=(70,43,13,255))
    d.ellipse((n*.58,n*.48,n*.66,n*.62),fill=(70,43,13,255))
    d.arc((n*.34,n*.55,n*.66,n*.77),start=10,end=170,fill=(91,43,5,255),width=int(n*.035))
    # Small glossy highlight.
    d.ellipse((n*.25,n*.37,n*.39,n*.43),fill=(255,255,220,120))
    im.resize((size,size),Image.Resampling.LANCZOS).save(output, "PNG", optimize=True)

base=Path(__file__).resolve().parent
make_icon(57, base/"Icon.png")
make_icon(114, base/"Icon@2x.png")
print("Generated Icon.png (57x57) and Icon@2x.png (114x114)")
