extends Control

signal close_requested
signal restart_requested

@onready var backdrop: ColorRect = $Backdrop
@onready var title_label: Label = $Panel/Margin/Stack/Title
@onready var summary_label: Label = $Panel/Margin/Stack/Summary
@onready var highlights_label: Label = $Panel/Margin/Stack/Highlights
@onready var restart_button: Button = $Panel/Margin/Stack/Buttons/RestartButton
@onready var close_button: Button = $Panel/Margin/Stack/Buttons/CloseButton


func _ready() -> void:
	hide()
	refresh_locale()
	restart_button.pressed.connect(func(): restart_requested.emit())
	close_button.pressed.connect(func():
		hide()
		close_requested.emit()
	)


func show_report(report: Dictionary) -> void:
	title_label.text = "%s  |  Nota %s  |  Score %d" % [
		String(report.get("title", _tr("ui.report_title_default"))),
		String(report.get("grade", "-")),
		int(report.get("score", 0)),
	]
	summary_label.text = "%s: %s\n%s: %d\n%s: %s min\n%s: %d  |  %s: %d  |  %s: %d\n%s: %d" % [
		_tr("report.end_reason"),
		String(report.get("end_reason", "")),
		_tr("report.seed"),
		int(report.get("seed", 0)),
		_tr("report.time_minutes"),
		int(report.get("elapsed_minutes", 0)),
		_tr("report.saved"),
		int(report.get("saved_population", 0)),
		_tr("report.dead"),
		int(report.get("dead_population", 0)),
		_tr("report.remaining"),
		int(report.get("remaining_population", 0)),
		_tr("report.collapsed"),
		int(report.get("collapsed_districts", 0)),
	]
	if bool(report.get("daily_mode", false)):
		summary_label.text += "\n%s: %s" % [_tr("report.daily"), String(report.get("daily_key", ""))]
		var daily_source := String(report.get("daily_source_scenario_name", ""))
		if not daily_source.is_empty():
			summary_label.text += "\n%s: %s" % [_tr("report.daily_base"), daily_source]
		var modifiers: Array = Array(report.get("daily_modifier_labels", [])).duplicate(true)
		if not modifiers.is_empty():
			summary_label.text += "\n%s: %s" % [_tr("report.daily_modifiers"), " | ".join(modifiers)]
	if int(report.get("wave_reached", 0)) > 0:
		summary_label.text += "\n%s: %d  |  %s: %d" % [
			_tr("report.waves"),
			int(report.get("wave_reached", 0)),
			_tr("report.wave_score"),
			int(report.get("wave_score", 0)),
		]
	var leaderboard: Array = Array(report.get("local_leaderboard", [])).duplicate(true)
	if not leaderboard.is_empty():
		summary_label.text += "\n%s:" % _tr("report.local_leaderboard")
		for index in range(mini(3, leaderboard.size())):
			var entry: Dictionary = Dictionary(leaderboard[index])
			summary_label.text += "\n#%d Seed %d | Score %d | Nota %s" % [
				index + 1,
				int(entry.get("seed", 0)),
				int(entry.get("score", 0)),
				String(entry.get("grade", "-")),
			]

	var card_lines := _format_list("Cartas marcantes", Array(report.get("highlight_cards", [])))
	var event_lines := _format_list("Eventos marcantes", Array(report.get("highlight_events", [])))
	highlights_label.text = "%s\n\n%s" % [card_lines, event_lines]
	show()


func _format_list(title: String, entries: Array) -> String:
	if entries.is_empty():
		return "%s:\n%s" % [title, _tr("report.no_highlights")]
	return "%s:\n%s" % [title, "\n".join(entries)]


func refresh_locale() -> void:
	if restart_button != null:
		restart_button.text = _tr("report.restart")
	if close_button != null:
		close_button.text = _tr("report.close")


func _tr(key: String) -> String:
	return LocalizationService.text(key)
