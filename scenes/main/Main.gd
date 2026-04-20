extends Control

const GameConstants = preload("res://scripts/core/GameConstants.gd")
const DailyChallengeService = preload("res://scripts/core/DailyChallengeService.gd")
const RunConfig = preload("res://scripts/core/RunConfig.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const SimulationRunner = preload("res://scripts/sim/SimulationRunner.gd")
const CityGraph = preload("res://scripts/sim/CityGraph.gd")
const ModifierStack = preload("res://scripts/sim/ModifierStack.gd")
const BusUnit = preload("res://scripts/sim/BusUnit.gd")
const CardSystem = preload("res://scripts/sim/CardSystem.gd")
const EvacuationOrder = preload("res://scripts/sim/EvacuationOrder.gd")
const ScoreSystem = preload("res://scripts/sim/ScoreSystem.gd")
const EndRunReportScene = preload("res://scenes/report/EndRunReport.tscn")

const DEFAULT_SEED := 20260420

var runner = null
var graph = null
var scenario_def = null
var modifier_stack = null
var card_system = null
var score_system = null
var report_overlay = null
var order_serial: int = 1
var selected_pickup_id: String = ""
var selected_shelter_id: String = ""
var focused_district_id: String = ""
var last_logged_pending_event: String = ""
var last_autosave_minute: int = -1
var report_recorded: bool = false
var last_logged_infinite_wave: int = 0
var log_entries: Array = []
var log_filter_query: String = ""
var map_filter_mode: String = "all"
var pending_event_confirmation: Dictionary = {}

var root_margin: MarginContainer
var title_label: Label
var version_label: Label
var resources_label: Label
var time_label: Label
var scenario_select: OptionButton
var new_run_button: Button
var save_button: Button
var load_button: Button
var simulation_button: Button
var retire_run_button: Button
var create_order_button: Button
var pause_on_event_check: CheckBox
var colorblind_mode_check: CheckBox
var font_size_select: OptionButton
var map_filter_select: OptionButton
var locale_select: OptionButton
var log_search_input: LineEdit
var credits_button: Button
var tutorial_status_label: Label
var leaderboard_label: Label
var selection_label: Label
var district_details_label: Label
var order_status_label: Label
var bus_status_label: Label
var step_button: Button
var clear_selection_button: Button
var cards_title_label: Label
var events_title_label: Label
var log_label: RichTextLabel
var generate_cards_button: Button
var reroll_cards_button: Button
var card_offer_container: VBoxContainer
var event_panel_label: Label
var event_options_container: VBoxContainer
var map_panel: Panel
var map_canvas: Control
var tick_timer: Timer
var confirmation_dialog: ConfirmationDialog
var credits_dialog: AcceptDialog
var credits_text_label: RichTextLabel

var district_buttons: Dictionary = {}
var bus_markers: Dictionary = {}


func _ready() -> void:
	_build_ui()
	_load_settings_controls()
	_apply_localized_texts()
	_apply_accessibility_settings()
	await get_tree().process_frame
	_bootstrap_run()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.color = Color(0.078, 0.094, 0.11, 1.0)
	add_child(background)

	root_margin = MarginContainer.new()
	root_margin.anchor_right = 1.0
	root_margin.anchor_bottom = 1.0
	root_margin.add_theme_constant_override("margin_left", 18)
	root_margin.add_theme_constant_override("margin_top", 18)
	root_margin.add_theme_constant_override("margin_right", 18)
	root_margin.add_theme_constant_override("margin_bottom", 18)
	add_child(root_margin)

	var main_split := HBoxContainer.new()
	main_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_split.add_theme_constant_override("separation", 16)
	root_margin.add_child(main_split)

	var left_column := VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_theme_constant_override("separation", 10)
	main_split.add_child(left_column)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 18)
	left_column.add_child(top_bar)

	resources_label = Label.new()
	resources_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resources_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resources_label.add_theme_color_override("font_color", Color(0.93, 0.91, 0.83, 1.0))
	top_bar.add_child(resources_label)

	time_label = Label.new()
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.add_theme_color_override("font_color", Color(0.88, 0.75, 0.55, 1.0))
	top_bar.add_child(time_label)

	var controls_bar := HBoxContainer.new()
	controls_bar.add_theme_constant_override("separation", 10)
	left_column.add_child(controls_bar)

	scenario_select = OptionButton.new()
	scenario_select.custom_minimum_size = Vector2(260, 0)
	controls_bar.add_child(scenario_select)

	new_run_button = Button.new()
	new_run_button.text = "Novo Cenario"
	new_run_button.tooltip_text = "Reinicia a run usando o cenario atualmente selecionado."
	new_run_button.pressed.connect(_on_new_run_pressed)
	controls_bar.add_child(new_run_button)

	save_button = Button.new()
	save_button.text = "Salvar"
	save_button.tooltip_text = "Grava a run atual em user://saves/current_run.json."
	save_button.pressed.connect(_on_save_pressed)
	controls_bar.add_child(save_button)

	load_button = Button.new()
	load_button.text = "Carregar"
	load_button.tooltip_text = "Carrega o save manual ou, se nao houver, o autosave mais recente."
	load_button.pressed.connect(_on_load_pressed)
	controls_bar.add_child(load_button)

	simulation_button = Button.new()
	_update_simulation_button_text()
	simulation_button.tooltip_text = "Alterna entre rodar e pausar a simulacao."
	simulation_button.pressed.connect(_on_simulation_toggle_pressed)
	controls_bar.add_child(simulation_button)

	retire_run_button = Button.new()
	retire_run_button.text = "Extrair Relatorio"
	retire_run_button.visible = false
	retire_run_button.tooltip_text = "Encerra voluntariamente a run infinita quando uma janela de extracao estiver disponivel."
	retire_run_button.pressed.connect(_on_retire_run_pressed)
	controls_bar.add_child(retire_run_button)

	step_button = Button.new()
	step_button.text = "Avancar 1 Min"
	step_button.tooltip_text = "Avanca exatamente um minuto sem destravar a simulacao continua."
	step_button.pressed.connect(_on_step_pressed)
	controls_bar.add_child(step_button)

	create_order_button = Button.new()
	create_order_button.text = "Criar Rota"
	create_order_button.disabled = true
	create_order_button.tooltip_text = "Cria uma ordem de evacuacao entre a origem e o abrigo selecionados."
	create_order_button.pressed.connect(_on_create_order_pressed)
	controls_bar.add_child(create_order_button)

	clear_selection_button = Button.new()
	clear_selection_button.text = "Limpar Selecao"
	clear_selection_button.tooltip_text = "Remove a origem e o abrigo atualmente marcados."
	clear_selection_button.pressed.connect(_on_clear_selection_pressed)
	controls_bar.add_child(clear_selection_button)

	map_panel = Panel.new()
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel.custom_minimum_size = Vector2(920, 620)
	left_column.add_child(map_panel)

	map_canvas = Control.new()
	map_canvas.anchor_right = 1.0
	map_canvas.anchor_bottom = 1.0
	map_canvas.grow_horizontal = Control.GROW_DIRECTION_BOTH
	map_canvas.grow_vertical = Control.GROW_DIRECTION_BOTH
	map_panel.add_child(map_canvas)

	var right_column := VBoxContainer.new()
	right_column.custom_minimum_size = Vector2(360, 0)
	right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.add_theme_constant_override("separation", 10)
	main_split.add_child(right_column)

	title_label = Label.new()
	title_label.text = "Despachante do Apocalipse"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8, 1.0))
	right_column.add_child(title_label)

	var version_row := HBoxContainer.new()
	version_row.add_theme_constant_override("separation", 8)
	right_column.add_child(version_row)

	version_label = Label.new()
	version_label.text = "Versao %s" % GameConstants.GAME_VERSION
	version_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.76, 1.0))
	version_row.add_child(version_label)

	credits_button = Button.new()
	credits_button.text = "Creditos"
	credits_button.tooltip_text = "Abre a pagina de creditos e licencas da demo."
	credits_button.pressed.connect(_on_credits_pressed)
	version_row.add_child(credits_button)

	tutorial_status_label = Label.new()
	tutorial_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_status_label.add_theme_color_override("font_color", Color(0.92, 0.87, 0.72, 1.0))
	right_column.add_child(tutorial_status_label)

	leaderboard_label = Label.new()
	leaderboard_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leaderboard_label.add_theme_color_override("font_color", Color(0.77, 0.86, 0.92, 1.0))
	right_column.add_child(leaderboard_label)

	var accessibility_row := HBoxContainer.new()
	accessibility_row.add_theme_constant_override("separation", 8)
	right_column.add_child(accessibility_row)

	pause_on_event_check = CheckBox.new()
	pause_on_event_check.text = "Pausar em evento"
	pause_on_event_check.tooltip_text = "Pausa automaticamente a simulacao quando um evento entra na fila."
	pause_on_event_check.toggled.connect(_on_pause_on_event_toggled)
	accessibility_row.add_child(pause_on_event_check)

	colorblind_mode_check = CheckBox.new()
	colorblind_mode_check.text = "Modo daltônico"
	colorblind_mode_check.tooltip_text = "Troca as cores principais do mapa por uma paleta com contraste mais seguro."
	colorblind_mode_check.toggled.connect(_on_colorblind_mode_toggled)
	accessibility_row.add_child(colorblind_mode_check)

	var controls_row := HBoxContainer.new()
	controls_row.add_theme_constant_override("separation", 8)
	right_column.add_child(controls_row)

	font_size_select = OptionButton.new()
	font_size_select.tooltip_text = "Ajusta o tamanho base da fonte da interface."
	font_size_select.item_selected.connect(_on_font_size_selected)
	controls_row.add_child(font_size_select)

	map_filter_select = OptionButton.new()
	map_filter_select.tooltip_text = "Filtra o mapa para destacar distritos por tipo de risco."
	map_filter_select.item_selected.connect(_on_map_filter_selected)
	controls_row.add_child(map_filter_select)

	locale_select = OptionButton.new()
	locale_select.tooltip_text = "Troca o idioma da interface principal."
	locale_select.item_selected.connect(_on_locale_selected)
	controls_row.add_child(locale_select)

	log_search_input = LineEdit.new()
	log_search_input.placeholder_text = "Buscar no log"
	log_search_input.tooltip_text = "Filtra o historico por palavras-chave."
	log_search_input.text_changed.connect(_on_log_filter_changed)
	right_column.add_child(log_search_input)

	selection_label = Label.new()
	selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	selection_label.add_theme_color_override("font_color", Color(0.86, 0.86, 0.82, 1.0))
	right_column.add_child(selection_label)

	district_details_label = Label.new()
	district_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	district_details_label.add_theme_color_override("font_color", Color(0.8, 0.87, 0.9, 1.0))
	right_column.add_child(district_details_label)

	order_status_label = Label.new()
	order_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	order_status_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.72, 1.0))
	right_column.add_child(order_status_label)

	bus_status_label = Label.new()
	bus_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bus_status_label.add_theme_color_override("font_color", Color(0.93, 0.76, 0.63, 1.0))
	right_column.add_child(bus_status_label)

	cards_title_label = Label.new()
	cards_title_label.text = "Cartas"
	cards_title_label.add_theme_font_size_override("font_size", 20)
	cards_title_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.74, 1.0))
	right_column.add_child(cards_title_label)

	var cards_controls := HBoxContainer.new()
	cards_controls.add_theme_constant_override("separation", 8)
	right_column.add_child(cards_controls)

	generate_cards_button = Button.new()
	generate_cards_button.text = "Gerar Oferta"
	generate_cards_button.tooltip_text = "Forca uma nova oferta de cartas quando a feature estiver liberada."
	generate_cards_button.pressed.connect(_on_generate_cards_pressed)
	cards_controls.add_child(generate_cards_button)

	reroll_cards_button = Button.new()
	reroll_cards_button.text = "Reroll"
	reroll_cards_button.tooltip_text = "Gasta verba para trocar a oferta atual por outra."
	reroll_cards_button.pressed.connect(_on_reroll_cards_pressed)
	cards_controls.add_child(reroll_cards_button)

	card_offer_container = VBoxContainer.new()
	card_offer_container.add_theme_constant_override("separation", 6)
	right_column.add_child(card_offer_container)

	events_title_label = Label.new()
	events_title_label.text = "Evento Atual"
	events_title_label.add_theme_font_size_override("font_size", 20)
	events_title_label.add_theme_color_override("font_color", Color(0.9, 0.78, 0.74, 1.0))
	right_column.add_child(events_title_label)

	event_panel_label = Label.new()
	event_panel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_panel_label.add_theme_color_override("font_color", Color(0.9, 0.86, 0.82, 1.0))
	right_column.add_child(event_panel_label)

	event_options_container = VBoxContainer.new()
	event_options_container.add_theme_constant_override("separation", 6)
	right_column.add_child(event_options_container)

	log_label = RichTextLabel.new()
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.bbcode_enabled = false
	log_label.scroll_active = true
	log_label.fit_content = false
	right_column.add_child(log_label)

	tick_timer = Timer.new()
	tick_timer.wait_time = 0.25
	tick_timer.one_shot = false
	tick_timer.timeout.connect(_on_tick_timer_timeout)
	add_child(tick_timer)

	report_overlay = EndRunReportScene.instantiate()
	report_overlay.restart_requested.connect(_on_report_restart_requested)
	report_overlay.close_requested.connect(_on_report_close_requested)
	add_child(report_overlay)

	confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.title = "Confirmar decisao"
	confirmation_dialog.confirmed.connect(_on_event_confirmation_accepted)
	add_child(confirmation_dialog)

	credits_dialog = AcceptDialog.new()
	credits_dialog.title = "Creditos e Licencas"
	credits_dialog.dialog_hide_on_ok = true
	credits_dialog.size = Vector2i(780, 560)
	var credits_margin := MarginContainer.new()
	credits_margin.anchor_right = 1.0
	credits_margin.anchor_bottom = 1.0
	credits_margin.add_theme_constant_override("margin_left", 16)
	credits_margin.add_theme_constant_override("margin_top", 16)
	credits_margin.add_theme_constant_override("margin_right", 16)
	credits_margin.add_theme_constant_override("margin_bottom", 16)
	credits_dialog.add_child(credits_margin)
	var credits_scroll := ScrollContainer.new()
	credits_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	credits_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	credits_margin.add_child(credits_scroll)
	credits_text_label = RichTextLabel.new()
	credits_text_label.bbcode_enabled = false
	credits_text_label.fit_content = true
	credits_text_label.scroll_active = false
	credits_scroll.add_child(credits_text_label)
	add_child(credits_dialog)

	score_system = ScoreSystem.new()


func _load_settings_controls() -> void:
	font_size_select.clear()
	for option in [
		{"label": _tr("ui.font_scale_90"), "value": 0.9},
		{"label": _tr("ui.font_scale_100"), "value": 1.0},
		{"label": _tr("ui.font_scale_115"), "value": 1.15},
		{"label": _tr("ui.font_scale_130"), "value": 1.3},
	]:
		font_size_select.add_item(String(option["label"]))
		font_size_select.set_item_metadata(font_size_select.item_count - 1, float(option["value"]))

	map_filter_select.clear()
	for option in [
		{"label": _tr("ui.map_filter_all"), "value": "all"},
		{"label": _tr("ui.map_filter_high_danger"), "value": "high_danger"},
		{"label": _tr("ui.map_filter_shelters"), "value": "shelters"},
		{"label": _tr("ui.map_filter_collapse"), "value": "collapse"},
	]:
		map_filter_select.add_item(String(option["label"]))
		map_filter_select.set_item_metadata(map_filter_select.item_count - 1, String(option["value"]))

	locale_select.clear()
	for locale_code in LocalizationService.get_supported_locales():
		var locale_label := _tr("ui.locale_%s" % String(locale_code))
		locale_select.add_item(locale_label)
		locale_select.set_item_metadata(locale_select.item_count - 1, String(locale_code))

	pause_on_event_check.button_pressed = bool(SettingsService.get_setting(&"pause_on_event", true))
	colorblind_mode_check.button_pressed = bool(SettingsService.get_setting(&"colorblind_mode", false))
	map_filter_mode = String(SettingsService.get_setting(&"map_filter", "all"))
	var configured_locale := String(SettingsService.get_setting(&"locale", LocalizationService.get_locale()))

	var current_scale := float(SettingsService.get_setting(&"font_scale", 1.0))
	for index in range(font_size_select.item_count):
		if is_equal_approx(float(font_size_select.get_item_metadata(index)), current_scale):
			font_size_select.select(index)
			break
	if font_size_select.selected < 0 and font_size_select.item_count > 0:
		font_size_select.select(1)

	for index in range(map_filter_select.item_count):
		if String(map_filter_select.get_item_metadata(index)) == map_filter_mode:
			map_filter_select.select(index)
			break
	if map_filter_select.selected < 0 and map_filter_select.item_count > 0:
		map_filter_select.select(0)

	for index in range(locale_select.item_count):
		if String(locale_select.get_item_metadata(index)) == configured_locale:
			locale_select.select(index)
			break
	if locale_select.selected < 0 and locale_select.item_count > 0:
		locale_select.select(0)
	if credits_text_label != null:
		credits_text_label.text = _build_credits_text()


func _apply_accessibility_settings() -> void:
	var font_scale := float(SettingsService.get_setting(&"font_scale", 1.0))
	var base_font := int(round(14.0 * font_scale))
	var title_font := int(round(24.0 * font_scale))
	for button in [
		new_run_button,
		save_button,
		load_button,
		simulation_button,
		retire_run_button,
		create_order_button,
		generate_cards_button,
		reroll_cards_button,
		pause_on_event_check,
		colorblind_mode_check,
		font_size_select,
		map_filter_select,
		locale_select,
		credits_button,
	]:
		if button != null:
			button.add_theme_font_size_override("font_size", base_font)

	for label in [
		resources_label,
		time_label,
		tutorial_status_label,
		leaderboard_label,
		selection_label,
		district_details_label,
		order_status_label,
		bus_status_label,
		event_panel_label,
		version_label,
		log_search_input,
	]:
		if label != null:
			label.add_theme_font_size_override("font_size", base_font)

	if title_label != null:
		title_label.add_theme_font_size_override("font_size", title_font)
	if log_label != null:
		log_label.add_theme_font_size_override("normal_font_size", base_font)
	if credits_text_label != null:
		credits_text_label.add_theme_font_size_override("normal_font_size", base_font)
	_refresh_log_view()
	if runner != null:
		_refresh_district_buttons()
		_refresh_bus_markers()


func _on_pause_on_event_toggled(enabled: bool) -> void:
	SettingsService.set_setting(&"pause_on_event", enabled)


func _on_colorblind_mode_toggled(enabled: bool) -> void:
	SettingsService.set_setting(&"colorblind_mode", enabled)
	_apply_accessibility_settings()
	if runner != null:
		_refresh_ui()


func _on_font_size_selected(index: int) -> void:
	if index < 0:
		return
	SettingsService.set_setting(&"font_scale", float(font_size_select.get_item_metadata(index)))
	_apply_accessibility_settings()
	if runner != null:
		_refresh_ui()


func _on_map_filter_selected(index: int) -> void:
	if index < 0:
		return
	map_filter_mode = String(map_filter_select.get_item_metadata(index))
	SettingsService.set_setting(&"map_filter", map_filter_mode)
	if runner != null:
		_refresh_district_buttons()
		_refresh_bus_markers()


func _on_locale_selected(index: int) -> void:
	if index < 0:
		return
	var locale_code := String(locale_select.get_item_metadata(index))
	LocalizationService.set_locale(locale_code)
	_load_settings_controls()
	_apply_localized_texts()
	_apply_accessibility_settings()
	if report_overlay != null and report_overlay.has_method("refresh_locale"):
		report_overlay.refresh_locale()
	if runner != null:
		_refresh_ui()


func _on_log_filter_changed(new_text: String) -> void:
	log_filter_query = new_text.strip_edges().to_lower()
	_refresh_log_view()


func _apply_localized_texts() -> void:
	if title_label != null:
		title_label.text = _tr("ui.game_title")
	if version_label != null:
		version_label.text = "%s %s" % [_tr("ui.version_prefix"), GameConstants.GAME_VERSION]
	if new_run_button != null:
		new_run_button.text = _tr("ui.new_run")
		new_run_button.tooltip_text = _tr("ui.new_run_tooltip")
	if save_button != null:
		save_button.text = _tr("ui.save")
		save_button.tooltip_text = _tr("ui.save_tooltip")
	if load_button != null:
		load_button.text = _tr("ui.load")
		load_button.tooltip_text = _tr("ui.load_tooltip")
	if simulation_button != null:
		simulation_button.tooltip_text = _tr("ui.toggle_simulation_tooltip")
	if retire_run_button != null:
		retire_run_button.text = _tr("ui.retire_run")
		retire_run_button.tooltip_text = _tr("ui.retire_run_tooltip")
	if step_button != null:
		step_button.text = _tr("ui.step_minute")
		step_button.tooltip_text = _tr("ui.step_minute_tooltip")
	if create_order_button != null:
		create_order_button.text = _tr("ui.create_route")
		create_order_button.tooltip_text = _tr("ui.create_route_tooltip")
	if clear_selection_button != null:
		clear_selection_button.text = _tr("ui.clear_selection")
		clear_selection_button.tooltip_text = _tr("ui.clear_selection_tooltip")
	if pause_on_event_check != null:
		pause_on_event_check.text = _tr("ui.pause_on_event")
		pause_on_event_check.tooltip_text = _tr("ui.pause_on_event_tooltip")
	if colorblind_mode_check != null:
		colorblind_mode_check.text = _tr("ui.colorblind_mode")
		colorblind_mode_check.tooltip_text = _tr("ui.colorblind_mode_tooltip")
	if map_filter_select != null:
		map_filter_select.tooltip_text = _tr("ui.map_filter_tooltip")
	if locale_select != null:
		locale_select.tooltip_text = _tr("ui.locale_tooltip")
	if log_search_input != null:
		log_search_input.placeholder_text = _tr("ui.log_search_placeholder")
		log_search_input.tooltip_text = _tr("ui.log_search_tooltip")
	if credits_button != null:
		credits_button.text = _tr("ui.credits")
		credits_button.tooltip_text = _tr("ui.credits_tooltip")
	if credits_dialog != null:
		credits_dialog.title = _tr("ui.credits_dialog_title")
	if cards_title_label != null:
		cards_title_label.text = _tr("ui.cards_title")
	if events_title_label != null:
		events_title_label.text = _tr("ui.events_title")
	_update_simulation_button_text()


func _on_credits_pressed() -> void:
	if credits_dialog == null:
		return
	credits_text_label.text = _build_credits_text()
	credits_dialog.popup_centered_ratio(0.8)


func _bootstrap_run(requested_scenario_id: String = "") -> void:
	if not ContentDb.load_content("res://data"):
		_append_log("[ERRO] Falha ao carregar conteudo.")
		for error_message in ContentDb.get_last_errors():
			_append_log(error_message)
		return

	var preferred_scenario_id := requested_scenario_id
	if preferred_scenario_id.is_empty():
		preferred_scenario_id = SaveService.get_preferred_scenario_id(ContentDb)
		if preferred_scenario_id.is_empty():
			preferred_scenario_id = "campanha_tiny_map"

	_populate_scenario_options(preferred_scenario_id)
	scenario_def = ContentDb.get_runtime_scenario(preferred_scenario_id)
	if scenario_def == null:
		_append_log("[ERRO] Cenario '%s' nao encontrado." % preferred_scenario_id)
		return

	var run_config := RunConfig.new(scenario_def.to_dictionary())
	run_config.seed = DailyChallengeService.resolve_seed_for_scenario(scenario_def, DEFAULT_SEED)

	var initial_state = GameState.create_initial(run_config)
	initial_state.run_flags["allowed_event_ids"] = scenario_def.allowed_event_ids.duplicate(true)
	initial_state.run_flags["current_scenario_id"] = scenario_def.id

	graph = CityGraph.new(ContentDb.get_map(scenario_def.map_id).to_dictionary())
	graph.apply_to_game_state(initial_state)
	modifier_stack = ModifierStack.new()

	runner = SimulationRunner.new(run_config, initial_state)
	runner.configure_runtime(graph, modifier_stack, null, null, null, null, ContentDb)
	card_system = CardSystem.new(ContentDb, modifier_stack, runner.rng)

	order_serial = 1
	selected_pickup_id = ""
	selected_shelter_id = ""
	focused_district_id = ""
	last_logged_pending_event = ""
	last_autosave_minute = -1
	report_recorded = false
	last_logged_infinite_wave = int(_infinite_state().get("wave", 0))
	log_entries.clear()
	_refresh_log_view()
	if report_overlay != null:
		report_overlay.hide()

	_spawn_buses()
	_rebuild_map()
	_refresh_ui()
	_append_log("Cenario carregado: %s." % scenario_def.name)
	if not scenario_def.tutorial_steps.is_empty():
		_append_log("Tutorial ativo. Siga o proximo passo destacado para aprender a criar rotas, usar cartas e salvar a run.")
	else:
		_append_log("Run pronta. Selecione um distrito de origem e um abrigo para criar a primeira rota.")
	_append_log("Cartas surgem em marcos do cenario; eventos entram automaticamente na fila quando o trigger dispara.")


func _apply_loaded_runtime(bundle: Dictionary) -> void:
	runner = bundle.get("runner")
	graph = bundle.get("graph")
	modifier_stack = bundle.get("modifier_stack")
	scenario_def = bundle.get("scenario_def")
	card_system = CardSystem.new(ContentDb, modifier_stack, runner.rng)
	score_system = ScoreSystem.new()

	var ui_state: Dictionary = Dictionary(bundle.get("ui_state", {})).duplicate(true)
	selected_pickup_id = String(ui_state.get("selected_pickup_id", ""))
	selected_shelter_id = String(ui_state.get("selected_shelter_id", ""))
	focused_district_id = String(ui_state.get("focused_district_id", ""))
	order_serial = _next_order_serial()
	last_logged_pending_event = ""
	last_autosave_minute = runner.state.elapsed_minutes
	report_recorded = bool(runner.state.run_flags.get("result_recorded", false))
	last_logged_infinite_wave = int(_infinite_state().get("wave", 0))
	log_entries.clear()
	_refresh_log_view()

	if report_overlay != null:
		report_overlay.hide()
	tick_timer.stop()
	_update_simulation_button_text()

	_populate_scenario_options(String(scenario_def.id))
	_rebuild_map()
	_refresh_ui()
	_append_log("Save carregado: %s em %s." % [scenario_def.name, _format_time(runner.state.elapsed_minutes)])

	if bool(runner.state.score_state.get("run_over", false)):
		var report: Dictionary = Dictionary(runner.state.run_flags.get("last_end_report", {})).duplicate(true)
		if report.is_empty():
			report = score_system.evaluate_run(runner.state, scenario_def, graph, ContentDb)
		_show_end_report(report)


func _populate_scenario_options(selected_id: String) -> void:
	scenario_select.clear()
	var scenario_ids: Array = SaveService.get_available_scenario_ids(ContentDb)
	if scenario_ids.is_empty():
		scenario_ids = ContentDb.scenarios.keys()
		scenario_ids.sort()

	for scenario_id in scenario_ids:
		var resolved_id := String(scenario_id)
		var item_scenario = ContentDb.get_scenario(resolved_id)
		var label: String = resolved_id if item_scenario == null else String(item_scenario.name)
		var runtime_scenario = ContentDb.get_runtime_scenario(resolved_id)
		if runtime_scenario != null and bool(Dictionary(runtime_scenario.metadata).get("daily_mode", false)):
			label = "%s (%s)" % [
				String(item_scenario.name if item_scenario != null else runtime_scenario.name),
				String(runtime_scenario.metadata.get("daily_key", "")),
			]
		scenario_select.add_item(label)
		scenario_select.set_item_metadata(scenario_select.item_count - 1, resolved_id)

	for index in range(scenario_select.item_count):
		if String(scenario_select.get_item_metadata(index)) == selected_id:
			scenario_select.select(index)
			return
	if scenario_select.item_count > 0:
		scenario_select.select(0)


func _selected_scenario_id() -> String:
	if scenario_select.item_count <= 0:
		return ""
	return String(scenario_select.get_item_metadata(scenario_select.selected))


func _spawn_buses() -> void:
	for bus_data in scenario_def.starting_buses:
		var bus = BusUnit.new(bus_data)
		bus.current_district_id = _default_bus_start_district()
		runner.state.bus_units[bus.id] = bus


func _default_bus_start_district() -> String:
	for district_id in graph.district_states.keys():
		var district = graph.get_district(String(district_id))
		if district != null and district.tags.has("terminal"):
			return district.id
	for district_id in graph.district_states.keys():
		var district = graph.get_district(String(district_id))
		if district != null and not district.is_shelter:
			return district.id
	return ""


func _rebuild_map() -> void:
	for child in map_canvas.get_children():
		child.queue_free()
	district_buttons.clear()
	bus_markers.clear()

	var district_ids: Array = graph.district_states.keys()
	district_ids.sort()
	for district_id in district_ids:
		var district = graph.get_district(String(district_id))
		var button := Button.new()
		button.toggle_mode = false
		button.size = Vector2(170, 72)
		button.pressed.connect(_on_district_pressed.bind(district.id))
		map_canvas.add_child(button)
		district_buttons[district.id] = button

	for bus_id in runner.state.bus_units.keys():
		var marker := ColorRect.new()
		marker.size = Vector2(18, 18)
		marker.color = Color(0.98, 0.48, 0.35, 1.0)
		map_canvas.add_child(marker)
		bus_markers[String(bus_id)] = marker


func _refresh_ui() -> void:
	if runner == null:
		return

	var state = runner.state
	resources_label.text = _tr("ui.resources_summary", {
		"budget": _format_number(state.global_resources.get("budget", 0)),
		"fuel": _format_number(state.global_resources.get("fuel", 0)),
		"trust": _format_number(state.global_resources.get("trust", 0)),
		"communication": _format_number(state.global_resources.get("communication", 0)),
	})
	time_label.text = _tr("ui.time_summary", {
		"time": _format_time(state.elapsed_minutes),
		"crisis": state.crisis_level,
	})

	save_button.disabled = runner == null
	load_button.disabled = not SaveService.has_manual_save() and not SaveService.has_autosave()
	simulation_button.disabled = _run_over()
	retire_run_button.visible = _is_infinite_scenario()
	retire_run_button.disabled = not _can_retire_run()
	create_order_button.disabled = _run_over() or selected_pickup_id.is_empty() or selected_shelter_id.is_empty()

	selection_label.text = _tr("ui.selection_summary", {
		"pickup": selected_pickup_id if not selected_pickup_id.is_empty() else "-",
		"shelter": selected_shelter_id if not selected_shelter_id.is_empty() else "-",
	})

	var focused_district = graph.get_district(focused_district_id) if not focused_district_id.is_empty() else null
	if focused_district != null:
		district_details_label.text = _tr("ui.district_summary", {
			"name": focused_district.name,
			"population": focused_district.total_population(),
			"panic": "%.1f" % focused_district.panic,
			"danger": "%.1f" % focused_district.danger,
			"collapse": "%.1f" % focused_district.collapse,
		})
	else:
		district_details_label.text = _tr("ui.district_empty")

	var active_orders: Array = runner.state.evacuation_orders.keys()
	active_orders.sort()
	var order_lines: Array = []
	for order_id in active_orders:
		var order = runner.state.evacuation_orders[order_id]
		order_lines.append("%s: %s -> %s (%s)" % [
			order.id,
			order.pickup_district_id,
			order.dropoff_shelter_id,
			"ativa" if order.active else "encerrada",
		])
	order_status_label.text = "%s\n%s" % [
		_tr("ui.orders_title"),
		"\n".join(order_lines) if not order_lines.is_empty() else _tr("ui.orders_empty"),
	]

	var bus_lines: Array = []
	for bus_id in runner.state.bus_units.keys():
		var bus = runner.state.bus_units[bus_id]
		bus_lines.append("%s: %s @ %s | carga %d | diesel %.1f" % [
			bus.id,
			bus.state,
			bus.current_district_id if not bus.current_district_id.is_empty() else "estrada",
			bus.total_passengers(),
			bus.fuel_current,
		])
	bus_status_label.text = "%s\n%s" % [
		_tr("ui.fleet_title"),
		"\n".join(bus_lines) if not bus_lines.is_empty() else _tr("ui.fleet_empty"),
	]

	_refresh_tutorial_ui()
	_refresh_leaderboard_ui()
	_refresh_district_buttons()
	_refresh_bus_markers()
	_refresh_card_ui()
	_refresh_event_ui()


func _refresh_tutorial_ui() -> void:
	if scenario_def == null:
		tutorial_status_label.text = ""
		return

	if _is_daily_scenario():
		var scenario_line := "%s: %s" % [_tr("ui.scenario_label"), scenario_def.name]
		var mode_line := "%s: %s" % [_tr("ui.mode_label"), _current_mode_label()]
		var date_line := "%s %s" % [_tr("ui.daily_date_label"), String(scenario_def.metadata.get("daily_key", ""))]
		var lines: Array = [
			scenario_line,
			"%s | %s" % [mode_line, date_line],
		]
		var source_name := String(scenario_def.metadata.get("daily_source_scenario_name", ""))
		if not source_name.is_empty():
			lines.append("%s: %s" % [_tr("ui.daily_base_label"), source_name])
		var modifiers: Array = Array(scenario_def.metadata.get("daily_modifier_labels", [])).duplicate(true)
		if not modifiers.is_empty():
			lines.append("%s: %s" % [_tr("ui.daily_modifiers_label"), " | ".join(modifiers)])
		lines.append("%s: %s" % [_tr("ui.objectives_label"), _format_objectives(scenario_def.objectives)])
		tutorial_status_label.text = "\n".join(lines)
		return

	if _is_infinite_scenario():
		var infinite_state := _infinite_state()
		var wave := int(infinite_state.get("wave", 0))
		var next_wave_minute := int(infinite_state.get("next_wave_minute", maxi(1, int(scenario_def.metadata.get("wave_interval_minutes", 15)))))
		var extraction_text := _tr("ui.infinite_extract_available") if _can_retire_run() else _tr("ui.infinite_extract_pending", {
			"time": _format_time(next_wave_minute),
		})
		tutorial_status_label.text = _tr("ui.infinite_status", {
			"scenario_line": "%s: %s" % [_tr("ui.scenario_label"), scenario_def.name],
			"mode_line": "%s: %s" % [_tr("ui.mode_label"), _current_mode_label()],
			"wave_line": "%s %d" % [_tr("ui.wave_label"), wave],
			"extraction_line": extraction_text,
			"objectives_line": "%s: %s" % [_tr("ui.objectives_label"), _format_objectives(scenario_def.objectives)],
		})
		return

	if scenario_def.tutorial_steps.is_empty():
		tutorial_status_label.text = _tr("ui.default_status", {
			"scenario_line": "%s: %s" % [_tr("ui.scenario_label"), scenario_def.name],
			"mode_line": "%s: %s" % [_tr("ui.mode_label"), _current_mode_label()],
			"objectives_line": "%s: %s" % [_tr("ui.objectives_label"), _format_objectives(scenario_def.objectives)],
		})
		return

	var total_steps := 0
	var completed_steps := 0
	var next_title := ""
	var next_body := ""
	var checklist: Array = []
	for raw_step in scenario_def.tutorial_steps:
		if not raw_step is Dictionary:
			continue
		total_steps += 1
		var step: Dictionary = raw_step
		var done := _is_tutorial_step_complete(step)
		if done:
			completed_steps += 1
		elif next_title.is_empty():
			next_title = String(step.get("title", step.get("id", "Passo")))
			next_body = String(step.get("body", ""))
		checklist.append("%s %s" % ["[x]" if done else "[ ]", String(step.get("title", step.get("id", "Passo")))])

	var header := "Tutorial %d/%d" % [completed_steps, total_steps]
	if next_title.is_empty():
		tutorial_status_label.text = _tr("ui.tutorial_all_done", {"header": header})
	else:
		tutorial_status_label.text = _tr("ui.tutorial_next", {
			"header": header,
			"title": next_title,
			"body": next_body,
			"checklist": "\n".join(checklist),
		})


func _refresh_leaderboard_ui() -> void:
	if leaderboard_label == null:
		return
	if scenario_def == null:
		leaderboard_label.text = ""
		return
	var is_daily := _is_daily_scenario()
	var entries: Array = _current_leaderboard_entries(3)
	var lines: Array = [_tr("ui.daily_leaderboard_title") if is_daily else _tr("ui.seed_leaderboard_title")]
	if is_daily:
		lines.append("%s: %s" % [_tr("ui.daily_date_label"), String(scenario_def.metadata.get("daily_key", ""))])
	if runner != null:
		lines.append("%s: %d" % [_tr("ui.current_seed_label"), int(runner.state.seed)])
	if entries.is_empty():
		lines.append(_tr("ui.daily_empty") if is_daily else _tr("ui.seed_empty"))
	else:
		for index in range(entries.size()):
			var entry: Dictionary = Dictionary(entries[index])
			lines.append("#%d Seed %d | Score %d | Nota %s" % [
				index + 1,
				int(entry.get("seed", 0)),
				int(entry.get("score", 0)),
				String(entry.get("grade", "-")),
			])
	leaderboard_label.text = "\n".join(lines)


func _refresh_district_buttons() -> void:
	for district_id in district_buttons.keys():
		var button = district_buttons[district_id]
		var district = graph.get_district(String(district_id))
		button.visible = _district_matches_filter(district)
		button.text = "%s\nPop %d | P %.0f | D %.0f" % [
			district.name,
			district.total_population(),
			district.panic,
			district.danger,
		]
		button.tooltip_text = "%s\nPopulacao: %d\nPanico: %.1f\nPerigo: %.1f\nColapso: %.1f%s" % [
			district.name,
			district.total_population(),
			district.panic,
			district.danger,
			district.collapse,
			"\nAbrigo ativo" if district.is_shelter else "",
		]
		button.position = _district_button_position(district)
		button.modulate = _district_button_color(district)


func _refresh_bus_markers() -> void:
	for bus_id in bus_markers.keys():
		var marker = bus_markers[bus_id]
		var bus = runner.state.bus_units[bus_id]
		marker.color = Color(0.98, 0.48, 0.35, 1.0) if not bool(SettingsService.get_setting(&"colorblind_mode", false)) else Color(0.98, 0.85, 0.3, 1.0)
		marker.position = _bus_marker_position(bus)


func _refresh_card_ui() -> void:
	var cards_unlocked := _cards_feature_unlocked()
	generate_cards_button.disabled = card_system == null or _run_over() or not cards_unlocked
	reroll_cards_button.disabled = card_system == null or _run_over() or not cards_unlocked or int(runner.state.global_resources.get("budget", 0)) <= 0
	for child in card_offer_container.get_children():
		child.queue_free()

	if card_system == null:
		return

	var current_offer: Array = Array(runner.state.run_flags.get("current_card_offer", []))
	if current_offer.is_empty():
		var hint := Label.new()
		hint.text = "Sem oferta no momento."
		if not cards_unlocked:
			hint.text = "Cartas desbloqueiam depois da primeira rota."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_offer_container.add_child(hint)
		return

	for card_id in current_offer:
		var card_def = ContentDb.get_card(String(card_id))
		if card_def == null:
			continue
		var button := Button.new()
		button.text = "%s [%s]\n%s" % [card_def.name, card_def.rarity, card_def.description]
		button.custom_minimum_size = Vector2(0, 72)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_card_chosen.bind(card_def.id))
		card_offer_container.add_child(button)


func _refresh_event_ui() -> void:
	for child in event_options_container.get_children():
		child.queue_free()

	if runner == null or runner.state.scheduled_events.is_empty():
		event_panel_label.text = _tr("ui.pending_event_empty")
		return

	var current_event: Dictionary = runner.state.scheduled_events[0]
	event_panel_label.text = "%s\n\n%s" % [
		String(current_event.get("title", "")),
		String(current_event.get("body", "")),
	]

	for option in Array(current_event.get("options", [])):
		if not option is Dictionary:
			continue
		var button := Button.new()
		button.text = String(option.get("label", option.get("id", "Opcao")))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = _run_over()
		button.tooltip_text = _describe_event_option(Dictionary(option))
		button.pressed.connect(_on_event_option_pressed.bind(String(current_event.get("event_id", "")), String(option.get("id", "")), Dictionary(option).duplicate(true)))
		event_options_container.add_child(button)


func _district_button_position(district) -> Vector2:
	var size := map_canvas.size
	var button_size := Vector2(170, 72)
	return Vector2(size.x * district.x, size.y * district.y) - (button_size * 0.5)


func _district_button_color(district) -> Color:
	var colorblind_mode := bool(SettingsService.get_setting(&"colorblind_mode", false))
	if colorblind_mode:
		if district.id == selected_pickup_id:
			return Color(0.88, 0.55, 0.12, 1.0)
		if district.id == selected_shelter_id:
			return Color(0.15, 0.68, 0.76, 1.0)
		if district.is_shelter:
			return Color(0.19, 0.45, 0.78, 1.0)
		if district.danger >= 65.0:
			return Color(0.94, 0.82, 0.25, 1.0)
		return Color(0.3, 0.32, 0.36, 1.0)
	if district.id == selected_pickup_id:
		return Color(0.48, 0.78, 0.57, 1.0)
	if district.id == selected_shelter_id:
		return Color(0.45, 0.62, 0.9, 1.0)
	if district.is_shelter:
		return Color(0.36, 0.48, 0.7, 1.0)
	if district.danger >= 65.0:
		return Color(0.82, 0.38, 0.28, 1.0)
	return Color(0.24, 0.28, 0.34, 1.0)


func _bus_marker_position(bus) -> Vector2:
	if not bus.current_road_id.is_empty():
		var road = graph.get_road(bus.current_road_id)
		if road != null:
			var from_district = graph.get_district(road.from_id)
			var to_district = graph.get_district(road.to_id)
			if from_district != null and to_district != null and road.length_km > 0.0:
				var origin := Vector2(map_canvas.size.x * from_district.x, map_canvas.size.y * from_district.y)
				var target := Vector2(map_canvas.size.x * to_district.x, map_canvas.size.y * to_district.y)
				var traveled_ratio := clampf((road.length_km - bus.current_segment_remaining_km) / road.length_km, 0.0, 1.0)
				return origin.lerp(target, traveled_ratio) - Vector2(9, 9)

	var district = graph.get_district(bus.current_district_id)
	if district == null:
		return Vector2.ZERO
	return Vector2(map_canvas.size.x * district.x, map_canvas.size.y * district.y) - Vector2(9, 9)


func _on_district_pressed(district_id: String) -> void:
	var district = graph.get_district(district_id)
	focused_district_id = district_id
	if district == null or _run_over():
		return

	if district.is_shelter:
		selected_shelter_id = "" if selected_shelter_id == district_id else district_id
	else:
		selected_pickup_id = "" if selected_pickup_id == district_id else district_id

	_refresh_ui()


func _on_create_order_pressed() -> void:
	if runner == null or selected_pickup_id.is_empty() or selected_shelter_id.is_empty() or _run_over():
		return
	var bus = _pick_available_bus()
	if bus == null:
		_append_log("Nenhum onibus livre para assumir a rota.")
		return

	var order_id := "order_%02d" % order_serial
	order_serial += 1
	var order = EvacuationOrder.new({
		"id": order_id,
		"pickup_district_id": selected_pickup_id,
		"dropoff_shelter_id": selected_shelter_id,
		"priority_policy": "balanced",
		"assigned_bus_ids": [bus.id],
		"repeat": true,
		"min_load_percent": 0.45,
	})
	runner.state.evacuation_orders[order.id] = order
	bus.assigned_order_id = order.id
	_append_log("Rota criada: %s -> %s com %s." % [selected_pickup_id, selected_shelter_id, bus.id])
	_refresh_ui()
	_maybe_autosave(false)


func _pick_available_bus():
	for bus_id in runner.state.bus_units.keys():
		var bus = runner.state.bus_units[bus_id]
		if bus.assigned_order_id.is_empty() or bus.state == "idle":
			return bus
	return null


func _on_clear_selection_pressed() -> void:
	selected_pickup_id = ""
	selected_shelter_id = ""
	focused_district_id = ""
	_refresh_ui()


func _on_simulation_toggle_pressed() -> void:
	if _run_over():
		return
	if tick_timer.is_stopped():
		tick_timer.start()
		_update_simulation_button_text()
		_append_log("Simulacao iniciada.")
	else:
		tick_timer.stop()
		_update_simulation_button_text()
		_append_log("Simulacao pausada.")


func _on_step_pressed() -> void:
	if runner == null or _run_over():
		return
	_advance_simulation(1)


func _on_tick_timer_timeout() -> void:
	if runner == null or _run_over():
		return
	_advance_simulation(1)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.ctrl_pressed and event.keycode == KEY_S:
		_on_save_pressed()
		get_viewport().set_input_as_handled()
		return
	if event.ctrl_pressed and event.keycode == KEY_L:
		_on_load_pressed()
		get_viewport().set_input_as_handled()
		return
	match event.keycode:
		KEY_SPACE:
			_on_simulation_toggle_pressed()
		KEY_PERIOD:
			_on_step_pressed()
		KEY_R:
			_on_create_order_pressed()
		KEY_G:
			_on_generate_cards_pressed()
		KEY_1, KEY_2, KEY_3:
			var option_index := int(event.keycode - KEY_1)
			if runner != null and not runner.state.scheduled_events.is_empty():
				var options: Array = Array(runner.state.scheduled_events[0].get("options", []))
				if option_index >= 0 and option_index < options.size() and options[option_index] is Dictionary:
					var option: Dictionary = Dictionary(options[option_index])
					_on_event_option_pressed(String(runner.state.scheduled_events[0].get("event_id", "")), String(option.get("id", "")), option)
		_:
			return
	get_viewport().set_input_as_handled()


func _advance_simulation(minutes: int) -> void:
	runner.advance(minutes)
	_trigger_card_offer_milestones()
	_log_infinite_wave_if_needed()
	_log_pending_event_if_needed()
	_maybe_autosave(false)
	_refresh_ui()
	_check_run_completion()


func _append_log(message: String) -> void:
	var timestamp := "Boot"
	if runner != null:
		timestamp = _format_time(runner.state.elapsed_minutes)
	log_entries.append("[%s] %s" % [timestamp, message])
	_refresh_log_view()


func _update_simulation_button_text() -> void:
	if simulation_button == null:
		return
	if runner == null or tick_timer == null or tick_timer.is_stopped():
		simulation_button.text = _tr("ui.start_simulation")
	else:
		simulation_button.text = _tr("ui.pause_simulation")


func _tr(key: String, placeholders: Dictionary = {}) -> String:
	return LocalizationService.text(key, placeholders)


func _format_time(total_minutes: int) -> String:
	var day := int(total_minutes / 1440) + 1
	var hour := int((total_minutes / 60) % 24)
	var minute := int(total_minutes % 60)
	return "Dia %d %02d:%02d" % [day, hour, minute]


func _format_number(value) -> String:
	return str(snapped(float(value), 0.1))


func _format_objectives(objectives: Array) -> String:
	if objectives.is_empty():
		return "Nenhum objetivo configurado."
	var parts: Array = []
	for objective in objectives:
		if not objective is Dictionary:
			continue
		parts.append(String(objective.get("label", objective.get("type", "objetivo"))))
	return " | ".join(parts)


func _on_generate_cards_pressed() -> void:
	if card_system == null or not _cards_feature_unlocked() or _run_over():
		return
	card_system.generate_offer(runner.state, scenario_def)
	_append_log("Nova oferta de cartas gerada.")
	_refresh_ui()


func _on_reroll_cards_pressed() -> void:
	if card_system == null or _run_over():
		return
	var result: Array = card_system.reroll_offer(runner.state, scenario_def)
	if result.is_empty():
		_append_log("Reroll indisponivel: verba insuficiente ou sem cartas suficientes.")
	else:
		_append_log("Reroll executado. Verba restante: %s." % _format_number(runner.state.global_resources.get("budget", 0)))
	_refresh_ui()


func _on_card_chosen(card_id: String) -> void:
	if card_system == null or _run_over():
		return
	var result: Dictionary = card_system.choose_card(runner.state, card_id)
	if bool(result.get("ok", false)):
		_append_log("Carta escolhida: %s (nivel %d)." % [card_id, int(result.get("new_level", 1))])
		_refresh_ui()
		_maybe_autosave(false)
		_check_run_completion()


func _on_event_option_pressed(event_id: String, option_id: String, option_data: Dictionary) -> void:
	if _is_dangerous_event_option(option_data):
		pending_event_confirmation = {
			"event_id": event_id,
			"option_id": option_id,
		}
		confirmation_dialog.dialog_text = "Essa decisao pode piorar a situacao.\n\n%s" % _describe_event_option(option_data)
		confirmation_dialog.popup_centered()
		return
	_on_event_option_chosen(event_id, option_id)


func _on_event_option_chosen(event_id: String, option_id: String) -> void:
	if runner == null or runner.event_director == null or _run_over():
		return
	var result: Dictionary = runner.event_director.choose_option(runner.state, event_id, option_id, graph)
	if bool(result.get("ok", false)):
		_append_log("Opcao escolhida em %s: %s." % [event_id, option_id])
	_refresh_ui()
	_maybe_autosave(false)
	_check_run_completion()


func _on_event_confirmation_accepted() -> void:
	if pending_event_confirmation.is_empty():
		return
	var event_id := String(pending_event_confirmation.get("event_id", ""))
	var option_id := String(pending_event_confirmation.get("option_id", ""))
	pending_event_confirmation.clear()
	_on_event_option_chosen(event_id, option_id)


func _on_new_run_pressed() -> void:
	_bootstrap_run(_selected_scenario_id())


func _on_save_pressed() -> void:
	if runner == null or scenario_def == null:
		return
	runner.state.run_flags["manual_saved"] = true
	var result := SaveService.save_current_run(runner, scenario_def, _build_ui_state())
	if bool(result.get("ok", false)):
		_append_log("Run salva em %s." % SaveService.get_manual_save_path())
	else:
		_append_log("[ERRO] Falha ao salvar a run.")
	_refresh_ui()


func _on_load_pressed() -> void:
	if not ContentDb.has_loaded_content():
		if not ContentDb.load_content("res://data"):
			_append_log("[ERRO] Falha ao carregar conteudo para load.")
			return
	var result := SaveService.load_preferred_runtime(ContentDb)
	if not bool(result.get("ok", false)):
		_append_log("[ERRO] Nenhum save valido encontrado para carregar.")
		return
	_apply_loaded_runtime(result)


func _on_retire_run_pressed() -> void:
	if runner == null or not _can_retire_run():
		return
	runner.state.score_state["run_over"] = true
	runner.state.score_state["end_reason"] = "player_retired"
	var report: Dictionary = score_system.evaluate_run(runner.state, scenario_def, graph, ContentDb)
	runner.state.run_flags["last_end_report"] = report.duplicate(true)
	_finalize_run(report)


func _on_report_restart_requested() -> void:
	if report_overlay != null:
		report_overlay.hide()
	_bootstrap_run("" if scenario_def == null else String(scenario_def.id))


func _on_report_close_requested() -> void:
	_refresh_ui()


func _build_ui_state() -> Dictionary:
	return {
		"selected_pickup_id": selected_pickup_id,
		"selected_shelter_id": selected_shelter_id,
		"focused_district_id": focused_district_id,
	}


func _cards_feature_unlocked() -> bool:
	if scenario_def == null or scenario_def.tutorial_steps.is_empty():
		return true
	return runner.state.evacuation_orders.size() > 0


func _trigger_card_offer_milestones() -> void:
	if scenario_def == null or card_system == null:
		return
	var metadata: Dictionary = scenario_def.metadata
	var milestone_minutes: Array = Array(metadata.get("card_offer_minutes", [])).duplicate(true)
	var triggered: Array = Array(runner.state.run_flags.get("card_offer_milestones_triggered", [])).duplicate(true)
	for raw_minute in milestone_minutes:
		var milestone := int(raw_minute)
		if runner.state.elapsed_minutes < milestone or triggered.has(milestone):
			continue
		triggered.append(milestone)
		runner.state.run_flags["card_offer_milestones_triggered"] = triggered
		if Array(runner.state.run_flags.get("current_card_offer", [])).is_empty():
			card_system.generate_offer(runner.state, scenario_def)
			_append_log("Oferta de cartas liberada no marco de %d minutos." % milestone)

	var repeat_interval := int(metadata.get("card_offer_repeat_interval_minutes", 0))
	if repeat_interval <= 0:
		return
	var next_repeat := int(runner.state.run_flags.get("next_card_repeat_minute", 0))
	if next_repeat <= 0:
		var last_milestone := 0
		for raw_minute in milestone_minutes:
			last_milestone = maxi(last_milestone, int(raw_minute))
		next_repeat = (last_milestone + repeat_interval) if last_milestone > 0 else repeat_interval
	var generated_repeat_offer := false
	while runner.state.elapsed_minutes >= next_repeat:
		if not generated_repeat_offer and Array(runner.state.run_flags.get("current_card_offer", [])).is_empty():
			card_system.generate_offer(runner.state, scenario_def)
			_append_log("Oferta recorrente liberada em %d minutos." % next_repeat)
			generated_repeat_offer = true
		next_repeat += repeat_interval
	runner.state.run_flags["next_card_repeat_minute"] = next_repeat


func _log_pending_event_if_needed() -> void:
	if runner == null or runner.state.scheduled_events.is_empty():
		last_logged_pending_event = ""
		return
	var current_event: Dictionary = runner.state.scheduled_events[0]
	var event_key := "%s:%s" % [
		String(current_event.get("event_id", "")),
		String(current_event.get("queued_at", runner.state.elapsed_minutes)),
	]
	if event_key == last_logged_pending_event:
		return
	last_logged_pending_event = event_key
	if bool(SettingsService.get_setting(&"pause_on_event", true)) and not tick_timer.is_stopped():
		tick_timer.stop()
		_update_simulation_button_text()
		_append_log("Simulacao pausada automaticamente para revisar o evento.")
	_append_log("Evento pendente: %s" % String(current_event.get("title", current_event.get("event_id", "evento"))))


func _maybe_autosave(force: bool) -> void:
	if runner == null or scenario_def == null:
		return
	var interval := int(scenario_def.metadata.get("autosave_interval_minutes", 0))
	if force:
		SaveService.autosave_current_run(runner, scenario_def, _build_ui_state())
		last_autosave_minute = runner.state.elapsed_minutes
		return
	if interval <= 0 or runner.state.elapsed_minutes <= 0:
		return
	if runner.state.elapsed_minutes % interval != 0:
		return
	if last_autosave_minute == runner.state.elapsed_minutes:
		return
	SaveService.autosave_current_run(runner, scenario_def, _build_ui_state())
	last_autosave_minute = runner.state.elapsed_minutes


func _check_run_completion() -> void:
	if runner == null or score_system == null:
		return
	if _run_over():
		return
	var evaluation: Dictionary = score_system.evaluate_end_conditions(runner.state, scenario_def, graph)
	if not bool(evaluation.get("run_over", false)):
		return
	var report: Dictionary = score_system.evaluate_run(runner.state, scenario_def, graph, ContentDb)
	runner.state.run_flags["last_end_report"] = report.duplicate(true)
	_finalize_run(report)


func _finalize_run(report: Dictionary) -> void:
	tick_timer.stop()
	_update_simulation_button_text()
	_append_log("Run encerrada: %s." % String(report.get("end_reason", "fim_da_run")))
	_maybe_autosave(true)

	if not report_recorded:
		if String(report.get("end_reason", "")) == "tutorial_complete":
			var unlocks: Array = Array(scenario_def.metadata.get("unlock_scenarios_on_complete", [])).duplicate(true)
			SaveService.mark_tutorial_completed(ContentDb, unlocks)
			_populate_scenario_options(String(scenario_def.id))
		SaveService.record_run_result(report, ContentDb)
		runner.state.run_flags["result_recorded"] = true
		report_recorded = true

	report["local_leaderboard"] = _current_leaderboard_entries(5)
	_show_end_report(report)
	_refresh_ui()


func _show_end_report(report: Dictionary) -> void:
	if report_overlay != null:
		report_overlay.show_report(report)


func _refresh_log_view() -> void:
	if log_label == null:
		return
	log_label.clear()
	var visible_entries: Array = []
	for raw_entry in log_entries:
		var entry := String(raw_entry)
		if log_filter_query.is_empty() or entry.to_lower().contains(log_filter_query):
			visible_entries.append(entry)
	if visible_entries.is_empty():
		log_label.append_text("%s\n" % _tr("ui.no_log_entries") if not log_filter_query.is_empty() else "")
	else:
		log_label.append_text("%s\n" % "\n".join(visible_entries))
	log_label.scroll_to_line(log_label.get_line_count())


func _build_credits_text() -> String:
	var fallback_text := "\n".join([
		"Despachante do Apocalipse",
		"Versao %s" % GameConstants.GAME_VERSION,
		"",
		"Projeto e conteudo da demo:",
		"- Design, codigo e conteudo jogavel produzidos neste repositorio.",
		"",
		"Dependencias de terceiros:",
		"- Godot Engine 4.x",
		"- GUT (Godot Unit Test)",
		"",
		"Licencas e atribuicoes detalhadas tambem estao em docs/credits_and_licenses.md.",
	])
	var docs_path := "res://docs/credits_and_licenses.md"
	if FileAccess.file_exists(docs_path):
		var file := FileAccess.open(docs_path, FileAccess.READ)
		if file != null:
			var content := file.get_as_text()
			file.close()
			if not content.strip_edges().is_empty():
				return content
	return fallback_text


func _current_mode_label() -> String:
	if scenario_def == null:
		return "Cenario"
	return String(scenario_def.metadata.get("game_mode_name", "Cenario"))


func _is_daily_scenario() -> bool:
	return scenario_def != null and bool(Dictionary(scenario_def.metadata).get("daily_mode", false))


func _current_leaderboard_entries(limit: int) -> Array:
	if scenario_def == null:
		return []
	if _is_daily_scenario():
		return SaveService.get_daily_leaderboard(
			ContentDb,
			String(scenario_def.id),
			String(scenario_def.metadata.get("daily_key", "")),
			limit
		)
	return SaveService.get_seed_leaderboard(ContentDb, String(scenario_def.id), limit)


func _district_matches_filter(district) -> bool:
	match map_filter_mode:
		"high_danger":
			return district.danger >= 55.0 or district.collapse >= 35.0
		"shelters":
			return district.is_shelter
		"collapse":
			return district.collapse >= 35.0
		_:
			return true


func _describe_event_option(option: Dictionary) -> String:
	var lines: Array = []
	var requirements: Dictionary = Dictionary(option.get("requirements", {}))
	if not requirements.is_empty():
		for key in requirements.keys():
			lines.append("Requer %s >= %s" % [String(key), str(requirements[key])])
	var effects: Dictionary = Dictionary(option.get("effects", {}))
	if effects.is_empty():
		lines.append("Sem efeito numerico previsto.")
	else:
		for effect_key in effects.keys():
			var value = effects[effect_key]
			var prefix := "+" if float(value) >= 0.0 else ""
			lines.append("%s: %s%s" % [String(effect_key), prefix, str(value)])
	return "\n".join(lines)


func _is_dangerous_event_option(option: Dictionary) -> bool:
	var effects: Dictionary = Dictionary(option.get("effects", {}))
	for effect_key in effects.keys():
		var key := String(effect_key)
		var value := float(effects[effect_key])
		if key == "panic_add" and value > 0.0:
			return true
		if key.ends_with("_add") and value < 0.0:
			return true
		if key.findn("dead") != -1 and value > 0.0:
			return true
	return false


func _run_over() -> bool:
	return runner != null and bool(runner.state.score_state.get("run_over", false))


func _is_infinite_scenario() -> bool:
	return scenario_def != null and bool(scenario_def.metadata.get("infinite_mode", false))


func _infinite_state() -> Dictionary:
	if runner == null:
		return {}
	var infinite_state: Variant = runner.state.run_flags.get("infinite_mode", {})
	if infinite_state is Dictionary:
		return Dictionary(infinite_state)
	return {}


func _can_retire_run() -> bool:
	if runner == null or _run_over() or not _is_infinite_scenario():
		return false
	return bool(_infinite_state().get("extraction_unlocked", false))


func _log_infinite_wave_if_needed() -> void:
	if not _is_infinite_scenario():
		return
	var infinite_state := _infinite_state()
	var wave := int(infinite_state.get("wave", 0))
	if wave <= last_logged_infinite_wave:
		return
	last_logged_infinite_wave = wave
	_append_log("Onda %d atingiu a cidade. Extracao liberada. Proxima onda em %s." % [
		wave,
		_format_time(int(infinite_state.get("next_wave_minute", runner.state.elapsed_minutes))),
	])


func _is_tutorial_step_complete(step: Dictionary) -> bool:
	var condition: Dictionary = Dictionary(step.get("condition", {}))
	match String(condition.get("type", "")):
		"selected_pickup":
			return not selected_pickup_id.is_empty()
		"selected_shelter":
			return not selected_shelter_id.is_empty()
		"order_count_at_least":
			return runner.state.evacuation_orders.size() >= int(condition.get("value", 0))
		"elapsed_minutes_at_least":
			return runner.state.elapsed_minutes >= int(condition.get("value", 0))
		"owned_card_count_at_least":
			return _count_owned_cards() >= int(condition.get("value", 0))
		"event_history_count_at_least":
			return runner.state.event_history.size() >= int(condition.get("value", 0))
		"manual_save_exists":
			return bool(runner.state.run_flags.get("manual_saved", false))
		"saved_population_at_least":
			return int(runner.state.global_metrics.get("saved_population", 0)) >= int(condition.get("value", 0))
		_:
			return false


func _count_owned_cards() -> int:
	var total := 0
	for level in runner.state.owned_cards.values():
		if int(level) > 0:
			total += 1
	return total


func _next_order_serial() -> int:
	return runner.state.evacuation_orders.size() + 1
