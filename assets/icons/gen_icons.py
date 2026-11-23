import pathlib
import subprocess
import sys

OUT = pathlib.Path(sys.argv[1])

THEMES = {
    "ember": ("#FFC285", "#FF6A00", "rgba(255,122,26,.28)"),
    "lava": ("#FFB199", "#E5361B", "rgba(255,77,46,.28)"),
    "blue": ("#9CC4FF", "#2F6BFF", "rgba(61,139,255,.28)"),
    "pink": ("#FFB3D3", "#FF3D8B", "rgba(255,95,162,.26)"),
    "mono": ("#6B7280", "#FFFFFF", "rgba(255,255,255,.14)"),
}

BG = "#0A0A0F"
TRACK = "#1F2937"


def gauge(g1, g2, *, track=TRACK, dot_fill=BG, uid="g"):
    return f"""
  <defs>
    <linearGradient id="{uid}" x1="0" y1="1" x2="1" y2="0" gradientUnits="objectBoundingBox">
      <stop offset="0" stop-color="{g1}"/><stop offset="1" stop-color="{g2}"/>
    </linearGradient>
  </defs>
  <circle cx="48" cy="50" r="28" fill="none" stroke="{track}" stroke-width="9" stroke-linecap="round" stroke-dasharray="131.9 175.9" transform="rotate(135 48 50)"/>
  <circle cx="48" cy="50" r="28" fill="none" stroke="url(#{uid})" stroke-width="9" stroke-linecap="round" stroke-dasharray="102.9 175.9" transform="rotate(135 48 50)"/>
  <circle cx="75.1" cy="43" r="6.5" fill="{dot_fill}" stroke="{g2}" stroke-width="3.5"/>"""


def glyph_solid(color):
    return f"""
  <circle cx="48" cy="50" r="28" fill="none" stroke="{color}" stroke-opacity=".35" stroke-width="9" stroke-linecap="round" stroke-dasharray="131.9 175.9" transform="rotate(135 48 50)"/>
  <circle cx="48" cy="50" r="28" fill="none" stroke="{color}" stroke-width="9" stroke-linecap="round" stroke-dasharray="102.9 175.9" transform="rotate(135 48 50)"/>
  <circle cx="75.1" cy="43" r="8.25" fill="{color}"/>"""


def svg(body, *, size=1024, frame=96):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" '
        f'viewBox="0 0 {frame} {frame}">{body}\n</svg>\n'
    )


def halo_layer(halo, *, cy):
    r, g, b, a = halo.removeprefix("rgba(").removesuffix(")").split(",")
    return f"""
  <defs>
    <radialGradient id="halo" cx="0.5" cy="{cy}" r="0.62">
      <stop offset="0" stop-color="rgb({r},{g},{b})" stop-opacity="{a}"/>
      <stop offset="1" stop-color="rgb({r},{g},{b})" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="96" height="96" fill="{BG}"/>
  <rect width="96" height="96" fill="url(#halo)"/>"""


def full_bleed(g1, g2, halo):
    return svg(halo_layer(halo, cy=0.47) + gauge(g1, g2))


def halo_background(halo):
    return svg(halo_layer(halo, cy=0.5))


def safe_zone(body):
    return svg(f'<g transform="translate(54 54) scale(0.88) translate(-48.5 -50)">{body}</g>', frame=108)


def render(svg_path, png_path, *, opaque=False):
    subprocess.run(["rsvg-convert", "-o", str(png_path), str(svg_path)], check=True)
    if opaque:
        subprocess.run(["convert", str(png_path), "-background", BG, "-alpha", "remove", "-alpha", "off", str(png_path)], check=True)


def emit(rel, content, *, opaque=False):
    svg_path = OUT / "svg" / f"{rel}.svg"
    png_path = OUT / "png" / f"{rel}.png"
    svg_path.parent.mkdir(parents=True, exist_ok=True)
    png_path.parent.mkdir(parents=True, exist_ok=True)
    svg_path.write_text(content)
    render(svg_path, png_path, opaque=opaque)


for name, (g1, g2, halo) in THEMES.items():
    emit(f"ios/{name}/app_icon", full_bleed(g1, g2, halo), opaque=True)
    emit(f"ios/{name}/app_icon_dark", svg(gauge(g1, g2, track="#2B2F3A", dot_fill="#000000")))
    emit(f"android/{name}/foreground", safe_zone(gauge(g1, g2)))
    emit(f"android/{name}/background", halo_background(halo), opaque=True)

emit("ios/tinted", svg(f'<rect width="96" height="96" fill="#000000"/>{glyph_solid("#FFFFFF")}'), opaque=True)
emit("android/monochrome", safe_zone(glyph_solid("#FFFFFF")))
