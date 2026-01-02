@tool
extends RefCounted

## Smart Refactorer
## Automated refactoring with AI assistance

class_name SmartRefactorer

## Refactoring result
class RefactoringResult:
	var success: bool = false
	var original_code: String = ""
	var refactored_code: String = ""
	var changes: Array = []
	var warnings: Array = []
	var error: String = ""

## Extract method refactoring
static func extract_method(code: String, start_line: int, end_line: int, method_name: String) -> RefactoringResult:
	var result = RefactoringResult.new()
	result.original_code = code
	
	var lines = code.split("\n")
	if start_line < 1 or end_line > lines.size() or start_line > end_line:
		result.error = "Invalid line range"
		return result
	
	# Extract the code block
	var extracted_lines = lines.slice(start_line - 1, end_line)
	var extracted_code = "\n".join(extracted_lines)
	
	# Determine parameters
	var parameters = _extract_parameters(extracted_code, lines.slice(0, start_line - 1))
	
	# Create new method
	var indent = _get_indent(lines[start_line - 1])
	var new_method = f"{indent}func {method_name}({', '.join(parameters)}):\n"
	for line in extracted_lines:
		new_method += _increase_indent(line, indent) + "\n"
	
	# Replace extracted code with method call
	var method_call = f"{indent}{method_name}({', '.join(parameters)})"
	lines[start_line - 1] = method_call
	for i in range(start_line, end_line):
		lines[i] = ""
	
	# Add new method after the replacement
	var insert_pos = end_line
	for i in range(end_line, lines.size()):
		if lines[i].strip_edges() != "":
			insert_pos = i
			break
	
	lines.insert(insert_pos, new_method)
	result.refactored_code = "\n".join(lines)
	result.changes.append(f"Extracted method '{method_name}' from lines {start_line}-{end_line}")
	result.success = true
	
	return result

## Rename variable refactoring
static func rename_variable(code: String, old_name: String, new_name: String) -> RefactoringResult:
	var result = RefactoringResult.new()
	result.original_code = code
	
	# Use regex to replace variable name (avoid replacing parts of other names)
	var regex = RegEx.new()
	regex.compile(f"\\b{old_name}\\b")
	
	var lines = code.split("\n")
	for i in range(lines.size()):
		lines[i] = regex.sub(lines[i], new_name)
	
	result.refactored_code = "\n".join(lines)
	result.changes.append(f"Renamed '{old_name}' to '{new_name}'")
	result.success = true
	
	return result

## Extract constant refactoring
static func extract_constant(code: String, value: String, constant_name: String) -> RefactoringResult:
	var result = RefactoringResult.new()
	result.original_code = code
	
	var lines = code.split("\n")
	var constant_declaration = f"const {constant_name} = {value}\n"
	
	# Find first non-empty line after class declaration
	var insert_pos = 0
	for i in range(lines.size()):
		if lines[i].strip_edges().begins_with("extends") or lines[i].strip_edges().begins_with("class_name"):
			insert_pos = i + 1
			break
	
	# Replace all occurrences
	for i in range(lines.size()):
		lines[i] = lines[i].replace(value, constant_name)
	
	lines.insert(insert_pos, constant_declaration)
	result.refactored_code = "\n".join(lines)
	result.changes.append(f"Extracted constant '{constant_name}' with value {value}")
	result.success = true
	
	return result

## Extract parameters from code block
static func _extract_parameters(code: String, context: Array) -> Array:
	var parameters = []
	
	# Find variables used in code but defined in context
	var used_vars = _find_variables(code)
	var defined_vars = _find_variables("\n".join(context))
	
	for var_name in used_vars:
		if var_name in defined_vars and var_name not in parameters:
			parameters.append(var_name)
	
	return parameters

## Find variables in code
static func _find_variables(code: String) -> Array:
	var variables = []
	var regex = RegEx.new()
	regex.compile("\\b([a-z_][a-z0-9_]*)\\b")
	
	var results = regex.search_all(code)
	for result in results:
		var var_name = result.get_string(1)
		if var_name not in ["func", "var", "const", "if", "else", "for", "while", "return", "extends", "class_name"]:
			if var_name not in variables:
				variables.append(var_name)
	
	return variables

## Get indentation of a line
static func _get_indent(line: String) -> String:
	var indent = ""
	for char in line:
		if char == "\t" or char == " ":
			indent += char
		else:
			break
	return indent

## Increase indentation
static func _increase_indent(line: String, base_indent: String) -> String:
	return base_indent + "\t" + line.lstrip("\t ")
	
## AI-powered refactoring
func ai_refactor(code: String, refactoring_type: String, api_handler: Node) -> void:
	var prompt = f"""Refactor this GDScript code using {refactoring_type}:

```gdscript
{code}
```

Provide the refactored code with explanations of changes."""
	
	var params = {
		"prompt": prompt,
		"include_codebase": true
	}
	
	if api_handler.has_method("send_request"):
		api_handler.send_request(params)
