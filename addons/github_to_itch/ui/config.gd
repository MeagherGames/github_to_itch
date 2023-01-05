@tool
extends ScrollContainer

@onready var itch_username = get_node("%Username")
@onready var itch_project_name = get_node("%ProjectName")

func _ready():
	if ProjectSettings.has_setting("github_to_itch/config/itch_username"):
		itch_username.text = ProjectSettings.get_setting("github_to_itch/config/itch_username")
	else:
		ProjectSettings.set_setting("github_to_itch/config/itch_username", "")
		ProjectSettings.add_property_info({
			name = "github_to_itch/config/itch_username",
			type = TYPE_STRING
		})
	if ProjectSettings.has_setting("github_to_itch/config/itch_project_name"):
		itch_project_name.text = ProjectSettings.get_setting("github_to_itch/config/itch_project_name")
	else:
		ProjectSettings.set_setting("github_to_itch/config/itch_project_name", "")
		ProjectSettings.add_property_info({
			name = "github_to_itch/config/itch_project_name",
			type = TYPE_STRING
		})

func _on_meta_clicked(meta):
	OS.shell_open(meta)

func _on_username_text_changed(new_text):
	ProjectSettings.set_setting("github_to_itch/config/itch_username", new_text)
	ProjectSettings.save()

func _on_project_name_text_changed(new_text):
	ProjectSettings.set_setting("github_to_itch/config/itch_project_name", new_text)
	ProjectSettings.save()
