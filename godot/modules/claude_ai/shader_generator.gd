@tool
extends RefCounted

## Shader Generator
## AI-powered shader code generation

class_name ShaderGenerator

## Generate shader from description
static func generate_shader(description: String, shader_type: String = "canvas_item") -> String:
	var shader_code = ""
	
	match shader_type:
		"canvas_item":
			shader_code = _generate_canvas_item_shader(description)
		"spatial":
			shader_code = _generate_spatial_shader(description)
		"particles":
			shader_code = _generate_particle_shader(description)
		_:
			shader_code = _generate_canvas_item_shader(description)
	
	return shader_code

## Generate canvas item shader
static func _generate_canvas_item_shader(description: String) -> String:
	var shader = """shader_type canvas_item;

// Generated shader based on: """ + description + """

void fragment() {
	COLOR = texture(TEXTURE, UV);
"""
	
	# Add effects based on description
	if "glow" in description.to_lower() or "glowing" in description.to_lower():
		shader += """
	// Glow effect
	COLOR.rgb += vec3(0.2, 0.2, 0.3);
"""
	
	if "pulse" in description.to_lower() or "pulsing" in description.to_lower():
		shader += """
	// Pulsing effect
	float pulse = sin(TIME * 2.0) * 0.1 + 1.0;
	COLOR.rgb *= pulse;
"""
	
	if "color" in description.to_lower() or "tint" in description.to_lower():
		shader += """
	// Color tint
	COLOR.rgb *= vec3(1.0, 0.8, 0.8);
"""
	
	shader += "}\n"
	return shader

## Generate spatial shader
static func _generate_spatial_shader(description: String) -> String:
	var shader = """shader_type spatial;
render_mode unshaded;

// Generated spatial shader based on: """ + description + """

void vertex() {
	// Vertex shader code
}

void fragment() {
	ALBEDO = vec3(1.0, 1.0, 1.0);
"""
	
	if "metallic" in description.to_lower():
		shader += """
	METALLIC = 0.8;
	ROUGHNESS = 0.2;
"""
	
	shader += "}\n"
	return shader

## Generate particle shader
static func _generate_particle_shader(description: String) -> String:
	return """shader_type particles;

// Generated particle shader based on: """ + description + """

void vertex() {
	// Particle vertex shader
	COLOR = vec4(1.0, 1.0, 1.0, 1.0);
}
"""

## Generate AI shader
func generate_ai_shader(description: String, shader_type: String, api_handler: Node) -> void:
	var prompt = f"""Generate a Godot {shader_type} shader based on this description:

{description}

Requirements:
- Use proper shader syntax
- Include all necessary uniforms
- Add comments explaining the code
- Optimize for performance
- Follow Godot shader conventions"""
	
	var params = {
		"prompt": prompt,
		"include_codebase": false
	}
	
	if api_handler.has_method("send_request"):
		api_handler.send_request(params)

## Generate shader from image
func generate_shader_from_image(image_path: String, effect_type: String, api_handler: Node) -> void:
	var prompt = f"""Analyze this image and generate a shader that recreates or enhances the visual effect:

Image: {image_path}
Effect Type: {effect_type}

Generate a complete shader code that produces similar visual effects."""
	
	var params = {
		"prompt": prompt,
		"include_codebase": false
	}
	
	if api_handler.has_method("send_request"):
		api_handler.send_request(params)
