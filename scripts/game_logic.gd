extends RefCounted

static func evaluate_answer(selected_answer: int, expected_answer: int) -> String:
	return "correct" if selected_answer == expected_answer else "incorrect"

static func next_feedback_state(current_state: String, selected_answer: int, expected_answer: int) -> String:
	if current_state == "correct":
		return "correct"
	return evaluate_answer(selected_answer, expected_answer)
