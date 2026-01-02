@tool
extends RefCounted

## Version Control Integration
## AI-assisted git operations and commit messages

class_name VersionControl

## Generate commit message from changes
static func generate_commit_message(changed_files: Array, diff_summary: String = "") -> String:
	var message = "Update "
	
	if changed_files.size() == 1:
		message += changed_files[0].get_file()
	else:
		message += str(changed_files.size()) + " files"
	
	if diff_summary != "":
		message += "\n\n" + diff_summary
	
	return message

## Generate AI commit message
func generate_ai_commit_message(changed_files: Array, api_handler: Node) -> void:
	var prompt = "Generate a clear, concise git commit message for these changes:\n\n"
	
	for file_path in changed_files:
		prompt += f"- {file_path}\n"
	
	prompt += "\nFollow conventional commit format: type(scope): description"
	
	var params = {
		"prompt": prompt,
		"include_codebase": false
	}
	
	if api_handler.has_method("send_request"):
		api_handler.send_request(params)

## Analyze git diff
static func analyze_diff(diff_text: String) -> Dictionary:
	var analysis = {
		"files_changed": 0,
		"lines_added": 0,
		"lines_removed": 0,
		"files": []
	}
	
	var lines = diff_text.split("\n")
	var current_file = null
	
	for line in lines:
		if line.begins_with("diff --git"):
			if current_file != null:
				analysis.files.append(current_file)
			current_file = {
				"path": "",
				"additions": 0,
				"deletions": 0
			}
		elif line.begins_with("+++") and current_file != null:
			var path_match = RegEx.new()
			path_match.compile("\\+\\+\\+ b/(.+)")
			var match_result = path_match.search(line)
			if match_result:
				current_file.path = match_result.get_string(1)
		elif line.begins_with("+") and not line.begins_with("+++") and current_file != null:
			current_file.additions += 1
			analysis.lines_added += 1
		elif line.begins_with("-") and not line.begins_with("---") and current_file != null:
			current_file.deletions += 1
			analysis.lines_removed += 1
	
	if current_file != null:
		analysis.files.append(current_file)
		analysis.files_changed = analysis.files.size()
	
	return analysis

## Suggest branch name from changes
static func suggest_branch_name(changed_files: Array, feature_description: String = "") -> String:
	if feature_description != "":
		var branch_name = feature_description.to_lower()
		branch_name = branch_name.replace(" ", "-")
		branch_name = branch_name.replace(/[^a-z0-9-]/, "")
		return "feature/" + branch_name
	
	# Infer from file names
	var first_file = changed_files[0] if changed_files.size() > 0 else ""
	if first_file != "":
		var file_name = first_file.get_file().get_basename()
		return "feature/" + file_name.to_lower()
	
	return "feature/update"

## Check git status
static func get_git_status(project_path: String = ".") -> Dictionary:
	# This would require OS.execute to run git commands
	# Simplified version for now
	return {
		"has_changes": false,
		"modified_files": [],
		"untracked_files": []
	}

## Stage files for commit
static func stage_files(file_paths: Array) -> bool:
	# Would use OS.execute("git", ["add"] + file_paths)
	return true

## Create commit
static func create_commit(message: String, file_paths: Array = []) -> bool:
	# Would use OS.execute("git", ["commit", "-m", message] + file_paths)
	return true
