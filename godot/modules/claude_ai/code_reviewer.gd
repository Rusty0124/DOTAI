@tool
extends RefCounted

## Interactive Code Reviewer
## AI reviews code changes and suggests improvements

class_name CodeReviewer

## Review comment structure
class ReviewComment:
	var file_path: String
	var line_number: int
	var severity: String  # "blocking", "suggestion", "info"
	var category: String  # "style", "performance", "security", "bug", "best_practice"
	var message: String
	var suggestion: String
	var code_snippet: String
	
	func _init(p_path: String, p_line: int, p_severity: String, p_category: String, p_msg: String):
		file_path = p_path
		line_number = p_line
		severity = p_severity
		category = p_category
		message = p_msg

## Review code changes
static func review_changes(old_code: String, new_code: String, file_path: String) -> Array[ReviewComment]:
	var comments: Array[ReviewComment] = []
	
	var old_lines = old_code.split("\n")
	var new_lines = new_code.split("\n")
	
	# Simple diff-based review
	var diff = _compute_diff(old_lines, new_lines)
	
	for change in diff:
		match change.type:
			"added":
				comments.append_array(_review_added_line(change.line, change.line_number, file_path))
			"modified":
				comments.append_array(_review_modified_line(change.old_line, change.new_line, change.line_number, file_path))
			"removed":
				comments.append_array(_review_removed_line(change.line, change.line_number, file_path))
	
	return comments

## Review a single file
static func review_file(file_path: String) -> Array[ReviewComment]:
	var comments: Array[ReviewComment] = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		return comments
	
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	
	# Check for common issues
	for i in range(lines.size()):
		var line = lines[i]
		var line_num = i + 1
		
		# Style checks
		if _check_style_issues(line):
			var comment = ReviewComment.new(file_path, line_num, "suggestion", "style",
				"Code style could be improved")
			comment.suggestion = _suggest_style_improvement(line)
			comment.code_snippet = line
			comments.append(comment)
		
		# Performance checks
		if _check_performance_issues(line):
			var comment = ReviewComment.new(file_path, line_num, "suggestion", "performance",
				"Potential performance issue detected")
			comment.suggestion = _suggest_performance_improvement(line)
			comment.code_snippet = line
			comments.append(comment)
		
		# Security checks
		if _check_security_issues(line):
			var comment = ReviewComment.new(file_path, line_num, "blocking", "security",
				"Security concern detected")
			comment.suggestion = _suggest_security_fix(line)
			comment.code_snippet = line
			comments.append(comment)
		
		# Best practice checks
		if _check_best_practices(line, lines, i):
			var comment = ReviewComment.new(file_path, line_num, "suggestion", "best_practice",
				"Consider following best practices")
			comment.suggestion = _suggest_best_practice(line)
			comment.code_snippet = line
			comments.append(comment)
	
	return comments

## Check for style issues
static func _check_style_issues(line: String) -> bool:
	# Check for inconsistent naming
	if "var " in line and not line.matches("var [a-z_][a-z0-9_]*"):
		return true
	
	# Check for missing type hints
	if "var " in line and ":" not in line and "@export" not in line:
		return true
	
	return false

## Check for performance issues
static func _check_performance_issues(line: String) -> bool:
	# Check for repeated get_node calls
	if line.count("get_node(") > 1:
		return true
	
	# Check for inefficient string operations
	if "str(" in line and "+" in line and line.count("+") > 3:
		return true
	
	return false

## Check for security issues
static func _check_security_issues(line: String) -> bool:
	# Check for eval or exec
	if "eval(" in line or "exec(" in line:
		return true
	
	# Check for user input without validation
	if "Input.get_text()" in line or "get_text()" in line:
		return true
	
	return false

## Check for best practices
static func _check_best_practices(line: String, lines: Array, index: int) -> bool:
	# Check for magic numbers
	var number_pattern = RegEx.new()
	number_pattern.compile("\\b\\d+\\.?\\d*\\b")
	var numbers = number_pattern.search_all(line)
	if numbers.size() > 2:
		return true
	
	# Check for long functions
	if "func " in line:
		var func_line_count = 0
		for i in range(index + 1, lines.size()):
			if lines[i].strip_edges().begins_with("func "):
				break
			func_line_count += 1
		if func_line_count > 50:
			return true
	
	return false

## Suggest style improvement
static func _suggest_style_improvement(line: String) -> String:
	if "var " in line and ":" not in line:
		return "Add type hint: var name: Type = value"
	return "Follow GDScript style guide"

## Suggest performance improvement
static func _suggest_performance_improvement(line: String) -> String:
	if "get_node(" in line:
		return "Cache node reference using @onready var"
	if "+" in line and "str(" in line:
		return "Use string formatting or StringBuilder for multiple concatenations"
	return "Review performance optimization opportunities"

## Suggest security fix
static func _suggest_security_fix(line: String) -> String:
	if "eval(" in line or "exec(" in line:
		return "Avoid using eval/exec - use safer alternatives"
	if "get_text()" in line:
		return "Validate and sanitize user input"
	return "Review security implications"

## Suggest best practice
static func _suggest_best_practice(line: String) -> String:
	return "Follow Godot and GDScript best practices"

## Review added line
static func _review_added_line(line: String, line_num: int, file_path: String) -> Array[ReviewComment]:
	var comments: Array[ReviewComment] = []
	
	# Check if it follows project conventions
	if "var " in line and ":" not in line:
		var comment = ReviewComment.new(file_path, line_num, "suggestion", "style",
			"New variable should have type hint")
		comment.suggestion = "Add type hint for better type safety"
		comments.append(comment)
	
	return comments

## Review modified line
static func _review_modified_line(old_line: String, new_line: String, line_num: int, file_path: String) -> Array[ReviewComment]:
	var comments: Array[ReviewComment] = []
	
	# Check if change introduces issues
	if "get_node(" in new_line and "get_node(" not in old_line:
		var comment = ReviewComment.new(file_path, line_num, "suggestion", "performance",
			"New get_node() call added - consider caching")
		comment.suggestion = "Cache node reference"
		comments.append(comment)
	
	return comments

## Review removed line
static func _review_removed_line(line: String, line_num: int, file_path: String) -> Array[ReviewComment]:
	var comments: Array[ReviewComment] = []
	
	# Check if removal might cause issues
	if "disconnect(" in line:
		var comment = ReviewComment.new(file_path, line_num, "info", "best_practice",
			"Signal disconnect removed - ensure cleanup is handled elsewhere")
		comments.append(comment)
	
	return comments

## Compute diff between two code blocks
static func _compute_diff(old_lines: Array, new_lines: Array) -> Array:
	# Simplified diff algorithm
	var diff = []
	var max_len = max(old_lines.size(), new_lines.size())
	
	for i in range(max_len):
		if i >= old_lines.size():
			diff.append({"type": "added", "line": new_lines[i], "line_number": i + 1})
		elif i >= new_lines.size():
			diff.append({"type": "removed", "line": old_lines[i], "line_number": i + 1})
		elif old_lines[i] != new_lines[i]:
			diff.append({
				"type": "modified",
				"old_line": old_lines[i],
				"new_line": new_lines[i],
				"line_number": i + 1
			})
	
	return diff

## Generate AI-powered review
func generate_ai_review(file_path: String, api_handler: Node) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return
	
	var content = file.get_as_text()
	file.close()
	
	var prompt = f"""Review this GDScript code and provide detailed feedback:

File: {file_path}
Code:
```gdscript
{content}
```

Provide:
1. Code quality assessment
2. Potential bugs or issues
3. Performance optimizations
4. Style improvements
5. Best practice suggestions
6. Security concerns (if any)"""
	
	var params = {
		"prompt": prompt,
		"include_codebase": true
	}
	
	if api_handler.has_method("send_request"):
		api_handler.send_request(params)
