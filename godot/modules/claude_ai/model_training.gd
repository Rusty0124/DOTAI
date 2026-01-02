@tool
extends RefCounted

## Custom Model Training
## Train models on your specific codebase patterns

class_name ModelTraining

## Training configuration
class TrainingConfig:
	var codebase_path: String = "res://"
	var output_model_path: String = "user://trained_model"
	var epochs: int = 10
	var learning_rate: float = 0.001
	var batch_size: int = 32
	var patterns_to_learn: Array = []

## Generate training data from codebase
static func generate_training_data(codebase_path: String = "res://") -> Dictionary:
	var structure = CodebaseScanner.scan_and_cache_project(codebase_path)
	var training_data = {
		"examples": [],
		"patterns": [],
		"statistics": {}
	}
	
	# Extract code patterns
	for script_info in structure.scripts:
		var metadata = structure.metadata.get(script_info.path, null)
		if metadata:
			var example = {
				"file": script_info.path,
				"class_name": metadata.class_name,
				"extends": metadata.extends_class,
				"functions": metadata.functions,
				"signals": metadata.signals,
				"pattern": _extract_pattern(metadata)
			}
			training_data.examples.append(example)
			training_data.patterns.append(example.pattern)
	
	training_data.statistics = {
		"total_files": structure.scripts.size(),
		"unique_patterns": training_data.patterns.size(),
		"average_functions": _calculate_average(training_data.examples, "functions")
	}
	
	return training_data

## Extract pattern from metadata
static func _extract_pattern(metadata) -> Dictionary:
	return {
		"type": "class" if metadata.class_name != "" else "script",
		"extends": metadata.extends_class,
		"function_count": metadata.functions.size(),
		"signal_count": metadata.signals.size()
	}

## Calculate average
static func _calculate_average(examples: Array, field: String) -> float:
	if examples.size() == 0:
		return 0.0
	
	var total = 0.0
	for example in examples:
		if example.has(field):
			var value = example[field]
			if value is Array:
				total += value.size()
			elif value is float or value is int:
				total += value
	
	return total / float(examples.size())

## Train model on codebase
func train_model(config: TrainingConfig, api_handler: Node) -> void:
	var training_data = generate_training_data(config.codebase_path)
	
	var prompt = f"""Train a custom model based on this codebase:

Training Data:
- Files: {training_data.statistics.total_files}
- Patterns: {training_data.statistics.unique_patterns}
- Average functions per file: {training_data.statistics.average_functions}

Code Patterns:
{_format_patterns(training_data.patterns)}

Learn these patterns and generate code that follows the same style and structure."""
	
	var params = {
		"prompt": prompt,
		"include_codebase": true
	}
	
	if api_handler.has_method("send_request"):
		api_handler.send_request(params)

## Format patterns for prompt
static func _format_patterns(patterns: Array) -> String:
	var formatted = ""
	for i in range(min(patterns.size(), 10)):  # Limit to 10 patterns
		var pattern = patterns[i]
		formatted += f"- {pattern}\n"
	return formatted

## Fine-tune model with examples
func fine_tune_model(examples: Array, api_handler: Node) -> void:
	var prompt = "Fine-tune the model with these examples:\n\n"
	
	for i in range(min(examples.size(), 20)):  # Limit examples
		var example = examples[i]
		prompt += f"Example {i + 1}:\n{example}\n\n"
	
	prompt += "Learn from these examples and apply similar patterns in future code generation."
	
	var params = {
		"prompt": prompt,
		"include_codebase": true
	}
	
	if api_handler.has_method("send_request"):
		api_handler.send_request(params)
