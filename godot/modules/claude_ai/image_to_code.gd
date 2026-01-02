@tool
extends Node

## Image to Code Generator
## Converts screenshots/mockups to code

class_name ImageToCode

signal code_generated(file_paths: Array)
signal generation_error(error: String)

var api_handler: Node = null

## Convert image to code
func convert_image_to_code(image_path: String, description: String = "") -> void:
	if api_handler == null:
		generation_error.emit("API handler not set")
		return
	
	# Load image
	var image = Image.new()
	var error = image.load(image_path)
	if error != OK:
		generation_error.emit("Failed to load image: " + str(error))
		return
	
	# Convert image to base64 for API
	var image_texture = ImageTexture.create_from_image(image)
	var png_data = image.save_png_to_buffer()
	var base64_image = Marshalls.raw_to_base64(png_data)
	
	# Build prompt
	var prompt = "Analyze this image and generate Godot code (GDScript, scenes, resources) based on what you see."
	if description != "":
		prompt += "\n\nAdditional context: " + description
	prompt += "\n\nGenerate complete, production-ready code with proper file markers."
	
	# For vision-capable models, include image in request
	# This is a simplified version - real implementation would use vision API
	var params = {
		"prompt": prompt,
		"image_data": base64_image,
		"include_codebase": false
	}
	
	# Send to API handler
	if api_handler.has_method("send_request"):
		api_handler.send_request(params)
	else:
		generation_error.emit("API handler does not support image requests")

## Analyze UI mockup and generate UI code
func generate_ui_from_mockup(image_path: String, ui_type: String = "Control") -> void:
	var description = f"Generate a {ui_type} UI based on this mockup. Include all UI elements, layouts, and styling."
	convert_image_to_code(image_path, description)

## Analyze game screenshot and generate game code
func generate_game_from_screenshot(image_path: String, game_type: String = "") -> void:
	var description = f"Analyze this game screenshot and generate the game code. Game type: {game_type}"
	convert_image_to_code(image_path, description)

## Set API handler
func set_api_handler(handler: Node) -> void:
	api_handler = handler
