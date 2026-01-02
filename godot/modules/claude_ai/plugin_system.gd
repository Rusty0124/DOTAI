@tool
extends Node

## Plugin System
## Extensible plugin architecture for custom AI features

class_name PluginSystem

signal plugin_loaded(plugin_name: String)
signal plugin_unloaded(plugin_name: String)
signal plugin_error(plugin_name: String, error: String)

var loaded_plugins: Dictionary = {}
var plugin_directory: String = "res://addons/dotai_plugins/"

## Load a plugin
func load_plugin(plugin_path: String) -> bool:
	var plugin_script = load(plugin_path)
	if plugin_script == null:
		plugin_error.emit(plugin_path.get_file(), "Failed to load plugin script")
		return false
	
	var plugin_instance = Node.new()
	plugin_instance.set_script(plugin_script)
	
	# Check if plugin has required methods
	if not plugin_instance.has_method("get_plugin_name"):
		plugin_error.emit(plugin_path.get_file(), "Plugin missing get_plugin_name() method")
		return false
	
	var plugin_name = plugin_instance.call("get_plugin_name")
	
	# Initialize plugin
	if plugin_instance.has_method("initialize"):
		plugin_instance.call("initialize", self)
	
	add_child(plugin_instance)
	loaded_plugins[plugin_name] = plugin_instance
	plugin_loaded.emit(plugin_name)
	
	return true

## Unload a plugin
func unload_plugin(plugin_name: String) -> bool:
	if not loaded_plugins.has(plugin_name):
		return false
	
	var plugin = loaded_plugins[plugin_name]
	
	# Cleanup
	if plugin.has_method("cleanup"):
		plugin.call("cleanup")
	
	plugin.queue_free()
	loaded_plugins.erase(plugin_name)
	plugin_unloaded.emit(plugin_name)
	
	return true

## Get loaded plugin
func get_plugin(plugin_name: String) -> Node:
	return loaded_plugins.get(plugin_name, null)

## Load all plugins from directory
func load_all_plugins() -> Array:
	var loaded = []
	var dir = DirAccess.open(plugin_directory)
	
	if dir == null:
		dir.make_dir_recursive(plugin_directory)
		return loaded
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".gd"):
			var plugin_path = plugin_directory + file_name
			if load_plugin(plugin_path):
				loaded.append(file_name)
		file_name = dir.get_next()
	
	return loaded

## Register plugin hook
func register_hook(hook_name: String, plugin_name: String, callback: Callable) -> void:
	if not loaded_plugins.has(plugin_name):
		return
	
	# Store hook registration
	if not has_meta("hooks"):
		set_meta("hooks", {})
	
	var hooks = get_meta("hooks")
	if not hooks.has(hook_name):
		hooks[hook_name] = []
	
	hooks[hook_name].append({
		"plugin": plugin_name,
		"callback": callback
	})

## Call plugin hooks
func call_hooks(hook_name: String, data: Dictionary = {}) -> Array:
	var results = []
	
	if not has_meta("hooks"):
		return results
	
	var hooks = get_meta("hooks")
	if not hooks.has(hook_name):
		return results
	
	for hook in hooks[hook_name]:
		if hook.callback.is_valid():
			var result = hook.callback.call(data)
			results.append(result)
	
	return results

## Get plugin list
func get_plugin_list() -> Array:
	var plugins = []
	for plugin_name in loaded_plugins:
		var plugin = loaded_plugins[plugin_name]
		var info = {
			"name": plugin_name,
			"enabled": true
		}
		if plugin.has_method("get_plugin_info"):
			var plugin_info = plugin.call("get_plugin_info")
			info.merge(plugin_info)
		plugins.append(info)
	return plugins
