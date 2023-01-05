@tool
extends EditorPlugin

const Templates = preload("res://addons/github_to_itch/templates.gd")
const ConfigPopup = preload("res://addons/github_to_itch/popup.tscn")
const workflow_path = "res://.github/workflows/github_to_itch.yml"

var template_helper:Templates = Templates.new()
var timer = Timer.new()
var popup = ConfigPopup.instantiate()
var last_exports_modified_time:int
var last_project_modified_time:int

func save(forced = false):
	
	var export_modified_time = FileAccess.get_modified_time("res://export_presets.cfg")
	var project_modified_time = FileAccess.get_modified_time("res://project.godot")
	
	if forced or export_modified_time != last_exports_modified_time or project_modified_time != last_project_modified_time:
		last_exports_modified_time = export_modified_time
		last_project_modified_time = project_modified_time
	
		var workflow_directory = workflow_path.get_base_dir()
		if not DirAccess.dir_exists_absolute(workflow_directory):
			DirAccess.make_dir_recursive_absolute(workflow_directory)
		
		var file = FileAccess.open(workflow_path, FileAccess.WRITE)
		file.store_string(template_helper.workflow())

func _enter_tree():
	
	timer.one_shot = true
	timer.wait_time = 1.0
	timer.connect("timeout", _timer_timeout)
	
	add_child(timer)
	
	_timer_timeout()
	connect("project_settings_changed", func(): save(true))
	add_tool_menu_item("Github To Itch Config", show_popup)
	
	if not ProjectSettings.has_setting("github_to_itch/config/itch_username") || not ProjectSettings.has_setting("github_to_itch/config/itch_project_name"):
		show_popup()
	

func _exit_tree():
	remove_child(timer)
	if popup.get_parent():
		popup.get_parent().remove_child(popup)
	remove_tool_menu_item("Github To Itch Config")

func _timer_timeout():
	save()
	timer.start()

func show_popup():
	if not popup.get_parent():
		add_child(popup)
	popup.popup_centered(Vector2i(1000,600))
