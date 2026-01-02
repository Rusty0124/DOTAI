@tool
extends Node

## Claude AI API Handler (Direct API Mode)
## Handles HTTP requests directly to the Claude API
## For SaaS mode, use saas_api_handler.gd instead

signal request_complete(response_text: String)
signal request_error(error_message: String)
signal ai_question(question: String)  # AI is asking a question
signal conversation_updated()  # Conversation history updated

const CLAUDE_API_URL = "https://api.anthropic.com/v1/messages"
const MODEL = "claude-3-5-sonnet-20240620"  # Using latest Sonnet model for best quality
const MAX_TOKENS = 32768  # Increased for complete game generation (multiple files, scenes, scripts)

# Multi-model support
var multi_model_handler: MultiModelHandler = null
var use_multi_model: bool = false

# SaaS mode detection
const SAAS_API_URL = "https://api.dotai.dev"  # DotAI SaaS API URL
var use_saas_mode = false  # Set to true to use SaaS backend
var saas_handler = null  # Reference to SaaS handler if available

var http_request: HTTPRequest
var current_response_text: String = ""

# Cache loaded scripts
var _codebase_scanner_script = null
var _file_writer_script = null

# AI-Native Engine Components
var conversation_manager: ConversationManager = null

func _ready():
	# Check if SaaS handler is available and should be used
	_check_saas_mode()
	
	if not use_saas_mode:
		http_request = HTTPRequest.new()
		add_child(http_request)
		http_request.request_completed.connect(_on_request_completed)
	
	# Try to load scripts (with fallback paths)
	_codebase_scanner_script = _load_script("res://addons/claude_ai/codebase_scanner.gd", "res://codebase_scanner.gd")
	_file_writer_script = _load_script("res://addons/claude_ai/file_writer.gd", "res://file_writer.gd")
	
	# Initialize AI-Native Engine components
	_initialize_ai_native_components()

func _check_saas_mode():
	# SaaS mode DISABLED FOR TESTING - always use direct API mode
	use_saas_mode = false
	
	# Original SaaS mode check (commented out for testing)
	# var saas_script = _load_script("res://addons/claude_ai/saas_api_handler.gd", "res://saas_api_handler.gd")
	# if saas_script != null:
	# 	# Check if SaaS mode is enabled in config
	# 	var config = ConfigFile.new()
	# 	var config_path = "user://godot_ai_studio.cfg"
	# 	if config.load(config_path) == OK:
	# 		use_saas_mode = config.get_value("settings", "use_saas_mode", true)
	# 	else:
	# 		use_saas_mode = true  # Default to SaaS mode
	# 	
	# 	if use_saas_mode:
	# 		# Create SaaS handler instance
	# 		saas_handler = Node.new()
	# 		saas_handler.set_script(saas_script)
	# 		add_child(saas_handler)
	# 		
	# 		# Connect SaaS handler signals
	# 		if saas_handler.has_signal("request_complete"):
	# 			saas_handler.connect("request_complete", _on_saas_request_complete)
	# 		if saas_handler.has_signal("request_error"):
	# 			saas_handler.connect("request_error", _on_saas_request_error)
	# 		if saas_handler.has_signal("auth_status_changed"):
	# 			saas_handler.connect("auth_status_changed", _on_auth_status_changed)
	# 		if saas_handler.has_signal("usage_updated"):
	# 			saas_handler.connect("usage_updated", _on_usage_updated)

func _on_saas_request_complete(response_text: String):
	request_complete.emit(response_text)

func _on_saas_request_error(error_message: String):
	request_error.emit(error_message)

func _on_auth_status_changed(is_authenticated: bool):
	# Emit signal for UI to update
	pass  # Can be handled by UI

func _on_usage_updated(usage_data: Dictionary):
	# Emit signal for UI to update usage display
	pass  # Can be handled by UI

func _load_script(primary_path: String, fallback_path: String):
	var script = load(primary_path)
	if script == null:
		script = load(fallback_path)
	return script

func _initialize_ai_native_components():
	if conversation_manager == null:
		var conv_script = _load_script("res://addons/claude_ai/conversation_manager.gd", "res://conversation_manager.gd")
		if conv_script:
			var conv_node = Node.new()
			conv_node.set_script(conv_script)
			add_child(conv_node)
			
			if conv_node.has_method("start_conversation") and conv_node.has_method("add_message"):
				conversation_manager = conv_node
				conversation_manager.start_conversation()
				if conversation_manager.has_signal("conversation_updated"):
					conversation_manager.conversation_updated.connect(_on_conversation_updated)
				if conversation_manager.has_signal("ai_question"):
					conversation_manager.ai_question.connect(_on_ai_question)
			else:
				push_error("ConversationManager: Script loaded but missing required methods")
				conv_node.queue_free()
		else:
			push_warning("DotAI: conversation_manager.gd script not found")
	
	if multi_model_handler == null:
		var multi_model_script = _load_script("res://addons/claude_ai/multi_model_handler.gd", "res://multi_model_handler.gd")
		if multi_model_script:
			var handler_node = Node.new()
			handler_node.set_script(multi_model_script)
			add_child(handler_node)
			if handler_node.has_method("send_request"):
				multi_model_handler = handler_node
				multi_model_handler.request_complete.connect(_on_multi_model_complete)
				multi_model_handler.request_error.connect(_on_multi_model_error)

func send_request(params: Dictionary) -> void:
	var provider = params.get("provider", -1)
	if provider >= 0:
		if multi_model_handler == null:
			var multi_model_script = _load_script("res://addons/claude_ai/multi_model_handler.gd", "res://multi_model_handler.gd")
			if multi_model_script:
				var handler_node = Node.new()
				handler_node.set_script(multi_model_script)
				add_child(handler_node)
				if handler_node.has_method("send_request"):
					multi_model_handler = handler_node
					multi_model_handler.request_complete.connect(_on_multi_model_complete)
					multi_model_handler.request_error.connect(_on_multi_model_error)
		
		if multi_model_handler != null:
			use_multi_model = true
			# Pass conversation manager to multi-model handler
			if conversation_manager != null:
				multi_model_handler.conversation_manager = conversation_manager
			
			# Build enhanced prompt with codebase context BEFORE passing to multi-model handler
			var enhanced_messages = []
			if conversation_manager != null and is_conversation:
				enhanced_messages = conversation_manager.get_conversation_context()
				# Add codebase context to the last user message if needed
				if include_codebase and enhanced_messages.size() > 0:
					var last_user_idx = -1
					for i in range(enhanced_messages.size() - 1, -1, -1):
						if enhanced_messages[i].role == "user":
							last_user_idx = i
							break
					if last_user_idx >= 0:
						var original_content = enhanced_messages[last_user_idx].content
						var enhanced_content = _build_enhanced_prompt(original_content, include_codebase)
						enhanced_messages[last_user_idx].content = enhanced_content
			else:
				# Single-shot mode - build enhanced prompt
				var enhanced_prompt = _build_enhanced_prompt(prompt, include_codebase)
				enhanced_messages = [{"role": "user", "content": enhanced_prompt}]
			
			# Update params with enhanced messages
			params["messages"] = enhanced_messages
			
			multi_model_handler.set_provider(provider, params.get("api_key", ""), params.get("model", ""))
			multi_model_handler.send_request(params)
			return
	
	# If SaaS mode is enabled, delegate to SaaS handler
	if use_saas_mode and saas_handler != null:
		if saas_handler.has_method("send_request"):
			saas_handler.call("send_request", params)
			return
		else:
			request_error.emit("SaaS handler not properly initialized")
			return
	
	# Direct API mode (original implementation)
	var api_key: String = params.get("api_key", "")
	var prompt: String = params.get("prompt", "")
	var include_codebase: bool = params.get("include_codebase", true)
	var is_conversation: bool = params.get("is_conversation", true)  # Default to conversation mode
	
	# API key is required
	if api_key.is_empty():
		request_error.emit("API key is required. Please provide your Claude API key in the DotAI panel or use SaaS mode.")
		return
	
	if prompt.is_empty():
		request_error.emit("Prompt is required")
		return
	
	if conversation_manager != null and is_conversation:
		conversation_manager.add_message("user", prompt)
	
	# Build conversation context
	var messages = []
	if conversation_manager != null and is_conversation:
		# Use conversation history (get a copy so we can modify it)
		messages = conversation_manager.get_conversation_context()
		
		# Add codebase context to the last user message if needed
		if include_codebase and messages.size() > 0:
			# Find the last user message
			var last_user_idx = -1
			for i in range(messages.size() - 1, -1, -1):
				if messages[i].role == "user":
					last_user_idx = i
					break
			
			if last_user_idx >= 0:
				var original_content = messages[last_user_idx].content
				var enhanced_content = _build_enhanced_prompt(original_content, include_codebase)
				messages[last_user_idx].content = enhanced_content
	else:
		# Single-shot mode (no conversation)
		var enhanced_prompt = _build_enhanced_prompt(prompt, include_codebase)
		messages = [
			{
				"role": "user",
				"content": enhanced_prompt
			}
		]
	
	# Build the request payload with enhanced settings for game generation
	var payload = {
		"model": MODEL,
		"max_tokens": MAX_TOKENS,  # Maximum tokens for complete game generation
		"messages": messages,
		"temperature": 0.6,  # Lower temperature for more consistent, production-ready code
		"top_p": 0.95  # Focus on high-quality, complete responses
	}
	
	var json_string = JSON.stringify(payload)
	var headers = [
		"Content-Type: application/json",
		"x-api-key: " + api_key,
		"anthropic-version: 2023-06-01"
	]
	
	var error = http_request.request(CLAUDE_API_URL, headers, HTTPClient.METHOD_POST, json_string)
	if error != OK:
		request_error.emit("Failed to create HTTP request: " + str(error))

func _build_enhanced_prompt(user_prompt: String, include_codebase: bool) -> String:
	var system_prompt = """You are DotAI, an AI assistant that generates complete, playable games for Godot Engine.

Your goal is to transform game ideas into fully functional games that can be run immediately. Generate all necessary files (scripts, scenes, resources) in a single response.

Requirements:
- Always use file markers: # File: path/to/file.ext (paths relative to res://)
- Create complete, functional code - no placeholders or TODOs
- Generate all files needed for a playable game in one response
- Use proper GDScript: type hints, error handling, node caching
- Follow Godot conventions: snake_case for vars/funcs, PascalCase for classes
- Organize files: scripts/player/, scripts/enemies/, scripts/managers/, scripts/ui/, scenes/

For each game request, create:
1. Main scene (scenes/main.tscn) with all game elements
2. Player controller script with movement
3. Game manager for state/score
4. UI/HUD scripts
5. Enemy/entity scripts if needed
6. Any other systems mentioned

Code quality:
- Type hints: @export var name: Type
- Error handling: null checks, validation
- Performance: cache nodes with @onready, avoid repeated get_node calls
- Signals: declare at class level, connect properly
- Comments: explain why, not just what

Example structure:
# File: scenes/main.tscn
[gd_scene format=3]
[node name="Main" type="Node2D"]
...

# File: scripts/player/player.gd
extends CharacterBody2D
@export var speed: float = 300.0
...

User Request: """ + user_prompt

	if include_codebase:
		if _codebase_scanner_script != null:
			var project_summary = CodebaseScanner.get_project_summary("res://")
			var relevant_files = CodebaseScanner.get_relevant_files(user_prompt, "res://", 12)
			
			var context_prompt = "\n\nProject Context:\n" + project_summary
			
			if relevant_files.size() > 0:
				context_prompt += "\n\nRelevant Files:\n"
				for i in range(relevant_files.size()):
					var file_data = relevant_files[i]
					var file_header = "[" + str(i + 1) + "] " + file_data.path
					
					if file_data.has("class_name") and file_data.class_name != "":
						file_header += " (class: " + file_data.class_name + ")"
					if file_data.has("extends") and file_data.extends != "":
						file_header += " extends " + file_data.extends
					
					context_prompt += file_header + "\n"
					
					var content = file_data.content
					var max_length = 3000
					if content.length() > max_length:
						var first_part = content.substr(0, max_length / 2)
						var last_part = content.substr(content.length() - max_length / 2)
						content = first_part + "\n\n... [truncated] ...\n\n" + last_part
					
					context_prompt += "```gdscript\n" + content + "\n```\n\n"
			
			context_prompt += "\nWhen generating code:\n"
			context_prompt += "- Match existing code style and patterns\n"
			context_prompt += "- Follow the project's file organization\n"
			context_prompt += "- Consider dependencies when modifying files\n"
			context_prompt += "- Maintain consistency with existing architecture\n"
			
			system_prompt += context_prompt
	
	system_prompt += "\n\nOutput Format:\n"
	system_prompt += "- Use file markers: # File: path/to/file.ext\n"
	system_prompt += "- Create all files in one response\n"
	system_prompt += "- No placeholders or incomplete code\n"
	system_prompt += "- Paths relative to res://\n"
	system_prompt += "- Complete, production-ready code only\n"

	return system_prompt

func _build_project_summary_from_graph() -> String:
	# Project summary is now built by CodebaseScanner
	return ""

func _build_relevant_files_from_context(context: Dictionary) -> Array:
	var files = []
	
	# Add target file
	if context.has("target") and context.target != "":
		files.append({"path": context.target, "relation": "target"})
	
	# Add dependencies
	if context.has("dependencies"):
		for dep in context.dependencies:
			files.append({"path": dep, "relation": "dependency"})
	
	# Add dependents
	if context.has("dependents"):
		for dep in context.dependents:
			files.append({"path": dep, "relation": "dependent"})
	
	return files

func _on_conversation_updated() -> void:
	conversation_updated.emit()

func _on_ai_question(question: String) -> void:
	ai_question.emit(question)

## Get conversation history
func get_conversation_history() -> Array:
	if conversation_manager != null:
		return conversation_manager.get_formatted_conversation()
	return []

## Clear conversation
func clear_conversation() -> void:
	if conversation_manager != null:
		conversation_manager.clear_history()

## Start new conversation
func start_new_conversation() -> void:
	if conversation_manager != null:
		conversation_manager.start_conversation()

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		request_error.emit("HTTP request failed: " + str(result))
		return
	
	if response_code != 200:
		var error_msg = "API request failed with code: " + str(response_code)
		var body_text = body.get_string_from_utf8()
		if body_text:
			error_msg += "\n" + body_text
		request_error.emit(error_msg)
		return
	
	var json = JSON.new()
	var parse_error = json.parse(body.get_string_from_utf8())
	if parse_error != OK:
		request_error.emit("Failed to parse JSON response: " + str(parse_error))
		return
	
	var response_data = json.data
	if not response_data.has("content"):
		request_error.emit("Invalid API response format")
		return
	
	var content = response_data["content"]
	if content is Array and content.size() > 0:
		var first_content = content[0]
		if first_content.has("text"):
			var response_text = first_content["text"]
			
			# Add AI response to conversation
			if conversation_manager != null:
				conversation_manager.add_message("assistant", response_text)
			
			# Check if AI is asking a question
			if conversation_manager != null and conversation_manager.detect_ai_question(response_text):
				var question = conversation_manager.extract_question(response_text)
				if question != "":
					ai_question.emit(question)
			
			# Emit full response for conversation display (keep full text, don't extract code)
			request_complete.emit(response_text)
		else:
			request_error.emit("Response content missing text field")
	else:
		request_error.emit("Empty response content")

func _extract_code(text: String) -> String:
	# Extract code from markdown code blocks if present
	var regex = RegEx.new()
	regex.compile("```(?:gdscript)?\\s*\\n([\\s\\S]*?)```")
	var result = regex.search(text)
	if result:
		return result.get_string(1).strip_edges()
	
	# Also check for inline code blocks
	regex.compile("`([^`]+)`")
	result = regex.search(text)
	if result:
		return result.get_string(1).strip_edges()
	
	# If no code blocks found, return the whole text
	return text.strip_edges()

func write_files_to_codebase(params: Dictionary) -> Dictionary:
	var response_text: String = params.get("response_text", "")
	
	if response_text.is_empty():
		return {"success": false, "error": "No response text provided"}
	
	if _file_writer_script == null:
		return {"success": false, "error": "file_writer.gd script not found"}
	
	var result = FileWriter.parse_and_write_files(response_text, "res://")
	
	# Return comprehensive result
	var return_dict = {
		"success": result.files_failed.size() == 0,
		"files_written": result.files_written,
		"files_failed": result.files_failed,
		"messages": result.messages,
		"error": "" if result.files_failed.size() == 0 else "Some files failed to write"
	}
	
	# Add created/modified info if available
	if result.has("files_created"):
		return_dict["files_created"] = result.files_created
	if result.has("files_modified"):
		return_dict["files_modified"] = result.files_modified
	
	# Refresh editor file system after writing
	if Engine.is_editor_hint():
		call_deferred("_refresh_file_system")
	
	if result.success and result.files_created.size() > 0:
		var game_engine_script = load("res://addons/claude_ai/game_engine_core.gd")
		if game_engine_script == null:
			game_engine_script = load("res://game_engine_core.gd")
		
		if game_engine_script:
			GameEngineCore.post_process_generated_files(result.files_created)
		else:
			for file_path in result.files_created:
				if file_path.ends_with("main.tscn") or file_path.ends_with("main_scene.tscn"):
					var project_settings = ProjectSettings.get_singleton()
					if project_settings:
						project_settings.set_setting("application/run/main_scene", "res://" + file_path)
						project_settings.save()
					break
	
	return return_dict

func _refresh_file_system():
	if Engine.is_editor_hint():
		EditorFileSystem.get_singleton().scan_changes()

func _on_multi_model_complete(response_text: String):
	request_complete.emit(response_text)

func _on_multi_model_error(error_message: String):
	request_error.emit(error_message)