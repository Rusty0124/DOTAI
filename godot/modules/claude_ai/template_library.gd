@tool
extends RefCounted

## Template Library for Common Game Patterns
## Provides pre-built templates for common game development patterns

class_name TemplateLibrary

## Template structure
class Template:
	var name: String
	var description: String
	var category: String
	var files: Array[Dictionary] = []
	var variables: Dictionary = {}
	
	func _init(p_name: String, p_description: String, p_category: String):
		name = p_name
		description = p_description
		category = p_category

## Available templates
static var templates: Dictionary = {}

## Initialize templates
static func _initialize_templates():
	if templates.size() > 0:
		return
	
	# 2D Platformer Template
	var platformer = Template.new("2D Platformer", "Complete 2D platformer with player movement, jumping, and basic enemies", "Platformer")
	platformer.files = [
		{
			"path": "scripts/player/player.gd",
			"content": """extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
@export var acceleration: float = 2000.0
@export var friction: float = 2000.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
	
	# Handle horizontal movement
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	move_and_slide()
"""
		},
		{
			"path": "scripts/enemies/basic_enemy.gd",
			"content": """extends CharacterBody2D

@export var speed: float = 100.0
@export var health: int = 100

var direction: int = -1

func _physics_process(delta: float) -> void:
	velocity.x = direction * speed
	
	# Simple collision detection
	if is_on_wall():
		direction *= -1
	
	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
"""
		}
	]
	templates["2d_platformer"] = platformer
	
	# Top-Down Shooter Template
	var shooter = Template.new("Top-Down Shooter", "Top-down shooter with player movement, shooting, and enemies", "Shooter")
	shooter.files = [
		{
			"path": "scripts/player/player.gd",
			"content": """extends CharacterBody2D

@export var speed: float = 200.0
@export var rotation_speed: float = 5.0

var velocity_vector: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	# Movement
	var input_vector = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()
	
	velocity_vector = input_vector * speed
	move_and_slide()
	
	# Rotation towards mouse
	var mouse_pos = get_global_mouse_position()
	look_at(mouse_pos)
"""
		}
	]
	templates["top_down_shooter"] = shooter
	
	# Inventory System Template
	var inventory = Template.new("Inventory System", "Complete inventory system with items, UI, and drag-and-drop", "System")
	inventory.files = [
		{
			"path": "scripts/inventory/inventory.gd",
			"content": """extends Node

signal item_added(item: Dictionary)
signal item_removed(item: Dictionary)
signal inventory_changed()

var items: Array[Dictionary] = []
var max_size: int = 20

func add_item(item: Dictionary) -> bool:
	if items.size() >= max_size:
		return false
	
	items.append(item)
	item_added.emit(item)
	inventory_changed.emit()
	return true

func remove_item(item: Dictionary) -> bool:
	var index = items.find(item)
	if index >= 0:
		items.remove_at(index)
		item_removed.emit(item)
		inventory_changed.emit()
		return true
	return false

func has_item(item_name: String) -> bool:
	for item in items:
		if item.get("name") == item_name:
			return true
	return false
"""
		}
	]
	templates["inventory_system"] = inventory
	
	# State Machine Template
	var state_machine = Template.new("State Machine", "Generic state machine for game objects", "Pattern")
	state_machine.files = [
		{
			"path": "scripts/state_machine/state_machine.gd",
			"content": """extends Node

signal state_changed(old_state: String, new_state: String)

var current_state: String = ""
var states: Dictionary = {}

func add_state(state_name: String, state_node: Node) -> void:
	states[state_name] = state_node
	add_child(state_node)

func change_state(new_state: String) -> void:
	if new_state == current_state:
		return
	
	if not states.has(new_state):
		push_error("State not found: " + new_state)
		return
	
	var old_state = current_state
	if states.has(current_state):
		states[current_state].exit()
	
	current_state = new_state
	states[current_state].enter()
	state_changed.emit(old_state, new_state)

func _ready() -> void:
	if states.size() > 0:
		var first_state = states.keys()[0]
		change_state(first_state)
"""
		},
		{
			"path": "scripts/state_machine/state.gd",
			"content": """extends Node

class_name State

signal finished(next_state: String)

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(delta: float) -> void:
	pass

func handle_input(event: InputEvent) -> void:
	pass
"""
		}
	]
	templates["state_machine"] = state_machine
	
	# Game Manager Template
	var game_manager = Template.new("Game Manager", "Singleton game manager for game state, score, and scene management", "Manager")
	game_manager.files = [
		{
			"path": "scripts/managers/game_manager.gd",
			"content": """extends Node

signal score_changed(new_score: int)
signal game_over()
signal game_won()

var score: int = 0
var lives: int = 3
var is_game_over: bool = false

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

func lose_life() -> void:
	lives -= 1
	if lives <= 0:
		end_game(false)

func end_game(won: bool) -> void:
	if is_game_over:
		return
	
	is_game_over = true
	if won:
		game_won.emit()
	else:
		game_over.emit()

func restart_game() -> void:
	score = 0
	lives = 3
	is_game_over = false
	get_tree().reload_current_scene()
"""
		}
	]
	templates["game_manager"] = game_manager

## Get all templates
static func get_all_templates() -> Array:
	_initialize_templates()
	return templates.values()

## Get templates by category
static func get_templates_by_category(category: String) -> Array:
	_initialize_templates()
	var result = []
	for template in templates.values():
		if template.category == category:
			result.append(template)
	return result

## Get template by name
static func get_template(template_id: String) -> Template:
	_initialize_templates()
	return templates.get(template_id, null)

## Apply template to project
static func apply_template(template_id: String, project_root: String = "res://", variables: Dictionary = {}) -> Dictionary:
	var template = get_template(template_id)
	if template == null:
		return {"success": false, "error": "Template not found: " + template_id}
	
	var result = {
		"success": true,
		"files_created": [],
		"files_failed": []
	}
	
	for file_data in template.files:
		var file_path = file_data.path
		var content = file_data.content
		
		# Replace variables in content
		for var_name in variables:
			content = content.replace("{{" + var_name + "}}", str(variables[var_name]))
		
		# Ensure full path
		if not file_path.begins_with("res://"):
			file_path = project_root + "/" + file_path
		
		# Write file
		var write_result = FileWriter.write_file(file_path, content)
		if write_result.success:
			result.files_created.append(file_path)
		else:
			result.files_failed.append({"path": file_path, "error": write_result.error})
	
	return result

## Get template categories
static func get_categories() -> Array:
	_initialize_templates()
	var categories = []
	for template in templates.values():
		if not categories.has(template.category):
			categories.append(template.category)
	return categories
