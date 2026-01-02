@tool
extends RefCounted

## Advanced Scene Analyzer
## Deep analysis of scene structure and optimization

class_name SceneAnalyzer

## Scene analysis result
class SceneAnalysis:
	var scene_path: String
	var node_count: int = 0
	var depth: int = 0
	var issues: Array = []
	var optimizations: Array = []
	var structure_score: float = 100.0
	
	func _init(p_path: String):
		scene_path = p_path

## Analyze scene file
static func analyze_scene(scene_path: String) -> SceneAnalysis:
	var analysis = SceneAnalysis.new(scene_path)
	
	var file = FileAccess.open(scene_path, FileAccess.READ)
	if file == null:
		return analysis
	
	var content = file.get_as_text()
	file.close()
	
	# Parse scene structure
	var nodes = _parse_scene_nodes(content)
	analysis.node_count = nodes.size()
	analysis.depth = _calculate_depth(nodes)
	
	# Check for issues
	analysis.issues = _check_scene_issues(content, nodes)
	analysis.optimizations = _suggest_optimizations(content, nodes)
	
	# Calculate structure score
	analysis.structure_score = _calculate_structure_score(analysis)
	
	return analysis

## Parse scene nodes
static func _parse_scene_nodes(content: String) -> Array:
	var nodes = []
	var lines = content.split("\n")
	var current_node = null
	var depth = 0
	
	for line in lines:
		if "[node" in line:
			if current_node != null:
				nodes.append(current_node)
			
			var node_match = RegEx.new()
			node_match.compile("\\[node name=\"([^\"]+)\" type=\"([^\"]+)\"")
			var match_result = node_match.search(line)
			if match_result:
				current_node = {
					"name": match_result.get_string(1),
					"type": match_result.get_string(2),
					"depth": depth
				}
				depth += 1
		elif "parent=\"" in line:
			depth = max(0, depth - 1)
	
	if current_node != null:
		nodes.append(current_node)
	
	return nodes

## Calculate scene depth
static func _calculate_depth(nodes: Array) -> int:
	if nodes.size() == 0:
		return 0
	
	var max_depth = 0
	for node in nodes:
		if node.depth > max_depth:
			max_depth = node.depth
	return max_depth

## Check scene issues
static func _check_scene_issues(content: String, nodes: Array) -> Array:
	var issues = []
	
	# Check for too many nodes
	if nodes.size() > 100:
		issues.append({
			"type": "performance",
			"severity": "high",
			"message": "Scene has too many nodes (" + str(nodes.size()) + ") - consider splitting"
		})
	
	# Check for deep nesting
	var max_depth = _calculate_depth(nodes)
	if max_depth > 10:
		issues.append({
			"type": "structure",
			"severity": "medium",
			"message": "Scene has deep nesting (depth: " + str(max_depth) + ") - consider flattening"
		})
	
	# Check for missing scripts
	var script_count = content.count("script = ExtResource")
	var node_count = nodes.size()
	if script_count < node_count * 0.3 and node_count > 5:
		issues.append({
			"type": "organization",
			"severity": "low",
			"message": "Many nodes without scripts - consider adding scripts for better organization"
		})
	
	return issues

## Suggest optimizations
static func _suggest_optimizations(content: String, nodes: Array) -> Array:
	var optimizations = []
	
	# Check for duplicate nodes
	var node_types = {}
	for node in nodes:
		var type = node.type
		if not node_types.has(type):
			node_types[type] = 0
		node_types[type] += 1
	
	for type in node_types:
		if node_types[type] > 5:
			optimizations.append({
				"type": "performance",
				"suggestion": "Consider using MultiMeshInstance or instancing for multiple " + type + " nodes"
			})
	
	# Check for unused resources
	if content.count("ExtResource") > nodes.size() * 2:
		optimizations.append({
			"type": "memory",
			"suggestion": "Review external resources - some may be unused"
		})
	
	return optimizations

## Calculate structure score
static func _calculate_structure_score(analysis: SceneAnalysis) -> float:
	var score = 100.0
	
	# Penalize for too many nodes
	if analysis.node_count > 100:
		score -= (analysis.node_count - 100) * 0.5
	
	# Penalize for deep nesting
	if analysis.depth > 10:
		score -= (analysis.depth - 10) * 2.0
	
	# Penalize for issues
	score -= analysis.issues.size() * 5.0
	
	return max(0.0, score)

## Analyze entire project scenes
static func analyze_project_scenes(root_path: String = "res://") -> Dictionary:
	var structure = CodebaseScanner.scan_and_cache_project(root_path)
	var project_analysis = {
		"total_scenes": structure.scenes.size(),
		"total_nodes": 0,
		"average_depth": 0.0,
		"scenes": []
	}
	
	var total_depth = 0.0
	
	for scene_info in structure.scenes:
		var analysis = analyze_scene(scene_info.full_path)
		project_analysis.total_nodes += analysis.node_count
		total_depth += analysis.depth
		project_analysis.scenes.append({
			"path": scene_info.path,
			"node_count": analysis.node_count,
			"depth": analysis.depth,
			"score": analysis.structure_score,
			"issues": analysis.issues.size()
		})
	
	if structure.scenes.size() > 0:
		project_analysis.average_depth = total_depth / float(structure.scenes.size())
	
	return project_analysis
