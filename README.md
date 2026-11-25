# GD Juice Lab Arithmetic

A Godot 4.6.1 interactive prototype based on the supplied Juice Lab arithmetic storyboard.

## Status

The first image-matching prototype is implemented. The original storyboard is used for the reference-board view and exact panel crops; answer selection moves between question, incorrect-feedback, and correct-feedback states for subtraction, multiplication, and division.

See [`docs/IMPLEMENTATION_PROGRESS.md`](docs/IMPLEMENTATION_PROGRESS.md) for completed milestones and test results, and [`docs/PROJECT_IMPLEMENTATION_PLAN.md`](docs/PROJECT_IMPLEMENTATION_PLAN.md) for scope and known limitations.

## Run the game

Install Godot 4.6.1, then from this repository folder run:

```sh
godot --path .
```

Or open this folder in the Godot editor and press **Run Project**.

## Controls

- **Board screen:** use the operation buttons or press `1`, `2`, or `3` to start Subtraction, Multiplication, or Division.
- **Question/incorrect screen:** click an answer fruit or press the matching number key.
- **Correct screen:** press `Enter` or `Space` to replay the question.
- Press `Escape` or **← Board** to return to the full reference board.
- Press `R` or **Replay question** to restart the current operation.

## Run checks

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_game_logic.gd
godot --headless --path . --quit-after 3
```

## Source references

- Design sheet: `references/math-juice-lab-arithmetic-levels-sheet.png`
- Meeting transcripts: `references/meeting-tamil-transcript.md` and `references/meeting-english-transcript.md`
