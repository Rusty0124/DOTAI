@tool
extends RefCounted

## Enhanced Dependency Graph for Codebase Understanding
## Provides visualization and analysis of code dependencies

class_name DependencyGraph

## Graph node structure
class GraphNode:
	var file_path: String
	var dependencies: Array[String] = []
	var dependents: Array[String] = []
	var metadata: Dictionary = {}
	
	func _init(p_path: String):
		file_path = p_path

## Dependency graph storage
static var _graph: Dictionary = {}
static var _nodes: Dictionary = {}

## Build complete dependency graph from codebase
static func build_graph(root_path: String = "res://") -> Dictionary:
	_graph.clear()
	_nodes.clear()
	
	var structure = CodebaseScanner.scan_and_cache_project(root_path)
	
	# Build nodes for all files
	for script_path in structure.metadata:
		var metadata = structure.metadata[script_path]
		var node = GraphNode.new(script_path)
		node.metadata = {
			"class_name": metadata.class_name,
			"extends": metadata.extends_class if metadata.extends_class != "" else metadata.extends_path,
			"functions": metadata.functions,
			"signals": metadata.signals,
			"line_count": metadata.line_count
		}
		_nodes[script_path] = node
		_graph[script_path] = {
			"dependencies": [],
			"dependents": []
		}
	
	# Build edges
	for script_path in structure.metadata:
		var metadata = structure.metadata[script_path]
		var node = _nodes[script_path]
		
		# Add extends as dependency
		if not metadata.extends_path.is_empty():
			var extends_full = _resolve_path(script_path, metadata.extends_path)
			if _nodes.has(extends_full):
				node.dependencies.append(extends_full)
				_graph[script_path].dependencies.append(extends_full)
				if not _graph.has(extends_full):
					_graph[extends_full] = {"dependencies": [], "dependents": []}
				_graph[extends_full].dependents.append(script_path)
		
		# Add imports as dependencies
		for import_path in metadata.imports:
			var import_full = _resolve_path(script_path, import_path)
			if _nodes.has(import_full):
				node.dependencies.append(import_full)
				_graph[script_path].dependencies.append(import_full)
				if not _graph.has(import_full):
					_graph[import_full] = {"dependencies": [], "dependents": []}
				_graph[import_full].dependents.append(script_path)
	
	return _graph

## Get dependency chain for a file (all files it depends on, recursively)
static func get_dependency_chain(file_path: String, visited: Dictionary = {}) -> Array:
	if visited.has(file_path):
		return []
	
	visited[file_path] = true
	var chain = []
	
	if not _graph.has(file_path):
		return chain
	
	for dep in _graph[file_path].dependencies:
		chain.append(dep)
		chain.append_array(get_dependency_chain(dep, visited))
	
	return chain

## Get dependent chain for a file (all files that depend on it, recursively)
static func get_dependent_chain(file_path: String, visited: Dictionary = {}) -> Array:
	if visited.has(file_path):
		return []
	
	visited[file_path] = true
	var chain = []
	
	if not _graph.has(file_path):
		return chain
	
	for dep in _graph[file_path].dependents:
		chain.append(dep)
		chain.append_array(get_dependent_chain(dep, visited))
	
	return chain

## Get files affected by changing a file (dependents + their dependents)
static func get_affected_files(file_path: String) -> Array:
	var affected = get_dependent_chain(file_path)
	affected.append(file_path)
	return affected

## Find circular dependencies
static func find_circular_dependencies() -> Array:
	var cycles = []
	var visited = {}
	var rec_stack = {}
	
	for node_path in _graph:
		if not visited.has(node_path):
			_find_cycles_dfs(node_path, visited, rec_stack, [], cycles)
	
	return cycles

## DFS helper for cycle detection
static func _find_cycles_dfs(node: String, visited: Dictionary, rec_stack: Dictionary, path: Array, cycles: Array):
	visited[node] = true
	rec_stack[node] = true
	path.append(node)
	
	if _graph.has(node):
		for dep in _graph[node].dependencies:
			if not visited.has(dep):
				_find_cycles_dfs(dep, visited, rec_stack, path, cycles)
			elif rec_stack.has(dep) and rec_stack[dep]:
				# Found cycle
				var cycle_start = path.find(dep)
				if cycle_start >= 0:
					var cycle = path.slice(cycle_start)
					cycle.append(dep)
					cycles.append(cycle)
	
	rec_stack[node] = false
	path.pop_back()

## Get graph visualization as text
static func get_graph_visualization(root_path: String = "res://", max_depth: int = 3) -> String:
	build_graph(root_path)
	
	var visualization = "DEPENDENCY GRAPH VISUALIZATION\n"
	visualization += "=" * 60 + "\n\n"
	
	# Group by depth
	var depth_map = {}
	for node_path in _nodes:
		var depth = _calculate_depth(node_path)
		if not depth_map.has(depth):
			depth_map[depth] = []
		depth_map[depth].append(node_path)
	
	# Sort depths
	var depths = depth_map.keys()
	depths.sort()
	
	for depth in depths:
		if depth > max_depth:
			break
		
		visualization += f"Depth {depth}:\n"
		for node_path in depth_map[depth]:
			var node = _nodes[node_path]
			visualization += f"  {node_path}\n"
			if node.metadata.has("class_name") and node.metadata.class_name != "":
				visualization += f"    Class: {node.metadata.class_name}\n"
			if node.dependencies.size() > 0:
				visualization += f"    Depends on: {', '.join(node.dependencies.slice(0, 5))}\n"
			if node.dependents.size() > 0:
				visualization += f"    Used by: {', '.join(node.dependents.slice(0, 5))}\n"
		visualization += "\n"
	
	# Check for circular dependencies
	var cycles = find_circular_dependencies()
	if cycles.size() > 0:
		visualization += "⚠️ CIRCULAR DEPENDENCIES DETECTED:\n"
		for cycle in cycles:
			visualization += f"  {' -> '.join(cycle)} -> {cycle[0]}\n"
	
	return visualization

## Calculate depth of a node (distance from root dependencies)
static func _calculate_depth(node_path: String, visited: Dictionary = {}) -> int:
	if visited.has(node_path):
		return 0
	
	visited[node_path] = true
	
	if not _graph.has(node_path) or _graph[node_path].dependencies.size() == 0:
		return 0
	
	var max_depth = 0
	for dep in _graph[node_path].dependencies:
		var dep_depth = _calculate_depth(dep, visited) + 1
		if dep_depth > max_depth:
			max_depth = dep_depth
	
	return max_depth

## Resolve relative path
static func _resolve_path(from_path: String, relative_path: String) -> String:
	if relative_path.begins_with("res://"):
		return relative_path.trim_prefix("res://")
	
	var base_dir = from_path.get_base_dir()
	if base_dir == "":
		base_dir = "."
	
	return base_dir.path_join(relative_path).simplify_path()

## Get graph statistics
static func get_statistics() -> Dictionary:
	var stats = {
		"total_nodes": _nodes.size(),
		"total_edges": 0,
		"max_dependencies": 0,
		"max_dependents": 0,
		"circular_dependencies": find_circular_dependencies().size()
	}
	
	for node_path in _graph:
		var deps_count = _graph[node_path].dependencies.size()
		var dependents_count = _graph[node_path].dependents.size()
		stats.total_edges += deps_count
		if deps_count > stats.max_dependencies:
			stats.max_dependencies = deps_count
		if dependents_count > stats.max_dependents:
			stats.max_dependents = dependents_count
	
	return stats
