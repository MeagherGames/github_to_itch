@tool
extends RefCounted

## Helper script to render the workflow yml file

const workflow_template_path:String = "res://addons/github_to_itch/tempaltes/workflow_template.yml"
const export_template_path:String = "res://addons/github_to_itch/tempaltes/export.yml"

const ITCH_PLATFORM_MAP = {
	"HTML5": "web",
	"Windows Desktop": "win",
	# TODO add the rest
}

var export_template:String = """  - name: Export {PLATFORM}
	run: |
	 mkdir -p {EXPORT_PATH}
	 ./godot --path ./project.godot --export "{NAME}" {EXPORT_FILE}
	
""".replace("\t", "    ")
var uploads_template:String = """	- name: Push {PLATFORM} to Itch
	  run: ./butler push {EXPORT_PATH} {ITCH_USERNAME}/{ITCH_PROJECT_NAME}:{ITCH_PLATFORM} --userversion-file ./VERSION/VERSION.txt
	
""".replace("\t", "    ")

static func get_version_info() -> Dictionary:
	var info = Engine.get_version_info()
	var version = str(info.major) + "." + str(info.minor)
	if info.patch != 0:
		version += "." + str(info.patch)
	
	return {
		version = version,
		status = info.status
	}

static func get_project_name() -> String:
	return ProjectSettings.get("application/config/name")

static func get_exports() -> Array[Dictionary]:
	var res:Array[Dictionary] = []
	var config := ConfigFile.new()
	config.load("res://export_presets.cfg")
	
	for section in config.get_sections():
		if config.get_value(section, "runnable", false):
			res.append({
				name = config.get_value(section, "name"),
				platform = config.get_value(section, "platform"),
				export_path = config.get_value(section, "export_path"),
			})
	
	return res

func exports() -> String:
	
	var exports = get_exports()
	
	var res:PackedStringArray
	for export in exports:
		res.append(export_template.format({
			NAME = export.name,
			PLATFORM = export.platform,
			EXPORT_PATH = export.export_path.get_base_dir(),
			EXPORT_FILE = export.export_path
		}))
	
	return "".join(res)

func uploads() -> String:
	var exports = get_exports()
	var ITCH_USERNAME = ProjectSettings.get_setting("github_to_itch/config/itch_username")
	var ITCH_PROJECT_NAME = ProjectSettings.get_setting("github_to_itch/config/itch_project_name")
	
	var res:PackedStringArray
	for export in exports:
		res.append(uploads_template.format({
			PLATFORM = export.platform,
			EXPORT_PATH = "./" + export.export_path.get_base_dir(),
			ITCH_PLATFORM = ITCH_PLATFORM_MAP[export.platform],
			ITCH_USERNAME = ITCH_USERNAME.to_lower(),
			ITCH_PROJECT_NAME = ITCH_PROJECT_NAME.to_lower()
		}))
	
	return "".join(res)

func workflow() -> String:
	var file := File.new()
	file.open(workflow_template_path, File.READ)
	var workflow_template = file.get_as_text()
	file.close()
	
	var version_info = get_version_info()
	var GODOT_PATH = version_info.version
	
	if version_info.status != "stable":
		GODOT_PATH += "/" + version_info.status
	
	return workflow_template.replace("\t", "    ").format({
		PROJECT_NAME = get_project_name(),
		GODOT_VERSION = version_info.version,
		GODOT_STATUS = version_info.status,
		GODOT_PATH = GODOT_PATH,
		ITCH_PROJECT_NAME = ProjectSettings.get_setting("github_to_itch/config/itch_project_name"),
		ITCH_USERNAME = ProjectSettings.get_setting("github_to_itch/config/itch_username"),
		EXPORTS_FROM_GODOT = exports(),
		UPLOADS_TO_ITCH = uploads()
	})
