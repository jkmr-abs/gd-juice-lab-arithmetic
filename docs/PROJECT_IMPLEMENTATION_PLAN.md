# GD Juice Lab Arithmetic — Real 3D Godot Implementation

**Status:** Corrected 3D prototype implemented and pushed to `main`
**Engine:** Godot 4.6.1
**Repository:** `jkmr-abs/gd-juice-lab-arithmetic`

## 1. Corrected goal

The supplied Juice Lab sheet is a **visual/design reference only**. It must not be displayed as the game's background, cropped into gameplay panels, or used instead of game objects.

The game itself is a real-time Godot 3D scene: actual meshes with materials, lighting, shadows, camera perspective, collision/raycast input, and object animations. The orange answer choices must be physical-looking 3D fruit objects that the learner clicks in the scene. HUD buttons may select an operation or restart; they must not replace the 3D answer objects.

The image's three arithmetic examples define the first playable slice:

- Subtraction: `7 − 2 = 5`
- Multiplication: `3 × 2 = 6`
- Division: `6 ÷ 2 = 3`

## 2. Reference-to-3D mapping

| Reference element | 3D implementation |
|---|---|
| Juice Lab garden | Godot 3D sky, ground, low-poly trees and bushes |
| Wooden table/tray | Layered 3D workbench geometry with generated wood grain and normal textures |
| Orange character | 3D orange head, eyes, glasses, coat and arms |
| Answer oranges | Separate textured 3D orange meshes with 3D number labels and collision areas |
| Subtraction examples | Seven small 3D oranges; on wrong feedback, two animate into a side basket, leaving five |
| Multiplication groups | Three 3D woven baskets with two actual orange meshes in each |
| Division | Six 3D orange segments and two transparent cups; feedback distributes three pieces into each cup |
| Reward jar | 3D transparent glass jar, animated juice fill and 3D star meshes |
| Question/feedback text | Godot HUD text; not baked into or pasted from the reference image |

The design sheet remains in `references/`. It is not referenced by the gameplay scene. Runtime art lives under `assets/models/` and `assets/textures/`.

## 3. Project structure

```text
gd-juice-lab-arithmetic/
├── project.godot
├── scenes/
│   └── main_3d.tscn
├── scripts/
│   ├── juice_lab_3d.gd       # scene, 3D props, input and feedback
│   ├── operation_data.gd    # equations and answer data
│   └── game_logic.gd        # answer/state rules
├── assets/
│   ├── models/              # Blender-authored GLB meshes
│   └── textures/            # orange peel, wood grain, garden textures
├── tools/
│   ├── generate_3d_assets.py
│   └── generate_textures.py
├── tests/
│   └── test_game_logic.gd
├── references/              # source image and meeting transcripts only
└── docs/                    # plan and progress log
```

## 4. Interaction procedure

1. The learner selects Subtraction, Multiplication, or Division from the HUD tabs.
2. Godot builds the selected 3D activity: prompt, operation-specific objects, three 3D answer oranges, and the reward jar.
3. The learner clicks a numbered orange in the 3D scene. Mouse picking uses a camera raycast against an `Area3D` collider; number keys remain a test/accessibility fallback.
4. A wrong answer updates the HUD and animates actual objects to demonstrate the operation. It does not award stars.
5. The correct answer updates the HUD, raises the juice fill, lights the star meshes, and prevents duplicate rewards.
6. The learner may switch operations or restart.

## 5. Asset pipeline

1. `tools/generate_3d_assets.py` uses Blender to build and export actual GLB meshes: orange with peel texture and leaves, woven basket, glass jar, and glass cup.
2. `tools/generate_textures.py` creates the wood grain/normal and garden ground textures.
3. Godot imports the GLB and PNG assets as 3D scene resources/materials.
4. `scripts/juice_lab_3d.gd` creates the extruded orange-segment `ArrayMesh`, instantiates all props into operation scenes, and handles state changes.
5. The source storyboard is retained only for visual comparison; it is not loaded by the game.

Regenerate assets from the repository root:

```sh
python3 tools/generate_textures.py
blender --background --python tools/generate_3d_assets.py
godot --headless --path . --editor --quit
```

## 6. Verification checklist

- [ ] Main scene contains a `Node3D` world and camera; no storyboard image is shown at runtime.
- [ ] Answer choices are actual 3D orange models with readable numbers and colliders.
- [ ] Mouse raycast selects the visible 3D fruit; number-key fallback selects the same answer.
- [ ] Subtraction wrong feedback animates two of seven fruit away; correct answer is five.
- [ ] Multiplication visually shows three groups of two; correct answer is six.
- [ ] Division shows six pieces and two cups; feedback splits three into each cup.
- [ ] Wrong and correct feedback, jar fill, star reward, operation switching, and restart are tested.
- [ ] Godot headless import, scene startup, and automated logic tests pass.
- [ ] GUI screenshots are reviewed at the target viewport for object legibility and composition.

## 7. Current prototype boundaries

- Fixed example levels; no generated questions or saved progression.
- Stylized 3D models and procedural materials, not photoreal scans or a full character rig.
- Simple click-to-answer activity; no drag-and-pour measurement level yet.
- The reference art is not used as a runtime image. It is only a guide for composition and content.

## 8. Team review notes

The earlier image-crop implementation did not meet the request for actual 3D gameplay. It has been removed from the active scene and replaced with the 3D object approach above. Review the running scene and `docs/IMPLEMENTATION_PROGRESS.md`; visual polish should be assessed on the 3D models, lighting, and interactions, not on the source sheet being displayed.
