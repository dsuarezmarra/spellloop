# RunAuditReport.gd
# Generador de reportes Markdown para auditoría de runs
# Produce un informe "human-friendly" con secciones y tablas
class_name RunAuditReport
extends RefCounted

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN GENERATION METHOD
# ═══════════════════════════════════════════════════════════════════════════════

static func generate(summary: Dictionary, context: Dictionary, run_id: String, run_seed: int) -> String:
	"""Generar reporte Markdown completo."""
	var md: PackedStringArray = PackedStringArray()
	
	# Header
	md.append("# 🎮 Run Audit Report")
	md.append("")
	md.append("**Run ID:** `%s`" % run_id)
	md.append("**Seed:** `%d`" % run_seed)
	md.append("**Generated:** %s" % Time.get_datetime_string_from_system())
	md.append("")
	md.append("---")
	md.append("")
	
	# 1. Executive Summary
	md.append(_section_executive_summary(summary, context))

	# 1b. Death Summary (solo si murió)
	if context.get("end_reason", "") == "death":
		md.append(_section_death_summary(context))

	# 2. Build Final
	md.append(_section_build_final(summary, context))

	# 2b. Upgrade Audit Summary (si hay datos)
	md.append(_section_upgrade_audit_summary(summary))
	
	# 3. Damage by Weapon (Top 10)
	md.append(_section_damage_by_weapon(summary))
	
	# 4. Most Dangerous Enemies (Top 10)
	md.append(_section_dangerous_enemies(summary))
	
	# 5. Progression
	md.append(_section_progression(summary))
	
	# 6. Fusions and Chests
	md.append(_section_fusions_chests(summary))
	
	# 7. Scoring Breakdown
	md.append(_section_scoring(summary, context))
	
	# 8. Performance
	md.append(_section_performance(summary))
	
	# 9. Findings and Suspicions
	md.append(_section_findings(summary, context))
	
	return "\n".join(md)

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION GENERATORS
# ═══════════════════════════════════════════════════════════════════════════════

static func _section_executive_summary(summary: Dictionary, context: Dictionary) -> String:
	var md: PackedStringArray = PackedStringArray()
	
	md.append("## 1. 📋 Resumen Ejecutivo")
	md.append("")
	
	var duration = summary.get("duration_minutes", 0)
	var level = summary.get("final_level", 1)
	var phase = summary.get("phase_reached", 1)
	var score = summary.get("score_final", 0)
	var kills = context.get("kills", 0)
	var killed_by = context.get("killed_by", "unknown")
	var end_reason = context.get("end_reason", "death")
	
	md.append("| Métrica | Valor |")
	md.append("|---------|-------|")
	md.append("| ⏱️ Duración | **%d min** |" % duration)
	md.append("| 🏆 Score Final | **%s** |" % _format_number(score))
	md.append("| 📍 Fase Alcanzada | **Phase %d** |" % phase)
	md.append("| 📈 Nivel Final | **%d** |" % level)
	md.append("| 💀 Kills Totales | **%s** |" % _format_number(kills))
	md.append("| ☠️ Razón de Fin | `%s` |" % end_reason)
	if end_reason == "death":
		md.append("| 🔪 Killed By | `%s` |" % killed_by)
	md.append("")
	
	# Quick damage summary
	var damage = summary.get("damage", {})
	md.append("### Daño")
	md.append("- **Daño Total Infligido:** %s" % _format_number(damage.get("dealt_total", 0)))
	md.append("- **Daño Total Recibido:** %s" % _format_number(damage.get("taken_total", 0)))
	md.append("")
	
	return "\n".join(md)

static func _section_death_summary(context: Dictionary) -> String:
	"""Sección Death Summary: qué mató al jugador, ventana de daño, contributors."""
	var md: PackedStringArray = PackedStringArray()

	md.append("## \uD83D\uDC80 Death Summary")
	md.append("")

	var death_ctx = context.get("death_context", {})
	if death_ctx.is_empty():
		md.append("_No death context available (killed_by = `%s`)._ " % context.get("killed_by", "unknown"))
		md.append("")
		return "\n".join(md)

	var killer = death_ctx.get("killer", "unknown")
	var attack = death_ctx.get("killer_attack", "unknown")
	var damage = death_ctx.get("killing_blow_damage", 0)
	var element = death_ctx.get("killing_blow_element", "physical")
	var damage_type = death_ctx.get("killer_damage_type", element)
	var source_kind = death_ctx.get("killer_source_kind", "melee")
	var window_s = death_ctx.get("window_duration_s", 0.0)
	var total_dmg = death_ctx.get("total_damage_in_window", 0)
	var hits = death_ctx.get("hits_in_window", 0)
	var status_effects = death_ctx.get("active_status_effects", [])
	var density = death_ctx.get("enemy_density", 0)

	md.append("### Causa Principal")
	md.append("")
	if killer != "unknown":
		md.append("| Dato | Valor |")
		md.append("|------|-------|")
		md.append("| \uD83D\uDD2A Killer | `%s` |" % killer)
		var attack_label = attack if attack != "unknown" else damage_type
		md.append("| \u2694\uFE0F Ataque | `%s` |" % attack_label)
		md.append("| \uD83C\uDF0A Tipo de Da\u00f1o | `%s` |" % damage_type)
		md.append("| \uD83C\uDFAF Fuente | `%s` |" % source_kind)
		
		# Shield Breakdown
		var shield_abs = death_ctx.get("killing_blow_shield_absorbed", death_ctx.get("shield_absorbed", 0))
		if shield_abs > 0:
			md.append("| \uD83D\uDCA5 Golpe Final | **%d** (HP: -%d | \uD83D\uDEE1\uFE0F: -%d) |" % [damage + shield_abs, damage, shield_abs])
		else:
			md.append("| \uD83D\uDCA5 Golpe Final | %d da\u00f1o |" % damage)
			
		md.append("| \u23F1\uFE0F Ventana | %.1fs (%d hits, %s da\u00f1o total) |" % [window_s, hits, _format_number(total_dmg)])
		md.append("| \uD83D\uDC7E Densidad | %d enemigos cerca |" % density)
		md.append("")
	else:
		md.append("- **Causa:** Da\u00f1o acumulado (no se pudo identificar origen)")
		md.append("")

	# Damage window table
	var window = death_ctx.get("last_damage_window", [])
	if window.size() > 0:
		md.append("### Ventana de Da\u00f1o (\u00faltimos %.1fs)" % window_s)
		md.append("")
		md.append("| # | Enemigo | Ataque | Tipo | Da\u00f1o | HP Antes \u2192 Despu\u00e9s |")
		md.append("|---|---------|--------|------|------|---------------------|")
		var idx = 0
		for entry in window:
			idx += 1
			var is_killing_blow = (idx == window.size())
			var prefix = "\u2620\uFE0F" if is_killing_blow else str(idx)
			var entry_attack = entry.get("attack_id", "?")
			if entry_attack == "unknown":
				entry_attack = entry.get("damage_type", entry.get("element", "?"))
			md.append("| %s | %s | %s | %s | %d | %d \u2192 %d |" % [
				prefix,
				entry.get("enemy_id", "?"),
				entry_attack,
				entry.get("damage_type", entry.get("element", "?")),
				entry.get("damage", 0),
				entry.get("hp_before", 0),
				entry.get("hp_after", 0)
			])
		md.append("")

		# Contributor analysis
		var contributors: Dictionary = {}  # enemy_id -> total_damage
		for entry in window:
			var eid = entry.get("enemy_id", "unknown")
			contributors[eid] = contributors.get(eid, 0) + entry.get("damage", 0)
		if contributors.size() > 1:
			md.append("### Contribuidores")
			md.append("")
			var sorted_contribs = contributors.keys()
			for eid in sorted_contribs:
				var pct = (float(contributors[eid]) / float(maxi(total_dmg, 1))) * 100.0
				md.append("- `%s`: %d da\u00f1o (%.0f%%)" % [eid, contributors[eid], pct])
			md.append("")

	# Status effects
	if status_effects.size() > 0:
		md.append("### Estados Activos al Morir")
		md.append("")
		for s in status_effects:
			md.append("- \u26A0\uFE0F `%s`" % s)
		md.append("")

	return "\n".join(md)

static func _section_upgrade_audit_summary(summary: Dictionary) -> String:
	"""Sección resumen de la auditoría de upgrades (datos de UpgradeAuditor)."""
	var md: PackedStringArray = PackedStringArray()

	# Get UpgradeAuditor data from the autoload
	var ua: Dictionary = {}
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		var auditor = tree.root.get_node_or_null("UpgradeAuditor")
		if auditor and auditor.has_method("get_run_summary"):
			ua = auditor.get_run_summary()

	if ua.is_empty():
		return ""

	md.append("## \uD83D\uDD0D Auditor\u00eda de Upgrades")
	md.append("")

	var counts = ua.get("counts", {})
	var total = ua.get("total_pickups", 0)
	md.append("| Resultado | Cantidad |")
	md.append("|-----------|----------|")
	md.append("| \u2705 OK | %d |" % counts.get("ok", 0))
	md.append("| \u274C FAIL | %d |" % counts.get("fail", 0))
	md.append("| \u26A0\uFE0F WARN | %d |" % counts.get("warn", 0))
	md.append("| \uD83D\uDC80 DEAD_STAT | %d |" % counts.get("dead_stat", 0))
	md.append("| **Total** | **%d** |" % total)
	md.append("")

	var top = ua.get("top_upgrades_picked", [])
	if top.size() > 0:
		md.append("### Top Upgrades Recogidos")
		md.append("")
		md.append("| Upgrade | Veces |")
		md.append("|---------|-------|")
		for entry in top:
			md.append("| `%s` | %d |" % [entry.get("id", "?"), entry.get("count", 0)])
		md.append("")

	return "\n".join(md)

static func _section_build_final(summary: Dictionary, context: Dictionary) -> String:
	var md: PackedStringArray = PackedStringArray()
	
	md.append("## 2. 🛠️ Build Final")
	md.append("")
	
	# Weapons
	var weapons = context.get("weapons", [])
	if weapons.size() > 0:
		md.append("### Armas Equipadas")
		md.append("")
		for weapon in weapons:
			var name = weapon.get("name", weapon.get("id", "unknown"))
			# Support both "level" and "lvl" keys (BalanceTelemetry uses "lvl")
			var level = weapon.get("level", weapon.get("lvl", 1))
			md.append("- **%s** (Nivel %d)" % [name, level])
		md.append("")
	
	# Top Upgrades
	var upgrades = summary.get("upgrades", {})
	var picks = upgrades.get("timeline", [])
	if picks.size() > 0:
		md.append("### Upgrades Adquiridos (%d total)" % picks.size())
		md.append("")
		# Group by type
		var by_source: Dictionary = {}
		for pick in picks:
			var source = pick.get("source", "levelup")
			if not by_source.has(source):
				by_source[source] = []
			by_source[source].append(pick)
		
		for source in by_source:
			md.append("**%s:** %d" % [source.capitalize(), by_source[source].size()])
		md.append("")
	
	# Player Stats Snapshot
	var stats_history = summary.get("player_stats_history", [])
	if stats_history.size() > 0:
		var final_stats = stats_history[-1].get("stats", {})
		if not final_stats.is_empty():
			md.append("### Stats Finales del Jugador")
			md.append("")
			md.append("| Stat | Valor |")
			md.append("|------|-------|")
			for stat_name in final_stats:
				md.append("| %s | %s |" % [stat_name, str(final_stats[stat_name])])
			md.append("")
	
	return "\n".join(md)

static func _section_damage_by_weapon(summary: Dictionary) -> String:
	var md: PackedStringArray = PackedStringArray()
	
	md.append("## 3. ⚔️ Daño por Arma (Top 10)")
	md.append("")
	
	var weapons_data = summary.get("weapons", {})
	var top_weapons = weapons_data.get("top_10", [])
	
	if top_weapons.size() == 0:
		md.append("_No hay datos de armas._")
		md.append("")
		return "\n".join(md)
	
	# Calculate total for percentage
	var total_damage: int = 0
	for w in top_weapons:
		total_damage += w.get("damage_total", 0)
	
	md.append("| # | Arma | Daño Total | % | Hits | Crit% | DPS (último min) | Status Procs |")
	md.append("|---|------|------------|---|------|-------|------------------|--------------|")
	
	var rank = 0
	for w in top_weapons:
		rank += 1
		var name = w.get("weapon_name", w.get("weapon_id", "?"))
		var damage = w.get("damage_total", 0)
		var pct = 0.0
		if total_damage > 0:
			pct = (float(damage) / float(total_damage)) * 100.0
		var hits = w.get("hits_total", 0)
		var crit_rate = w.get("crit_rate", 0.0) * 100.0
		var dps = w.get("dps_last_60s", 0.0)
		var procs = w.get("status_procs", {})
		var procs_str = _format_status_procs(procs)
		
		md.append("| %d | %s | %s | %.1f%% | %s | %.1f%% | %.0f | %s |" % [
			rank, name, _format_number(damage), pct, _format_number(hits), crit_rate, dps, procs_str
		])
	
	md.append("")
	
	# Highlight dominant weapon
	if top_weapons.size() > 0:
		var top_weapon = top_weapons[0]
		var top_pct = 0.0
		if total_damage > 0:
			top_pct = (float(top_weapon.get("damage_total", 0)) / float(total_damage)) * 100.0
		if top_pct > 45.0:
			md.append("> ⚠️ **OUTLIER:** `%s` domina con %.1f%% del daño total" % [
				top_weapon.get("weapon_name", "?"), top_pct
			])
			md.append("")
	
	return "\n".join(md)

static func _section_dangerous_enemies(summary: Dictionary) -> String:
	var md: PackedStringArray = PackedStringArray()
	
	md.append("## 4. 👹 Enemigos Más Peligrosos (Top 10)")
	md.append("")
	
	var enemies_data = summary.get("enemies", {})
	var top_enemies = enemies_data.get("top_10_dangerous", [])
	
	if top_enemies.size() == 0:
		md.append("_No hay datos de enemigos._")
		md.append("")
		return "\n".join(md)
	
	md.append("| # | Enemigo | Daño al Jugador | Hits | Spawns | Ataques Principales |")
	md.append("|---|---------|-----------------|------|--------|---------------------|")
	
	var rank = 0
	for e in top_enemies:
		rank += 1
		var name = e.get("enemy_name", e.get("enemy_id", "?"))
		var damage = e.get("damage_to_player", 0)
		var hits = e.get("hits_to_player", 0)
		var spawns = e.get("spawns", 0)
		var top_attacks = e.get("top_attacks", [])
		var attacks_str = ""
		for atk in top_attacks:
			if attacks_str.length() > 0:
				attacks_str += ", "
			attacks_str += "%s (%d)" % [atk.get("attack_id", "?"), atk.get("damage", 0)]
		if attacks_str.is_empty():
			attacks_str = "-"
		
		md.append("| %d | %s | %s | %d | %d | %s |" % [
			rank, name, _format_number(damage), hits, spawns, attacks_str
		])
	
	md.append("")
	
	return "\n".join(md)

static func _section_progression(summary: Dictionary) -> String:
	var md: PackedStringArray = PackedStringArray()
	
	md.append("## 5. 📈 Progresión")
	md.append("")
	
	# Level Timeline
	var level_timeline = summary.get("level_timeline", [])
	if level_timeline.size() > 0:
		md.append("### Timeline de Niveles")
		md.append("")
		md.append("```")
		var timeline_str = ""
		for entry in level_timeline:
			var t_min = entry.get("t_min", 0)
			var level = entry.get("level", 1)
			timeline_str += "Min %d: Lvl %d | " % [int(t_min), level]
		md.append(timeline_str.trim_suffix(" | "))
		md.append("```")
		md.append("")
	
	# Player stats over time (simplified)
	var stats_history = summary.get("player_stats_history", [])
	if stats_history.size() > 1:
		md.append("### Evolución de Stats")
		md.append("")
		md.append("_Ver archivo JSONL para historial completo por minuto._")
		md.append("")
	
	return "\n".join(md)

static func _section_fusions_chests(summary: Dictionary) -> String:
	var md: PackedStringArray = PackedStringArray()
	
	md.append("## 6. 🎁 Fusiones y Cofres")
	md.append("")
	
	var economy = summary.get("economy", {})
	var chests = economy.get("chests_opened", {})
	
	md.append("### Cofres Abiertos")
	md.append("")
	md.append("| Tipo | Cantidad |")
	md.append("|------|----------|")
	for chest_type in chests:
		md.append("| %s | %d |" % [chest_type.capitalize(), chests[chest_type]])
	md.append("")
	
	# Fusions
	var fusions_count = economy.get("fusions_obtained", 0)
	md.append("### Fusiones Obtenidas: **%d**" % fusions_count)
	md.append("")
	
	# Rerolls
	var rerolls = economy.get("rerolls_used", 0)
	md.append("### Rerolls Usados: **%d**" % rerolls)
	md.append("")
	
	return "\n".join(md)

static func _section_scoring(summary: Dictionary, context: Dictionary) -> String:
	var md: PackedStringArray = PackedStringArray()
	
	md.append("## 7. 🏆 Scoring Breakdown")
	md.append("")
	
	var score_final = summary.get("score_final", 0)
	md.append("### Score Final: **%s**" % _format_number(score_final))
	md.append("")
	
	var score_snapshots = summary.get("score_snapshots", [])
	if score_snapshots.size() > 0:
		md.append("### Snapshots (cada 5 min)")
		md.append("")
		md.append("| Minuto | Score | Breakdown |")
		md.append("|--------|-------|-----------|")
		for snap in score_snapshots:
			var t_min = snap.get("t_min", 0)
			var score = snap.get("score_total", 0)
			var breakdown = snap.get("breakdown", {})
			var breakdown_str = ""
			for key in breakdown:
				if breakdown_str.length() > 0:
					breakdown_str += ", "
				breakdown_str += "%s: %s" % [key, str(breakdown[key])]
			if breakdown_str.is_empty():
				breakdown_str = "-"
			md.append("| %d | %s | %s |" % [t_min, _format_number(score), breakdown_str])
		md.append("")
	
	# Tips
	md.append("### 💡 Cómo Maximizar Score")
	md.append("")
	md.append("1. **Sobrevivir más tiempo** (diminishing returns después de 20 min)")
	md.append("2. **Matar más elites y bosses** (mayor peso que kills normales)")
	md.append("3. **Subir más niveles** (bonus por nivel alto)")
	md.append("4. **Minimizar daño recibido** (penalizaciones)")
	md.append("")
	
	return "\n".join(md)

static func _section_performance(summary: Dictionary) -> String:
	var md: PackedStringArray = PackedStringArray()
	
	md.append("## 8. ⚡ Performance")
	md.append("")
	
	var perf = summary.get("performance", {})
	var spikes_33 = perf.get("spikes_33ms_total", 0)
	var spikes_66 = perf.get("spikes_66ms_total", 0)
	
	md.append("### Spikes Detectados")
	md.append("")
	md.append("| Severidad | Cantidad |")
	md.append("|-----------|----------|")
	md.append("| ⚠️ >33ms (~30 FPS) | %d |" % spikes_33)
	md.append("| 🔴 >66ms (~15 FPS) | %d |" % spikes_66)
	md.append("")
	
	# Top scopes
	var top_scopes = perf.get("top_scopes_run", [])
	if top_scopes.size() > 0:
		md.append("### Top Sistemas por Coste (Run Total)")
		md.append("")
		md.append("| Sistema | Total (ms) | Avg (ms) | Max (ms) | Calls |")
		md.append("|---------|------------|----------|----------|-------|")
		for scope in top_scopes:
			md.append("| %s | %.2f | %.3f | %.2f | %d |" % [
				scope.get("name", "?"),
				scope.get("total_ms", 0),
				scope.get("avg_ms", 0),
				scope.get("max_ms", 0),
				scope.get("calls", 0)
			])
		md.append("")
	
	# Spike samples
	var spike_samples = perf.get("spike_samples", [])
	if spike_samples.size() > 0:
		md.append("### Muestra de Spikes (contexto)")
		md.append("")
		md.append("| Min | Frame Time | Enemies | Projectiles | Nodes | Top Scope |")
		md.append("|-----|------------|---------|-------------|-------|-----------|")
		for sample in spike_samples.slice(0, 10):  # Show first 10
			var top_scope = "?"
			var scopes = sample.get("top_scopes", [])
			if scopes.size() > 0:
				top_scope = scopes[0].get("name", "?")
			md.append("| %d | %.1f ms | %d | %d | %d | %s |" % [
				sample.get("t_min", 0),
				sample.get("frame_time_ms", 0),
				sample.get("enemies_alive", -1),
				sample.get("projectiles_alive", -1),
				sample.get("node_count", -1),
				top_scope
			])
		md.append("")
	
	# Recommendations
	md.append("### 🔧 Recomendaciones Automáticas")
	md.append("")
	
	var recommendations: Array = []
	
	if spikes_66 > 10:
		recommendations.append("- 🔴 **Spikes severos frecuentes:** Revisar pooling de proyectiles y VFX")
	
	for scope in top_scopes:
		if scope.get("name", "") == "ProjectileUpdate" and scope.get("avg_ms", 0) > 2.0:
			recommendations.append("- ⚠️ **ProjectileUpdate alto:** Considerar spatial partitioning o reducir projectile count")
		if scope.get("name", "") == "EnemyAI" and scope.get("avg_ms", 0) > 3.0:
			recommendations.append("- ⚠️ **EnemyAI alto:** Considerar LOD para AI distante")
		if scope.get("name", "") == "DamageCalc" and scope.get("avg_ms", 0) > 1.0:
			recommendations.append("- ⚠️ **DamageCalc alto:** Cachear cálculos de bonus/stats")
	
	if recommendations.size() == 0:
		md.append("_Sin problemas de rendimiento detectados._")
	else:
		for rec in recommendations:
			md.append(rec)
	md.append("")
	
	return "\n".join(md)

static func _section_findings(summary: Dictionary, context: Dictionary) -> String:
	var md: PackedStringArray = PackedStringArray()
	
	md.append("## 9. 🔍 Hallazgos y Sospechas")
	md.append("")
	
	var findings: Array = []
	
	# Check weapon dominance
	var weapons_data = summary.get("weapons", {})
	var top_weapons = weapons_data.get("top_10", [])
	if top_weapons.size() > 0:
		var total_damage: int = 0
		for w in top_weapons:
			total_damage += w.get("damage_total", 0)
		
		if total_damage > 0:
			var top_pct = (float(top_weapons[0].get("damage_total", 0)) / float(total_damage)) * 100.0
			if top_pct > 45.0:
				findings.append("⚠️ **Arma dominante:** `%s` con %.1f%% del daño. Posible desbalance o build muy especializado." % [
					top_weapons[0].get("weapon_name", "?"), top_pct
				])
	
	# Check damage taken vs sustain
	var damage = summary.get("damage", {})
	var taken = damage.get("taken_total", 0)
	var duration = summary.get("duration_minutes", 1)
	var damage_per_min = float(taken) / maxf(float(duration), 1.0)
	
	if damage_per_min < 50 and duration > 10:
		findings.append("📊 **Daño recibido muy bajo** (%.0f/min). Build muy defensivo o dificultad baja." % damage_per_min)
	elif damage_per_min > 500:
		findings.append("📊 **Daño recibido muy alto** (%.0f/min). Build frágil o dificultad alta." % damage_per_min)
	
	# Check elite combos
	var elite_combos = summary.get("elite_ability_combos", {})
	for combo in elite_combos:
		if elite_combos[combo] >= 3:
			findings.append("👹 **Elite combo repetido:** `%s` apareció %d veces." % [combo, elite_combos[combo]])
	
	# Check level pacing
	var level_timeline = summary.get("level_timeline", [])
	if level_timeline.size() > 2:
		# Check if levels stopped coming
		var last_level = level_timeline[-1]
		var t_min_last = last_level.get("t_min", 0)
		if duration - t_min_last > 5:
			findings.append("📈 **Pacing:** Último nivel subido en minuto %d, pero run duró %d min. XP farming lento al final." % [
				int(t_min_last), duration
			])
	
	# Output findings
	if findings.size() == 0:
		md.append("_No se detectaron anomalías significativas._")
	else:
		for finding in findings:
			md.append("- %s" % finding)
	md.append("")
	
	md.append("---")
	md.append("")
	md.append("_Reporte generado automáticamente por RunAuditTracker v%d_" % 1)
	md.append("")
	
	return "\n".join(md)

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

static func _format_number(n: int) -> String:
	"""Formatear número con separadores de miles."""
	var s = str(n)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result

static func _format_status_procs(procs: Dictionary) -> String:
	"""Formatear status procs como string."""
	if procs.is_empty():
		return "-"
	
	var parts: Array = []
	for status in procs:
		parts.append("%s:%d" % [status, procs[status]])
	
	return " ".join(parts)
