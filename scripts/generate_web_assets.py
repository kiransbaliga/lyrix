import os
from PIL import Image, ImageDraw, ImageFont

DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DOCS = os.path.join(DIR, "docs")
USER_ICON = "/Users/narix/.gemini/antigravity/brain/77d8ce67-effe-4ea8-8761-fff8d148a7e2/.user_uploaded/media_1787683776141.png"
BG_SRC = "/Users/narix/.gemini/antigravity/brain/77d8ce67-effe-4ea8-8761-fff8d148a7e2/dmg_background_1787683242744.jpg"

def generate_web_assets():
    os.makedirs(DOCS, exist_ok=True)
    
    # 1. Base App Icon on Black Squircle
    glyph = Image.open(USER_ICON).convert("RGBA")
    canvas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    
    padding = 45
    squircle_box = [padding, padding, 1024 - padding, 1024 - padding]
    radius = 215
    draw.rounded_rectangle(
        squircle_box,
        radius=radius,
        fill=(14, 16, 20, 255),
        outline=(255, 255, 255, 45),
        width=3
    )
    glyph_scaled = glyph.resize((760, 760), Image.Resampling.LANCZOS)
    canvas.paste(glyph_scaled, (132, 132), glyph_scaled)
    
    # Export Favicons
    canvas.resize((32, 32), Image.Resampling.LANCZOS).save(os.path.join(DOCS, "favicon.png"))
    canvas.resize((180, 180), Image.Resampling.LANCZOS).save(os.path.join(DOCS, "apple-touch-icon.png"))
    canvas.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(DOCS, "icon-512.png"))
    
    # 2. OpenGraph 1200x630 Social Banner
    og_img = Image.open(BG_SRC).resize((1200, 630), Image.Resampling.LANCZOS)
    og_draw = ImageDraw.Draw(og_img)
    
    # Draw large centered squircle icon
    icon_preview = canvas.resize((240, 240), Image.Resampling.LANCZOS)
    og_img.paste(icon_preview, (480, 90), icon_preview)
    
    font_path = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
    if not os.path.exists(font_path):
        font_path = "/System/Library/Fonts/Helvetica.ttc"
        
    try:
        title_font = ImageFont.truetype(font_path, 48)
        sub_font = ImageFont.truetype(font_path, 22)
    except:
        title_font = ImageFont.load_default()
        sub_font = title_font
        
    og_draw.text((600, 390), "Lyrix", font=title_font, fill=(255, 255, 255), anchor="mm")
    og_draw.text((600, 460), "Real-time floating lyrics overlay for macOS", font=sub_font, fill=(200, 210, 230), anchor="mm")
    og_draw.text((600, 510), "By Kiran S Baliga · baliga.dev", font=sub_font, fill=(0, 240, 255), anchor="mm")
    
    og_img.save(os.path.join(DOCS, "og-image.png"))
    print("Generated all web favicon and OpenGraph assets!")

if __name__ == "__main__":
    generate_web_assets()
