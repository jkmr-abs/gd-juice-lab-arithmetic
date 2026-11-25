# GD Juice Lab Arithmetic

Godot 4.6.1 prototype of the Juice Lab arithmetic activity using actual 3D meshes and object interaction. The supplied sheet is a visual reference only; it is not used as a gameplay texture.

## Current status

The corrected 3D prototype is implemented and GUI-tested. Subtraction, multiplication, and division are interactive: the player clicks a numbered 3D orange, and the scene demonstrates wrong/correct feedback using actual 3D objects. Final visual polish and team review can continue from this baseline.

- Detailed implementation/design mapping: [`docs/PROJECT_IMPLEMENTATION_PLAN.md`](docs/PROJECT_IMPLEMENTATION_PLAN.md)
- Step-by-step milestone log: [`docs/IMPLEMENTATION_PROGRESS.md`](docs/IMPLEMENTATION_PROGRESS.md)
- Source design image and meeting transcripts: `references/`

## Run

Install Godot 4.6.1 and run from the repository root:

```sh
godot --path .
```

## Controls

- Use the top HUD tabs to switch operation.
- Click one of the 3D numbered orange fruits to answer.
- Number keys select the answer by choice order as a fallback.
- `R` or **Restart level** resets the active operation.

## Checks

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_game_logic.gd
godot --headless --path . --quit-after 5
```

## Regenerate 3D assets

```sh
python3 tools/generate_textures.py
blender --background --python tools/generate_3d_assets.py
godot --headless --path . --editor --quit
```

## Key folders

- `scenes/`, `scripts/` — actual 3D game scene and logic.
- `assets/models/` — Blender-generated orange, basket, jar, cup, and orange-segment meshes.
- `assets/textures/` — procedural PBR textures.
- `references/` — source image/transcripts only; these are not loaded by gameplay.
