@tool
extends Node

## Multi-Model Handler
## Supports multiple AI providers: Claude, GPT-4, GPT-3.5, and local models

class_name MultiModelHandler

signal request_complete(response_text: String)
signal request_error(error_message: String)

enum Provider {
	CLAUDE_ANTHROPIC,
	OPENAI_GPT4,
	OPENAI_GPT35,
	OLLAMA_LOCAL,
	CUSTOM_ENDPOINT
}

var current_provider: Provider = Provider.CLAUDE_ANTHROPIC
var http_request: HTTPRequest
var conversation_manager: Node = null

# Provider configurations
var provider_configs = {
	Provider.CLAUDE_ANTHROPIC: {
		"name": "Claude (Anthropic)",
		"url": "https://api.anthropic.com/v1/messages",
		"model": "claude-3-5-sonnet-20240620",
		"max_tokens": 32768,
		"header_key": "x-api-key",
		"version_header": "anthropic-version: 2023-06-01"
	},
	Provider.OPENAI_GPT4: {
		"name": "GPT-4 (OpenAI)",
		"url": "https://api.openai.com/v1/chat/completions",
		"model": "gpt-4-turbo-preview",
		"max_tokens": 16384,
		"header_key": "Authorization"
	},
	Provider.OPENAI_GPT35: {
		"name": "GPT-3.5 (OpenAI)",
		"url": "https://api.openai.com/v1/chat/completions",
		"model": "gpt-3.5-turbo",
		"max_tokens": 16384,
		"header_key": "Authorization"
	},
	Provider.OLLAMA_LOCAL: {
		"name": "Ollama (Local)",
		"url": "http://localhost:11434/api/chat",
		"model": "llama2",
		"max_tokens": 8192,
		"header_key": ""
	}
}

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

## Set the AI provider
func set_provider(provider: Provider, api_key: String = "", model_override: String = ""):
	current_provider = provider
	var config = provider_configs[provider]
	
	if model_override != "":
		config.model = model_override
	
	print("DotAI: Set provider to ", config.name)

## Send request to current provider
func send_request(params: Dictionary) -> void:
	var api_key: String = params.get("api_key", "")
	var prompt: String = params.get("prompt", "")
	var messages: Array = params.get("messages", [])
	var include_codebase: bool = params.get("include_codebase", true)
	var is_conversation: bool = params.get("is_conversation", true)
	
	# Try to get conversation manager from parent (API handler)
	if conversation_manager == null and get_parent() != null:
		if get_parent().has_method("get") and get_parent().get("conversation_manager") != null:
			conversation_manager = get_parent().get("conversation_manager")
	
	# If messages are already provided (enhanced with codebase context), use them
	# Otherwise, build messages from conversation manager if available
	if messages.is_empty():
		if conversation_manager != null and is_conversation:
			if prompt != "":
				conversation_manager.add_message("user", prompt)
			messages = conversation_manager.get_conversation_context()
		
		# Fallback to single message if no conversation
		if messages.is_empty():
			messages = [{"role": "user", "content": prompt}]
	
	if api_key.is_empty() and current_provider != Provider.OLLAMA_LOCAL:
		request_error.emit("API key is required for " + provider_configs[current_provider].name)
		return
	
	if prompt.is_empty() and messages.is_empty():
		request_error.emit("Prompt is required")
		return
	
	match current_provider:
		Provider.CLAUDE_ANTHROPIC:
			_send_claude_request(api_key, messages)
		Provider.OPENAI_GPT4, Provider.OPENAI_GPT35:
			_send_openai_request(api_key, messages)
		Provider.OLLAMA_LOCAL:
			_send_ollama_request(messages)
		_:
			request_error.emit("Unsupported provider")

## Send request to Claude API
func _send_claude_request(api_key: String, messages: Array):
	var config = provider_configs[Provider.CLAUDE_ANTHROPIC]
	
	var payload = {
		"model": config.model,
		"max_tokens": config.max_tokens,
		"messages": messages,
		"temperature": 0.6,
		"top_p": 0.95
	}
	
	var json_string = JSON.stringify(payload)
	var headers = [
		"Content-Type: application/json",
		config.header_key + ": " + api_key,
		config.version_header
	]
	
	var error = http_request.request(config.url, headers, HTTPClient.METHOD_POST, json_string)
	if error != OK:
		request_error.emit("Failed to create HTTP request: " + str(error))

## Send request to OpenAI API
func _send_openai_request(api_key: String, messages: Array):
	var config = provider_configs[current_provider]
	
	var payload = {
		"model": config.model,
		"messages": messages,
		"max_tokens": config.max_tokens,
		"temperature": 0.6
	}
	
	var json_string = JSON.stringify(payload)
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key
	]
	
	var error = http_request.request(config.url, headers, HTTPClient.METHOD_POST, json_string)
	if error != OK:
		request_error.emit("Failed to create HTTP request: " + str(error))

## Send request to Ollama (local model)
func _send_ollama_request(messages: Array):
	var config = provider_configs[Provider.OLLAMA_LOCAL]
	
	# Convert messages to Ollama format
	var ollama_messages = []
	for msg in messages:
		ollama_messages.append({
			"role": msg.role,
			"content": msg.content
		})
	
	var payload = {
		"model": config.model,
		"messages": ollama_messages,
		"stream": false
	}
	
	var json_string = JSON.stringify(payload)
	var headers = ["Content-Type: application/json"]
	
	var error = http_request.request(config.url, headers, HTTPClient.METHOD_POST, json_string)
	if error != OK:
		request_error.emit("Failed to connect to Ollama. Make sure Ollama is running on localhost:11434")

## Handle HTTP response
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
	var response_text = ""
	
	match current_provider:
		Provider.CLAUDE_ANTHROPIC:
			if response_data.has("content") and response_data.content is Array and response_data.content.size() > 0:
				if response_data.content[0].has("text"):
					response_text = response_data.content[0].text
		Provider.OPENAI_GPT4, Provider.OPENAI_GPT35:
			if response_data.has("choices") and response_data.choices is Array and response_data.choices.size() > 0:
				if response_data.choices[0].has("message") and response_data.choices[0].message.has("content"):
					response_text = response_data.choices[0].message.content
		Provider.OLLAMA_LOCAL:
			if response_data.has("message") and response_data.message.has("content"):
				response_text = response_data.message.content
	
	if response_text.is_empty():
		request_error.emit("Empty response from AI provider")
		return
	
	# Add response to conversation manager if available
	if conversation_manager != null:
		conversation_manager.add_message("assistant", response_text)
	
	request_complete.emit(response_text)

## Get available providers
static func get_available_providers() -> Array:
	return [
		{"id": Provider.CLAUDE_ANTHROPIC, "name": "Claude (Anthropic)"},
		{"id": Provider.OPENAI_GPT4, "name": "GPT-4 (OpenAI)"},
		{"id": Provider.OPENAI_GPT35, "name": "GPT-3.5 (OpenAI)"},
		{"id": Provider.OLLAMA_LOCAL, "name": "Ollama (Local)"}
	]

## Check if Ollama is available
static func check_ollama_available() -> bool:
	# This would require an async check, simplified for now
	return false  # Would need HTTPRequest to check
