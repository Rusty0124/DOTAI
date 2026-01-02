@tool
extends RefCounted

## Multi-Language Support
## Support for C# and other Godot-supported languages

class_name MultiLanguageSupport

enum Language {
	GDSCRIPT,
	CSHARP,
	VISUAL_SCRIPT,
	CPP  # Future support
}

## Language configuration
static var language_configs = {
	Language.GDSCRIPT: {
		"name": "GDScript",
		"extension": ".gd",
		"comment_prefix": "#",
		"class_keyword": "class_name",
		"extends_keyword": "extends"
	},
	Language.CSHARP: {
		"name": "C#",
		"extension": ".cs",
		"comment_prefix": "//",
		"class_keyword": "public class",
		"extends_keyword": ":"
	}
}

## Detect language from file
static func detect_language(file_path: String) -> Language:
	if file_path.ends_with(".gd"):
		return Language.GDSCRIPT
	elif file_path.ends_with(".cs"):
		return Language.CSHARP
	elif file_path.ends_with(".vs"):
		return Language.VISUAL_SCRIPT
	return Language.GDSCRIPT

## Convert code between languages
static func convert_code(code: String, from_lang: Language, to_lang: Language) -> String:
	if from_lang == to_lang:
		return code
	
	match from_lang:
		Language.GDSCRIPT:
			match to_lang:
				Language.CSHARP:
					return _gdscript_to_csharp(code)
				_:
					return code
		Language.CSHARP:
			match to_lang:
				Language.GDSCRIPT:
					return _csharp_to_gdscript(code)
				_:
					return code
		_:
			return code

## Convert GDScript to C#
static func _gdscript_to_csharp(gd_code: String) -> String:
	var cs_code = gd_code
	
	# Basic conversions
	cs_code = cs_code.replace("extends ", "public class ")
	cs_code = cs_code.replace("class_name ", "public class ")
	cs_code = cs_code.replace("func ", "public void ")
	cs_code = cs_code.replace("var ", "public ")
	cs_code = cs_code.replace("const ", "public const ")
	cs_code = cs_code.replace("signal ", "public event ")
	cs_code = cs_code.replace(": float", ": float")
	cs_code = cs_code.replace(": int", ": int")
	cs_code = cs_code.replace(": String", ": string")
	cs_code = cs_code.replace(": bool", ": bool")
	cs_code = cs_code.replace(": Vector2", ": Vector2")
	cs_code = cs_code.replace(": Vector3", ": Vector3")
	
	# Replace GDScript-specific syntax
	cs_code = cs_code.replace("@export", "[Export]")
	cs_code = cs_code.replace("@onready", "[OnReady]")
	cs_code = cs_code.replace("_ready()", "_Ready()")
	cs_code = cs_code.replace("_process(", "_Process(")
	cs_code = cs_code.replace("_physics_process(", "_PhysicsProcess(")
	
	# Add using statements
	cs_code = "using Godot;\n\n" + cs_code
	
	return cs_code

## Convert C# to GDScript
static func _csharp_to_gdscript(cs_code: String) -> String:
	var gd_code = cs_code
	
	# Remove using statements
	gd_code = gd_code.replace("using Godot;\n\n", "")
	
	# Basic conversions
	gd_code = gd_code.replace("public class ", "extends ")
	gd_code = gd_code.replace("public void ", "func ")
	gd_code = gd_code.replace("public ", "var ")
	gd_code = gd_code.replace("public const ", "const ")
	gd_code = gd_code.replace("public event ", "signal ")
	gd_code = gd_code.replace(": float", ": float")
	gd_code = gd_code.replace(": int", ": int")
	gd_code = gd_code.replace(": string", ": String")
	gd_code = gd_code.replace(": bool", ": bool")
	gd_code = gd_code.replace(": Vector2", ": Vector2")
	gd_code = gd_code.replace(": Vector3", ": Vector3")
	
	# Replace C#-specific syntax
	gd_code = gd_code.replace("[Export]", "@export")
	gd_code = gd_code.replace("[OnReady]", "@onready")
	gd_code = gd_code.replace("_Ready()", "_ready()")
	gd_code = gd_code.replace("_Process(", "_process(")
	gd_code = gd_code.replace("_PhysicsProcess(", "_physics_process(")
	
	return gd_code

## Generate code in specific language
static func generate_code(language: Language, template: String, variables: Dictionary) -> String:
	var config = language_configs.get(language, language_configs[Language.GDSCRIPT])
	var code = template
	
	# Replace variables
	for key in variables:
		code = code.replace("{{" + key + "}}", str(variables[key]))
	
	# Apply language-specific formatting
	match language:
		Language.GDSCRIPT:
			code = _format_gdscript(code)
		Language.CSHARP:
			code = _format_csharp(code)
	
	return code

## Format GDScript code
static func _format_gdscript(code: String) -> String:
	# Basic GDScript formatting
	var lines = code.split("\n")
	var formatted = []
	var indent_level = 0
	
	for line in lines:
		var stripped = line.strip_edges()
		if stripped.begins_with("func ") or stripped.begins_with("class "):
			indent_level = 0
		elif stripped.begins_with("if ") or stripped.begins_with("for ") or stripped.begins_with("while "):
			formatted.append("\t" * indent_level + stripped)
			indent_level += 1
		elif stripped == "else:" or stripped == "elif ":
			indent_level = max(0, indent_level - 1)
			formatted.append("\t" * indent_level + stripped)
			indent_level += 1
		else:
			formatted.append("\t" * indent_level + stripped)
	
	return "\n".join(formatted)

## Format C# code
static func _format_csharp(code: String) -> String:
	# Basic C# formatting
	var lines = code.split("\n")
	var formatted = []
	var indent_level = 0
	
	for line in lines:
		var stripped = line.strip_edges()
		if stripped.contains("{"):
			formatted.append("    " * indent_level + stripped)
			indent_level += 1
		elif stripped.contains("}"):
			indent_level = max(0, indent_level - 1)
			formatted.append("    " * indent_level + stripped)
		else:
			formatted.append("    " * indent_level + stripped)
	
	return "\n".join(formatted)

## Get language info
static func get_language_info(language: Language) -> Dictionary:
	return language_configs.get(language, {})

## Check if language is supported
static func is_language_supported(language: Language) -> bool:
	return language_configs.has(language)
