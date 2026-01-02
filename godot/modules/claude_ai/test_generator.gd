@tool
extends RefCounted

## Test Generator
## Auto-generate unit tests for code

class_name TestGenerator

## Generate tests for a file
static func generate_tests(file_path: String, output_path: String = "") -> Dictionary:
	var result = {"success": false, "error": "", "test_file": ""}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		result.error = "Cannot read file"
		return result
	
	var content = file.get_as_text()
	file.close()
	
	# Parse functions from file
	var functions = _extract_functions(content)
	
	# Generate test file
	if output_path == "":
		var base_name = file_path.get_file().get_basename()
		output_path = file_path.get_base_dir() + "/" + base_name + "_test.gd"
	
	var test_code = _generate_test_code(file_path, functions, content)
	
	# Write test file
	var test_file = FileAccess.open(output_path, FileAccess.WRITE)
	if test_file == null:
		result.error = "Cannot write test file"
		return result
	
	test_file.store_string(test_code)
	test_file.close()
	
	result.success = true
	result.test_file = output_path
	return result

## Extract functions from code
static func _extract_functions(content: String) -> Array:
	var functions = []
	var lines = content.split("\n")
	var current_func = null
	var func_start = 0
	
	for i in range(lines.size()):
		var line = lines[i]
		if line.strip_edges().begins_with("func "):
			if current_func != null:
				current_func.end_line = i - 1
				functions.append(current_func)
			
			var func_match = RegEx.new()
			func_match.compile("func\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\(([^)]*)\\)")
			var match_result = func_match.search(line)
			if match_result:
				current_func = {
					"name": match_result.get_string(1),
					"parameters": _parse_parameters(match_result.get_string(2)),
					"start_line": i + 1,
					"end_line": lines.size()
				}
	
	if current_func != null:
		current_func.end_line = lines.size()
		functions.append(current_func)
	
	return functions

## Parse function parameters
static func _parse_parameters(param_string: String) -> Array:
	if param_string.strip_edges() == "":
		return []
	
	var parameters = []
	var parts = param_string.split(",")
	for part in parts:
		var param = part.strip_edges()
		if ":" in param:
			var name_type = param.split(":")
			parameters.append({
				"name": name_type[0].strip_edges(),
				"type": name_type[1].strip_edges()
			})
		else:
			parameters.append({"name": param, "type": ""})
	
	return parameters

## Generate test code
static func _generate_test_code(file_path: String, functions: Array, original_code: String) -> String:
	var test_code = "extends GutTest\n\n"
	
	# Extract class name or file name
	var class_name = _extract_class_name(original_code)
	var file_name = file_path.get_file().get_basename()
	
	test_code += f"# Test file for {file_path}\n"
	test_code += f"# Generated automatically\n\n"
	
	# Add setup
	test_code += "var test_instance\n\n"
	test_code += "func before_each():\n"
	if class_name != "":
		test_code += f"\ttest_instance = {class_name}.new()\n"
	else:
		test_code += f"\ttest_instance = load(\"res://{file_path}\").new()\n"
	test_code += "\n"
	
	# Generate tests for each function
	for func_data in functions:
		var func_name = func_data.name
		
		# Skip private functions (starting with _)
		if func_name.begins_with("_"):
			continue
		
		# Skip _ready, _process, etc.
		if func_name in ["_ready", "_process", "_physics_process", "_input", "_unhandled_input"]:
			continue
		
		test_code += f"func test_{func_name}():\n"
		test_code += f"\t# Test {func_name}\n"
		
		# Generate test based on function signature
		if func_data.parameters.size() == 0:
			test_code += f"\tvar result = test_instance.{func_name}()\n"
			test_code += f"\tassert_not_null(result, \"{func_name} should return a value\")\n"
		else:
			# Generate test with parameters
			var param_values = []
			for param in func_data.parameters:
				var test_value = _generate_test_value(param.get("type", ""))
				param_values.append(test_value)
			
			test_code += f"\tvar result = test_instance.{func_name}({', '.join(param_values)})\n"
			test_code += f"\tassert_not_null(result, \"{func_name} should return a value\")\n"
		
		test_code += "\n"
	
	return test_code

## Extract class name from code
static func _extract_class_name(code: String) -> String:
	var regex = RegEx.new()
	regex.compile("class_name\\s+([A-Za-z_][A-Za-z0-9_]*)")
	var result = regex.search(code)
	if result:
		return result.get_string(1)
	return ""

## Generate test value based on type
static func _generate_test_value(type: String) -> String:
	match type.to_lower():
		"int", "int32", "int64":
			return "42"
		"float", "float32", "float64":
			return "3.14"
		"string":
			return "\"test\""
		"bool":
			return "true"
		"vector2":
			return "Vector2(1, 1)"
		"vector3":
			return "Vector3(1, 1, 1)"
		"array":
			return "[]"
		"dictionary":
			return "{}"
		_:
			return "null"

## Generate AI-powered tests
func generate_ai_tests(file_path: String, api_handler: Node) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return
	
	var content = file.get_as_text()
	file.close()
	
	var prompt = f"""Generate comprehensive unit tests for this GDScript file:

File: {file_path}
Code:
```gdscript
{content}
```

Generate:
1. Test setup and teardown
2. Tests for all public functions
3. Edge case tests
4. Error handling tests
5. Use GUT testing framework format"""
	
	var params = {
		"prompt": prompt,
		"include_codebase": true
	}
	
	if api_handler.has_method("send_request"):
		api_handler.send_request(params)
