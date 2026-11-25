"""Create lightweight tileable PBR color/height textures for the Godot 3D scene."""
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1] / "assets" / "textures"
ROOT.mkdir(parents=True, exist_ok=True)
size = 768
rng = np.random.default_rng(731)
y, x = np.mgrid[0:size, 0:size].astype(np.float32)
u = x / size
v = y / size

# Warm horizontal wood grain with a few understated knots.
noise = rng.normal(0.0, 0.025, (size, size)).astype(np.float32)
wood_wave = 0.075 * np.sin(v * 150.0 + np.sin(u * 13.0) * 3.2)
wood_wave += 0.035 * np.sin(v * 410.0 + np.sin(u * 7.0) * 4.0)
wood_wave += 0.018 * np.sin(u * 95.0 + v * 11.0)
knots = np.zeros((size, size), dtype=np.float32)
for cx, cy, rx, ry in [(0.24, 0.34, 0.045, 0.022), (0.72, 0.72, 0.035, 0.018), (0.50, 0.12, 0.024, 0.014)]:
    dx = (u - cx + 0.5) % 1.0 - 0.5
    dy = (v - cy + 0.5) % 1.0 - 0.5
    r = np.sqrt((dx / rx) ** 2 + (dy / ry) ** 2)
    knots += 0.035 * np.cos(r * 19.0) * np.exp(-r * 0.65)
wood = np.clip(0.52 + wood_wave + noise + knots, 0.0, 1.0)
wood_rgb = np.stack([0.38 + wood * 0.42, 0.17 + wood * 0.28, 0.065 + wood * 0.15], axis=-1)
Image.fromarray((np.clip(wood_rgb, 0, 1) * 255).astype(np.uint8), "RGB").save(ROOT / "wood_grain.png")
height = np.clip(0.5 + wood_wave * 1.5 + noise * 0.65 + knots, 0, 1)
grad_y, grad_x = np.gradient(height)
nx = -grad_x * 5.0
ny = -grad_y * 5.0
nz = np.ones_like(nx)
norm = np.sqrt(nx * nx + ny * ny + nz * nz)
normal_rgb = np.stack([nx / norm * 0.5 + 0.5, ny / norm * 0.5 + 0.5, nz / norm * 0.5 + 0.5], axis=-1)
Image.fromarray((np.clip(normal_rgb, 0, 1) * 255).astype(np.uint8), "RGB").save(ROOT / "wood_normal.png")

# Muted garden grass mottling; color is intentionally darker than the lighting.
grass_noise = rng.normal(0.0, 0.055, (size, size)).astype(np.float32)
grass_wave = 0.035 * np.sin(x * 0.18 + np.sin(y * 0.04)) + 0.02 * np.sin(y * 0.28)
grass = np.clip(0.42 + grass_noise + grass_wave, 0.05, 0.9)
grass_rgb = np.stack([0.11 + grass * 0.28, 0.23 + grass * 0.38, 0.10 + grass * 0.20], axis=-1)
Image.fromarray((np.clip(grass_rgb, 0, 1) * 255).astype(np.uint8), "RGB").save(ROOT / "garden_grass.png")
print("Generated wood_grain.png, wood_normal.png, and garden_grass.png")
