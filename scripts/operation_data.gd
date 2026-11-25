extends RefCounted

const ORDER: Array[String] = ["subtraction", "multiplication", "division"]

static func all_operations() -> Dictionary:
	return {
		"subtraction": {
			"label": "Subtraction",
			"equation": "7 − 2 = ?",
			"story": "Take away two oranges. How many are left?",
			"choices": [4, 5, 6],
			"answer": 5,
			"incorrect_answer": 4,
			"explanation": "Take 2 away from 7. Five oranges remain.",
			"success": "7 − 2 = 5! Great work."
		},
		"multiplication": {
			"label": "Multiplication",
			"equation": "3 × 2 = ?",
			"story": "Count three baskets with two oranges in each.",
			"choices": [5, 6, 7],
			"answer": 6,
			"incorrect_answer": 5,
			"explanation": "Three groups of 2 make 6 oranges.",
			"success": "3 × 2 = 6! Great work."
		},
		"division": {
			"label": "Division",
			"equation": "6 ÷ 2 = ?",
			"story": "Share six orange pieces equally between two cups.",
			"choices": [2, 3, 4],
			"answer": 3,
			"incorrect_answer": 2,
			"explanation": "Share 6 equally into 2 cups. Each cup gets 3.",
			"success": "6 ÷ 2 = 3! Great work."
		}
	}

static func operation_ids() -> Array[String]:
	return ORDER.duplicate()

static func get_operation(operation_id: String) -> Dictionary:
	var operations := all_operations()
	if not operations.has(operation_id):
		return {}
	return operations[operation_id].duplicate(true)
