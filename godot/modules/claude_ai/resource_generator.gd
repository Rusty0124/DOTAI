@tool
extends RefCounted

## Resource File Generator
## Generates .tres resource files for Godot

class_name ResourceGenerator

## Generate a resource file (.tres)
static func generate_resource(resource_type: String, properties: Dictionary, file_path: String) -> Dictionary:
	var result = {"success": false, "error": "", "file_path": file_path}
	
	# Ensure .tres extension
	if not file_path.ends_with(".tres"):
		file_path += ".tres"
	
	# Build resource content
	var content = "[gd_resource type=\"" + resource_type + "\""
	if properties.has("uid"):
		content += " uid=\"" + properties.uid + "\""
	content += "]\n\n"
	
	# Add properties
	for key in properties:
		if key == "uid" or key == "type":
			continue
		
		var value = properties[key]
		var prop_line = _format_property(key, value)
		if prop_line != "":
			content += prop_line + "\n"
	
	# Ensure directory exists
	var dir_path = file_path.get_base_dir()
	if dir_path != "" and dir_path != "res://":
		var dir = DirAccess.open("res://")
		if dir != null:
			var current_path = "res://"
			var path_parts = dir_path.trim_prefix("res://").split("/")
			for part in path_parts:
				if part != "":
					current_path += "/" + part
					if not dir.dir_exists(current_path):
						var error = dir.make_dir(current_path)
						if error != OK:
							result.error = "Failed to create directory: " + current_path
							return result
	
	# Write file
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		result.error = "Failed to open file for writing: " + file_path
		return result
	
	file.store_string(content)
	file.close()
	
	result.success = true
	return result

## Format property for .tres file
static func _format_property(key: String, value) -> String:
	var prop_name = key.replace("_", " ").capitalize()
	
	if value is String:
		return prop_name + " = \"" + value + "\""
	elif value is int or value is float:
		return prop_name + " = " + str(value)
	elif value is bool:
		return prop_name + " = " + ("true" if value else "false")
	elif value is Vector2:
		return prop_name + " = Vector2(" + str(value.x) + ", " + str(value.y) + ")"
	elif value is Vector3:
		return prop_name + " = Vector3(" + str(value.x) + ", " + str(value.y) + ", " + str(value.z) + ")"
	elif value is Color:
		return prop_name + " = Color(" + str(value.r) + ", " + str(value.g) + ", " + str(value.b) + ", " + str(value.a) + ")"
	elif value is Array:
		var array_str = "["
		for i in range(value.size()):
			if i > 0:
				array_str += ", "
			array_str += str(value[i])
		array_str += "]"
		return prop_name + " = " + array_str
	elif value is Dictionary:
		var dict_str = "{"
		var first = true
		for k in value:
			if not first:
				dict_str += ", "
			dict_str += "\"" + str(k) + "\": " + str(value[k])
			first = false
		dict_str += "}"
		return prop_name + " = " + dict_str
	else:
		return prop_name + " = " + str(value)

## Generate common resource types
static func generate_script_resource(script_path: String, file_path: String) -> Dictionary:
	return generate_resource("Script", {
		"script": load(script_path),
		"uid": "uid://" + str(randi() % 1000000)
	}, file_path)

static func generate_stylebox_resource(stylebox_type: String, properties: Dictionary, file_path: String) -> Dictionary:
	return generate_resource(stylebox_type, properties, file_path)

static func generate_theme_resource(properties: Dictionary, file_path: String) -> Dictionary:
	return generate_resource("Theme", properties, file_path)

static func generate_audio_stream_resource(stream_path: String, file_path: String) -> Dictionary:
	return generate_resource("AudioStream", {
		"stream": load(stream_path),
		"uid": "uid://" + str(randi() % 1000000)
	}, file_path)

## Parse resource from AI response
static func parse_resource_from_response(response_text: String, project_root: String = "res://") -> Array:
	var resources = []
	var lines = response_text.split("\n")
	var in_resource = false
	var current_resource = null
	var current_content = ""
	
	for i in range(lines.size()):
		var line = lines[i]
		
		# Check for resource file marker
		if line.begins_with("# File:") and ".tres" in line:
			if current_resource != null:
				resources.append(current_resource)
			
			var path_match = line.match("# File: (.+\\.tres)")
			if path_match:
				current_resource = {
					"path": path_match[1].strip_edges(),
					"content": ""
				}
				current_content = ""
				in_resource = true
				continue
		
		# Check for [gd_resource] header
		if "[gd_resource" in line:
			in_resource = true
			if current_resource == null:
				# Try to infer path
				current_resource = {
					"path": "resources/resource_" + str(resources.size() + 1) + ".tres",
					"content": ""
				}
			current_content = line + "\n"
			continue
		
		if in_resource:
			current_content += line + "\n"
			if current_resource != null:
				current_resource.content = current_content
	
	if current_resource != null:
		resources.append(current_resource)
	
	return resources
