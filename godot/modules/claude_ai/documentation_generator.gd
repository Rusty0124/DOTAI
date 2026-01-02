@tool
extends RefCounted

## Documentation Generator
## Auto-generate API documentation from code

class_name DocumentationGenerator

## Generate documentation for a file
static func generate_documentation(file_path: String, output_path: String = "") -> Dictionary:
	var result = {"success": false, "error": "", "doc_file": ""}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		result.error = "Cannot read file"
		return result
	
	var content = file.get_as_text()
	file.close()
	
	# Parse code structure
	var doc_data = _parse_code_structure(content, file_path)
	
	# Generate markdown documentation
	var markdown = _generate_markdown(doc_data)
	
	# Determine output path
	if output_path == "":
		var base_name = file_path.get_file().get_basename()
		output_path = file_path.get_base_dir() + "/" + base_name + ".md"
	
	# Write documentation
	var doc_file = FileAccess.open(output_path, FileAccess.WRITE)
	if doc_file == null:
		result.error = "Cannot write documentation file"
		return result
	
	doc_file.store_string(markdown)
	doc_file.close()
	
	result.success = true
	result.doc_file = output_path
	return result

## Parse code structure
static func _parse_code_structure(content: String, file_path: String) -> Dictionary:
	var structure = {
		"file_path": file_path,
		"class_name": "",
		"extends": "",
		"description": "",
		"signals": [],
		"properties": [],
		"methods": [],
		"constants": []
	}
	
	var lines = content.split("\n")
	var in_comment_block = false
	var comment_buffer = []
	
	for i in range(lines.size()):
		var line = lines[i]
		
		# Handle comments
		if line.strip_edges().begins_with("##"):
			var comment = line.strip_edges().trim_prefix("##").strip_edges()
			if comment != "":
				comment_buffer.append(comment)
			continue
		
		# Extract class name
		if line.strip_edges().begins_with("class_name"):
			var regex = RegEx.new()
			regex.compile("class_name\\s+([A-Za-z_][A-Za-z0-9_]*)")
			var match_result = regex.search(line)
			if match_result:
				structure.class_name = match_result.get_string(1)
				if comment_buffer.size() > 0:
					structure.description = "\n".join(comment_buffer)
					comment_buffer.clear()
		
		# Extract extends
		if line.strip_edges().begins_with("extends"):
			var regex = RegEx.new()
			regex.compile("extends\\s+([A-Za-z_][A-Za-z0-9_.]*)")
			var match_result = regex.search(line)
			if match_result:
				structure.extends = match_result.get_string(1)
		
		# Extract signals
		if line.strip_edges().begins_with("signal"):
			var regex = RegEx.new()
			regex.compile("signal\\s+([A-Za-z_][A-Za-z0-9_]*)\\(([^)]*)\\)")
			var match_result = regex.search(line)
			if match_result:
				var signal_data = {
					"name": match_result.get_string(1),
					"parameters": match_result.get_string(2),
					"description": "\n".join(comment_buffer) if comment_buffer.size() > 0 else ""
				}
				structure.signals.append(signal_data)
				comment_buffer.clear()
		
		# Extract properties
		if "var " in line or "@export var " in line:
			var regex = RegEx.new()
			regex.compile("(@export\\s+)?var\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*:?\\s*([A-Za-z0-9_]*)?\\s*=?\\s*(.*)?")
			var match_result = regex.search(line)
			if match_result:
				var prop_data = {
					"name": match_result.get_string(2),
					"type": match_result.get_string(3),
					"default_value": match_result.get_string(4).strip_edges(),
					"exported": match_result.get_string(1) != "",
					"description": "\n".join(comment_buffer) if comment_buffer.size() > 0 else ""
				}
				structure.properties.append(prop_data)
				comment_buffer.clear()
		
		# Extract constants
		if line.strip_edges().begins_with("const"):
			var regex = RegEx.new()
			regex.compile("const\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*(.*)")
			var match_result = regex.search(line)
			if match_result:
				var const_data = {
					"name": match_result.get_string(1),
					"value": match_result.get_string(2),
					"description": "\n".join(comment_buffer) if comment_buffer.size() > 0 else ""
				}
				structure.constants.append(const_data)
				comment_buffer.clear()
		
		# Extract methods
		if line.strip_edges().begins_with("func "):
			var regex = RegEx.new()
			regex.compile("func\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\(([^)]*)\\)\\s*->\\s*([A-Za-z0-9_]*)?")
			var match_result = regex.search(line)
			if match_result:
				var method_data = {
					"name": match_result.get_string(1),
					"parameters": match_result.get_string(2),
					"return_type": match_result.get_string(3),
					"is_private": match_result.get_string(1).begins_with("_"),
					"description": "\n".join(comment_buffer) if comment_buffer.size() > 0 else ""
				}
				structure.methods.append(method_data)
				comment_buffer.clear()
	
	return structure

## Generate markdown documentation
static func _generate_markdown(doc_data: Dictionary) -> String:
	var md = ""
	
	# Header
	var title = doc_data.class_name if doc_data.class_name != "" else doc_data.file_path.get_file()
	md += f"# {title}\n\n"
	
	# Description
	if doc_data.description != "":
		md += f"{doc_data.description}\n\n"
	
	# Class info
	if doc_data.extends != "":
		md += f"**Extends:** `{doc_data.extends}`\n\n"
	
	md += "---\n\n"
	
	# Signals
	if doc_data.signals.size() > 0:
		md += "## Signals\n\n"
		for signal_data in doc_data.signals:
			md += f"### `{signal_data.name}`\n\n"
			if signal_data.description != "":
				md += f"{signal_data.description}\n\n"
			if signal_data.parameters != "":
				md += f"**Parameters:** `{signal_data.parameters}`\n\n"
		md += "\n"
	
	# Properties
	if doc_data.properties.size() > 0:
		md += "## Properties\n\n"
		for prop_data in doc_data.properties:
			var prop_type = prop_data.type if prop_data.type != "" else "var"
			md += f"### `{prop_data.name}: {prop_type}`\n\n"
			if prop_data.description != "":
				md += f"{prop_data.description}\n\n"
			if prop_data.exported:
				md += "**Exported:** Yes\n\n"
			if prop_data.default_value != "":
				md += f"**Default:** `{prop_data.default_value}`\n\n"
		md += "\n"
	
	# Constants
	if doc_data.constants.size() > 0:
		md += "## Constants\n\n"
		for const_data in doc_data.constants:
			md += f"### `{const_data.name}`\n\n"
			if const_data.description != "":
				md += f"{const_data.description}\n\n"
			md += f"**Value:** `{const_data.value}`\n\n"
		md += "\n"
	
	# Methods
	if doc_data.methods.size() > 0:
		md += "## Methods\n\n"
		for method_data in doc_data.methods:
			if method_data.is_private:
				continue  # Skip private methods in public API docs
			
			md += f"### `{method_data.name}({method_data.parameters})`\n\n"
			if method_data.description != "":
				md += f"{method_data.description}\n\n"
			if method_data.return_type != "":
				md += f"**Returns:** `{method_data.return_type}`\n\n"
			if method_data.parameters != "":
				md += f"**Parameters:** `{method_data.parameters}`\n\n"
		md += "\n"
	
	return md

## Generate project-wide documentation
static func generate_project_documentation(root_path: String = "res://", output_dir: String = "docs/") -> Dictionary:
	var structure = CodebaseScanner.scan_and_cache_project(root_path)
	var result = {
		"success": true,
		"files_documented": [],
		"errors": []
	}
	
	# Create docs directory
	var dir = DirAccess.open(root_path)
	if dir != null:
		dir.make_dir(output_dir)
	
	# Generate docs for each script
	for script_info in structure.scripts:
		var doc_result = generate_documentation(
			script_info.full_path,
			output_dir + "/" + script_info.path.get_file().get_basename() + ".md"
		)
		if doc_result.success:
			result.files_documented.append(doc_result.doc_file)
		else:
			result.errors.append({"file": script_info.path, "error": doc_result.error})
	
	return result
