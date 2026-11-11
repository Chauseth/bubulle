"""Dessine les textures du carnet de Bubulle (Media/*.tga).

Utilisation, depuis la racine du dépôt :  python3 tools/draw_textures.py
Il faut Python 3, NumPy et Pillow (pip install numpy pillow).

Tout est généré ici (bruit filtré, dégradés, formes simples) : aucune image
n'est reprise d'ailleurs. Les tailles sont des puissances de 2, comme
WoW les préfère.
"""
import os
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEDIA = os.path.join(ROOT, "Media")
rng = np.random.default_rng(7)


def blur_noise(size, sigma):
    """Bruit blanc filtré (par FFT : il se répète sans couture)."""
    n = rng.standard_normal((size, size))
    f = np.fft.fftfreq(size)
    fx, fy = np.meshgrid(f, f)
    g = np.exp(-2 * (np.pi * sigma) ** 2 * (fx ** 2 + fy ** 2))
    a = np.real(np.fft.ifft2(np.fft.fft2(n) * g)).astype(np.float32)
    return (a - a.mean()) / (a.std() + 1e-6)


def save_rgb(arr, name):
    Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB").save(os.path.join(MEDIA, name + ".tga"))


def save_rgba(img, name):
    img.save(os.path.join(MEDIA, name + ".tga"))


def supersample(draw_fn, size, factor=4):
    big = Image.new("RGBA", (size[0] * factor, size[1] * factor), (0, 0, 0, 0))
    draw_fn(big, factor)
    return big.resize(size, Image.LANCZOS)


# Page : papier brun foncé, grain fin et deux auréoles d'eau discrètes.
S = 512
base = np.array([40, 28, 18], np.float32)
blotch = blur_noise(S, 40) * 0.07 + blur_noise(S, 12) * 0.04
fibre = blur_noise(S, 0.6) * 0.05
paper = base[None, None, :] * (1 + blotch[..., None] + fibre[..., None])
yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
for (cx, cy, r) in [(390, 120, 70), (120, 420, 52)]:
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    ring = np.exp(-((d - r) ** 2) / (2 * 2.5 ** 2)) * 0.10
    paper *= (1 + ring[..., None] * np.array([0.9, 0.8, 0.6]))
save_rgb(paper, "page")

# Reliure : cuir brun, grain "galets" en relief.
h = blur_noise(S, 1.6) * 0.6 + blur_noise(S, 4) * 0.4
gx = np.roll(h, -1, 1) - np.roll(h, 1, 1)
gy = np.roll(h, -1, 0) - np.roll(h, 1, 0)
light = 1 + (gx * -0.55 + gy * -0.55) * 0.18
mottle = 1 + blur_noise(S, 50) * 0.07
leather = np.array([52, 27, 16], np.float32)[None, None, :] * (light * mottle)[..., None]
save_rgb(leather, "leather")


# Coin en laiton (en haut à gauche ; les autres coins sont retournés en jeu).
def corner(img, k):
    d = ImageDraw.Draw(img)
    s = 64 * k
    d.polygon([(0, 0), (s, 0), (s * 0.62, s * 0.20), (s * 0.20, s * 0.62), (0, s)], fill=(190, 150, 84, 255))
    arr = np.asarray(img).astype(np.float32)
    y, x = np.mgrid[0:s, 0:s].astype(np.float32)
    arr[..., :3] *= (1.15 - (x + y) / (2 * s) * 0.55)[..., None]
    img.paste(Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA"))
    d = ImageDraw.Draw(img)
    d.line([(s * 0.62, s * 0.20), (s * 0.20, s * 0.62)], fill=(110, 80, 36, 255), width=int(1.5 * k))
    for (cx, cy) in [(13, 13), (37, 7.5), (7.5, 37)]:
        cx, cy = cx * k, cy * k
        d.ellipse([cx - 3.5 * k, cy - 3.5 * k, cx + 3.5 * k, cy + 3.5 * k], fill=(120, 88, 40, 255))
        d.ellipse([cx - 2.5 * k, cy - 3 * k, cx + 2 * k, cy + 1.5 * k], fill=(236, 206, 140, 255))


save_rgba(supersample(corner, (64, 64)), "corner")


# Signet : ruban rouge, bout fendu en V.
def ribbon(img, k):
    w, h = 32 * k, 256 * k
    arr = np.zeros((h, w, 4), np.float32)
    x = np.linspace(-1, 1, w)
    shade = 1 - 0.35 * x ** 2
    arr[..., 0] = 181 * shade
    arr[..., 1] = 67 * shade
    arr[..., 2] = 43 * shade
    arr[..., 3] = 255
    notch = 14 * k
    for yy_ in range(h - notch, h):
        depth = (yy_ - (h - notch)) / notch
        half = depth * w / 2
        arr[yy_, int(w / 2 - half):int(w / 2 + half) + 1, 3] = 0
    img.paste(Image.fromarray(arr.astype(np.uint8), "RGBA"))


save_rgba(supersample(ribbon, (32, 256)), "ribbon")


# Bouchon : rouge en haut, crème en bas, cerclé d'encre.
def bobber(img, k):
    d = ImageDraw.Draw(img)
    s = 32 * k
    m = 3 * k
    d.ellipse([m, m, s - m, s - m], fill=(244, 236, 214, 255))
    d.pieslice([m, m, s - m, s - m], 180, 360, fill=(200, 67, 43, 255))
    d.ellipse([m, m, s - m, s - m], outline=(30, 20, 12, 255), width=int(2 * k))


save_rgba(supersample(bobber, (32, 32)), "bobber")


# Bouton rond en laiton (fermer la fenêtre).
def button(img, k):
    s = 64 * k
    arr = np.zeros((s, s, 4), np.float32)
    y, x = np.mgrid[0:s, 0:s].astype(np.float32)
    r = np.sqrt((x - s * 0.5) ** 2 + (y - s * 0.5) ** 2) / (s * 0.46)
    hl = np.sqrt((x - s * 0.36) ** 2 + (y - s * 0.32) ** 2) / s
    t = np.clip(hl * 1.6, 0, 1)
    top, bottom = np.array([240, 212, 154]), np.array([150, 108, 48])
    col = top[None, None, :] * (1 - t[..., None]) + bottom[None, None, :] * t[..., None]
    arr[..., :3] = col
    arr[..., 3] = np.clip((1 - r) * s * 0.08, 0, 1) * 255
    img.paste(Image.fromarray(arr.astype(np.uint8), "RGBA"))
    d = ImageDraw.Draw(img)
    d.ellipse([s * 0.04, s * 0.04, s * 0.96, s * 0.96], outline=(96, 66, 26, 255), width=int(2.5 * k))


save_rgba(supersample(button, (64, 64)), "button")

# Page claire (thème « Clair ») : papier crème, même grain, auréoles plus
# discrètes. Ajoutée à la fin pour ne pas changer les autres textures.
base = np.array([238, 226, 200], np.float32)
blotch = blur_noise(S, 40) * 0.025 + blur_noise(S, 12) * 0.015
fibre = blur_noise(S, 0.6) * 0.02
paper = base[None, None, :] * (1 + blotch[..., None] + fibre[..., None])
for (cx, cy, r) in [(390, 120, 70), (120, 420, 52)]:
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    ring = np.exp(-((d - r) ** 2) / (2 * 2.5 ** 2)) * 0.05
    paper *= (1 - ring[..., None] * np.array([0.6, 0.8, 1.0]))
save_rgb(paper, "page_light")

# Marque-page des onglets : ruban de tissu couché, bout fendu en V à droite.
# Dessiné en gris clair : le jeu le teinte (SetVertexColor) selon l'onglet.
def bookmark(img, k):
    w, h = 128 * k, 32 * k
    y = np.linspace(-1, 1, h)[:, None]
    x = np.arange(w)[None, :]
    # Volume : bombé au milieu, plus sombre sur les bords du ruban
    shade = 1 - 0.30 * y ** 2 + 0.06 * (1 - np.abs(y)) ** 6
    # Trame du tissu : fines rayures horizontales
    weave = 1 + 0.035 * np.sin(np.arange(h)[:, None] / k * np.pi)
    lum = np.clip(225 * shade * weave * np.ones((1, w)), 0, 255)
    arr = np.zeros((h, w, 4), np.float32)
    arr[..., 0] = arr[..., 1] = arr[..., 2] = lum
    arr[..., 3] = 255
    # Couture en pointillés près des deux bords
    for row in (int(4.5 * k), h - int(5.5 * k)):
        dash = ((x // (5 * k)) % 2 == 0) & (x > 2 * k)
        for r in range(row, row + k):
            arr[r, dash[0], :3] = np.minimum(arr[r, dash[0], :3] * 1.45, 255)
    # Ourlet : une ligne sombre tout au bord
    arr[:k, :, :3] *= 0.7
    arr[-k:, :, :3] *= 0.7
    # Bout fendu en V (côté droit)
    notch = 14 * k
    for xx_ in range(w - notch, w):
        depth = (xx_ - (w - notch)) / notch
        half = depth * h / 2
        arr[int(h / 2 - half):int(h / 2 + half) + 1, xx_, 3] = 0
    img.paste(Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA"))


save_rgba(supersample(bookmark, (128, 32)), "bookmark")

print("Textures écrites dans", MEDIA)
