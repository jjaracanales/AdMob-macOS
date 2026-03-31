#!/usr/bin/env python3
"""
Generate AdMob Widget app icon at all required macOS sizes.
Creates a green gradient background with a white dollar sign
and a small earnings chart line.
"""

import json
import math
from PIL import Image, ImageDraw, ImageFont

OUTPUT_DIR = "AdMobWidget/Sources/App/Assets.xcassets/AppIcon.appiconset"
SIZES = [16, 32, 64, 128, 256, 512, 1024]

# Colors
GREEN_DARK = (46, 125, 50)      # #2E7D32
GREEN_LIGHT = (102, 187, 106)   # #66BB6A
WHITE = (255, 255, 255)
WHITE_SEMI = (255, 255, 255, 180)
WHITE_FAINT = (255, 255, 255, 60)


def lerp_color(c1, c2, t):
    """Linear interpolation between two RGB colors."""
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))


def create_rounded_mask(size, radius):
    """Create a rounded rectangle mask."""
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask


def draw_gradient(img, c_top, c_bottom):
    """Draw a vertical linear gradient."""
    draw = ImageDraw.Draw(img)
    w, h = img.size
    for y in range(h):
        t = y / (h - 1) if h > 1 else 0
        color = lerp_color(c_top, c_bottom, t)
        draw.line([(0, y), (w, y)], fill=color)


def draw_chart_line(draw, size):
    """Draw a small upward-trending chart/graph line in the lower portion."""
    # Chart area: lower-right quadrant area, behind the dollar sign
    margin = size * 0.18
    chart_left = margin
    chart_right = size - margin
    chart_bottom = size * 0.78
    chart_top = size * 0.48

    # Points for an upward trending line with some variation
    points_norm = [
        (0.0, 0.7),
        (0.15, 0.55),
        (0.3, 0.65),
        (0.45, 0.4),
        (0.6, 0.45),
        (0.75, 0.2),
        (0.9, 0.05),
        (1.0, 0.0),
    ]

    chart_w = chart_right - chart_left
    chart_h = chart_bottom - chart_top

    points = []
    for px, py in points_norm:
        x = chart_left + px * chart_w
        y = chart_top + py * chart_h
        points.append((x, y))

    # Draw the line with glow effect
    line_width = max(1, int(size * 0.025))

    # Glow layer
    glow_width = line_width + max(1, int(size * 0.015))
    draw.line(points, fill=WHITE_FAINT, width=glow_width, joint="curve")

    # Main line
    draw.line(points, fill=WHITE_SEMI, width=line_width, joint="curve")

    # Small dot at the end (peak)
    dot_r = max(1, int(size * 0.018))
    ex, ey = points[-1]
    draw.ellipse(
        [ex - dot_r, ey - dot_r, ex + dot_r, ey + dot_r],
        fill=WHITE,
    )


def draw_dollar_sign(draw, size):
    """Draw a bold dollar sign in the center using the best available font."""
    font_size = int(size * 0.55)

    # Try to find a good bold system font
    font_paths = [
        "/System/Library/Fonts/SFNSRounded.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/Library/Fonts/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    ]

    font = None
    for fp in font_paths:
        try:
            font = ImageFont.truetype(fp, font_size)
            break
        except (IOError, OSError):
            continue

    if font is None:
        # Fallback to default
        try:
            font = ImageFont.truetype(
                "/System/Library/Fonts/Supplemental/Helvetica.ttc", font_size
            )
        except (IOError, OSError):
            font = ImageFont.load_default()

    text = "$"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]

    # Center the text, nudged slightly up to feel visually centered
    x = (size - tw) / 2 - bbox[0]
    y = (size - th) / 2 - bbox[1] - size * 0.02

    # Shadow for depth
    shadow_offset = max(1, int(size * 0.008))
    shadow_color = (0, 80, 0, 80)
    draw.text(
        (x + shadow_offset, y + shadow_offset), text, font=font, fill=shadow_color
    )

    # Main dollar sign
    draw.text((x, y), text, font=font, fill=WHITE)


def generate_icon(size_px):
    """Generate a single icon at the given pixel size."""
    # Work at high resolution for quality, then downscale
    work_size = max(size_px, 1024)

    # Create base image with gradient
    base = Image.new("RGB", (work_size, work_size), GREEN_DARK)
    draw_gradient(base, GREEN_LIGHT, GREEN_DARK)

    # Convert to RGBA for compositing
    img = base.convert("RGBA")
    overlay = Image.new("RGBA", (work_size, work_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Draw chart line behind the dollar sign
    draw_chart_line(draw, work_size)

    # Draw dollar sign on top
    draw_dollar_sign(draw, work_size)

    img = Image.alpha_composite(img, overlay)

    # Apply rounded corners (macOS icon corner radius ~ 22.37% of size)
    corner_radius = int(work_size * 0.2237)
    mask = create_rounded_mask(work_size, corner_radius)

    # Create final image with transparent background
    final = Image.new("RGBA", (work_size, work_size), (0, 0, 0, 0))
    final.paste(img, mask=mask)

    # Downscale to target size with high-quality resampling
    if size_px != work_size:
        final = final.resize((size_px, size_px), Image.LANCZOS)

    return final


def build_contents_json():
    """Build the Contents.json for the appiconset."""
    images = []
    for s in SIZES:
        filename = f"icon_{s}x{s}.png"
        images.append(
            {
                "filename": filename,
                "idiom": "mac",
                "size": f"{s}x{s}",
            }
        )
    return {
        "images": images,
        "info": {"version": 1, "author": "xcode"},
    }


def main():
    import os

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("Generating AdMob Widget icons...")
    for s in SIZES:
        icon = generate_icon(s)
        path = os.path.join(OUTPUT_DIR, f"icon_{s}x{s}.png")
        icon.save(path, "PNG")
        print(f"  {path} ({s}x{s})")

    # Write Contents.json
    contents = build_contents_json()
    contents_path = os.path.join(OUTPUT_DIR, "Contents.json")
    with open(contents_path, "w") as f:
        json.dump(contents, f, indent=2)
    print(f"  {contents_path}")

    print("Done! Icons generated successfully.")


if __name__ == "__main__":
    main()
