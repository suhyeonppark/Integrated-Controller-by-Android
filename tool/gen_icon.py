"""Generate the launcher icon: a white rounded-square with a blue gradient
power badge. Renders each Android mipmap density at the size Flutter expects.

Run:  python tool/gen_icon.py
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

WHITE = (255, 255, 255, 255)
BLUE_TOP = (59, 130, 246)     # #3B82F6
BLUE_BOTTOM = (29, 78, 216)   # #1D4ED8
SHADOW = (29, 78, 216)        # badge drop shadow tint

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


def _gradient_circle(diameter: int) -> Image.Image:
    """A circle filled with a vertical top->bottom blue gradient."""
    grad = Image.new("RGB", (1, diameter))
    for y in range(diameter):
        t = y / (diameter - 1)
        grad.putpixel(
            (0, y),
            tuple(
                round(a + (b - a) * t)
                for a, b in zip(BLUE_TOP, BLUE_BOTTOM)
            ),
        )
    grad = grad.resize((diameter, diameter))

    mask = Image.new("L", (diameter, diameter), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, diameter - 1, diameter - 1], fill=255)

    out = Image.new("RGBA", (diameter, diameter), (0, 0, 0, 0))
    out.paste(grad, (0, 0), mask)
    return out


def _power_glyph(d: ImageDraw.ImageDraw, cx: float, cy: float, R: float,
                 stroke: float, color) -> None:
    """White power symbol: a ring open at the top plus a vertical bar."""
    half = stroke / 2
    bbox = [cx - R, cy - R, cx + R, cy + R]
    gap = 52  # degrees of opening at 12 o'clock (270 deg in PIL)
    start = 270 + gap / 2
    end = 270 - gap / 2 + 360
    d.arc(bbox, start=start, end=end, fill=color, width=int(stroke))
    for ang in (start, end):
        ex = cx + R * math.cos(math.radians(ang))
        ey = cy + R * math.sin(math.radians(ang))
        d.ellipse([ex - half, ey - half, ex + half, ey + half], fill=color)

    top = cy - R * 1.32
    bot = cy - R * 0.06
    d.line([cx, top, cx, bot], fill=color, width=int(stroke))
    for y in (top, bot):
        d.ellipse([cx - half, y - half, cx + half, y + half], fill=color)


def render(size: int) -> Image.Image:
    s = size * SS
    cx = cy = s / 2

    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))

    # White rounded-square background, transparent corners.
    bg = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(bg).rounded_rectangle(
        [0, 0, s - 1, s - 1], radius=int(s * 0.23), fill=WHITE)
    img = Image.alpha_composite(img, bg)

    badge_r = s * 0.345
    diameter = int(badge_r * 2)

    # Soft drop shadow under the badge.
    shadow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    sy = cy + s * 0.03
    ImageDraw.Draw(shadow).ellipse(
        [cx - badge_r, sy - badge_r, cx + badge_r, sy + badge_r],
        fill=SHADOW + (90,),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(s * 0.05))
    img = Image.alpha_composite(img, shadow)

    # Gradient blue badge.
    badge = _gradient_circle(diameter)
    badge_layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    badge_layer.paste(badge, (int(cx - badge_r), int(cy - badge_r)), badge)
    img = Image.alpha_composite(img, badge_layer)

    # White power glyph on the badge.
    d = ImageDraw.Draw(img)
    _power_glyph(d, cx, cy, R=badge_r * 0.5, stroke=s * 0.052, color=WHITE)

    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    for density, size in SIZES.items():
        out = os.path.join(RES, f"mipmap-{density}", "ic_launcher.png")
        render(size).save(out)
        print(f"wrote {out} ({size}x{size})")


if __name__ == "__main__":
    main()
