@tool
extends RefCounted

class_name FileWriter

static func parse_and_write_files(response_text: String, project_root: String = "res://") -> Dictionary:
	
	var result = {
		"success": false,  # Will be set to true if any files are written successfully
		"files_written": [],
		"files_failed": [],
		"messages": [],
		"files_modified": [],
		"files_created": [],
		"error": ""
	}
	
	var files = []
	var current_file = null
	var current_content = ""
	var in_code_block = false
	var code_block_lang = ""
	
	var lines = response_text.split("\n")
	var i = 0
	
	while i < lines.size():
		var line = lines[i]
		
		# Check for file marker patterns
		var file_match = _match_file_marker(line)
		if file_match != null:
			# Save previous file if exists
			if current_file != null and current_content.strip_edges() != "":
				files.append({
					"path": current_file,
					"content": current_content.strip_edges(),
					"is_new": not _file_exists(_resolve_path(project_root, current_file))
				})
			
			# Start new file
			current_file = file_match.strip_edges()
			current_content = ""
			in_code_block = false
			i += 1
			continue
		
		# Check for code block start with file path
		if line.begins_with("```"):
			var lang_and_path = line.trim_prefix("```").strip_edges()
			if ":" in lang_and_path:
				var parts = lang_and_path.split(":", false, 1)
				code_block_lang = parts[0]
				var path_part = parts[1].strip_edges()
				if path_part != "":
					# This is a file path in code block
					if current_file == null:
						current_file = path_part
						current_content = ""
					in_code_block = true
					i += 1
					continue
			else:
				in_code_block = true
				i += 1
				continue
		
		# Check for code block end
		if line.strip_edges() == "```" and in_code_block:
			in_code_block = false
			i += 1
			continue
		
		# Add line to current file content
		if current_file != null:
			if in_code_block or not line.begins_with("```"):
				current_content += line + "\n"
		else:
			# Content before first file marker - might be explanation or code
			# Try to detect if it's actual code
			var stripped_line = line.strip_edges()
			
			# More aggressive code detection
			if stripped_line.begins_with("@tool") or \
			   stripped_line.begins_with("extends") or \
			   stripped_line.begins_with("class_name") or \
			   stripped_line.begins_with("func ") or \
			   stripped_line.begins_with("var ") or \
			   stripped_line.begins_with("const ") or \
			   stripped_line.begins_with("signal ") or \
			   stripped_line.begins_with("[gd_scene") or \
			   stripped_line.begins_with("[ext_resource") or \
			   stripped_line.begins_with("[node"):
				# Looks like code, try to infer filename from class_name or extends
				# We need to look ahead to get more context for inference
				var remaining_text = ""
				for j in range(i, min(i + 50, lines.size())):
					remaining_text += lines[j] + "\n"
				var inferred_filename = _infer_filename_from_code(stripped_line, remaining_text)
				current_file = inferred_filename
				current_content = line + "\n"
				print("DotAI FileWriter: Detected code without file marker, inferred filename: ", inferred_filename)
		
		i += 1
	
	# Save last file
	if current_file != null and current_content.strip_edges() != "":
		files.append({
			"path": current_file,
			"content": current_content.strip_edges(),
			"is_new": not _file_exists(_resolve_path(project_root, current_file))
		})
	
	# Fallback: extract code from markdown blocks if no file markers found
	if files.size() == 0:
		var code_regex = RegEx.new()
		code_regex.compile("```(?:gdscript|gd)?\\s*\\n?([\\s\\S]*?)```")
		var code_matches = code_regex.search_all(response_text)
		
		if code_matches.size() > 0:
			for i in range(code_matches.size()):
				var code_content = code_matches[i].get_string(1).strip_edges()
				if code_content.length() > 10:
					var lines = code_content.split("\n")
					var inferred_path = _infer_filename_from_code(lines[0] if lines.size() > 0 else "", code_content)
					if code_matches.size() > 1:
						var base = inferred_path.get_basename()
						var ext = inferred_path.get_extension()
						inferred_path = base + "_" + str(i + 1) + "." + ext
					files.append({"path": inferred_path, "content": code_content, "is_new": true})
		
		# Last resort: detect code without markdown blocks
		if files.size() == 0:
			var code_keywords = ["extends ", "class_name", "func ", "[gd_scene", "[ext_resource", "[node"]
			for keyword in code_keywords:
				if keyword in response_text:
					var cleaned = _extract_code_from_text(response_text)
					if cleaned.length() > 10:
						var lines = cleaned.split("\n")
						var inferred_path = _infer_filename_from_code(lines[0] if lines.size() > 0 else "", cleaned)
						files.append({"path": inferred_path, "content": cleaned, "is_new": true})
					break
		
		if files.size() == 0:
			result.error = "No code detected in response"
			result.messages.append(result.error)
	
	# Parse and add .tres resources from response
	var resource_generator_script = load("res://addons/claude_ai/resource_generator.gd")
	if resource_generator_script:
		var resources = ResourceGenerator.parse_resource_from_response(response_text, project_root)
		for resource in resources:
			files.append(resource)
	
	# Write files
	for file_data in files:
		var file_path = file_data.path
		if not file_path.begins_with("res://"):
			file_path = _resolve_path(project_root, file_path)
		
		var is_new_file = file_data.get("is_new", true)
		var write_result = _write_resource_file(file_path, file_data.content) if file_path.ends_with(".tres") else write_file(file_path, file_data.content)
		
		if write_result.success:
			result.success = true
			result.files_written.append(file_path)
			if is_new_file:
				result.files_created.append(file_path)
				result.messages.append("Created: " + file_path)
			else:
				result.files_modified.append(file_path)
				result.messages.append("Modified: " + file_path)
		else:
			result.files_failed.append(file_path)
			result.messages.append("Failed: " + file_path + " - " + write_result.error)
	
	if result.files_written.size() == 0 and result.error == "":
		result.error = "No files were written"
	
	return result

static func _extract_code_from_text(text: String) -> String:
	var cleaned = text.strip_edges()
	if cleaned.begins_with("```"):
		var parts = cleaned.split("```")
		if parts.size() >= 3:
			cleaned = parts[1].strip_edges()
			if "\n" in cleaned:
				var first_newline = cleaned.find("\n")
				var first_line = cleaned.substr(0, first_newline)
				if "gdscript" in first_line.to_lower() or "gd" in first_line.to_lower():
					cleaned = cleaned.substr(first_newline + 1).strip_edges()
	
	var lines = cleaned.split("\n")
	var code_start = 0
	for i in range(lines.size()):
		var line = lines[i].strip_edges()
		if line.begins_with("extends") or line.begins_with("class_name") or line.begins_with("@tool") or \
		   line.begins_with("[gd_scene") or line.begins_with("[ext_resource") or line.begins_with("[node"):
			code_start = i
			break
	
	if code_start > 0:
		cleaned = "\n".join(lines.slice(code_start))
	
	return cleaned

static func _infer_filename_from_code(first_line: String, full_text: String) -> String:
	# AI GAME ENGINE: Enhanced filename inference
	# Try to extract class_name first (most reliable)
	var class_name_regex = RegEx.new()
	class_name_regex.compile("class_name\\s+([A-Za-z_][A-Za-z0-9_]*)")
	var class_match = class_name_regex.search(full_text)
	if class_match:
		var class_name = class_match.get_string(1)
		# Convert PascalCase to snake_case for filename
		var filename = class_name.to_snake_case() + ".gd"
		
		# Determine directory based on class name patterns (AI Game Engine structure)
		var class_lower = class_name.to_lower()
		if "player" in class_lower:
			return "scripts/player/" + filename
		elif "enemy" in class_lower:
			return "scripts/enemies/" + filename
		elif "manager" in class_lower or "game" in class_lower:
			return "scripts/managers/" + filename
		elif "ui" in class_lower or "hud" in class_lower or "menu" in class_lower:
			return "scripts/ui/" + filename
		elif "collectible" in class_lower or "coin" in class_lower or "item" in class_lower:
			return "scripts/collectibles/" + filename
		else:
			return "scripts/" + filename
	
	# Try to extract from extends if class_name not found
	var extends_regex = RegEx.new()
	extends_regex.compile("extends\\s+([A-Za-z_][A-Za-z0-9_]*)")
	var extends_match = extends_regex.search(full_text)
	if extends_match:
		var extends_class = extends_match.get_string(1)
		var content_lower = full_text.to_lower()
		
		# Smart inference based on content and extends class
		if "player" in content_lower or ("movement" in content_lower and "jump" in content_lower):
			if extends_class == "CharacterBody2D" or extends_class == "CharacterBody3D":
				return "scripts/player/player.gd"
		elif "enemy" in content_lower or "patrol" in content_lower or "ai" in content_lower:
			return "scripts/enemies/enemy.gd"
		elif "game" in content_lower and "manager" in content_lower:
			return "scripts/managers/game_manager.gd"
		elif "ui" in content_lower or "hud" in content_lower or "label" in content_lower:
			return "scripts/ui/hud.gd"
		elif "coin" in content_lower or "collectible" in content_lower:
			return "scripts/collectibles/coin.gd"
		
		# Fallback to extends-based inference
		if extends_class == "CharacterBody2D":
			return "scripts/player/player.gd"
		elif extends_class == "CharacterBody3D":
			return "scripts/player/player.gd"
		elif extends_class == "Node2D":
			return "scripts/entity.gd"
		elif extends_class == "Node":
			return "scripts/manager.gd"
		elif extends_class == "Control":
			return "scripts/ui/ui.gd"
		else:
			var filename = extends_class.to_snake_case() + ".gd"
			return "scripts/" + filename
	
	# Try to infer from extends and content analysis
	var extends_regex = RegEx.new()
	extends_regex.compile("extends\\s+([A-Za-z_][A-Za-z0-9_]*)")
	var extends_match = extends_regex.search(first_line)
	if extends_match:
		var extends_class = extends_match.get_string(1)
		var content_lower = full_text.to_lower()
		
		# Smart inference based on content
		if "player" in content_lower or "movement" in content_lower or "jump" in content_lower:
			if extends_class == "CharacterBody2D" or extends_class == "CharacterBody3D":
				return "scripts/player/player.gd"
		elif "enemy" in content_lower or "patrol" in content_lower or "ai" in content_lower:
			return "scripts/enemies/enemy.gd"
		elif "game" in content_lower and "manager" in content_lower:
			return "scripts/managers/game_manager.gd"
		elif "ui" in content_lower or "hud" in content_lower or "label" in content_lower:
			return "scripts/ui/hud.gd"
		elif "coin" in content_lower or "collectible" in content_lower:
			return "scripts/collectibles/coin.gd"
		
		# Fallback to extends-based inference
		if extends_class == "CharacterBody2D":
			return "scripts/player/player.gd"
		elif extends_class == "CharacterBody3D":
			return "scripts/player/player.gd"
		elif extends_class == "Node2D":
			return "scripts/entity.gd"
		elif extends_class == "Node":
			return "scripts/manager.gd"
		elif extends_class == "Control":
			return "scripts/ui/ui.gd"
		else:
			var filename = extends_class.to_snake_case() + ".gd"
			return "scripts/" + filename
	
	# Default fallback
	return "scripts/generated_script.gd"

## Match various file marker patterns
static func _match_file_marker(line: String) -> String:
	# Pattern 1: # File: path/to/file.gd
	var regex1 = RegEx.new()
	regex1.compile("^#\\s*File:\\s*([^\\n]+)")
	var match1 = regex1.search(line)
	if match1:
		return match1.get_string(1).strip_edges()
	
	# Pattern 2: File: path/to/file.gd (without #)
	var regex2 = RegEx.new()
	regex2.compile("^File:\\s*([^\\n]+)")
	var match2 = regex2.search(line)
	if match2:
		return match2.get_string(1).strip_edges()
	
	return null

## Resolve relative path to absolute project path
static func _resolve_path(project_root: String, relative_path: String) -> String:
	if relative_path.begins_with("res://"):
		return relative_path
	
	var root = project_root.trim_suffix("/")
	if root == "":
		root = "res://"
	
	var path = relative_path.lstrip("/")
	return root + "/" + path

## Check if file exists
static func _file_exists(file_path: String) -> bool:
	return FileAccess.file_exists(file_path)

static func write_file(file_path: String, content: String) -> Dictionary:
	var result = {"success": false, "error": ""}
	
	if content.is_empty():
		result.error = "Cannot write empty file"
		return result
	
	var dir_path = file_path.get_base_dir()
	if dir_path != "" and dir_path != "res://":
		var dir = DirAccess.open("res://")
		if dir == null:
			result.error = "Failed to open res:// directory"
			return result
		
		var current_path = "res://"
		var path_parts = dir_path.trim_prefix("res://").split("/")
		for part in path_parts:
			if part != "":
				current_path += "/" + part
				if not dir.dir_exists(current_path):
					if dir.make_dir(current_path) != OK:
						result.error = "Failed to create directory: " + current_path
						return result
	
	var optimized_content = _optimize_content(content, file_path)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		result.error = "Failed to open file: " + file_path
		return result
	
	file.store_string(optimized_content)
	file.close()
	result.success = true
	return result

static func _optimize_content(content: String, file_path: String) -> String:
	var optimized = content
	if file_path.ends_with(".gd"):
		optimized = optimized.replace("get_node(\"../\")", "get_parent()")
		optimized = optimized.replace("get_node(\"./\")", "self")
		optimized = optimized.replace("\r\n", "\n").replace("\r", "\n")
	return optimized

static func _write_resource_file(file_path: String, content: String) -> Dictionary:
	var result = {"success": false, "error": ""}
	var dir_path = file_path.get_base_dir()
	if dir_path != "" and dir_path != "res://":
		var dir = DirAccess.open("res://")
		if dir != null:
			var current_path = "res://"
			var path_parts = dir_path.trim_prefix("res://").split("/")
			for part in path_parts:
				if part != "":
					current_path += "/" + part
					if not dir.dir_exists(current_path) and dir.make_dir(current_path) != OK:
						result.error = "Failed to create directory: " + current_path
						return result
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		result.error = "Failed to open file: " + file_path
		return result
	
	file.store_string(content)
	file.close()
	result.success = true
	return result

