@tool
extends RefCounted

## Animation Generator
## AI-assisted animation and tween creation

class_name AnimationGenerator

## Generate animation from description
static func generate_animation(description: String, animation_name: String = "generated_animation") -> Dictionary:
	var animation = Animation.new()
	animation.length = 1.0  # Default 1 second
	animation.loop_mode = Animation.LOOP_NONE
	
	# Parse description for animation properties
	var tracks = _parse_animation_description(description)
	
	for track_data in tracks:
		var track = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, track_data.path)
		animation.track_insert_key(track, 0.0, track_data.start_value)
		animation.track_insert_key(track, animation.length, track_data.end_value)
	
	return {
		"animation": animation,
		"tracks": tracks.size()
	}

## Parse animation description
static func _parse_animation_description(description: String) -> Array:
	var tracks = []
	var desc_lower = description.to_lower()
	
	# Position animations
	if "move" in desc_lower or "position" in desc_lower:
		if "left" in desc_lower or "x" in desc_lower:
			tracks.append({
				"path": "position:x",
				"start_value": 0.0,
				"end_value": -100.0
			})
		if "right" in desc_lower or "x" in desc_lower:
			tracks.append({
				"path": "position:x",
				"start_value": 0.0,
				"end_value": 100.0
			})
		if "up" in desc_lower or "y" in desc_lower:
			tracks.append({
				"path": "position:y",
				"start_value": 0.0,
				"end_value": -100.0
			})
		if "down" in desc_lower or "y" in desc_lower:
			tracks.append({
				"path": "position:y",
				"start_value": 0.0,
				"end_value": 100.0
			})
	
	# Rotation animations
	if "rotate" in desc_lower or "spin" in desc_lower:
		tracks.append({
			"path": "rotation",
			"start_value": 0.0,
			"end_value": TAU
		})
	
	# Scale animations
	if "scale" in desc_lower or "grow" in desc_lower or "shrink" in desc_lower:
		if "grow" in desc_lower or "bigger" in desc_lower:
			tracks.append({
				"path": "scale",
				"start_value": Vector2(1, 1),
				"end_value": Vector2(1.5, 1.5)
			})
		elif "shrink" in desc_lower or "smaller" in desc_lower:
			tracks.append({
				"path": "scale",
				"start_value": Vector2(1, 1),
				"end_value": Vector2(0.5, 0.5)
			})
	
	# Fade animations
	if "fade" in desc_lower or "opacity" in desc_lower:
		if "in" in desc_lower:
			tracks.append({
				"path": "modulate:a",
				"start_value": 0.0,
				"end_value": 1.0
			})
		elif "out" in desc_lower:
			tracks.append({
				"path": "modulate:a",
				"start_value": 1.0,
				"end_value": 0.0
			})
	
	return tracks

## Generate tween code
static func generate_tween_code(description: String, target_path: String = "self") -> String:
	var code = "var tween = create_tween()\n"
	var desc_lower = description.to_lower()
	
	# Parse description for tween properties
	if "move" in desc_lower:
		if "left" in desc_lower:
			code += f"tween.tween_property({target_path}, \"position:x\", position.x - 100, 1.0)\n"
		elif "right" in desc_lower:
			code += f"tween.tween_property({target_path}, \"position:x\", position.x + 100, 1.0)\n"
	
	if "rotate" in desc_lower:
		code += f"tween.tween_property({target_path}, \"rotation\", rotation + TAU, 1.0)\n"
	
	if "scale" in desc_lower:
		if "up" in desc_lower or "bigger" in desc_lower:
			code += f"tween.tween_property({target_path}, \"scale\", scale * 1.5, 1.0)\n"
		elif "down" in desc_lower or "smaller" in desc_lower:
			code += f"tween.tween_property({target_path}, \"scale\", scale * 0.5, 1.0)\n"
	
	if "fade" in desc_lower:
		if "in" in desc_lower:
			code += f"tween.tween_property({target_path}, \"modulate:a\", 1.0, 1.0)\n"
		elif "out" in desc_lower:
			code += f"tween.tween_property({target_path}, \"modulate:a\", 0.0, 1.0)\n"
	
	return code

## Generate AI animation
func generate_ai_animation(description: String, api_handler: Node) -> void:
	var prompt = f"""Generate Godot animation code based on this description:

{description}

Generate:
1. Animation resource code or AnimationPlayer setup
2. Tween code if appropriate
3. Complete, production-ready code
4. Include easing functions for smooth animations"""
	
	var params = {
		"prompt": prompt,
		"include_codebase": true
	}
	
	if api_handler.has_method("send_request"):
		api_handler.send_request(params)

## Generate animation from keyframes
static func generate_from_keyframes(keyframes: Array) -> Dictionary:
	var animation = Animation.new()
	animation.length = 0.0
	
	for keyframe in keyframes:
		if keyframe.time > animation.length:
			animation.length = keyframe.time
		
		var track = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, keyframe.property_path)
		animation.track_insert_key(track, keyframe.time, keyframe.value)
	
	return {"animation": animation, "keyframe_count": keyframes.size()}
