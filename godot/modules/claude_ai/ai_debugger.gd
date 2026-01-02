@tool
extends RefCounted

## AI-Powered Debugger
## Automatic bug detection and fix suggestions

class_name AIDebugger

## Bug report structure
class BugReport:
	var file_path: String
	var line_number: int
	var severity: String  # "error", "warning", "info"
	var bug_type: String  # "null_reference", "type_error", "logic_error", etc.
	var description: String
	var suggested_fix: String
	var code_snippet: String
	
	func _init(p_path: String, p_line: int, p_type: String, p_desc: String):
		file_path = p_path
		line_number = p_line
		bug_type = p_type
		description = p_desc

## Analyze code for bugs
static func analyze_for_bugs(file_path: String) -> Array[BugReport]:
	var bugs: Array[BugReport] = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		return bugs
	
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	
	# Check for common bug patterns
	for i in range(lines.size()):
		var line = lines[i]
		var line_num = i + 1
		
		# Check for null reference errors
		if _check_null_reference(line, lines, i):
			var bug = BugReport.new(file_path, line_num, "null_reference", 
				"Potential null reference - variable may be null before use")
			bug.suggested_fix = _suggest_null_fix(line)
			bug.code_snippet = line
			bugs.append(bug)
		
		# Check for type errors
		if _check_type_error(line):
			var bug = BugReport.new(file_path, line_num, "type_error",
				"Potential type mismatch or incorrect type usage")
			bug.suggested_fix = _suggest_type_fix(line)
			bug.code_snippet = line
			bugs.append(bug)
		
		# Check for logic errors
		if _check_logic_error(line, lines, i):
			var bug = BugReport.new(file_path, line_num, "logic_error",
				"Potential logic error detected")
			bug.suggested_fix = _suggest_logic_fix(line)
			bug.code_snippet = line
			bugs.append(bug)
		
		# Check for infinite loops
		if _check_infinite_loop(line, lines, i):
			var bug = BugReport.new(file_path, line_num, "infinite_loop",
				"Potential infinite loop detected")
			bug.suggested_fix = _suggest_loop_fix(line)
			bug.code_snippet = line
			bugs.append(bug)
		
		# Check for memory leaks
		if _check_memory_leak(line):
			var bug = BugReport.new(file_path, line_num, "memory_leak",
				"Potential memory leak - resource not properly freed")
			bug.suggested_fix = _suggest_memory_fix(line)
			bug.code_snippet = line
			bugs.append(bug)
	
	return bugs

## Check for null reference errors
static func _check_null_reference(line: String, lines: Array, index: int) -> bool:
	# Check for get_node() without null check
	if "get_node(" in line and not line.contains("if ") and not line.contains("?."):
		# Check if next lines use the result without checking
		if index + 1 < lines.size():
			var next_line = lines[index + 1]
			if "." in next_line and not next_line.contains("if ") and not next_line.contains("null"):
				return true
	
	# Check for accessing properties without null check
	if ".position" in line or ".velocity" in line or ".text" in line:
		var prev_lines = lines.slice(max(0, index - 3), index)
		var has_null_check = false
		for prev_line in prev_lines:
			if "if " in prev_line and ("null" in prev_line or "== null" in prev_line):
				has_null_check = true
				break
		if not has_null_check:
			return true
	
	return false

## Check for type errors
static func _check_type_error(line: String) -> bool:
	# Check for type mismatches
	if "as " in line and "as int" in line and "." in line:
		return true
	
	# Check for incorrect type conversions
	if "str(" in line and "int(" in line:
		return true
	
	return false

## Check for logic errors
static func _check_logic_error(line: String, lines: Array, index: int) -> bool:
	# Check for assignment instead of comparison
	if "if " in line and " = " in line and " == " not in line:
		return true
	
	# Check for unreachable code
	if index > 0:
		var prev_line = lines[index - 1]
		if "return" in prev_line or "break" in prev_line or "continue" in prev_line:
			if line.strip_edges().begins_with("var ") or line.strip_edges().begins_with("func "):
				return false  # New scope, not unreachable
			elif not line.strip_edges().begins_with("#"):
				return true
	
	return false

## Check for infinite loops
static func _check_infinite_loop(line: String, lines: Array, index: int) -> bool:
	if "while true:" in line or "while True:" in line:
		# Check if there's a break or return in the loop
		var has_exit = false
		for i in range(index + 1, min(index + 50, lines.size())):
			if "break" in lines[i] or "return" in lines[i]:
				has_exit = true
				break
			if lines[i].strip_edges().begins_with("func ") or lines[i].strip_edges().begins_with("class "):
				break
		if not has_exit:
			return true
	
	return false

## Check for memory leaks
static func _check_memory_leak(line: String) -> bool:
	# Check for instantiate without proper cleanup
	if "instantiate()" in line or "new()" in line:
		return true
	
	# Check for signal connections without disconnect
	if "connect(" in line:
		return true
	
	return false

## Suggest fix for null reference
static func _suggest_null_fix(line: String) -> String:
	if "get_node(" in line:
		return "Add null check: if node != null: or use null-safe operator"
	return "Add null check before accessing properties"

## Suggest fix for type error
static func _suggest_type_fix(line: String) -> String:
	return "Verify type compatibility or add explicit type conversion"

## Suggest fix for logic error
static func _suggest_logic_fix(line: String) -> String:
	if " = " in line and "if " in line:
		return "Use == for comparison instead of ="
	return "Review logic flow and conditions"

## Suggest fix for infinite loop
static func _suggest_loop_fix(line: String) -> String:
	return "Add break condition or exit mechanism to prevent infinite loop"

## Suggest fix for memory leak
static func _suggest_memory_fix(line: String) -> String:
	if "instantiate()" in line:
		return "Ensure instantiated objects are properly freed with queue_free() or free()"
	if "connect(" in line:
		return "Disconnect signals in _exit_tree() or cleanup function"
	return "Review resource management and cleanup"

## Generate fix suggestions using AI
static func generate_ai_fix_suggestions(bug: BugReport, api_handler) -> String:
	# This would call the AI API to generate fix suggestions
	var prompt = f"""Analyze this bug and suggest a fix:

File: {bug.file_path}
Line: {bug.line_number}
Type: {bug.bug_type}
Description: {bug.description}
Code: {bug.code_snippet}

Provide a specific fix suggestion with code example."""
	
	# In a real implementation, this would call the API handler
	return bug.suggested_fix

## Auto-fix bugs (where possible)
static func auto_fix_bug(file_path: String, bug: BugReport) -> Dictionary:
	var result = {"success": false, "error": "", "fixed_code": ""}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		result.error = "Cannot read file"
		return result
	
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	if bug.line_number > lines.size():
		result.error = "Line number out of range"
		return result
	
	var line_index = bug.line_number - 1
	var original_line = lines[line_index]
	var fixed_line = original_line
	
	# Apply automatic fixes based on bug type
	match bug.bug_type:
		"null_reference":
			if "get_node(" in original_line:
				# Add null check
				var var_name = _extract_variable_name(original_line)
				if var_name != "":
					fixed_line = f"var {var_name} = {original_line.strip_edges()}\n\tif {var_name} != null:"
		"logic_error":
			if " = " in original_line and "if " in original_line:
				fixed_line = original_line.replace(" = ", " == ")
	
	if fixed_line != original_line:
		lines[line_index] = fixed_line
		result.fixed_code = "\n".join(lines)
		result.success = true
	else:
		result.error = "Could not auto-fix this bug type"
	
	return result

## Extract variable name from line
static func _extract_variable_name(line: String) -> String:
	var regex = RegEx.new()
	regex.compile("var\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*=")
	var result = regex.search(line)
	if result:
		return result.get_string(1)
	return ""

## Analyze entire project for bugs
static func analyze_project(root_path: String = "res://") -> Dictionary:
	var structure = CodebaseScanner.scan_and_cache_project(root_path)
	var project_bugs = {
		"total_bugs": 0,
		"by_severity": {"error": 0, "warning": 0, "info": 0},
		"by_type": {},
		"files": []
	}
	
	for script_info in structure.scripts:
		var bugs = analyze_for_bugs(script_info.full_path)
		if bugs.size() > 0:
			project_bugs.total_bugs += bugs.size()
			project_bugs.files.append({
				"path": script_info.path,
				"bug_count": bugs.size(),
				"bugs": bugs
			})
			
			for bug in bugs:
				if not project_bugs.by_type.has(bug.bug_type):
					project_bugs.by_type[bug.bug_type] = 0
				project_bugs.by_type[bug.bug_type] += 1
				project_bugs.by_severity[bug.severity] += 1
	
	return project_bugs
