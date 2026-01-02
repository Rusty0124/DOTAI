@tool
extends Node

## AI Game Engine Core
## Complete game engine functionality for DotAI

class_name GameEngineCore

signal game_created(game_info: Dictionary)
signal scene_created(scene_path: String)
signal project_initialized()

## Initialize a new game project
static func initialize_game_project(project_name: String, game_type: String = "2d") -> Dictionary:
	var result = {
		"success": false,
		"error": "",
		"files_created": [],
		"main_scene": ""
	}
	
	# Create project structure
	var directories = [
		"scripts/player",
		"scripts/enemies",
		"scripts/managers",
		"scripts/ui",
		"scripts/collectibles",
		"scenes",
		"scenes/player",
		"scenes/enemies",
		"scenes/ui",
		"resources",
		"assets/sprites",
		"assets/sounds",
		"assets/music"
	]
	
	for dir_path in directories:
		var dir = DirAccess.open("res://")
		if dir != null:
			if not dir.dir_exists(dir_path):
				var error = dir.make_dir_recursive(dir_path)
				if error != OK:
					result.error = "Failed to create directory: " + dir_path
					return result
	
	# Create main scene based on game type
	match game_type.to_lower():
		"2d", "2d_platformer", "platformer":
			result.main_scene = _create_2d_platformer_main_scene(project_name)
		"3d", "3d_game":
			result.main_scene = _create_3d_main_scene(project_name)
		"top_down", "top_down_shooter":
			result.main_scene = _create_top_down_main_scene(project_name)
		_:
			result.main_scene = _create_default_main_scene(project_name)
	
	result.files_created.append(result.main_scene)
	result.success = true
	
	return result

## Create 2D platformer main scene
static func _create_2d_platformer_main_scene(project_name: String) -> String:
	var scene_path = "scenes/main.tscn"
	var scene_content = """[gd_scene load_steps=2 format=3 uid="uid://main_scene"]

[ext_resource type="Script" path="res://scripts/managers/game_manager.gd" id="1"]

[node name="Main" type="Node2D"]
script = ExtResource("1")

[node name="World" type="Node2D" parent="."]

[node name="UI" type="Control" parent="."]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2

[node name="HUD" type="Label" parent="UI"]
layout_mode = 1
anchors_preset = 2
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 20.0
offset_top = -40.0
offset_right = 200.0
offset_bottom = -10.0
text = "Score: 0"
"""
	
	var file = FileAccess.open("res://" + scene_path, FileAccess.WRITE)
	if file != null:
		file.store_string(scene_content)
		file.close()
	
	return scene_path

## Create 3D main scene
static func _create_3d_main_scene(project_name: String) -> String:
	var scene_path = "scenes/main.tscn"
	var scene_content = """[gd_scene load_steps=2 format=3 uid="uid://main_scene_3d"]

[ext_resource type="Script" path="res://scripts/managers/game_manager.gd" id="1"]

[node name="Main" type="Node3D"]
script = ExtResource("1")

[node name="World" type="Node3D" parent="."]

[node name="Camera3D" type="Camera3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 0.866025, 0.5, 0, -0.5, 0.866025, 0, 5, 10)
"""
	
	var file = FileAccess.open("res://" + scene_path, FileAccess.WRITE)
	if file != null:
		file.store_string(scene_content)
		file.close()
	
	return scene_path

## Create top-down main scene
static func _create_top_down_main_scene(project_name: String) -> String:
	var scene_path = "scenes/main.tscn"
	var scene_content = """[gd_scene load_steps=2 format=3 uid="uid://main_scene_topdown"]

[ext_resource type="Script" path="res://scripts/managers/game_manager.gd" id="1"]

[node name="Main" type="Node2D"]
script = ExtResource("1")

[node name="World" type="Node2D" parent="."]

[node name="Camera2D" type="Camera2D" parent="."]
"""
	
	var file = FileAccess.open("res://" + scene_path, FileAccess.WRITE)
	if file != null:
		file.store_string(scene_content)
		file.close()
	
	return scene_path

## Create default main scene
static func _create_default_main_scene(project_name: String) -> String:
	return _create_2d_platformer_main_scene(project_name)

## Set main scene in project settings
static func set_main_scene(scene_path: String) -> bool:
	var project_settings = ProjectSettings.get_singleton()
	if project_settings == null:
		return false
	
	# Set application/run/main_scene
	project_settings.set_setting("application/run/main_scene", "res://" + scene_path)
	project_settings.save()
	
	return true

## Create input map for common game actions
static func setup_input_map() -> Dictionary:
	var input_map = {
		"move_left": KEY_A,
		"move_right": KEY_D,
		"move_up": KEY_W,
		"move_down": KEY_S,
		"jump": KEY_SPACE,
		"shoot": MOUSE_BUTTON_LEFT,
		"interact": KEY_E
	}
	
	var project_settings = ProjectSettings.get_singleton()
	if project_settings == null:
		return {"success": false, "error": "ProjectSettings not available"}
	
	# Add input actions
	for action_name in input_map:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			var event = InputEventKey.new()
			event.keycode = input_map[action_name]
			InputMap.action_add_event(action_name, event)
	
	project_settings.save()
	return {"success": true, "actions_created": input_map.keys()}

## Verify game is playable
static func verify_game_playable() -> Dictionary:
	var result = {
		"playable": false,
		"issues": [],
		"main_scene": "",
		"has_player": false,
		"has_scene": false
	}
	
	# Check for main scene
	var main_scene_path = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_scene_path != "":
		result.main_scene = main_scene_path
		result.has_scene = true
		
		# Try to load and check scene
		var scene = load(main_scene_path)
		if scene != null:
			result.playable = true
		else:
			result.issues.append("Main scene file not found or invalid")
	else:
		result.issues.append("No main scene set in project settings")
	
	# Check for player script
	var player_script = "scripts/player/player.gd"
	if FileAccess.file_exists("res://" + player_script):
		result.has_player = true
	else:
		result.issues.append("Player script not found")
	
	return result

## Create complete game from description
func create_complete_game(description: String, api_handler: Node) -> void:
	var prompt = f"""Create a COMPLETE, PLAYABLE game based on this description:

{description}

REQUIREMENTS:
1. Create ALL necessary files (scripts, scenes, resources)
2. Set up proper project structure
3. Create a main scene that can be run immediately
4. Include player controller with movement
5. Add game manager for state management
6. Create UI/HUD elements
7. Make the game fully playable - user should be able to press PLAY and it works

Generate COMPLETE code with file markers (# File: path/to/file.ext) for ALL files needed."""
	
	var params = {
		"prompt": prompt,
		"include_codebase": true,
		"is_conversation": false
	}
	
	if api_handler.has_method("send_request"):
		api_handler.send_request(params)

## Post-process generated files
static func post_process_generated_files(files_created: Array) -> Dictionary:
	var result = {
		"success": true,
		"main_scene_set": false,
		"input_map_created": false,
		"issues": []
	}
	
	# Find main scene
	var main_scene = ""
	for file_path in files_created:
		if file_path.ends_with("main.tscn") or file_path.ends_with("main_scene.tscn"):
			main_scene = file_path
			break
	
	# If no main scene found, check for any scene file
	if main_scene == "":
		for file_path in files_created:
			if file_path.ends_with(".tscn"):
				main_scene = file_path
				break
	
	# Set main scene if found
	if main_scene != "":
		if set_main_scene(main_scene):
			result.main_scene_set = true
		else:
			result.issues.append("Failed to set main scene")
	
	# Setup input map
	var input_result = setup_input_map()
	if input_result.success:
		result.input_map_created = true
	
	return result
