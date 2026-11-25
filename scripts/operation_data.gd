extends RefCounted

const ORDER: Array[String] = ["subtraction", "multiplication", "division"]

static func all_operations() -> Dictionary:
	return {
		"subtraction": {
			"label": "Subtraction",
			"choices": [4, 5, 6],
			"answer": 5,
			"panels": [
				"res://assets/panels/subtraction_question.png",
				"res://assets/panels/subtraction_incorrect.png",
				"res://assets/panels/subtraction_correct.png"
			],
			"hotspots": [
				[[0.22, 0.72], [0.41, 0.72], [0.62, 0.72]],
				[[0.24, 0.72], [0.44, 0.72], [0.64, 0.72]],
				[[0.19, 0.75], [0.40, 0.75], [0.60, 0.75]]
			]
		},
		"multiplication": {
			"label": "Multiplication",
			"choices": [5, 6, 7],
			"answer": 6,
			"panels": [
				"res://assets/panels/multiplication_question.png",
				"res://assets/panels/multiplication_incorrect.png",
				"res://assets/panels/multiplication_correct.png"
			],
			"hotspots": [
				[[0.22, 0.76], [0.44, 0.76], [0.65, 0.76]],
				[[0.24, 0.76], [0.44, 0.76], [0.64, 0.76]],
				[[0.19, 0.78], [0.42, 0.78], [0.63, 0.78]]
			]
		},
		"division": {
			"label": "Division",
			"choices": [2, 3, 4],
			"answer": 3,
			"panels": [
				"res://assets/panels/division_question.png",
				"res://assets/panels/division_incorrect.png",
				"res://assets/panels/division_correct.png"
			],
			"hotspots": [
				[[0.22, 0.84], [0.44, 0.84], [0.66, 0.84]],
				[[0.24, 0.82], [0.45, 0.82], [0.65, 0.82]],
				[[0.24, 0.82], [0.45, 0.82], [0.65, 0.82]]
			]
		}
	}

static func operation_ids() -> Array[String]:
	return ORDER.duplicate()

static func get_operation(operation_id: String) -> Dictionary:
	var operations := all_operations()
	if not operations.has(operation_id):
		return {}
	return operations[operation_id].duplicate(true)
