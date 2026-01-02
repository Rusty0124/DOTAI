@tool
extends RefCounted

## Performance Profiler
## AI-powered performance analysis and optimization

class_name PerformanceProfiler

## Performance issue structure
class PerformanceIssue:
	var file_path: String
	var line_number: int
	var severity: String  # "critical", "high", "medium", "low"
	var issue_type: String  # "memory", "cpu", "gpu", "network"
	var description: String
	var impact: String
	var suggestion: String
	var code_snippet: String
	
	func _init(p_path: String, p_line: int, p_type: String, p_desc: String):
		file_path = p_path
		line_number = p_line
		issue_type = p_type
		description = p_desc

## Analyze file for performance issues
static func analyze_file(file_path: String) -> Array[PerformanceIssue]:
	var issues: Array[PerformanceIssue] = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		return issues
	
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	
	for i in range(lines.size()):
		var line = lines[i]
		var line_num = i + 1
		
		# Check for CPU-intensive operations
		var cpu_issues = _check_cpu_performance(line, lines, i)
		issues.append_array(cpu_issues)
		
		# Check for memory issues
		var memory_issues = _check_memory_performance(line, lines, i)
		issues.append_array(memory_issues)
		
		# Check for GPU issues
		var gpu_issues = _check_gpu_performance(line)
		issues.append_array(gpu_issues)
		
		# Check for network issues
		var network_issues = _check_network_performance(line)
		issues.append_array(network_issues)
	
	return issues

## Check CPU performance issues
static func _check_cpu_performance(line: String, lines: Array, index: int) -> Array[PerformanceIssue]:
	var issues: Array[PerformanceIssue] = []
	
	# Check for repeated get_node calls
	if line.count("get_node(") > 1:
		var issue = PerformanceIssue.new("", index + 1, "cpu", 
			"Multiple get_node() calls in single line - cache node references")
		issue.severity = "high"
		issue.impact = "High CPU overhead from repeated node lookups"
		issue.suggestion = "Cache node reference using @onready var"
		issue.code_snippet = line
		issues.append(issue)
	
	# Check for inefficient loops
	if "for " in line and "range(" in line:
		var range_match = RegEx.new()
		range_match.compile("range\\(([^)]+)\\)")
		var match_result = range_match.search(line)
		if match_result:
			var range_expr = match_result.get_string(1)
			if "size()" in range_expr or "length()" in range_expr:
				var issue = PerformanceIssue.new("", index + 1, "cpu",
					"Calling size()/length() in loop condition - cache value")
				issue.severity = "medium"
				issue.impact = "Repeated function calls in loop"
				issue.suggestion = "Cache size before loop: var size = array.size()"
				issue.code_snippet = line
				issues.append(issue)
	
	# Check for string concatenation in loops
	if index > 0 and "for " in lines[index - 1] and "+" in line and "\"" in line:
		var issue = PerformanceIssue.new("", index + 1, "cpu",
			"String concatenation in loop - use array join instead")
		issue.severity = "medium"
		issue.impact = "Inefficient string operations"
		issue.suggestion = "Use array.append() then array.join(\"\")"
		issue.code_snippet = line
		issues.append(issue)
	
	return issues

## Check memory performance issues
static func _check_memory_performance(line: String, lines: Array, index: int) -> Array[PerformanceIssue]:
	var issues: Array[PerformanceIssue] = []
	
	# Check for potential memory leaks
	if "instantiate()" in line or "new()" in line:
		# Check if result is stored
		if "var " not in line and "=" not in line:
			var issue = PerformanceIssue.new("", index + 1, "memory",
				"Instantiated object not stored - potential memory leak")
			issue.severity = "critical"
			issue.impact = "Memory leak - object not referenced"
			issue.suggestion = "Store reference or call queue_free() immediately"
			issue.code_snippet = line
			issues.append(issue)
	
	# Check for large arrays/dictionaries created frequently
	if "Array()" in line or "Dictionary()" in line:
		if index > 0 and ("_process" in lines[index - 1] or "_physics_process" in lines[index - 1]):
			var issue = PerformanceIssue.new("", index + 1, "memory",
				"Creating new array/dictionary every frame - allocate once")
			issue.severity = "high"
			issue.impact = "High memory allocation rate"
			issue.suggestion = "Create array/dictionary once in _ready() and reuse"
			issue.code_snippet = line
			issues.append(issue)
	
	return issues

## Check GPU performance issues
static func _check_gpu_performance(line: String) -> Array[PerformanceIssue]:
	var issues: Array[PerformanceIssue] = []
	
	# Check for texture operations in process
	if "ImageTexture" in line or "load(" in line and ".png" in line or ".jpg" in line:
		var issue = PerformanceIssue.new("", 0, "gpu",
			"Loading textures at runtime - preload or use ResourceLoader")
		issue.severity = "medium"
		issue.impact = "GPU memory and loading overhead"
		issue.suggestion = "Preload textures or use ResourceLoader.load_threaded_request()"
		issue.code_snippet = line
		issues.append(issue)
	
	return issues

## Check network performance issues
static func _check_network_performance(line: String) -> Array[PerformanceIssue]:
	var issues: Array[PerformanceIssue] = []
	
	# Check for synchronous HTTP requests
	if "HTTPRequest" in line and "request(" in line:
		var issue = PerformanceIssue.new("", 0, "network",
			"Synchronous HTTP request - use async requests")
		issue.severity = "high"
		issue.impact = "Blocks main thread"
		issue.suggestion = "Use HTTPRequest.request() with signal callbacks"
		issue.code_snippet = line
		issues.append(issue)
	
	return issues

## Generate performance report
static func generate_report(file_path: String) -> Dictionary:
	var issues = analyze_file(file_path)
	var report = {
		"file_path": file_path,
		"total_issues": issues.size(),
		"critical": 0,
		"high": 0,
		"medium": 0,
		"low": 0,
		"by_type": {"cpu": 0, "memory": 0, "gpu": 0, "network": 0},
		"issues": issues
	}
	
	for issue in issues:
		report[issue.severity] += 1
		report.by_type[issue.issue_type] += 1
	
	return report

## Analyze entire project
static func analyze_project(root_path: String = "res://") -> Dictionary:
	var structure = CodebaseScanner.scan_and_cache_project(root_path)
	var project_report = {
		"total_files": structure.scripts.size(),
		"total_issues": 0,
		"critical_issues": 0,
		"high_issues": 0,
		"files": []
	}
	
	for script_info in structure.scripts:
		var report = generate_report(script_info.full_path)
		project_report.total_issues += report.total_issues
		project_report.critical_issues += report.critical
		project_report.high_issues += report.high
		project_report.files.append(report)
	
	return project_report

## Get optimization suggestions
static func get_optimization_suggestions(file_path: String) -> Array:
	var issues = analyze_file(file_path)
	var suggestions = []
	
	for issue in issues:
		if issue.severity in ["critical", "high"]:
			suggestions.append({
				"line": issue.line_number,
				"type": issue.issue_type,
				"suggestion": issue.suggestion,
				"impact": issue.impact
			})
	
	return suggestions
