extends Node3D

const OperationData = preload("res://scripts/operation_data.gd")
const GameLogic = preload("res://scripts/game_logic.gd")

const ORANGE_MODEL := "res://assets/models/orange.glb"
const BASKET_MODEL := "res://assets/models/basket.glb"
const JAR_MODEL := "res://assets/models/glass_jar.glb"
const CUP_MODEL := "res://assets/models/glass_cup.glb"
const VIEW_SIZE := Vector2(1280.0, 960.0)

var _camera: Camera3D
var _content_root: Node3D
var _hud: Control
var _equation_label: Label
var _story_label: Label
var _feedback_label: Label
var _instruction_label: Label
var _star_label: Label
var _juice_fill: MeshInstance3D
var _star_meshes: Array[MeshInstance3D] = []
var _answer_areas: Array[Area3D] = []
var _demo_items: Array[Node3D] = []
var _division_slices: Array[Node3D] = []
var _operation_id := "subtraction"
var _operation: Dictionary = {}
var _phase := "question"
var _stars := 0
var _answer_awarded := false
var _last_wrong_answer := -1

func _ready() -> void:
	_create_environment()
	_create_static_world()
	_create_hud()
	_select_operation("subtraction")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_show_board_hint()
		elif event.keycode == KEY_R:
			_select_operation(_operation_id)
		elif _phase != "correct" and event.keycode >= KEY_1 and event.keycode <= KEY_3:
			var choice_index := int(event.keycode - KEY_1)
			var choices: Array = _operation.get("choices", [])
			if choice_index < choices.size():
				_submit_answer(int(choices[choice_index]))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pick_3d_answer(event.position)

func _create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#4f9ed0")
	sky_material.sky_horizon_color = Color("#d8f4ff")
	sky_material.ground_bottom_color = Color("#284b2f")
	sky_material.ground_horizon_color = Color("#7fbd67")
	sky_material.sun_angle_max = 18.0
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.42
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.92
	environment.glow_enabled = true
	environment.glow_intensity = 0.08
	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.name = "Warm afternoon sunlight"
	sunlight.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sunlight.light_color = Color("#fff0d0")
	sunlight.light_energy = 0.95
	sunlight.shadow_enabled = true
	sunlight.directional_shadow_max_distance = 35.0
	add_child(sunlight)

	var fill_light := OmniLight3D.new()
	fill_light.name = "Soft fill"
	fill_light.position = Vector3(1.5, 7.0, 8.0)
	fill_light.light_color = Color("#d5edff")
	fill_light.light_energy = 0.18
	fill_light.omni_range = 20.0
	add_child(fill_light)

	_camera = Camera3D.new()
	_camera.name = "ProductCamera"
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 10.8
	_camera.position = Vector3(0.0, 8.8, 17.0)
	add_child(_camera)
	_camera.look_at(Vector3(0.0, 1.8, 0.0), Vector3.UP)
	_camera.current = true

func _create_static_world() -> void:
	var ground_material := _material(Color("#b6c6a0"), 0.94)
	ground_material.albedo_texture = load("res://assets/textures/garden_grass.png")
	ground_material.uv1_triplanar = true
	ground_material.uv1_scale = Vector3(0.22, 0.22, 0.22)
	_create_box("Garden ground", Vector3(100.0, 0.5, 100.0), Vector3(0.0, -0.55, 0.0), ground_material, self)
	_create_garden()
	_create_workbench()
	_create_character()
	_content_root = Node3D.new()
	_content_root.name = "DynamicGameObjects"
	add_child(_content_root)

func _create_garden() -> void:
	var trunk_material := _material(Color("#68422b"), 0.86)
	var leaf_materials := [
		_material(Color("#458641"), 0.83),
		_material(Color("#5b9b48"), 0.86),
		_material(Color("#2f713c"), 0.9)
	]
	var tree_positions := [
		Vector3(-10.0, 0.0, -7.0), Vector3(-7.7, 0.0, -8.0), Vector3(-5.3, 0.0, -8.5),
		Vector3(5.2, 0.0, -8.2), Vector3(7.7, 0.0, -7.7), Vector3(10.2, 0.0, -6.7)
	]
	for index in range(tree_positions.size()):
		var tree_root := Node3D.new()
		tree_root.position = tree_positions[index]
		add_child(tree_root)
		var height := 2.6 + float(index % 3) * 0.48
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.18
		trunk.bottom_radius = 0.34
		trunk.height = height
		trunk.radial_segments = 12
		_add_mesh(tree_root, trunk, trunk_material, Vector3(0.0, height * 0.5, 0.0), Vector3.ONE, "TreeTrunk")
		for cluster in range(4):
			var crown := SphereMesh.new()
			crown.radius = 0.92 - float(cluster % 2) * 0.12
			crown.height = 1.72 - float(cluster % 2) * 0.16
			var offset := Vector3(
				float((cluster % 2) * 2 - 1) * 0.47,
				height * 0.72 + float(cluster / 2) * 0.62,
				float((cluster / 2) * 2 - 1) * 0.32
			)
			_add_mesh(tree_root, crown, leaf_materials[(index + cluster) % leaf_materials.size()], offset, Vector3.ONE, "TreeCanopy")

	var bush_material := _material(Color("#3e7c39"), 0.9)
	for index in range(13):
		var x := -10.0 + float(index) * 1.65
		if absf(x) < 5.0:
			continue
		var bush := SphereMesh.new()
		bush.radius = 0.65 + float(index % 3) * 0.12
		bush.height = 0.95
		_add_mesh(self, bush, bush_material, Vector3(x, 0.14, -4.8), Vector3.ONE, "GardenBush")

func _create_workbench() -> void:
	var wood_dark := _wood_material(Color("#8f684c"))
	var wood_mid := _wood_material(Color("#b07a4e"))
	var wood_light := _wood_material(Color("#d2a16a"))
	var table_top := _wood_material(Color("#c3915f"))
	_create_box("Workbench top", Vector3(14.0, 0.52, 6.0), Vector3(0.0, 0.12, 0.0), wood_dark, self)
	_create_box("Workbench surface", Vector3(13.65, 0.13, 5.66), Vector3(0.0, 0.40, 0.0), table_top, self)
	for x in [-5.9, 5.9]:
		for z in [-2.25, 2.25]:
			var leg := CylinderMesh.new()
			leg.top_radius = 0.27
			leg.bottom_radius = 0.34
			leg.height = 2.0
			leg.radial_segments = 12
			_add_mesh(self, leg, wood_dark, Vector3(x, -0.92, z), Vector3.ONE, "WorkbenchLeg")
	_create_box("Front apron", Vector3(13.4, 0.65, 0.22), Vector3(0.0, -0.34, 2.80), wood_mid, self)
	_create_box("Left apron", Vector3(0.22, 0.60, 5.35), Vector3(-6.55, -0.34, 0.0), wood_mid, self)
	_create_box("Right apron", Vector3(0.22, 0.60, 5.35), Vector3(6.55, -0.34, 0.0), wood_mid, self)

	# A shallow raised tray makes the answer fruits feel grounded in the scene.
	_create_box("Fruit tray base", Vector3(12.65, 0.16, 2.45), Vector3(0.0, 0.54, 1.03), wood_mid, self)
	_create_box("Tray front rim", Vector3(12.75, 0.43, 0.17), Vector3(0.0, 0.74, 2.20), wood_light, self)
	_create_box("Tray back rim", Vector3(12.75, 0.34, 0.15), Vector3(0.0, 0.70, -0.13), wood_dark, self)
	_create_box("Tray left rim", Vector3(0.17, 0.38, 2.38), Vector3(-6.28, 0.72, 1.02), wood_light, self)
	_create_box("Tray right rim", Vector3(0.17, 0.38, 2.38), Vector3(6.28, 0.72, 1.02), wood_light, self)
	for line in range(7):
		var z := -2.45 + float(line) * 0.79
		_create_box("Table grain plank %02d" % line, Vector3(13.45, 0.012, 0.025), Vector3(0.0, 0.472, z), wood_light if line % 2 == 0 else wood_mid, self)

func _create_character() -> void:
	var character := Node3D.new()
	character.name = "3D Orange Scientist"
	character.position = Vector3(-5.25, 0.0, -0.08)
	add_child(character)
	var white_coat := _material(Color("#f5f2e8"), 0.66)
	var blue := _material(Color("#236fbd"), 0.3, 0.05)
	var white := _material(Color.WHITE, 0.28)
	var black := _material(Color("#1f2630"), 0.22)
	var head := _instance_model(ORANGE_MODEL, character, Vector3(0.0, 1.95, 0.0), Vector3(1.23, 1.23, 1.23), "ScientistOrangeHead")
	var coat := CapsuleMesh.new()
	coat.radius = 0.54
	coat.height = 1.60
	_add_mesh(character, coat, white_coat, Vector3(0.0, 0.72, -0.12), Vector3(1.05, 1.0, 0.82), "LabCoat")
	for side in [-1.0, 1.0]:
		var arm := CapsuleMesh.new()
		arm.radius = 0.19
		arm.height = 0.88
		var arm_node := _add_mesh(character, arm, white_coat, Vector3(side * 0.67, 0.96, 0.02), Vector3.ONE, "CoatSleeve")
		arm_node.rotation.z = side * -0.72
		var eye_white := SphereMesh.new()
		eye_white.radius = 0.19
		eye_white.height = 0.38
		_add_mesh(character, eye_white, white, Vector3(side * 0.25, 2.02, 0.66), Vector3.ONE, "EyeWhite")
		var pupil := SphereMesh.new()
		pupil.radius = 0.085
		pupil.height = 0.17
		_add_mesh(character, pupil, black, Vector3(side * 0.25 + 0.035, 2.00, 0.825), Vector3.ONE, "Pupil")
		var glasses := _create_ring_mesh(0.22, 0.285, 48)
		blue.cull_mode = BaseMaterial3D.CULL_DISABLED
		_add_mesh(character, glasses, blue, Vector3(side * 0.25, 2.02, 0.78), Vector3.ONE, "GlassesFrame")
	var bridge := BoxMesh.new()
	bridge.size = Vector3(0.18, 0.065, 0.055)
	_add_mesh(character, bridge, blue, Vector3(0.0, 2.02, 0.72), Vector3.ONE, "GlassesBridge")
	var smile := SphereMesh.new()
	smile.radius = 0.12
	smile.height = 0.08
	_add_mesh(character, smile, black, Vector3(0.0, 1.62, 0.70), Vector3(1.25, 0.55, 0.36), "Smile")
	if head == null:
		push_warning("Orange scientist model could not be loaded")

func _create_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.anchor_right = 1.0
	_hud.anchor_bottom = 1.0
	_hud.offset_right = 0.0
	_hud.offset_bottom = 0.0
	layer.add_child(_hud)

	var top_panel := ColorRect.new()
	top_panel.color = Color(0.20, 0.11, 0.07, 0.83)
	top_panel.position = Vector2(22.0, 18.0)
	top_panel.size = Vector2(1236.0, 150.0)
	_hud.add_child(top_panel)

	_add_hud_label("JUICE LAB", Rect2(42.0, 24.0, 220.0, 44.0), 29, Color("#ffe49a"), HORIZONTAL_ALIGNMENT_LEFT)
	_add_hud_label("3D ARITHMETIC LAB", Rect2(44.0, 66.0, 300.0, 28.0), 16, Color("#f8ead2"), HORIZONTAL_ALIGNMENT_LEFT)

	var operations := OperationData.operation_ids()
	var x := 660.0
	for operation_id in operations:
		var data := OperationData.get_operation(operation_id)
		var button := _make_hud_button(str(data["label"]), Rect2(x, 31.0, 180.0, 45.0))
		button.pressed.connect(_select_operation.bind(operation_id))
		x += 190.0

	_equation_label = _add_hud_label("", Rect2(300.0, 78.0, 680.0, 52.0), 38, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_story_label = _add_hud_label("", Rect2(250.0, 132.0, 780.0, 28.0), 18, Color("#fff3d8"), HORIZONTAL_ALIGNMENT_CENTER)
	_feedback_label = _add_hud_label("", Rect2(275.0, 770.0, 730.0, 48.0), 25, Color("#fff3d8"), HORIZONTAL_ALIGNMENT_CENTER)
	_instruction_label = _add_hud_label("Click a numbered 3D orange. Keyboard: press the matching answer number.  R: restart.", Rect2(110.0, 824.0, 1060.0, 36.0), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_star_label = _add_hud_label("JUICE JAR   ☆  ☆  ☆", Rect2(870.0, 76.0, 340.0, 40.0), 20, Color("#ffe49a"), HORIZONTAL_ALIGNMENT_RIGHT)

	var reset_button := _make_hud_button("Restart level", Rect2(520.0, 884.0, 240.0, 50.0))
	reset_button.pressed.connect(_restart_level)

func _select_operation(operation_id: String) -> void:
	var data := OperationData.get_operation(operation_id)
	if data.is_empty():
		return
	_operation_id = operation_id
	_operation = data
	_phase = "question"
	_answer_awarded = false
	_last_wrong_answer = -1
	_stars = 0
	_clear_dynamic_content()
	_build_jar_and_reward()
	_build_character_answer_choices()
	_build_operation_demonstration()
	_update_hud()

func _build_jar_and_reward() -> void:
	var jar := _instance_model(JAR_MODEL, _content_root, Vector3(5.25, 0.60, 0.00), Vector3(1.0, 1.0, 1.0), "RewardJar")
	if jar == null:
		return
	var juice_material := _material(Color("#f99a24"), 0.22)
	juice_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	juice_material.albedo_color.a = 0.82
	var juice_mesh := CylinderMesh.new()
	juice_mesh.top_radius = 0.48
	juice_mesh.bottom_radius = 0.58
	juice_mesh.height = 0.68
	juice_mesh.radial_segments = 48
	_juice_fill = _add_mesh(_content_root, juice_mesh, juice_material, Vector3(5.25, 0.98, 0.03), Vector3(1.0, 0.50, 1.0), "JuiceFill")
	for index in range(3):
		var star := _create_star_mesh(0.15, 0.065, 0.045)
		var star_material := _material(Color("#99928a"), 0.34, 0.08)
		var star_node := _add_mesh(_content_root, star, star_material, Vector3(5.78, 1.28 + index * 0.31, 0.86), Vector3.ONE, "RewardStar%d" % index)
		_star_meshes.append(star_node)

func _build_character_answer_choices() -> void:
	var choices: Array = _operation["choices"]
	var x_positions := [-3.25, -0.65, 1.95]
	for index in range(choices.size()):
		var answer := int(choices[index])
		var area := Area3D.new()
		area.name = "Clickable3DAnswer%d" % answer
		area.position = Vector3(x_positions[index], 1.17, 1.28)
		area.input_ray_pickable = true
		area.collision_layer = 1
		area.collision_mask = 1
		area.set_meta("answer_value", answer)
		_content_root.add_child(area)

		var collision := CollisionShape3D.new()
		var sphere_shape := SphereShape3D.new()
		sphere_shape.radius = 0.78
		collision.shape = sphere_shape
		collision.position.y = 0.08
		area.add_child(collision)

		var orange := _instance_model(ORANGE_MODEL, area, Vector3.ZERO, Vector3(1.0, 0.96, 1.0), "AnswerOrange")
		if orange != null:
			var number := Label3D.new()
			number.text = str(answer)
			number.font_size = 84
			number.pixel_size = 0.0075
			number.position = Vector3(0.0, -0.02, 0.72)
			number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			number.no_depth_test = true
			number.modulate = Color.WHITE
			number.outline_size = 10
			number.outline_modulate = Color("#743116")
			number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			area.add_child(number)

		_answer_areas.append(area)

func _build_operation_demonstration() -> void:
	match _operation_id:
		"subtraction":
			_build_subtraction_demo()
		"multiplication":
			_build_multiplication_demo()
		"division":
			_build_division_demo()

func _build_subtraction_demo() -> void:
	for index in range(7):
		var x := -3.1 + float(index) * 1.03
		var item := _instance_model(ORANGE_MODEL, _content_root, Vector3(x, 0.91, -1.33), Vector3(0.42, 0.42, 0.42), "SubtractCount%d" % index)
		if item != null:
			_demo_items.append(item)
	var take_away_bowl := _instance_model(BASKET_MODEL, _content_root, Vector3(4.1, 0.57, -1.15), Vector3(0.56, 0.56, 0.56), "TakeAwayBasket")
	if take_away_bowl != null:
		for index in range(2):
			var removed := _instance_model(ORANGE_MODEL, take_away_bowl, Vector3(-0.22 + index * 0.44, 0.28, 0.0), Vector3(0.36, 0.36, 0.36), "RemovedOrange")
			if removed != null:
				removed.visible = false

func _build_multiplication_demo() -> void:
	var basket_x := [-2.35, 0.0, 2.35]
	for group_index in range(3):
		var basket := _instance_model(BASKET_MODEL, _content_root, Vector3(basket_x[group_index], 0.58, -1.25), Vector3(0.72, 0.72, 0.72), "GroupBasket%d" % group_index)
		for item_index in range(2):
			var offset := -0.25 if item_index == 0 else 0.25
			var fruit := _instance_model(ORANGE_MODEL, _content_root, Vector3(basket_x[group_index] + offset, 1.02, -1.30), Vector3(0.39, 0.39, 0.39), "GroupFruit%d_%d" % [group_index, item_index])
			if fruit != null:
				_demo_items.append(fruit)
		if basket == null:
			push_warning("A multiplication basket could not be loaded")

func _build_division_demo() -> void:
	var cup_centers := [-1.55, 1.55]
	for index in range(2):
		_instance_model(CUP_MODEL, _content_root, Vector3(cup_centers[index], 0.63, -1.18), Vector3(0.86, 0.86, 0.86), "ShareCup%d" % index)
	for index in range(6):
		var x := -2.65 + float(index) * 1.06
		var slice := _create_orange_segment(Vector3(x, 1.20, -0.20), "OrangePiece%d" % index)
		_division_slices.append(slice)

func _create_orange_segment(position: Vector3, object_name: String) -> Node3D:
	var segment := Node3D.new()
	segment.name = object_name
	segment.position = position
	_content_root.add_child(segment)
	var rind_mesh := _sector_mesh(0.46, 0.58, 0.16)
	_add_mesh(segment, rind_mesh, _material(Color("#f5e5bb"), 0.66), Vector3.ZERO, Vector3.ONE, "PithAndRind")
	var flesh_mesh := _sector_mesh(0.405, 0.52, 0.13)
	_add_mesh(segment, flesh_mesh, _material(Color("#ed7415"), 0.48), Vector3(0.0, 0.0, 0.085), Vector3.ONE, "OrangeFlesh")
	var center := SphereMesh.new()
	center.radius = 0.06
	center.height = 0.08
	_add_mesh(segment, center, _material(Color("#fff1d0"), 0.62), Vector3(0.0, 0.0, 0.158), Vector3.ONE, "PithCenter")
	return segment

func _sector_mesh(radius: float, half_angle: float, depth: float) -> ArrayMesh:
	var arc_segments := 14
	var points := PackedVector2Array()
	for index in range(arc_segments + 1):
		var angle := -half_angle + (2.0 * half_angle * float(index) / float(arc_segments))
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var front_z := depth * 0.5
	var back_z := -depth * 0.5
	vertices.append(Vector3(0.0, 0.0, front_z))
	for point in points:
		vertices.append(Vector3(point.x, point.y, front_z))
	var back_center := vertices.size()
	vertices.append(Vector3(0.0, 0.0, back_z))
	for point in points:
		vertices.append(Vector3(point.x, point.y, back_z))
	for index in range(arc_segments):
		indices.append_array(PackedInt32Array([0, index + 1, index + 2]))
		indices.append_array(PackedInt32Array([back_center, back_center + index + 2, back_center + index + 1]))
	for index in range(arc_segments):
		var front_a := index + 1
		var front_b := index + 2
		var back_a := back_center + index + 1
		var back_b := back_center + index + 2
		indices.append_array(PackedInt32Array([front_a, back_a, back_b, front_a, back_b, front_b]))
	# Close both radial edges of the segment.
	var front_first := 1
	var front_last := arc_segments + 1
	var back_first := back_center + 1
	var back_last := back_center + arc_segments + 1
	indices.append_array(PackedInt32Array([0, back_center, back_first, 0, back_first, front_first]))
	indices.append_array(PackedInt32Array([0, front_last, back_last, 0, back_last, back_center]))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex_index in indices:
		surface.add_vertex(vertices[vertex_index])
	surface.generate_normals()
	return surface.commit()

func _pick_3d_answer(screen_position: Vector2) -> void:
	if _phase == "correct" or _camera == null:
		return
	var ray_origin := _camera.project_ray_origin(screen_position)
	var ray_direction := _camera.project_ray_normal(screen_position)
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 60.0)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider")
	if collider is Area3D and collider.has_meta("answer_value"):
		_submit_answer(int(collider.get_meta("answer_value")))

func _submit_answer(answer: int) -> void:
	if _phase == "correct":
		return
	var next_state: String = GameLogic.next_feedback_state(_phase, answer, int(_operation["answer"]))
	if next_state == "incorrect":
		_phase = "incorrect"
		_last_wrong_answer = answer
		_show_wrong_answer_feedback(answer)
	else:
		_phase = "correct"
		_last_wrong_answer = -1
		_award_success()
	_update_hud()

func _show_wrong_answer_feedback(answer: int) -> void:
	var selected_name := str(answer)
	_feedback_label.text = "%s is not correct. Let's use the objects to work it out." % selected_name
	_feedback_label.add_theme_color_override("font_color", Color("#ffd0b2"))
	if _operation_id == "subtraction":
		for index in range(5, _demo_items.size()):
			var item := _demo_items[index]
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(item, "position", Vector3(4.1 + (index - 5) * 0.32, 1.08, -1.15), 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(item, "scale", Vector3(0.32, 0.32, 0.32), 0.55)
	elif _operation_id == "division":
		var x_offsets := [-0.34, 0.34, 0.0]
		var y_offsets := [1.08, 1.08, 1.42]
		var z_offsets := [0.16, 0.16, 0.16]
		for index in range(_division_slices.size()):
			var cup_index := 0 if index < 3 else 1
			var local_index := index % 3
			var target_x := -1.55 if cup_index == 0 else 1.55
			var slice := _division_slices[index]
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(slice, "position", Vector3(target_x + x_offsets[local_index], y_offsets[local_index], -1.18 + z_offsets[local_index]), 0.62).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(slice, "scale", Vector3(0.56, 0.56, 0.56), 0.62).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		for index in range(3):
			var pulse := _demo_items[index * 2]
			var tween := create_tween()
			tween.tween_property(pulse, "scale", Vector3(0.48, 0.48, 0.48), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(pulse, "scale", Vector3(0.39, 0.39, 0.39), 0.22)

func _award_success() -> void:
	if _answer_awarded:
		return
	_answer_awarded = true
	_stars = 3
	_feedback_label.text = str(_operation["success"])
	_feedback_label.add_theme_color_override("font_color", Color("#b5ff9d"))
	_set_reward_stars(_stars)
	if _juice_fill != null:
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_juice_fill, "scale:y", 0.88, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(_juice_fill, "position:y", 1.16, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_create_success_sparkles()

func _set_reward_stars(count: int) -> void:
	for index in range(_star_meshes.size()):
		var material := _material(Color("#ffc83d") if index < count else Color("#99928a"), 0.32, 0.08)
		_star_meshes[index].material_override = material
	_star_label.text = "JUICE JAR   " + ("★  " if count > 0 else "☆  ") + ("★  " if count > 1 else "☆  ") + ("★" if count > 2 else "☆")

func _create_success_sparkles() -> void:
	var gold := _material(Color("#ffe66b"), 0.26, 0.12)
	for index in range(6):
		var sparkle := SphereMesh.new()
		sparkle.radius = 0.075
		sparkle.height = 0.15
		var x := -1.1 + float(index) * 0.44
		var node := _add_mesh(_content_root, sparkle, gold, Vector3(x, 2.45 + (index % 2) * 0.25, 1.0), Vector3.ONE, "SuccessSparkle")
		var tween := create_tween()
		tween.set_loops(2)
		tween.tween_property(node, "scale", Vector3(1.8, 1.8, 1.8), 0.18)
		tween.tween_property(node, "scale", Vector3.ZERO, 0.24)

func _update_hud() -> void:
	if _equation_label == null:
		return
	_equation_label.text = str(_operation["equation"])
	_story_label.text = str(_operation["story"])
	if _phase == "question":
		_feedback_label.text = ""
		_feedback_label.add_theme_color_override("font_color", Color("#fff3d8"))
	elif _phase == "incorrect":
		if _last_wrong_answer >= 0:
			_feedback_label.text = "%d is not correct. Let's use the 3D objects to work it out." % _last_wrong_answer
	elif _phase == "correct":
		_feedback_label.text = str(_operation["success"])
		_feedback_label.add_theme_color_override("font_color", Color("#b5ff9d"))
	_star_label.text = "JUICE JAR   " + ("★  " if _stars > 0 else "☆  ") + ("★  " if _stars > 1 else "☆  ") + ("★" if _stars > 2 else "☆")
	_instruction_label.text = "Click one of the numbered 3D oranges, or press the matching answer number.  R: restart level."

func _restart_level() -> void:
	_select_operation(_operation_id)

func _show_board_hint() -> void:
	_feedback_label.text = "Choose an operation from the top tabs."

func _clear_dynamic_content() -> void:
	for child in _content_root.get_children():
		_content_root.remove_child(child)
		child.queue_free()
	_answer_areas.clear()
	_demo_items.clear()
	_division_slices.clear()
	_star_meshes.clear()
	_juice_fill = null

func _create_box(name: String, size: Vector3, position: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add_mesh(parent, mesh, material, position, Vector3.ONE, name)

func _add_mesh(
	parent: Node3D,
	mesh: Mesh,
	material: Material,
	position: Vector3,
	scale: Vector3 = Vector3.ONE,
	object_name: String = "Mesh"
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = object_name
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	instance.scale = scale
	parent.add_child(instance)
	return instance

func _instance_model(path: String, parent: Node3D, position: Vector3, scale: Vector3, object_name: String) -> Node3D:
	var packed := load(path) as PackedScene
	if packed == null:
		push_warning("Could not load 3D model: %s" % path)
		return null
	var instance := packed.instantiate() as Node3D
	if instance == null:
		push_warning("3D model root is not Node3D: %s" % path)
		return null
	if path == ORANGE_MODEL:
		_style_orange_model(instance)
	instance.name = object_name
	instance.position = position
	instance.scale = scale
	parent.add_child(instance)
	return instance

func _style_orange_model(root: Node3D) -> void:
	var leaf_material := _material(Color("#2f762c"), 0.72)
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null:
			continue
		for surface_index in [2, 3]:
			if surface_index < mesh_node.mesh.get_surface_count():
				mesh_node.set_surface_override_material(surface_index, leaf_material)

func _material(color: Color, roughness: float = 0.5, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _wood_material(tint: Color) -> StandardMaterial3D:
	var material := _material(tint, 0.74)
	material.albedo_texture = load("res://assets/textures/wood_grain.png")
	material.uv1_triplanar = true
	material.uv1_scale = Vector3(0.58, 0.58, 0.58)
	material.normal_enabled = true
	material.normal_texture = load("res://assets/textures/wood_normal.png")
	material.normal_scale = 0.16
	return material

func _create_ring_mesh(inner_radius: float, outer_radius: float, segments: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		vertices.append(Vector3(cos(angle) * outer_radius, sin(angle) * outer_radius, 0.0))
		vertices.append(Vector3(cos(angle) * inner_radius, sin(angle) * inner_radius, 0.0))
	for index in range(segments):
		var base := index * 2
		var next := ((index + 1) % segments) * 2
		indices.append_array(PackedInt32Array([base, next, next + 1, base, next + 1, base + 1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _create_star_mesh(outer_radius: float, inner_radius: float, depth: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var points := PackedVector2Array()
	for index in range(10):
		var angle := -PI * 0.5 + float(index) * PI / 5.0
		var radius := outer_radius if index % 2 == 0 else inner_radius
		points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	for z in [-depth, depth]:
		for point in points:
			vertices.append(Vector3(point.x, point.y, z))
	for index in range(1, 9):
		indices.append_array(PackedInt32Array([0, index, index + 1]))
	for index in range(1, 9):
		indices.append_array(PackedInt32Array([10, 10 + index + 1, 10 + index]))
	for index in range(10):
		var next := (index + 1) % 10
		indices.append_array(PackedInt32Array([index, next, 10 + next, index, 10 + next, 10 + index]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _make_hud_button(text: String, rect: Rect2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _hud_button_style(false))
	button.add_theme_stylebox_override("hover", _hud_button_style(true))
	button.add_theme_stylebox_override("pressed", _hud_button_style(true))
	_hud.add_child(button)
	return button

func _hud_button_style(hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#87491f") if hovered else Color("#633719")
	style.border_color = Color("#e6b35c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style

func _add_hud_label(
	text: String,
	rect: Rect2,
	font_size: int,
	color: Color,
	alignment: HorizontalAlignment
) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(label)
	return label
