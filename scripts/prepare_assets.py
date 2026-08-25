import os
import subprocess
from PIL import Image, ImageDraw, ImageFont

DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
USER_ICON = "/Users/narix/.gemini/antigravity/brain/77d8ce67-effe-4ea8-8761-fff8d148a7e2/.user_uploaded/media_1787683776141.png"
BG_SRC = "/Users/narix/.gemini/antigravity/brain/77d8ce67-effe-4ea8-8761-fff8d148a7e2/dmg_background_1787683242744.jpg"

def create_app_icon():
    print("🎨 Step 2: Creating high-contrast black squircle AppIcon...")
    glyph = Image.open(USER_ICON).convert("RGBA")

    # 1024x1024 canvas
    canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    padding = 45
    squircle_box = [padding, padding, 1024 - padding, 1024 - padding]
    radius = 215

    # Deep obsidian black squircle with subtle highlight stroke
    draw.rounded_rectangle(
        squircle_box,
        radius=radius,
        fill=(14, 16, 20, 255),
        outline=(255, 255, 255, 45),
        width=3
    )

    # Scale and paste glyph in center
    glyph_scaled = glyph.resize((760, 760), Image.Resampling.LANCZOS)
    canvas.paste(glyph_scaled, (132, 132), glyph_scaled)

    # Save temporary master PNG
    master_png = os.path.join(DIR, "dist", "master_icon.png")
    os.makedirs(os.path.join(DIR, "dist"), exist_ok=True)
    canvas.save(master_png)

    # Create iconset
    iconset_dir = os.path.join(DIR, "dist", "AppIcon.iconset")
    os.makedirs(iconset_dir, exist_ok=True)

    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]

    for sz, filename in sizes:
        resized = canvas.resize((sz, sz), Image.Resampling.LANCZOS)
        resized.save(os.path.join(iconset_dir, filename))

    # Compile with iconutil
    icns_path = os.path.join(DIR, "dist", "Lyrix.app", "Contents", "Resources", "AppIcon.icns")
    os.makedirs(os.path.dirname(icns_path), exist_ok=True)
    subprocess.run(["iconutil", "-c", "icns", iconset_dir, "-o", icns_path], check=True)
    print("  ✅ Successfully compiled AppIcon.icns")

def create_dmg_background():
    print("🌌 Step 4: Generating HiDPI starry background with crisp white typography...")
    
    # Font resolution
    font_path = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
    if not os.path.exists(font_path):
        font_path = "/System/Library/Fonts/Helvetica.ttc"

    for scale, filename in [(1, "dmg_background.png"), (2, "dmg_background@2x.png")]:
        w, h = 660 * scale, 420 * scale
        img = Image.open(BG_SRC).resize((w, h), Image.Resampling.LANCZOS)
        draw = ImageDraw.Draw(img)

        try:
            label_font = ImageFont.truetype(font_path, 15 * scale)
            arrow_font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 28 * scale)
        except:
            label_font = ImageFont.load_default()
            arrow_font = label_font

        # Icon positions: Left = 165, Right = 495, Center Y = 185
        # Draw white labels below icons
        draw.text((165 * scale, 282 * scale), "Lyrix", font=label_font, fill=(255, 255, 255, 245), anchor="mm")
        draw.text((495 * scale, 282 * scale), "Applications", font=label_font, fill=(255, 255, 255, 245), anchor="mm")

        # Draw subtle glowing center arrow
        draw.text((330 * scale, 185 * scale), "➜", font=arrow_font, fill=(255, 255, 255, 140), anchor="mm")

        out_path = os.path.join(DIR, "dist", filename)
        img.save(out_path)

    print("  ✅ Successfully generated 1x and 2x Retina background images")

if __name__ == "__main__":
    create_app_icon()
    create_dmg_background()
