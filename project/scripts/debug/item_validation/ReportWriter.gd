extends Node
class_name ReportWriter

func generate_report(results: Array, metadata: Dictionary = {}) -> String:
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
		
	# First line: Metadata
	var meta_wrapped = {"type": "metadata", "data": metadata}
	file.store_line(JSON.stringify(meta_wrapped))
	
	for res in results:
		file.store_line(JSON.stringify(res))
		
	file.close() # Explicit close
	return full_path

func generate_summary_md(results_mem: Array, jsonl_path: String, metadata: Dictionary = {}) -> String:
	var md_path = jsonl_path.replace(".jsonl", ".md").replace("item_validation_report", "item_validation_summary")
	var file = FileAccess.open(md_path, FileAccess.WRITE)
	if not file:
		return ""
		
	# ROBUST PARSING OF JSONL
	var results = []
	var parse_errors = 0
	var meta_from_file = {}
	
	var r_file = FileAccess.open(jsonl_path, FileAccess.READ)
	if r_file:
		while not r_file.eof_reached():
			var line = r_file.get_line().strip_edges()
			if line.is_empty(): continue
			
			var json = JSON.new()
			var error = json.parse(line)
			if error != OK:
				parse_errors += 1
				continue
				
			var data = json.get_data()
			if typeof(data) == TYPE_DICTIONARY:
				if data.get("type") == "metadata":
					meta_from_file = data.get("data", {})
				else:
					# Validate schema
					if _validate_entry(data):
						results.append(data)
					else:
						data["PARSE_ERROR"] = true
						results.append(data)
						parse_errors += 1
		r_file.close() # Explicit close reader
	else:
		# Fallback to memory if file read fails (unlikely)
		results = results_mem
		
	var total = results.size()
	var passed = 0
	var violations = 0
	var bugs = 0
	var scopes = {}
	var deltas = []
	
	for res in results:
		if res.get("PARSE_ERROR", false): continue
		
		var item_id = res.get("item_id", "unknown")
		var is_success = res.get("success", false)
		var scope = res.get("scope", "UNKNOWN")
		scopes[scope] = scopes.get(scope, 0) + 1
		
		var subtests = res.get("subtests", [])
		var has_violation = false
		var has_bug = false
		
		for sub in subtests:
			var res_data = sub.get("res", {})
			var code = res_data.get("result_code", "PASS")
			if code == "BUG": has_bug = true
			elif code == "DESIGN_VIOLATION": has_violation = true
			
			if sub.get("type") == "mechanical_damage":
				var delta = res_data.get("delta_percent", 0.0)
				deltas.append({"id": item_id, "delta": delta, "actual": res_data.get("actual"), "expected": res_data.get("expected")})
		
		if has_bug: bugs += 1
		elif has_violation: violations += 1
		
		if is_success: passed += 1
	
	# Write MD Content
	file.store_line("# Item Validation Summary")
	file.store_line("Date: %s" % metadata.get("started_at", "N/A"))
	file.store_line("Run ID: %s" % metadata.get("run_id", "N/A"))
	file.store_line("Total Tests: %d" % total)
	file.store_line("- Passed: %d" % passed)
	file.store_line("- Violations: %d" % violations)
	file.store_line("- Bugs: %d" % bugs)
	file.store_line("- Parse Errors: %d" % parse_errors)

	file.store_line("\n## Status Verification Results")
	file.store_line("| Item ID | Status | Result | Details |")
	file.store_line("|---|---|---|---|")

	for res in results:
		var item_id = res.get("item_id", "unknown")
		var subtests = res.get("subtests", [])
		for sub in subtests:
			if sub.get("type") == "status_verification":
				var status = sub.get("status", "N/A")
				var r_res = sub.get("res", {})
				var r_pass = "✅" if r_res.get("passed", false) else "❌"
				var reason = r_res.get("reason", "No details")
				file.store_line("| %s | %s | %s | %s |" % [item_id, status, r_pass, reason])
	
	deltas.sort_custom(func(a, b): return abs(a["delta"]) > abs(b["delta"]))
	
	file.store_line("")
	file.store_line("## Metadata")
	file.store_line("- **Started At**: %s" % metadata.get("started_at", "N/A"))
	file.store_line("- **Git Commit**: %s" % metadata.get("git_commit", "N/A"))
	file.store_line("- **Duration**: %d ms" % metadata.get("duration_ms", 0))
	file.store_line("- **Seed**: %d" % metadata.get("test_seed", 1337))
	file.store_line("- **Scheduled Tests**: %d" % metadata.get("scheduled_tests_count", 0))
	file.store_line("- **Parsed Tests**: %d" % results.size())
	file.store_line("- **Parse Errors**: %d" % parse_errors)
	if metadata.get("is_measure_mode"):
		file.store_line("- **Mode**: MEASURE ONLY")
	if metadata.get("empty_reason"):
		file.store_line("- **Empty Queue Reason**: %s" % metadata.get("empty_reason"))
	
	if total == 0:
		file.store_line("")
		file.store_line("> [!CAUTION]")
		file.store_line("> **RUN FAILED**: Zero tests were parsed. Check logs for engine crash or empty queue.")
	file.store_line("")
	file.store_line("## Metrics")
	file.store_line("- **Total Valid Items**: %d" % results.size())
	file.store_line("- **%% Passed**: %.1f%% (%d)" % [(float(passed)/total*100) if total > 0 else 0, passed])
	file.store_line("- **%% Design Violations**: %.1f%% (%d)" % [(float(violations)/total*100) if total > 0 else 0, violations])
	file.store_line("- **Bugs Detected**: %d" % bugs)
	file.store_line("")
	file.store_line("## Top 20 Most Extreme Deltas")
	file.store_line("| Item | Delta %% | Actual | Expected |")
	file.store_line("| :--- | :--- | :--- | :--- |")
	for i in range(min(20, deltas.size())):
		var d = deltas[i]
		file.store_line("| %s | %.1f%% | %.1f | %.1f |" % [d.id, d.delta * 100, d.actual, d.expected])
		
	file.store_line("")
	file.store_line("## Scope Coverage")
	for s in scopes:
		file.store_line("- %s: %d" % [s, scopes[s]])
		
	file.store_line("")
	file.store_line("## Failures (Bugs & Violations)")
	if (total - passed + parse_errors) == 0:
		file.store_line("No issues found.")
	else:
		if parse_errors > 0:
			file.store_line("- **CRITICAL**: %d Parse Errors detected in JSONL." % parse_errors)
		for res in results:
			if res.get("PARSE_ERROR"):
				file.store_line("- **Malformed Entry**: Schema validation failed.")
			elif not res.get("success", false) or res.get("failures", []).size() > 0:
				file.store_line("- **%s**: %s" % [res.get("item_id"), str(res.get("failures"))])
	
	
	_update_daily_index(md_path, total, passed, violations, bugs, metadata)
	file.close() # Explicit close writer
	return md_path

func _update_daily_index(path: String, total: int, passed: int, violations: int, bugs: int, metadata: Dictionary):
	var user_dir = "user://test_reports/"
	var date_str = Time.get_date_string_from_system()
	var index_path = user_dir + "index_%s.md" % date_str
	
	var mode_suffix = " [MEASURE]" if metadata.get("is_measure_mode") else ""
	var status = "✅" if total == passed else "⚠️"
	if total == 0: status = "❌"
	
	var line = "| %s | %s | %d | %d/%d | %d | %d | [Summary](%s) |" % [
		Time.get_time_string_from_system(),
		metadata.get("run_id", "N/A") + mode_suffix,
		total,
		passed, total,
		violations,
		bugs,
		path.get_file()
	]
	
	var file: FileAccess
	if FileAccess.file_exists(index_path):
		file = FileAccess.open(index_path, FileAccess.READ_WRITE)
		file.seek_end()
	else:
		file = FileAccess.open(index_path, FileAccess.WRITE)
		file.store_line("# Daily Test Index - %s" % date_str)
		file.store_line("| Time | Run ID | Total | Pass | Viol | Bugs | Link |")
		file.store_line("| :--- | :--- | :--- | :--- | :--- | :--- | :--- |")
	
	file.store_line(line)

func _validate_entry(data: Dictionary) -> bool:
	var required = ["item_id", "scope", "success", "failures", "subtests"]
	for k in required:
		if not k in data: return false
	return true

## =================== FULL CYCLE REPORT =====================
## Generates a comprehensive report organized by scope

func generate_full_cycle_report(results: Array, metadata: Dictionary = {}) -> String:
	"""
	Generates a detailed report organized by scope, showing:
	- Per-scope pass/fail counts
	- Broken items by scope  
	- Items needing implementation
	"""
	var user_dir = "user://test_reports/"
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("test_reports"):
		dir.make_dir("test_reports")
		
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var filename = "full_cycle_report_%s.md" % timestamp
	var full_path = user_dir + filename
	
	var file = FileAccess.open(full_path, FileAccess.WRITE)
	if not file:
		print("[ReportWriter] Failed to open file: %s" % full_path)
		return ""
	
	# Organize results by scope
	var by_scope = {
		"WEAPON_SPECIFIC": {"passed": [], "failed": [], "not_implemented": []},
		"FUSION_SPECIFIC": {"passed": [], "failed": [], "not_implemented": []},
		"GLOBAL_WEAPON": {"passed": [], "failed": [], "not_implemented": []},
		"PLAYER_ONLY": {"passed": [], "failed": [], "not_implemented": []}
	}
	
	for res in results:
		var scope = res.get("scope", "PLAYER_ONLY")
		if scope not in by_scope:
			scope = "PLAYER_ONLY"
			
		var item_id = res.get("item_id", "unknown")
		var is_success = res.get("success", false)
		var failures = res.get("failures", [])
		
		# Check if it's "not implemented" vs actual bug
		var is_not_impl = false
		for f in failures:
			if "not implemented" in f.to_lower() or "placeholder" in f.to_lower():
				is_not_impl = true
				break
		
		if is_success:
			by_scope[scope]["passed"].append(res)
		elif is_not_impl:
			by_scope[scope]["not_implemented"].append(res)
		else:
			by_scope[scope]["failed"].append(res)
	
	# === WRITE REPORT ===
	file.store_line("# 🔄 Full Cycle Validation Report")
	file.store_line("**Date**: %s" % metadata.get("started_at", Time.get_datetime_string_from_system()))
	file.store_line("**Run ID**: %s" % metadata.get("run_id", "N/A"))
	file.store_line("**Git Commit**: %s" % metadata.get("git_commit", "N/A"))
	file.store_line("**Duration**: %d ms" % metadata.get("duration_ms", 0))
	file.store_line("")
	file.store_line("---")
	file.store_line("")
	
	# Executive Summary
	var total = results.size()
	var total_passed = 0
	var total_failed = 0
	var total_not_impl = 0
	
	for scope in by_scope:
		total_passed += by_scope[scope]["passed"].size()
		total_failed += by_scope[scope]["failed"].size()
		total_not_impl += by_scope[scope]["not_implemented"].size()
	
	file.store_line("## 📊 Executive Summary")
	file.store_line("")
	file.store_line("| Metric | Count | Percentage |")
	file.store_line("|--------|-------|------------|")
	file.store_line("| ✅ Passed | %d | %.1f%% |" % [total_passed, (float(total_passed)/total*100) if total > 0 else 0])
	file.store_line("| ❌ Failed (Bugs) | %d | %.1f%% |" % [total_failed, (float(total_failed)/total*100) if total > 0 else 0])
	file.store_line("| ⚠️ Not Implemented | %d | %.1f%% |" % [total_not_impl, (float(total_not_impl)/total*100) if total > 0 else 0])
	file.store_line("| **Total Items** | %d | 100%% |" % total)
	file.store_line("")
	
	# Scope Breakdown Summary
	file.store_line("## 🎯 Scope Coverage")
	file.store_line("")
	file.store_line("| Scope | Passed | Failed | Not Impl | Total | Health |")
	file.store_line("|-------|--------|--------|----------|-------|--------|")
	
	for scope in ["WEAPON_SPECIFIC", "FUSION_SPECIFIC", "GLOBAL_WEAPON", "PLAYER_ONLY"]:
		var p = by_scope[scope]["passed"].size()
		var f = by_scope[scope]["failed"].size()
		var n = by_scope[scope]["not_implemented"].size()
		var t = p + f + n
		var health = "✅" if f == 0 else ("⚠️" if f < 3 else "❌")
		if t == 0:
			health = "➖"
		file.store_line("| %s | %d | %d | %d | %d | %s |" % [scope, p, f, n, t, health])
	
	file.store_line("")
	
	# === Per-Scope Details ===
	for scope in ["WEAPON_SPECIFIC", "FUSION_SPECIFIC", "GLOBAL_WEAPON", "PLAYER_ONLY"]:
		var data = by_scope[scope]
		var total_scope = data["passed"].size() + data["failed"].size() + data["not_implemented"].size()
		if total_scope == 0:
			continue
			
		file.store_line("---")
		file.store_line("")
		file.store_line("## 📂 %s (%d items)" % [scope, total_scope])
		file.store_line("")
		
		# Failed items (BUGS) - Most important
		if data["failed"].size() > 0:
			file.store_line("### ❌ Bugs Detected (%d)" % data["failed"].size())
			file.store_line("")
			file.store_line("| Item ID | Expected | Actual | Delta | Failure Reason |")
			file.store_line("|---------|----------|--------|-------|----------------|")
			
			for res in data["failed"]:
				var item_id = res.get("item_id", "unknown")
				var expected = res.get("expected_damage", 0)
				var actual = res.get("actual_damage", 0)
				var delta = ((actual - expected) / expected * 100) if expected > 0 else 0
				var reason = str(res.get("failures", []))
				if reason.length() > 80:
					reason = reason.substr(0, 77) + "..."
				file.store_line("| %s | %.1f | %.1f | %.1f%% | %s |" % [item_id, expected, actual, delta, reason])
			
			file.store_line("")
		
		# Not implemented items
		if data["not_implemented"].size() > 0:
			file.store_line("### ⚠️ Not Implemented (%d)" % data["not_implemented"].size())
			file.store_line("")
			var ni_list = []
			for res in data["not_implemented"]:
				ni_list.append("`%s`" % res.get("item_id", "unknown"))
			file.store_line(", ".join(ni_list))
			file.store_line("")
		
		# Passed items (collapsed for brevity)
		if data["passed"].size() > 0:
			file.store_line("### ✅ Passed (%d)" % data["passed"].size())
			file.store_line("")
			file.store_line("<details>")
			file.store_line("<summary>Click to expand passed items</summary>")
			file.store_line("")
			var passed_list = []
			for res in data["passed"]:
				passed_list.append("`%s`" % res.get("item_id", "unknown"))
			file.store_line(", ".join(passed_list))
			file.store_line("")
			file.store_line("</details>")
			file.store_line("")
	
	# Action Items Section
	file.store_line("---")
	file.store_line("")
	file.store_line("## 🔧 Action Items")
	file.store_line("")
	
	if total_failed > 0:
		file.store_line("### Priority 1: Fix Bugs (%d items)" % total_failed)
		file.store_line("These items have incorrect behavior and need immediate fixes:")
		file.store_line("")
		for scope in by_scope:
			for res in by_scope[scope]["failed"]:
				file.store_line("- [ ] `%s` (%s)" % [res.get("item_id"), scope])
		file.store_line("")
	
	if total_not_impl > 0:
		file.store_line("### Priority 2: Implement Missing (%d items)" % total_not_impl)
		file.store_line("These items need their effects/logic implemented:")
		file.store_line("")
		for scope in by_scope:
			for res in by_scope[scope]["not_implemented"]:
				file.store_line("- [ ] `%s` (%s)" % [res.get("item_id"), scope])
		file.store_line("")
	
	if total_failed == 0 and total_not_impl == 0:
		file.store_line("🎉 **All items passed!** No action items required.")
		file.store_line("")
	
	file.close()
	return full_path


## =================== CONTRACT VALIDATION REPORT =====================
## Generates a report focused on contract violations and side effects

func generate_contract_validation_report(results: Array, metadata: Dictionary = {}) -> String:
	"""
	Generates a comprehensive contract-based validation report.
	Shows:
	- Contract violations (item doesn't do what it says)
	- Side effects (item does things it shouldn't)
	- Bugs (unexpected behavior)
	- Design violations (parameter mismatch)
	"""
	var user_dir = "user://test_reports/"
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("test_reports"):
		dir.make_dir("test_reports")
		
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var filename = "contract_validation_report_%s.md" % timestamp
	var full_path = user_dir + filename
	
	var file = FileAccess.open(full_path, FileAccess.WRITE)
	if not file:
		print("[ReportWriter] Failed to open file: %s" % full_path)
		return ""
	
	# Categorize results by issue type
	var categories = {
		"PASS": [],
		"CONTRACT_VIOLATION": [],
		"SIDE_EFFECT": [],
		"BUG": [],
		"DESIGN_VIOLATION": [],
		"SKIPPED": []  # Task 2: Track skipped tests due to missing event simulation
	}
	
	for res in results:
		var item_id = res.get("item_id", "unknown")
		var is_success = res.get("success", false)
		var failures = res.get("failures", [])
		var subtests = res.get("subtests", [])
		
		# Check for SKIPPED status first
		var is_skipped = res.get("skipped", false)
		var skip_reason = res.get("skip_reason", "")
		
		# Also check for skip markers in failures
		for f in failures:
			if f.begins_with("SKIPPED:"):
				is_skipped = true
				skip_reason = f.replace("SKIPPED:", "").strip_edges()
		
		if is_skipped:
			res["skip_reason"] = skip_reason  # Ensure it's set for reporting
			categories["SKIPPED"].append(res)
			continue
		
		# Categorize based on failure types
		var has_contract_violation = false
		var has_side_effect = false
		var has_bug = false
		var has_violation = false
		
		for f in failures:
			if f.begins_with("CONTRACT:"):
				has_contract_violation = true
			elif f.begins_with("BUG:"):
				has_bug = true
			elif f.begins_with("SIDE_EFFECT:"):
				has_side_effect = true
		
		# Also check subtests for result codes
		for sub in subtests:
			var res_data = sub.get("res", {})
			if sub.get("type") == "contract_validation":
				if not res_data.get("passed", true):
					has_contract_violation = true
			elif sub.get("type") == "side_effect_detection":
				if res_data.get("has_side_effects", false):
					if res_data.get("severity") == "critical":
						has_bug = true
					elif res_data.get("severity") == "major":
						has_side_effect = true
			elif sub.get("type") == "mechanical_damage":
				var code = res_data.get("result_code", "PASS")
				if code == "BUG":
					has_bug = true
				elif code == "DESIGN_VIOLATION":
					has_violation = true
		
		# Assign to primary category (priority order)
		if has_bug:
			categories["BUG"].append(res)
		elif has_contract_violation:
			categories["CONTRACT_VIOLATION"].append(res)
		elif has_side_effect:
			categories["SIDE_EFFECT"].append(res)
		elif has_violation:
			categories["DESIGN_VIOLATION"].append(res)
		elif is_success:
			categories["PASS"].append(res)
		else:
			categories["DESIGN_VIOLATION"].append(res)  # Fallback for other failures
	
	# === WRITE REPORT ===
	file.store_line("# 📋 Contract Validation Report")
	file.store_line("**Date**: %s" % metadata.get("started_at", Time.get_datetime_string_from_system()))
	file.store_line("**Run ID**: %s" % metadata.get("run_id", "N/A"))
	file.store_line("**Git Commit**: %s" % metadata.get("git_commit", "unknown"))
	file.store_line("**Strict Mode**: %s" % ("Enabled" if metadata.get("strict_contract_mode", true) else "Disabled"))
	file.store_line("")
	
	# Summary
	var total = results.size()
	file.store_line("## 📊 Summary")
	file.store_line("")
	file.store_line("| Category | Count | Percentage |")
	file.store_line("|----------|-------|------------|")
	for cat in ["PASS", "CONTRACT_VIOLATION", "SIDE_EFFECT", "DESIGN_VIOLATION", "BUG", "SKIPPED"]:
		var count = categories[cat].size()
		var pct = (float(count) / total * 100) if total > 0 else 0
		var emoji = _get_category_emoji(cat)
		file.store_line("| %s %s | %d | %.1f%% |" % [emoji, cat, count, pct])
	file.store_line("")
	
	# Critical Issues Section
	if categories["BUG"].size() > 0:
		file.store_line("## 🔴 BUGS (Critical)")
		file.store_line("These items have unexpected behavior that indicates code bugs:")
		file.store_line("")
		file.store_line("| Item | Scope | Failures |")
		file.store_line("|------|-------|----------|")
		for res in categories["BUG"]:
			var item_id = res.get("item_id", "unknown")
			var scope = res.get("scope", "UNKNOWN")
			var failures_str = ", ".join(res.get("failures", []))
			if failures_str.length() > 80:
				failures_str = failures_str.substr(0, 77) + "..."
			file.store_line("| `%s` | %s | %s |" % [item_id, scope, failures_str])
		file.store_line("")
	
	# Contract Violations
	if categories["CONTRACT_VIOLATION"].size() > 0:
		file.store_line("## 🟠 CONTRACT VIOLATIONS")
		file.store_line("These items do not do exactly what their description says:")
		file.store_line("")
		for res in categories["CONTRACT_VIOLATION"]:
			var item_id = res.get("item_id", "unknown")
			file.store_line("### `%s`" % item_id)
			
			# Extract contract details from subtests
			for sub in res.get("subtests", []):
				if sub.get("type") == "contract_validation":
					var contract = sub.get("contract", {})
					var result = sub.get("result", {})
					
					file.store_line("**Expected Contract:**")
					for stat in contract.get("stat_effects", {}):
						var eff = contract["stat_effects"][stat]
						file.store_line("- %s: %s %s" % [stat, eff.get("operation", "add"), str(eff.get("value", 0))])
					
					file.store_line("")
					file.store_line("**Violations:**")
					for violation in result.get("violations", []):
						file.store_line("- %s: Expected `%s`, Actual `%s`" % [
							violation.get("detail", "unknown"),
							str(violation.get("expected", "?")),
							str(violation.get("actual", "?"))
						])
					file.store_line("")
		file.store_line("")
	
	# Side Effects
	if categories["SIDE_EFFECT"].size() > 0:
		file.store_line("## 🟡 SIDE EFFECTS")
		file.store_line("These items produce effects not declared in their description:")
		file.store_line("")
		file.store_line("| Item | Undeclared Effect | Severity |")
		file.store_line("|------|-------------------|----------|")
		for res in categories["SIDE_EFFECT"]:
			var item_id = res.get("item_id", "unknown")
			for sub in res.get("subtests", []):
				if sub.get("type") == "side_effect_detection":
					var se_result = sub.get("result", {})
					for eff in se_result.get("undeclared_stat_changes", []):
						file.store_line("| `%s` | %s (%+.2f) | %s |" % [
							item_id, eff.get("stat", "?"), eff.get("delta", 0), eff.get("severity", "?")
						])
					for eff in se_result.get("undeclared_status_effects", []):
						file.store_line("| `%s` | Status: %s | %s |" % [
							item_id, eff.get("status", "?"), eff.get("severity", "?")
						])
		file.store_line("")
	
	# Design Violations
	if categories["DESIGN_VIOLATION"].size() > 0:
		file.store_line("## 🟣 DESIGN VIOLATIONS")
		file.store_line("These items have parameter mismatches (values outside expected tolerance):")
		file.store_line("")
		file.store_line("| Item | Delta | Expected | Actual |")
		file.store_line("|------|-------|----------|--------|")
		for res in categories["DESIGN_VIOLATION"]:
			var item_id = res.get("item_id", "unknown")
			var expected = res.get("expected_damage", 0)
			var actual = res.get("actual_damage", 0)
			var delta = 0.0
			if expected > 0:
				delta = (actual - expected) / expected * 100
			file.store_line("| `%s` | %.1f%% | %.2f | %.2f |" % [item_id, delta, expected, actual])
		file.store_line("")
	
	# SKIPPED Tests (Task 2: Event simulation required)
	if categories["SKIPPED"].size() > 0:
		file.store_line("## ⏭️ SKIPPED TESTS")
		file.store_line("These items require event simulation that was not available:")
		file.store_line("")
		file.store_line("| Item | Scope | Required Events | Reason |")
		file.store_line("|------|-------|-----------------|--------|")
		for res in categories["SKIPPED"]:
			var item_id = res.get("item_id", "unknown")
			var scope = res.get("scope", "UNKNOWN")
			var skip_reason = res.get("skip_reason", "Unknown")
			var required_events = res.get("required_events", [])
			var events_str = ", ".join(required_events) if not required_events.is_empty() else "N/A"
			file.store_line("| `%s` | %s | %s | %s |" % [item_id, scope, events_str, skip_reason])
		file.store_line("")
		file.store_line("> **Action Required**: Enable event simulation in ItemTestRunner or implement missing event handlers.")
		file.store_line("")
	
	# Passed Items (collapsed)
	file.store_line("## ✅ PASSED ITEMS (%d)" % categories["PASS"].size())
	file.store_line("")
	if categories["PASS"].size() > 0:
		file.store_line("<details>")
		file.store_line("<summary>Click to expand %d passing items</summary>" % categories["PASS"].size())
		file.store_line("")
		var passed_list = []
		for res in categories["PASS"]:
			passed_list.append("`%s`" % res.get("item_id", "unknown"))
		file.store_line(", ".join(passed_list))
		file.store_line("")
		file.store_line("</details>")
	else:
		file.store_line("No items passed contract validation.")
	file.store_line("")
	
	# Action Items
	file.store_line("---")
	file.store_line("## 🔧 Action Items")
	file.store_line("")
	
	if categories["BUG"].size() > 0:
		file.store_line("### P0 - Critical Bugs (%d)" % categories["BUG"].size())
		for res in categories["BUG"]:
			file.store_line("- [ ] `%s`" % res.get("item_id"))
		file.store_line("")
	
	if categories["CONTRACT_VIOLATION"].size() > 0:
		file.store_line("### P1 - Contract Violations (%d)" % categories["CONTRACT_VIOLATION"].size())
		for res in categories["CONTRACT_VIOLATION"]:
			file.store_line("- [ ] `%s`" % res.get("item_id"))
		file.store_line("")
	
	if categories["SIDE_EFFECT"].size() > 0:
		file.store_line("### P2 - Side Effects (%d)" % categories["SIDE_EFFECT"].size())
		for res in categories["SIDE_EFFECT"]:
			file.store_line("- [ ] `%s`" % res.get("item_id"))
		file.store_line("")
	
	if categories["DESIGN_VIOLATION"].size() > 0:
		file.store_line("### P3 - Design Violations (%d)" % categories["DESIGN_VIOLATION"].size())
		for res in categories["DESIGN_VIOLATION"]:
			file.store_line("- [ ] `%s`" % res.get("item_id"))
		file.store_line("")
	
	file.close()
	return full_path

func _get_category_emoji(category: String) -> String:
	match category:
		"PASS": return "✅"
		"CONTRACT_VIOLATION": return "🟠"
		"SIDE_EFFECT": return "🟡"
		"DESIGN_VIOLATION": return "🟣"
		"BUG": return "🔴"
		"SKIPPED": return "⏭️"
		_: return "⚪"