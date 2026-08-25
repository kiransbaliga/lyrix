import os

# Volume name
volume_name = "Lyrix Installer"

# Output format
format = "UDZO"
compression_level = 9

# Background image (dmgbuild automatically picks up @2x for HiDPI Retina)
background = os.path.abspath("dist/dmg_background.png")

# Window positioning and dimensions (centered on screen, 660x420)
window_rect = ((250, 150), (660, 420))

# View options
default_view = "icon-view"
show_icon_preview = False
include_icon_view_settings = "auto"
include_list_view_settings = "auto"

# Layout settings
arrange_by = None
grid_offset = (0, 0)
grid_spacing = 100
scroll_position = (0, 0)
label_pos = None  # Use our high-res baked white typography
icon_size = 135

# Files and links
files = [os.path.abspath("dist/Lyrix.app")]
symlinks = {"Applications": "/Applications"}

# Exact pixel icon coordinates on the 660x420 window (centered vertically at y=185)
icon_locations = {
    "Lyrix.app": (165, 185),
    "Applications": (495, 185),
}

# Hide extension
hide_extensions = ["Lyrix.app"]
