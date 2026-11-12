"""Génère les photos d'exemple et le logo par défaut (images de remplacement).
Usage : python3 tool/gen_assets.py  (depuis la racine du projet)"""
import random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 800, 600
OUT = "assets/photos/"

def font(size):
    for p in ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"]:
        try:
            return ImageFont.truetype(p, size)
        except OSError:
            pass
    return ImageFont.load_default()

def label(img, text):
    d = ImageDraw.Draw(img, "RGBA")
    f = font(30)
    w = d.textlength(text, font=f)
    d.rounded_rectangle([20, H - 70, 20 + w + 30, H - 20], 12, fill=(0, 0, 0, 150))
    d.text((35, H - 64), text, font=f, fill="white")

def tiles(dirty):
    r = random.Random(1)
    img = Image.new("RGB", (W, H), (200, 190, 170) if dirty else (238, 236, 230))
    d = ImageDraw.Draw(img, "RGBA")
    for y in range(0, H, 100):
        for x in range(0, W, 100):
            c = (190 + r.randint(-12, 8), 178 + r.randint(-12, 8), 155) if dirty else (245, 244, 240)
            d.rectangle([x + 3, y + 3, x + 97, y + 97], fill=c)
    if dirty:
        for _ in range(40):
            x, y, s = r.randint(0, W), r.randint(0, H), r.randint(10, 70)
            d.ellipse([x, y, x + s, y + s * 0.7], fill=(110, 85, 50, r.randint(40, 110)))
        for _ in range(25):
            x, y = r.randint(0, W), r.randint(0, H)
            d.line([x, y, x + r.randint(-60, 60), y + r.randint(-30, 30)], fill=(60, 50, 40, 120), width=3)
    else:
        d.polygon([(500, 0), (620, 0), (300, H), (180, H)], fill=(255, 255, 255, 70))
    return img.filter(ImageFilter.GaussianBlur(1.2))

def window(dirty):
    r = random.Random(2)
    img = Image.new("RGB", (W, H), (90, 90, 95))
    d = ImageDraw.Draw(img, "RGBA")
    for i, x in enumerate([40, 420]):
        sky = Image.new("RGB", (340, 520))
        sd = ImageDraw.Draw(sky)
        for y in range(520):
            sd.line([0, y, 340, y], fill=(120 + y // 8, 170 + y // 12, 230))
        sd.rectangle([0, 380, 340, 520], fill=(90, 140, 80))
        img.paste(sky, (x, 40))
        if dirty:
            for _ in range(70):
                px, py, s = x + r.randint(0, 320), 40 + r.randint(0, 500), r.randint(5, 40)
                d.ellipse([px, py, px + s, py + s], fill=(140, 130, 110, r.randint(50, 120)))
            d.rectangle([x, 40, x + 340, 560], fill=(150, 140, 120, 70))
        else:
            d.polygon([(x + 40, 40), (x + 120, 40), (x + 20, 300), (x, 300), (x, 160)], fill=(255, 255, 255, 60))
        d.rectangle([x, 40, x + 340, 560], outline=(235, 235, 235), width=10)
    return img.filter(ImageFilter.GaussianBlur(0.8))

def lawn(dirty):
    r = random.Random(3)
    img = Image.new("RGB", (W, H), (70, 120, 50))
    d = ImageDraw.Draw(img, "RGBA")
    if dirty:
        for _ in range(5000):
            x, y = r.randint(0, W), r.randint(0, H)
            g = r.randint(90, 150)
            d.line([x, y, x + r.randint(-6, 6), y - r.randint(10, 30)], fill=(40, g, 30), width=2)
        for _ in range(90):
            x, y, s = r.randint(0, W), r.randint(0, H), r.randint(10, 22)
            d.ellipse([x, y, x + s, y + s * 0.6], fill=(170 + r.randint(0, 50), 100 + r.randint(0, 40), 30, 230))
    else:
        for i, x in enumerate(range(0, W, 100)):
            d.rectangle([x, 0, x + 100, H], fill=(85, 150, 60) if i % 2 else (70, 130, 50))
        for _ in range(2500):
            x, y = r.randint(0, W), r.randint(0, H)
            d.point((x, y), fill=(60, 110 + r.randint(0, 50), 40))
    return img.filter(ImageFilter.GaussianBlur(0.6))

def hedge(dirty):
    r = random.Random(4)
    img = Image.new("RGB", (W, H), (150, 195, 235))
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle([0, 460, W, H], fill=(120, 110, 95))
    if dirty:
        for _ in range(900):
            x, y, s = r.randint(0, W), r.randint(120, 470), r.randint(20, 60)
            d.ellipse([x, y - r.randint(0, 90), x + s, y + s], fill=(30, r.randint(80, 130), 30))
        for _ in range(60):
            x, y = r.randint(0, W), r.randint(420, H)
            d.ellipse([x, y, x + 18, y + 10], fill=(60, 110, 40))
    else:
        d.rectangle([0, 220, W, 470], fill=(35, 105, 35))
        for _ in range(1800):
            x, y = r.randint(0, W), r.randint(222, 468)
            d.point((x, y), fill=(25, 80 + r.randint(0, 50), 25))
    return img.filter(ImageFilter.GaussianBlur(0.8))

pairs = {"carrelage": tiles, "vitres": window, "pelouse": lawn, "haie": hedge}
for name, fn in pairs.items():
    for dirty, tag, txt in [(True, "avant", "AVANT"), (False, "apres", "APRÈS")]:
        img = fn(dirty)
        label(img, f"{txt} · photo d'exemple")
        img.save(f"{OUT}{name}_{tag}.jpg", quality=72, optimize=True)

# Logo par défaut neutre
S = 512
logo = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(logo)
d.rectangle([0, 0, S, S], fill=(21, 101, 192))
d.line([(140, 270), (225, 355), (380, 170)], fill="white", width=56, joint="curve")
logo.save("assets/logo_default.png", optimize=True)
