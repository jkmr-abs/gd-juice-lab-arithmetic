extends SceneTree

const OperationData = preload("res://scripts/operation_data.gd")
const GameLogic = preload("res://scripts/game_logic.gd")

func _initialize() -> void:
	var operations := OperationData.all_operations()
	assert(operations.size() == 3, "Expected subtraction, multiplication, and division")
	var expected_answers := {"subtraction": 5, "multiplication": 6, "division": 3}

	for operation_id in OperationData.operation_ids():
		var operation: Dictionary = operations[operation_id]
		var answer: int = expected_answers[operation_id]
		assert(int(operation["answer"]) == answer, "%s answer mismatch" % operation_id)
		assert(answer in operation["choices"], "%s correct choice is missing" % operation_id)
		assert(not str(operation["story"]).is_empty(), "%s needs a visual prompt" % operation_id)
		assert(GameLogic.evaluate_answer(answer, answer) == "correct")
		assert(GameLogic.evaluate_answer(int(operation["incorrect_answer"]), answer) == "incorrect")
		assert(GameLogic.next_feedback_state("question", int(operation["incorrect_answer"]), answer) == "incorrect")
		assert(GameLogic.next_feedback_state("incorrect", answer, answer) == "correct")

	var main_scene := load("res://scenes/main_3d.tscn") as PackedScene
	assert(main_scene != null, "Main Godot scene is missing")
	var scene_root := main_scene.instantiate()
	assert(scene_root is Node3D, "Main scene must be an actual 3D scene")
	scene_root.free()

	for model_path in [
		"res://assets/models/orange.glb",
		"res://assets/models/basket.glb",
		"res://assets/models/glass_jar.glb",
		"res://assets/models/glass_cup.glb"
	]:
		assert(ResourceLoader.exists(model_path), "Missing actual 3D model: %s" % model_path)

	print("PASS: Node3D main scene, 3 operation rules, feedback transitions, and 4 imported 3D props")
	quit(0)
