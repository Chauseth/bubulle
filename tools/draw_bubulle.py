"""Dessine l'illustration de Bubulle (Media/Bubulle.tga).

Utilisation, depuis la racine du dépôt :  python3 tools/draw_bubulle.py
Il faut Python 3 et Pillow (pip install pillow).

Le style retenu est "A, Aplat". Les styles B (trait) et C (pastille) sont
gardés pour mémoire et enregistrés dans tools/previews/.
Tout est dessiné à 1024 px puis réduit à 256 px pour des bords nets.
"""
import os
import math
from PIL import Image, ImageDraw

S = 1024
C = S / 2
ACCENT = (244, 163, 58)
ACCENT_DK = (222, 118, 36)
ACCENT_LT = (250, 196, 112)
WATER = (74, 190, 219)
NAVY = (20, 27, 40)
INK = (22, 28, 42)


def bezier(p0, p1, p2, p3, n=48):
    out = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        out.append((u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0],
                    u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1]))
    return out


def ellipse_pts(cx, cy, rx, ry, a0=0, a1=360, n=120):
    return [(cx + rx * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             cy + ry * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


# --- one fish silhouette, shared by the three designs -------------------
BX, BY, RX, RY = 575, 520, 198, 172
BODY = ellipse_pts(BX, BY, RX, RY)
TAIL = (bezier((395, 520), (330, 470), (260, 380), (205, 360))
        + bezier((205, 360), (215, 430), (240, 490), (285, 520))
        + bezier((285, 520), (240, 550), (215, 610), (205, 680))
        + bezier((205, 680), (260, 660), (330, 570), (395, 520)))
DORSAL = bezier((480, 372), (520, 270), (610, 250), (680, 268)) + bezier((680, 268), (650, 300), (650, 330), (660, 362))
BELLY = ellipse_pts(BX, BY, RX, RY, 20, 160)
EYE = (665, 488, 30)


def round_line(d, pts, color, w):
    """Smooth stroke: stamp discs along the path (no jagged joins)."""
    r = w / 2
    stamp = Image.new("L", (S, S), 0)
    sd = ImageDraw.Draw(stamp)
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(1, int(math.hypot(x1 - x0, y1 - y0) / 2))
        for k in range(n + 1):
            x = x0 + (x1 - x0) * k / n
            y = y0 + (y1 - y0) * k / n
            sd.ellipse([x - r, y - r, x + r, y + r], fill=255)
    if len(color) == 4 and color[3] < 255:
        stamp = stamp.point(lambda v: v * color[3] // 255)
    d._image.paste(Image.new("RGBA", (S, S), color[:3] + (255,)), (0, 0), stamp)


def arc_pts(r, a0, a1):
    return ellipse_pts(C, C, r, r, a0, a1, 60)


def bubbles(d, color, fill=None, w=12):
    for (x, y, r) in [(830, 400, 24), (870, 320, 15)]:
        d.ellipse([x - r, y - r, x + r, y + r], outline=color, width=w, fill=fill)


def save(img, name):
    out = img.resize((256, 256), Image.LANCZOS)
    out.save(name)
    return out


# --- A: flat ---------------------------------------------------------------
def design_flat():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    R = 450
    d.ellipse([C - R, C - R, C + R, C + R], fill=WATER + (46,))
    d.ellipse([C - R, C - R, C + R, C + R], outline=WATER + (235,), width=16)
    round_line(d, arc_pts(R - 52, 200, 245), (255, 255, 255, 210), 18)
    d.polygon(TAIL, fill=ACCENT_DK + (255,))
    d.polygon(DORSAL, fill=ACCENT_DK + (255,))
    d.polygon(BODY, fill=ACCENT + (255,))
    belly = Image.new("L", (S, S), 0)
    ImageDraw.Draw(belly).ellipse([BX - 260, BY + 40, BX + 220, BY + 330], fill=255)
    body = Image.new("L", (S, S), 0)
    ImageDraw.Draw(body).polygon(BODY, fill=255)
    from PIL import ImageChops
    img.paste(Image.new("RGBA", (S, S), ACCENT_LT + (255,)), (0, 0), ImageChops.multiply(belly, body))
    d = ImageDraw.Draw(img)
    x, y, r = EYE
    d.ellipse([x - r, y - r, x + r, y + r], fill=INK + (255,))
    d.ellipse([x + 4, y - 18, x + 18, y - 4], fill=(255, 255, 255, 255))
    round_line(d, ellipse_pts(728, 548, 26, 22, 20, 120, 20), INK + (255,), 12)
    bubbles(d, WATER + (235,))
    return img


# --- B: line ---------------------------------------------------------------
def design_line():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    R = 450
    W = 22
    d.ellipse([C - R, C - R, C + R, C + R], outline=WATER + (235,), width=16)
    round_line(d, arc_pts(R - 52, 200, 245), WATER + (160,), 16)
    round_line(d, TAIL, ACCENT + (255,), W)
    round_line(d, DORSAL, ACCENT + (255,), W)
    d.polygon(BODY, fill=(0, 0, 0, 0))
    round_line(d, BODY, ACCENT + (255,), W)
    # gill curve
    round_line(d, bezier((610, 400), (570, 470), (570, 570), (610, 640), 30), ACCENT + (255,), W)
    x, y, r = EYE
    d.ellipse([x - 24, y - 24, x + 24, y + 24], fill=ACCENT + (255,))
    round_line(d, ellipse_pts(728, 548, 26, 22, 20, 120, 20), ACCENT + (255,), W)
    bubbles(d, WATER + (235,), w=14)
    return img


# --- C: badge ---------------------------------------------------------------
def design_badge():
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    R = 460
    d.ellipse([C - R, C - R, C + R, C + R], fill=(28, 38, 56, 255))
    d.ellipse([C - R, C - R, C + R, C + R], outline=WATER + (255,), width=14)
    # a calm water line across the badge
    wave = []
    for i in range(0, 101):
        t = i / 100
        x = C - 400 + 800 * t
        wave.append((x, 760 + math.sin(t * math.pi * 3) * 12))
    d.polygon(wave + [(C + 400, S), (C - 400, S)], fill=(36, 60, 84, 255))
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse([C - R + 8, C - R + 8, C + R - 8, C + R - 8], fill=255)
    clean = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    clean.paste(img, (0, 0), mask)
    img = clean
    d = ImageDraw.Draw(img)
    d.ellipse([C - R, C - R, C + R, C + R], outline=WATER + (255,), width=14)
    d.polygon(TAIL, fill=ACCENT_DK + (255,))
    d.polygon(DORSAL, fill=ACCENT_DK + (255,))
    d.polygon(BODY, fill=ACCENT + (255,))
    x, y, r = EYE
    d.ellipse([x - r, y - r, x + r, y + r], fill=(28, 38, 56, 255))
    round_line(d, ellipse_pts(728, 548, 26, 22, 20, 120, 20), (28, 38, 56, 255), 12)
    bubbles(d, (255, 255, 255, 230), w=12)
    return img


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PREVIEWS = os.path.join(ROOT, "tools", "previews")
os.makedirs(PREVIEWS, exist_ok=True)

designs = [("A", design_flat()), ("B", design_line()), ("C", design_badge())]
for key, img in designs:
    save(img, os.path.join(PREVIEWS, f"style_{key}.png"))
save(designs[0][1], os.path.join(ROOT, "Media", "Bubulle.tga"))

# comparison sheet: big + small sizes, on the addon's dark panel colour
sheet = Image.new("RGBA", (1200, 470), (16, 22, 34, 255))
d = ImageDraw.Draw(sheet)
for i, (key, img) in enumerate(designs):
    x0 = 40 + i * 390
    sheet.alpha_composite(img.resize((300, 300), Image.LANCZOS), (x0, 30))
    xs = x0
    for s in (88, 48, 24):
        sheet.alpha_composite(img.resize((s, s), Image.LANCZOS), (xs, 360 + (88 - s) // 2))
        xs += s + 30
    d.text((x0 + 140, 335), key, fill=(244, 163, 58, 255))
sheet.save(os.path.join(PREVIEWS, "comparaison.png"))
