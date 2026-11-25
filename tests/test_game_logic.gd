extends SceneTree

const OperationData = preload("res://scripts/operation_data.gd")
const GameLogic = preload("res://scripts/game_logic.gd")

func _initialize() -> void:
	var operations := OperationData.all_operations()
	assert(operations.size() == 3, "Expected three operation examples")

	var expected_answers := {
		"subtraction": 5,
		"multiplication": 6,
		"division": 3
	}
	for operation_id in OperationData.operation_ids():
		var operation: Dictionary = operations[operation_id]
		var expected: int = expected_answers[operation_id]
		assert(int(operation["answer"]) == expected, "%s answer mismatch" % operation_id)
		assert(expected in operation["choices"], "%s answer is missing from choices" % operation_id)
		assert(operation["panels"].size() == 3, "%s must have three state panels" % operation_id)
		assert(operation["hotspots"].size() == 3, "%s must have three hotspot layouts" % operation_id)
		for panel_path in operation["panels"]:
			assert(ResourceLoader.exists(panel_path), "Missing panel asset: %s" % panel_path)
		assert(GameLogic.evaluate_answer(expected, expected) == "correct")
		assert(GameLogic.evaluate_answer(int(operation["choices"][0]), expected) == "incorrect")
		assert(GameLogic.next_feedback_state("question", int(operation["choices"][0]), expected) == "incorrect")
		assert(GameLogic.next_feedback_state("incorrect", expected, expected) == "correct")

	print("PASS: 3 operations, 9 panel assets, answer evaluation, and feedback transitions")
	quit(0)
