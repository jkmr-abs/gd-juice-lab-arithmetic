# GD Juice Lab Arithmetic — Godot Implementation Plan

**Status:** First prototype implemented and pushed to `main`
**Technology:** Godot 4.6.1
**Repository:** `jkmr-abs/gd-juice-lab-arithmetic`
**Design source:** `references/math-juice-lab-arithmetic-levels-sheet.png`

## 1. Goal

Build a standalone Godot prototype whose visible operation screens match the supplied reference image exactly by using its original storyboard panels as textures. Make those screens interactive: learners can choose answers and move through the question, incorrect-feedback, and correct-feedback states.

The implemented scope is the image's three operations:

- Subtraction: `7 − 2 = 5`
- Multiplication: `3 × 2 = 6`
- Division: `6 ÷ 2 = 3`

This supersedes the earlier draft suggestion to limit the first build to measurement/fill-level addition. Measurement/addition can be considered later; it is not part of this image-matching implementation.

## 2. User-visible behavior

1. Show the reference board with three operation rows as the landing/preview screen.
2. Let the user select an operation: Subtraction, Multiplication, or Division.
3. Show the exact corresponding Question panel crop from the provided reference image.
4. Let the user click the pictured answer or use the keyboard number keys.
5. A wrong answer changes to that operation's exact Incorrect-feedback panel. The user can try again; the correct answer advances to the Correct panel.
6. On the Correct panel, Enter/Space or a clear replay/next action returns to the question or lets the user select another operation.
7. Keep a Reference Board action available to view the original full storyboard.

### Answer behavior

| Operation | Choices | Correct answer | Wrong state explains |
|---|---:|---:|---|
| Subtraction | 4, 5, 6 | 5 | Take away 2 |
| Multiplication | 5, 6, 7 | 6 | 3 groups of 2 |
| Division | 2, 3, 4 | 3 | Share 6 equally between 2 cups |

The fixed example art contains one depicted wrong choice per operation. Other wrong choices should produce the same operation-specific feedback panel; the correct answer advances to the success panel.

## 3. Visual fidelity and assets

- Keep the supplied reference image unchanged in `references/` as the source of truth.
- Create exact rectangular panel crops from that image for runtime use; do not redraw or regenerate the artwork in this first pass.
- Use the same pixels/text/artwork for each of the nine states: three operations times three states.
- Preserve aspect ratio and avoid stretching. Use a 4:3 reference-board view; scale individual panels proportionally within the Godot viewport.
- Add transparent mouse hotspots over the pictured answer fruits. Provide keyboard alternatives so the prototype remains testable if a hotspot is hard to click.
- Keep navigation controls visually outside the reference artwork; do not cover the equation, choices, feedback, or star jar.
- Do not assume a full 3D interaction. The prototype is 2D UI with the reference's pseudo-depth art.

## 4. Godot project structure

The repository is a Godot project with documentation and references at the repository root:

```text
gd-juice-lab-arithmetic/
├── project.godot
├── README.md
├── .gitignore
├── docs/
│   ├── PROJECT_IMPLEMENTATION_PLAN.md
│   └── IMPLEMENTATION_PROGRESS.md
├── references/
│   ├── math-juice-lab-arithmetic-levels-sheet.png
│   ├── meeting-tamil-transcript.md
│   └── meeting-english-transcript.md
├── assets/
│   ├── reference_board.png
│   └── panels/
│       ├── subtraction_question.png
│       ├── subtraction_incorrect.png
│       ├── subtraction_correct.png
│       ├── multiplication_question.png
│       ├── multiplication_incorrect.png
│       ├── multiplication_correct.png
│       ├── division_question.png
│       ├── division_incorrect.png
│       └── division_correct.png
├── scenes/
│   └── main.tscn
├── scripts/
│   ├── game_controller.gd
│   └── operation_data.gd
└── tests/
    └── test_game_logic.gd
```

## 5. Build sequence

1. **Repository and project setup:** initialize the Godot project at the repository root, set the main scene, configure the 4:3 viewport, and preserve the source image.
2. **Panel assets:** crop the nine operation/state panels from the source image and check the crops visually against the original.
3. **Screen flow:** implement the board preview, operation selection, question/incorrect/correct states, retry, replay, and return-to-board navigation.
4. **Answer input:** add transparent answer hotspots and number-key input; validate answers using operation data rather than UI position alone.
5. **Automated checks:** test the arithmetic answer rules and state transitions in headless Godot.
6. **Runtime check:** import and run the Godot project headlessly; then capture/inspect the running UI if the desktop is available.
7. **Documentation:** provide setup/run instructions, implementation results, completed/failed checks, and remaining limitations.
8. **Git:** commit the project and progress documents to the supplied GitHub repository; report the commit and push result.

## 6. Completion criteria

- Godot 4.6.1 opens the project with no parse/import errors.
- The board preview uses the original full reference image.
- All nine gameplay states use the exact source-image panel crops.
- All three operations can be selected and completed through wrong and correct paths.
- Mouse hotspots and keyboard answer input both select the intended answer.
- Wrong answers do not award success; correct answers reach the success panel.
- The app can return to the board and replay an operation.
- Tests cover all three correct answers and wrong-answer behavior.
- README and progress log tell the team how to run the app and what is/isn't implemented.

## 7. Scope boundaries

- Godot only for this implementation; no React project or second-framework comparison.
- No changes to the existing `gd-math-config` project.
- No generated/repainted art; the provided image is used as the exact visual source.
- No dynamic question generation, level progression, localization, audio, analytics, accounts, or production packaging in this first implementation.
- The broader measurement/fill-level addition activity is deferred unless requested as a later scope.
