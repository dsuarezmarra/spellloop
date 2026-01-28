extends Node
class_name ReportWriter

func generate_report(results: Array) -> String:
	var user_dir = "user://test_reports/"
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("test_reports"):
		dir.make_dir("test_reports")
		
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var filename = "item_validation_report_%s.jsonl" % timestamp
	var full_path = user_dir + filename
	
	var file = FileAccess.open(full_path, FileAccess.WRITE)
	if not file:
		print("[ReportWriter] Failed to open file: %s" % full_path)
		return ""
		
	for res in results:
		file.store_line(JSON.stringify(res))
		
	return full_path
