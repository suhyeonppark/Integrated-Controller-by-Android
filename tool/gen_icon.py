"""Generate the launcher icon: white rounded-square background with a blue
power symbol. Renders each Android mipmap density at the size Flutter expects.

Run:  python tool/gen_icon.py
"""
import math
import os

from PIL import Image, ImageDraw

# White background, blue power glyph.
WHITE = (255, 255, 255, 255)
BLUE = (37, 99, 235, 255)  # #2563EB

# Android legacy launcher densities -> pixel size.
SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

RES = os.path.join("android", "app", "src", "main", "res")
SS = 8  # supersampling factor for smooth edges


def render(size: int) -> Image.Image:
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Rounded-square white background (squircle-ish), transparent corners.
    radius = int(s * 0.23)
    d.rounded_rectangle([0, 0, s - 1, s - 1], radius=radius, fill=WHITE)

    cx = cy = s / 2
    R = s * 0.27          # power ring radius
    stroke = s * 0.085    # glyph stroke width
    half = stroke / 2

    bbox = [cx - R, cy - R, cx + R, cy + R]
    # Ring with a gap at the top, centered on 12 o'clock (270 deg in PIL).
    gap = 56  # degrees of opening
    start = 270 + gap / 2
    end = 270 - gap / 2 + 360
    d.arc(bbox, start=start, end=end, fill=BLUE, width=int(stroke))

    # Round caps on the two arc ends.
    for ang in (start, end):
        ex = cx + R * math.cos(math.radians(ang))
        ey = cy + R * math.sin(math.radians(ang))
        d.ellipse([ex - half, ey - half, ex + half, ey + half], fill=BLUE)

    # Vertical bar through the gap, with rounded caps.
    top = cy - s * 0.36
    bot = cy - s * 0.02
    d.line([cx, top, cx, bot], fill=BLUE, width=int(stroke))
    for y in (top, bot):
        d.ellipse([cx - half, y - half, cx + half, y + half], fill=BLUE)

    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    for density, size in SIZES.items():
        out = os.path.join(RES, f"mipmap-{density}", "ic_launcher.png")
        render(size).save(out)
        print(f"wrote {out} ({size}x{size})")


if __name__ == "__main__":
    main()
