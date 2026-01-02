@tool
extends RefCounted

## Code Analyzer and Refactoring Suggestions
## Analyzes code quality and suggests improvements

class_name CodeAnalyzer

## Analysis result structure
class AnalysisResult:
	var file_path: String
	var issues: Array = []
	var suggestions: Array = []
	var optimizations: Array = []
	var score: float = 100.0  # Code quality score (0-100)
	
	func _init(p_path: String):
		file_path = p_path

## Analyze a GDScript file
static func analyze_file(file_path: String) -> AnalysisResult:
	var result = AnalysisResult.new(file_path)
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		result.issues.append("Cannot read file")
		result.score = 0.0
		return result
	
	var content = file.get_as_text()
	file.close()
	
	_analyze_code_quality(content, result)
	_analyze_performance(content, result)
	_analyze_best_practices(content, result)
	_analyze_refactoring_opportunities(content, result)
	
	return result

## Analyze code quality
static func _analyze_code_quality(content: String, result: AnalysisResult):
	var lines = content.split("\n")
	
	# Check for type hints
	var has_type_hints = false
	var total_vars = 0
	var typed_vars = 0
	
	for line in lines:
		if "var " in line or "@export var " in line:
			total_vars += 1
			if ":" in line:
				typed_vars += 1
				has_type_hints = true
	
	if total_vars > 0:
		var type_hint_ratio = float(typed_vars) / float(total_vars)
		if type_hint_ratio < 0.8:
			result.suggestions.append("Add type hints to " + str(int((1.0 - type_hint_ratio) * total_vars)) + " variables for better type safety")
			result.score -= (1.0 - type_hint_ratio) * 10.0
	
	# Check for error handling
	if content.count("if ") < content.count("get_node("):
		result.suggestions.append("Add null checks for get_node() calls to prevent runtime errors")
		result.score -= 5.0
	
	# Check for comments
	var code_lines = 0
	var comment_lines = 0
	for line in lines:
		var stripped = line.strip_edges()
		if stripped.begins_with("#"):
			comment_lines += 1
		elif not stripped.is_empty() and not stripped.begins_with("func ") and not stripped.begins_with("var "):
			code_lines += 1
	
	if code_lines > 50 and comment_lines < code_lines * 0.1:
		result.suggestions.append("Add more comments to explain complex logic")
		result.score -= 3.0

## Analyze performance issues
static func _analyze_performance(content: String, result: AnalysisResult):
	# Check for repeated get_node() calls
	var get_node_pattern = RegEx.new()
	get_node_pattern.compile("get_node\\([^)]+\\)")
	var get_node_matches = get_node_pattern.search_all(content)
	
	if get_node_matches.size() > 5:
		result.optimizations.append("Cache frequently accessed nodes using @onready instead of repeated get_node() calls")
		result.score -= 5.0
	
	# Check for inefficient patterns
	if content.count("get_node(\"../\")") > 0:
		result.optimizations.append("Replace get_node(\"../\") with get_parent() for better performance")
		result.score -= 2.0
	
	# Check for process vs physics_process usage
	if "_process" in content and "physics" in content.to_lower():
		result.suggestions.append("Consider using _physics_process() instead of _process() for physics-related code")
	
	# Check for signal connections in _ready
	if content.count("connect(") > content.count("@onready"):
		result.optimizations.append("Use @onready to cache nodes before connecting signals for better performance")

## Analyze best practices
static func _analyze_best_practices(content: String, result: AnalysisResult):
	# Check for signal declarations
	if content.count("signal ") == 0 and content.count("emit_signal(") > 0:
		result.issues.append("Signals are being emitted but not declared. Declare signals at class level")
		result.score -= 10.0
	
	# Check for @export usage
	if content.count("var ") > 0 and content.count("@export") == 0:
		result.suggestions.append("Consider using @export for properties that should be editable in the editor")
	
	# Check for proper access modifiers
	var public_funcs = 0
	var private_funcs = 0
	for line in content.split("\n"):
		if line.strip_edges().begins_with("func "):
			if line.strip_edges().begins_with("func _"):
				private_funcs += 1
			else:
				public_funcs += 1
	
	if public_funcs > private_funcs * 2:
		result.suggestions.append("Consider making more functions private (prefix with _) to follow encapsulation principles")
	
	# Check for magic numbers
	var number_pattern = RegEx.new()
	number_pattern.compile("\\b\\d+\\.?\\d*\\b")
	var numbers = number_pattern.search_all(content)
	if numbers.size() > 10:
		result.suggestions.append("Consider extracting magic numbers into named constants for better maintainability")

## Analyze refactoring opportunities
static func _analyze_refactoring_opportunities(content: String, result: AnalysisResult):
	var lines = content.split("\n")
	
	# Check for long functions
	var current_func = ""
	var func_start_line = 0
	var func_line_count = 0
	
	for i in range(lines.size()):
		var line = lines[i]
		if line.strip_edges().begins_with("func "):
			if current_func != "" and func_line_count > 30:
				result.suggestions.append("Function '" + current_func + "' is too long (" + str(func_line_count) + " lines). Consider splitting into smaller functions")
				result.score -= 2.0
			
			var func_match = RegEx.new()
			func_match.compile("func\\s+([A-Za-z_][A-Za-z0-9_]*)")
			var match_result = func_match.search(line)
			if match_result:
				current_func = match_result.get_string(1)
			func_start_line = i
			func_line_count = 0
		else:
			func_line_count += 1
	
	# Check for code duplication
	var function_bodies = {}
	for i in range(lines.size()):
		var line = lines[i]
		if line.strip_edges().begins_with("func "):
			var func_name_match = RegEx.new()
			func_name_match.compile("func\\s+([A-Za-z_][A-Za-z0-9_]*)")
			var match_result = func_name_match.search(line)
			if match_result:
				var func_name = match_result.get_string(1)
				# Extract function body (simplified)
				var body_start = i + 1
				var body_end = body_start
				var indent_level = 0
				for j in range(body_start, lines.size()):
					var body_line = lines[j]
					if body_line.strip_edges().begins_with("func "):
						break
					if body_line.strip_edges() != "":
						body_end = j
				
				if body_end > body_start:
					var body = "\n".join(lines.slice(body_start, body_end + 1))
					if function_bodies.has(body):
						result.suggestions.append("Potential code duplication detected between functions")
						result.score -= 3.0
					else:
						function_bodies[body] = func_name
	
	# Check for complex conditionals
	var nested_if_count = 0
	for line in lines:
		var indent = 0
		for char in line:
			if char == "\t":
				indent += 1
			else:
				break
		if "if " in line and indent > 2:
			nested_if_count += 1
	
	if nested_if_count > 3:
		result.suggestions.append("Consider refactoring deeply nested conditionals using early returns or guard clauses")
		result.score -= 2.0

## Get refactoring suggestions for a file
static func get_refactoring_suggestions(file_path: String) -> Array:
	var analysis = analyze_file(file_path)
	return analysis.suggestions + analysis.optimizations

## Get optimization suggestions
static func get_optimization_suggestions(file_path: String) -> Array:
	var analysis = analyze_file(file_path)
	return analysis.optimizations

## Analyze entire project
static func analyze_project(root_path: String = "res://") -> Dictionary:
	var structure = CodebaseScanner.scan_and_cache_project(root_path)
	var project_analysis = {
		"files_analyzed": 0,
		"total_issues": 0,
		"total_suggestions": 0,
		"average_score": 0.0,
		"files": []
	}
	
	var total_score = 0.0
	
	for script_info in structure.scripts:
		var analysis = analyze_file(script_info.full_path)
		project_analysis.files.append({
			"path": script_info.path,
			"score": analysis.score,
			"issues": analysis.issues.size(),
			"suggestions": analysis.suggestions.size()
		})
		project_analysis.files_analyzed += 1
		project_analysis.total_issues += analysis.issues.size()
		project_analysis.total_suggestions += analysis.suggestions.size()
		total_score += analysis.score
	
	if project_analysis.files_analyzed > 0:
		project_analysis.average_score = total_score / float(project_analysis.files_analyzed)
	
	return project_analysis
