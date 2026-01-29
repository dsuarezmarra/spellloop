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

func generate_summary_md(results: Array, output_path_jsonl: String) -> String:
	var md_path = output_path_jsonl.replace(".jsonl", ".md").replace("item_validation_report", "item_validation_summary")
	var file = FileAccess.open(md_path, FileAccess.WRITE)
	if not file:
		return ""
		
	var total = results.size()
	var passed = 0
	var failed = 0
	var scopes = {}
	var mech_count = 0
	
	for res in results:
		if res.get("success", false):
			passed += 1
		else:
			failed += 1
		
		var scope = res.get("scope", "UNKNOWN")
		scopes[scope] = scopes.get(scope, 0) + 1
		
		var subtests = res.get("subtests", [])
		for sub in subtests:
			if sub.get("type") == "mechanical_damage":
				mech_count += 1
				break
	
	file.store_line("# Item Validation Summary")
	file.store_line("Date: %s" % Time.get_datetime_string_from_system())
	file.store_line("")
	file.store_line("## Metrics")
	file.store_line("- **Total Tests**: %d" % total)
	file.store_line("- **Passed**: %d" % passed)
	file.store_line("- **Failed**: %d" % failed)
	file.store_line("- **Mechanical Verified**: %d" % mech_count)
	file.store_line("")
	file.store_line("## Scope Coverage")
	for s in scopes:
		file.store_line("- %s: %d" % [s, scopes[s]])
		
	file.store_line("")
	file.store_line("## Failures")
	if failed == 0:
		file.store_line("No failures.")
	else:
		for res in results:
			if not res.get("success", false):
				file.store_line("- **%s**: %s" % [res.get("item_id"), str(res.get("failures"))])
	
	return md_path
