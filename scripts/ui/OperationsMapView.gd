extends Control
class_name OperationsMapView

signal district_activated(district_id: String)

const NODE_RING_SAFE := Color(0.24, 0.48, 0.58, 0.35)
const MAP_FRAME := Color(0.26, 0.31, 0.35, 0.9)
const MAP_SURFACE := Color(0.07, 0.1, 0.12, 1.0)
const MAP_SURFACE_ALT := Color(0.11, 0.14, 0.17, 1.0)
const PREVIEW_ROUTE := Color(0.95, 0.78, 0.33, 0.95)
const ACTIVE_ROUTE := Color(0.95, 0.56, 0.31, 0.95)
const TEXT_PRIMARY := Color(0.95, 0.94, 0.9, 1.0)
const TEXT_MUTED := Color(0.74, 0.79, 0.82, 1.0)

var graph = null
var game_state = null
var selected_pickup_id: String = ""
var selected_shelter_id: String = ""
var focused_district_id: String = ""
var hover_district_id: String = ""
var map_filter_mode: String = "all"
var colorblind_mode: bool = false
var font_scale: float = 1.0
var preview_route_road_ids: Array = []
var legend_title: String = ""
var legend_body: String = ""
var legend_origin_label: String = ""
var legend_shelter_label: String = ""
var legend_active_label: String = ""

var district_layout: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func sync_from_runtime(city_graph, state, view_state: Dictionary = {}) -> void:
	graph = city_graph
	game_state = state
	selected_pickup_id = String(view_state.get("selected_pickup_id", ""))
	selected_shelter_id = String(view_state.get("selected_shelter_id", ""))
	focused_district_id = String(view_state.get("focused_district_id", ""))
	map_filter_mode = String(view_state.get("map_filter_mode", "all"))
	colorblind_mode = bool(view_state.get("colorblind_mode", false))
	font_scale = float(view_state.get("font_scale", 1.0))
	preview_route_road_ids = Array(view_state.get("preview_route_road_ids", [])).duplicate(true)
	legend_title = String(view_state.get("legend_title", ""))
	legend_body = String(view_state.get("legend_body", ""))
	legend_origin_label = String(view_state.get("legend_origin_label", "Origem"))
	legend_shelter_label = String(view_state.get("legend_shelter_label", "Abrigo"))
	legend_active_label = String(view_state.get("legend_active_label", "Rotas ativas"))
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if graph == null:
		return
	if event is InputEventMouseMotion:
		var hovered_id := _district_at_point(event.position)
		if hovered_id != hover_district_id:
			hover_district_id = hovered_id
			queue_redraw()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var district_id := _district_at_point(event.position)
		if district_id.is_empty():
			return
		district_activated.emit(district_id)
		accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and not hover_district_id.is_empty():
		hover_district_id = ""
		queue_redraw()


func _draw() -> void:
	_draw_backdrop()
	if graph == null:
		return
	_rebuild_layout_cache()
	_draw_roads()
	_draw_zones()
	_draw_district_nodes()
	_draw_bus_tokens()
	_draw_legend()


func _rebuild_layout_cache() -> void:
	district_layout.clear()
	if graph == null:
		return

	var district_ids: Array = graph.district_states.keys()
	district_ids.sort_custom(func(a, b): return graph.get_district(String(a)).y < graph.get_district(String(b)).y)
	for district_id in district_ids:
		var district = graph.get_district(String(district_id))
		if district == null:
			continue
		var center := _district_anchor(district)
		var plaque_rect := _resolve_plaque_rect(district, center)
		var hit_rect := Rect2(center - Vector2(34, 34), Vector2(68, 68)).merge(plaque_rect.grow(8))
		district_layout[district.id] = {
			"center": center,
			"plaque_rect": plaque_rect,
			"hit_rect": hit_rect,
		}


func _draw_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), MAP_SURFACE)
	draw_rect(Rect2(Vector2(12, 12), size - Vector2(24, 24)), MAP_SURFACE_ALT, false, 1.5, true)

	var width := maxf(size.x, 1.0)
	var height := maxf(size.y, 1.0)
	for index in range(6):
		var y := lerpf(0.16, 0.88, float(index) / 5.0) * height
		draw_line(Vector2(24, y), Vector2(width - 24, y - 32), Color(0.2, 0.24, 0.28, 0.14), 1.0, true)
	for index in range(7):
		var x := lerpf(0.12, 0.9, float(index) / 6.0) * width
		draw_line(Vector2(x, 28), Vector2(x - 34, height - 28), Color(0.18, 0.22, 0.26, 0.12), 1.0, true)

	var warm_points := PackedVector2Array([
		Vector2(width * 0.08, height * 0.12),
		Vector2(width * 0.42, height * 0.04),
		Vector2(width * 0.58, height * 0.26),
		Vector2(width * 0.24, height * 0.34),
	])
	draw_colored_polygon(warm_points, Color(0.42, 0.18, 0.12, 0.12))
	var cool_points := PackedVector2Array([
		Vector2(width * 0.66, height * 0.46),
		Vector2(width * 0.92, height * 0.3),
		Vector2(width * 0.96, height * 0.74),
		Vector2(width * 0.72, height * 0.88),
		Vector2(width * 0.54, height * 0.68),
	])
	draw_colored_polygon(cool_points, Color(0.08, 0.19, 0.27, 0.14))
	draw_arc(Vector2(width * 0.5, height * 0.54), minf(width, height) * 0.34, -0.4, 2.7, 72, Color(0.32, 0.38, 0.42, 0.1), 2.0, true)


func _draw_roads() -> void:
	var active_roads := _active_road_ids()
	var road_ids: Array = graph.road_states.keys()
	road_ids.sort()
	for road_id in road_ids:
		var road = graph.get_road(String(road_id))
		if road == null:
			continue
		var from_layout: Dictionary = district_layout.get(String(road.from_id), {})
		var to_layout: Dictionary = district_layout.get(String(road.to_id), {})
		if from_layout.is_empty() or to_layout.is_empty():
			continue
		var origin: Vector2 = Vector2(from_layout.get("center", Vector2.ZERO))
		var target: Vector2 = Vector2(to_layout.get("center", Vector2.ZERO))
		var is_preview := preview_route_road_ids.has(road.id)
		var is_active := active_roads.has(road.id)
		var alpha := 0.28 if _road_matches_filter(road) else 0.1
		if is_preview or is_active:
			alpha = 0.95
		var base_color := _road_color(road, alpha)
		var width := 8.0 if road.tags.has("avenue") or road.tags.has("arterial") else 6.0
		draw_line(origin, target, Color(0.03, 0.04, 0.05, alpha * 0.85), width + 5.0, true)
		draw_line(origin, target, base_color, width, true)
		if is_active:
			draw_line(origin, target, ACTIVE_ROUTE, width - 2.0, true)
		if is_preview:
			draw_line(origin, target, PREVIEW_ROUTE, width - 3.0, true)
		if road.blockade > 0.0:
			var midpoint := origin.lerp(target, 0.5)
			draw_circle(midpoint, 6.0 + (road.blockade / 18.0), Color(0.98, 0.76, 0.42, 0.24 + alpha * 0.28))
		if road.blocked_by_collapse:
			var collapse_midpoint := origin.lerp(target, 0.5)
			draw_line(collapse_midpoint + Vector2(-10, -10), collapse_midpoint + Vector2(10, 10), Color(0.92, 0.35, 0.24, 0.9), 3.0, true)
			draw_line(collapse_midpoint + Vector2(-10, 10), collapse_midpoint + Vector2(10, -10), Color(0.92, 0.35, 0.24, 0.9), 3.0, true)


func _draw_zones() -> void:
	var district_ids: Array = district_layout.keys()
	district_ids.sort()
	for district_id in district_ids:
		var district = graph.get_district(String(district_id))
		var layout: Dictionary = district_layout.get(String(district_id), {})
		if district == null or layout.is_empty():
			continue
		var center: Vector2 = Vector2(layout.get("center", Vector2.ZERO))
		var alpha_scale := _district_alpha(district)
		var hazard_strength := clampf((district.danger + (district.collapse * 0.8)) / 160.0, 0.05, 1.0)
		var risk_color := _district_core_color(district)
		risk_color.a = 0.08 * alpha_scale
		draw_circle(center, 52.0 + hazard_strength * 28.0, risk_color)
		var ring_color := NODE_RING_SAFE if not district.is_shelter else _shelter_core_color()
		ring_color.a = (0.24 if _district_matches_filter(district) else 0.12) * alpha_scale
		draw_arc(center, 34.0 + hazard_strength * 12.0, -0.2, 3.2, 48, ring_color, 2.0, true)


func _draw_district_nodes() -> void:
	var district_ids: Array = district_layout.keys()
	district_ids.sort_custom(func(a, b): return graph.get_district(String(a)).y < graph.get_district(String(b)).y)
	for district_id in district_ids:
		var district = graph.get_district(String(district_id))
		var layout: Dictionary = district_layout.get(String(district_id), {})
		if district == null or layout.is_empty():
			continue
		var center: Vector2 = Vector2(layout.get("center", Vector2.ZERO))
		var plaque_rect: Rect2 = Rect2(layout.get("plaque_rect", Rect2()))
		var alpha_scale := _district_alpha(district)
		var is_hovered: bool = hover_district_id == district.id
		var is_focused: bool = focused_district_id == district.id
		var node_fill := _district_core_color(district)
		node_fill.a = 0.95 * alpha_scale
		var node_border := Color(0.97, 0.95, 0.89, 0.22 + (0.45 if is_hovered or is_focused else 0.0))
		var radius := 20.0 if district.is_shelter else 16.0
		draw_circle(center, radius + 7.0, Color(0.01, 0.02, 0.03, 0.78 * alpha_scale))
		draw_circle(center, radius, node_fill)
		draw_arc(center, radius + 4.0, 0.0, TAU, 48, node_border, 2.2, true)
		_draw_district_icon(center, district, alpha_scale)

		var connector_target := Vector2(plaque_rect.position.x, plaque_rect.get_center().y)
		if plaque_rect.get_center().x < center.x:
			connector_target.x = plaque_rect.end.x
		draw_line(center, connector_target, Color(0.75, 0.8, 0.82, 0.18 + alpha_scale * 0.2), 2.0, true)

		var plaque_fill := Color(0.09, 0.11, 0.14, 0.92 * alpha_scale)
		var plaque_border := _district_border_color(district, is_hovered or is_focused)
		_draw_round_rect(plaque_rect, plaque_fill, plaque_border, 16.0)
		_draw_plaque_content(plaque_rect, district, alpha_scale)
		if district.id == selected_pickup_id or district.id == selected_shelter_id:
			var selection_color := _selection_color(district.id)
			draw_arc(center, radius + 11.0, 0.0, TAU, 48, selection_color, 3.2, true)
		if is_hovered:
			draw_arc(center, radius + 15.0, 0.2, 5.8, 48, Color(0.97, 0.84, 0.4, 0.74), 2.4, true)


func _draw_bus_tokens() -> void:
	if game_state == null:
		return
	var bus_ids: Array = game_state.bus_units.keys()
	bus_ids.sort()
	for bus_id in bus_ids:
		var bus = game_state.bus_units[bus_id]
		var position: Vector2 = _bus_position(bus)
		var direction: Vector2 = _bus_direction(bus)
		if direction.length() < 0.1:
			direction = Vector2.RIGHT
		var accent := Color(0.96, 0.83, 0.32, 1.0) if colorblind_mode else Color(0.96, 0.48, 0.31, 1.0)
		accent = accent.lerp(Color(0.32, 0.72, 0.9, 1.0), clampf(float(bus.total_passengers()) / maxf(float(bus.capacity), 1.0), 0.0, 1.0) * 0.24)
		var rotation := direction.angle()
		draw_set_transform(position, rotation, Vector2.ONE)
		draw_rect(Rect2(Vector2(-18, -10), Vector2(36, 20)), Color(0.04, 0.05, 0.06, 0.9))
		draw_rect(Rect2(Vector2(-15, -8), Vector2(30, 16)), accent)
		draw_rect(Rect2(Vector2(-9, -4), Vector2(18, 6)), Color(0.84, 0.92, 0.97, 0.88))
		draw_circle(Vector2(-10, 10), 3.6, Color(0.02, 0.02, 0.03, 0.95))
		draw_circle(Vector2(10, 10), 3.6, Color(0.02, 0.02, 0.03, 0.95))
		draw_circle(Vector2(18, -2), 2.4, Color(0.95, 0.83, 0.44, 0.9))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		var label_rect := Rect2(position + Vector2(16, -34), Vector2(84, 22))
		_draw_round_rect(label_rect, Color(0.03, 0.04, 0.05, 0.86), Color(1, 1, 1, 0.08), 10.0)
		_draw_text(_fit_text(_body_font_size() - 1, bus.name if not bus.name.is_empty() else String(bus.id), label_rect.size.x - 14.0), label_rect.position + Vector2(8, 15), TEXT_PRIMARY, _body_font_size() - 1)


func _draw_legend() -> void:
	if legend_title.is_empty() and legend_body.is_empty():
		return
	var legend_rect := Rect2(Vector2(20, 20), Vector2(minf(420.0, size.x - 40.0), 78))
	_draw_round_rect(legend_rect, Color(0.04, 0.05, 0.06, 0.72), Color(1, 1, 1, 0.08), 18.0)
	_draw_text(legend_title, legend_rect.position + Vector2(16, 24), TEXT_PRIMARY, _title_font_size())
	_draw_text(legend_body, legend_rect.position + Vector2(16, 52), TEXT_MUTED, _body_font_size())

	var chip_y := legend_rect.end.y + 10.0
	_draw_chip(Rect2(Vector2(24, chip_y), Vector2(108, 24)), _selection_color(selected_pickup_id), legend_origin_label)
	_draw_chip(Rect2(Vector2(140, chip_y), Vector2(108, 24)), _selection_color(selected_shelter_id), legend_shelter_label)
	_draw_chip(Rect2(Vector2(256, chip_y), Vector2(132, 24)), ACTIVE_ROUTE, legend_active_label)


func _draw_chip(rect: Rect2, fill_color: Color, text: String) -> void:
	_draw_round_rect(rect, Color(fill_color.r, fill_color.g, fill_color.b, 0.16), Color(fill_color.r, fill_color.g, fill_color.b, 0.58), 12.0)
	draw_circle(rect.position + Vector2(14, rect.size.y * 0.5), 5.0, fill_color)
	_draw_text(text, rect.position + Vector2(26, 16), TEXT_PRIMARY, _body_font_size() - 1)


func _draw_round_rect(rect: Rect2, fill_color: Color, border_color: Color, radius: float) -> void:
	draw_rect(rect, fill_color, true)
	draw_rect(rect, border_color, false, 1.2, true)
	var corner_color := Color(fill_color.r, fill_color.g, fill_color.b, minf(fill_color.a + 0.08, 1.0))
	draw_circle(rect.position + Vector2(radius, radius), radius, corner_color)
	draw_circle(Vector2(rect.end.x - radius, rect.position.y + radius), radius, corner_color)
	draw_circle(Vector2(rect.position.x + radius, rect.end.y - radius), radius, corner_color)
	draw_circle(rect.end - Vector2(radius, radius), radius, corner_color)


func _draw_plaque_content(plaque_rect: Rect2, district, alpha_scale: float) -> void:
	var title_size := _body_font_size() + 1
	var name := _fit_text(title_size, district.name, plaque_rect.size.x - 20.0)
	var base_position := plaque_rect.position + Vector2(10, 20)
	_draw_text(name, base_position, TEXT_PRIMARY, title_size)

	var subtitle := ""
	if district.is_shelter:
		var shelter = graph.get_shelter(district.id)
		var occupants: int = 0 if shelter == null else shelter.total_occupants()
		var capacity: int = district.shelter_capacity if district.shelter_capacity > 0 else (0 if shelter == null else shelter.capacity)
		subtitle = "Abrigo %d/%d" % [occupants, capacity]
	else:
		subtitle = "Pop %d | Embarque %d/m" % [district.total_population(), district.boarding_base_per_minute]
	_draw_text(_fit_text(_body_font_size() - 1, subtitle, plaque_rect.size.x - 20.0), plaque_rect.position + Vector2(10, 40), TEXT_MUTED, _body_font_size() - 1)

	var risk_text := "Panico %.0f | Risco %.0f" % [district.panic, district.danger]
	if district.collapse > 0.0:
		risk_text = "Panico %.0f | Colapso %.0f" % [district.panic, district.collapse]
	_draw_text(_fit_text(_body_font_size() - 1, risk_text, plaque_rect.size.x - 20.0), plaque_rect.position + Vector2(10, 58), Color(0.95, 0.84, 0.68, 0.86 * alpha_scale), _body_font_size() - 1)


func _draw_district_icon(center: Vector2, district, alpha_scale: float) -> void:
	if district.is_shelter:
		var roof := PackedVector2Array([center + Vector2(-8, -2), center + Vector2(0, -10), center + Vector2(8, -2)])
		draw_colored_polygon(roof, Color(0.95, 0.95, 0.96, 0.92 * alpha_scale))
		draw_rect(Rect2(center + Vector2(-6, -2), Vector2(12, 9)), Color(0.11, 0.15, 0.19, 0.95 * alpha_scale))
		draw_rect(Rect2(center + Vector2(-1.5, 2), Vector2(3, 5)), Color(0.95, 0.95, 0.96, 0.75 * alpha_scale))
		return
	if district.tags.has("medical"):
		draw_rect(Rect2(center + Vector2(-2, -9), Vector2(4, 18)), Color(0.96, 0.95, 0.92, 0.92 * alpha_scale))
		draw_rect(Rect2(center + Vector2(-9, -2), Vector2(18, 4)), Color(0.96, 0.95, 0.92, 0.92 * alpha_scale))
		return
	if district.tags.has("terminal"):
		draw_rect(Rect2(center + Vector2(-9, -7), Vector2(18, 14)), Color(0.95, 0.95, 0.96, 0.9 * alpha_scale))
		draw_line(center + Vector2(-12, 9), center + Vector2(12, 9), Color(0.95, 0.95, 0.96, 0.82 * alpha_scale), 2.0, true)
		return
	draw_circle(center, 4.0, Color(0.95, 0.95, 0.96, 0.9 * alpha_scale))


func _district_at_point(point: Vector2) -> String:
	if district_layout.is_empty():
		_rebuild_layout_cache()
	for district_id in district_layout.keys():
		var layout: Dictionary = district_layout.get(String(district_id), {})
		if Rect2(layout.get("hit_rect", Rect2())).has_point(point):
			return String(district_id)
	return ""


func _district_anchor(district) -> Vector2:
	var bounds := _map_bounds()
	return Vector2(
		bounds.position.x + bounds.size.x * district.x,
		bounds.position.y + bounds.size.y * district.y
	)


func _resolve_plaque_rect(district, center: Vector2) -> Rect2:
	var attempts := [
		{"flip_h": false, "flip_v": false},
		{"flip_h": true, "flip_v": false},
		{"flip_h": false, "flip_v": true},
		{"flip_h": true, "flip_v": true},
	]
	for attempt in attempts:
		var candidate := _district_plaque_rect(district, center, bool(attempt.get("flip_h", false)), bool(attempt.get("flip_v", false)))
		if not _plaque_intersects_existing(candidate):
			return candidate

	var settled := _district_plaque_rect(district, center, false, false)
	var vertical_step := 18.0 if center.y <= size.y * 0.5 else -18.0
	for _index in range(8):
		if not _plaque_intersects_existing(settled):
			return settled
		settled.position.y = clampf(settled.position.y + vertical_step, 16.0, size.y - settled.size.y - 16.0)
	return settled


func _district_plaque_rect(district, center: Vector2, flip_horizontal: bool = false, flip_vertical: bool = false) -> Rect2:
	var plaque_size := _district_plaque_size()
	var horizontal_gap := 22.0
	var vertical_offset := 18.0 if center.y <= size.y * 0.58 else -plaque_size.y - 18.0
	if flip_vertical:
		vertical_offset = -plaque_size.y - 18.0 if vertical_offset > 0.0 else 18.0
	var plaque_x := center.x + horizontal_gap
	if (center.x >= size.x * 0.56 and not flip_horizontal) or (center.x < size.x * 0.56 and flip_horizontal):
		plaque_x = center.x - plaque_size.x - horizontal_gap
	var plaque_y := center.y + vertical_offset
	plaque_x = clampf(plaque_x, 16.0, size.x - plaque_size.x - 16.0)
	plaque_y = clampf(plaque_y, 16.0, size.y - plaque_size.y - 16.0)
	return Rect2(Vector2(plaque_x, plaque_y), plaque_size)


func _district_plaque_size() -> Vector2:
	var district_count: int = 0 if graph == null else int(graph.district_states.size())
	if district_count >= 10:
		return Vector2(158, 72)
	if district_count >= 6:
		return Vector2(170, 76)
	return Vector2(186, 82)


func _map_bounds() -> Rect2:
	var horizontal_padding := clampf(size.x * 0.08, 74.0, 112.0)
	var top_padding := clampf(size.y * 0.19, 112.0, 148.0)
	var bottom_padding := clampf(size.y * 0.1, 74.0, 110.0)
	return Rect2(
		Vector2(horizontal_padding, top_padding),
		Vector2(maxf(180.0, size.x - horizontal_padding * 2.0), maxf(180.0, size.y - top_padding - bottom_padding))
	)


func _road_color(road, alpha: float) -> Color:
	if colorblind_mode:
		var safe := Color(0.31, 0.67, 0.78, alpha)
		var dangerous := Color(0.92, 0.8, 0.24, alpha)
		return safe.lerp(dangerous, clampf((road.danger + road.blockade) / 150.0, 0.0, 1.0))
	var safe_default := Color(0.31, 0.45, 0.5, alpha)
	var dangerous_default := Color(0.82, 0.38, 0.26, alpha)
	return safe_default.lerp(dangerous_default, clampf((road.danger + road.blockade) / 150.0, 0.0, 1.0))


func _district_core_color(district) -> Color:
	if district.id == selected_pickup_id:
		return _selection_color(district.id)
	if district.id == selected_shelter_id:
		return _selection_color(district.id)
	if district.is_shelter:
		return _shelter_core_color()
	if colorblind_mode:
		return Color(0.28, 0.36, 0.42, 1.0).lerp(Color(0.94, 0.81, 0.22, 1.0), clampf((district.danger + district.collapse) / 150.0, 0.0, 1.0))
	return Color(0.22, 0.29, 0.34, 1.0).lerp(Color(0.86, 0.39, 0.27, 1.0), clampf((district.danger + district.collapse) / 150.0, 0.0, 1.0))


func _shelter_core_color() -> Color:
	return Color(0.23, 0.61, 0.74, 1.0) if colorblind_mode else Color(0.28, 0.46, 0.76, 1.0)


func _district_border_color(district, emphasized: bool) -> Color:
	var base := Color(1, 1, 1, 0.08 if not emphasized else 0.24)
	if district.id == selected_pickup_id or district.id == selected_shelter_id:
		var selection_color := _selection_color(district.id)
		return Color(selection_color.r, selection_color.g, selection_color.b, 0.72)
	if emphasized:
		return Color(0.97, 0.84, 0.4, 0.75)
	return base


func _selection_color(district_id: String) -> Color:
	if district_id == selected_shelter_id:
		return Color(0.21, 0.71, 0.85, 1.0) if colorblind_mode else Color(0.33, 0.69, 0.96, 1.0)
	return Color(0.95, 0.65, 0.22, 1.0) if colorblind_mode else Color(0.39, 0.82, 0.56, 1.0)


func _district_alpha(district) -> float:
	return 1.0 if _district_matches_filter(district) else 0.24


func _plaque_intersects_existing(candidate: Rect2) -> bool:
	for district_id in district_layout.keys():
		var existing: Dictionary = district_layout.get(String(district_id), {})
		var plaque_rect: Rect2 = Rect2(existing.get("plaque_rect", Rect2()))
		if candidate.grow(4.0).intersects(plaque_rect.grow(4.0)):
			return true
	return false


func _district_matches_filter(district) -> bool:
	match map_filter_mode:
		"high_danger":
			return district.danger >= 65.0
		"shelters":
			return district.is_shelter
		"collapse":
			return district.collapse > 0.0 or district.is_collapsed()
		_:
			return true


func _road_matches_filter(road) -> bool:
	if map_filter_mode == "all":
		return true
	var from_district = graph.get_district(road.from_id)
	var to_district = graph.get_district(road.to_id)
	return (from_district != null and _district_matches_filter(from_district)) or (to_district != null and _district_matches_filter(to_district))


func _active_road_ids() -> Array:
	var active: Array = []
	if game_state == null:
		return active
	for bus_id in game_state.bus_units.keys():
		var bus = game_state.bus_units[bus_id]
		if not bus.current_road_id.is_empty() and not active.has(bus.current_road_id):
			active.append(bus.current_road_id)
		for road_id in bus.route_road_ids:
			var route_road_id := String(road_id)
			if not route_road_id.is_empty() and not active.has(route_road_id):
				active.append(route_road_id)
	return active


func _bus_position(bus) -> Vector2:
	if not bus.current_road_id.is_empty():
		var road = graph.get_road(bus.current_road_id)
		if road != null:
			var from_layout: Dictionary = district_layout.get(String(road.from_id), {})
			var to_layout: Dictionary = district_layout.get(String(road.to_id), {})
			if not from_layout.is_empty() and not to_layout.is_empty() and road.length_km > 0.0:
				var origin: Vector2 = Vector2(from_layout.get("center", Vector2.ZERO))
				var target: Vector2 = Vector2(to_layout.get("center", Vector2.ZERO))
				var traveled_ratio := clampf((road.length_km - bus.current_segment_remaining_km) / road.length_km, 0.0, 1.0)
				return origin.lerp(target, traveled_ratio)
	var layout: Dictionary = district_layout.get(String(bus.current_district_id), {})
	return Vector2(layout.get("center", Vector2.ZERO))


func _bus_direction(bus) -> Vector2:
	if not bus.current_road_id.is_empty():
		var road = graph.get_road(bus.current_road_id)
		if road != null:
			var from_layout: Dictionary = district_layout.get(String(road.from_id), {})
			var to_layout: Dictionary = district_layout.get(String(road.to_id), {})
			return Vector2(to_layout.get("center", Vector2.ZERO)) - Vector2(from_layout.get("center", Vector2.ZERO))
	if not bus.route_road_ids.is_empty():
		var next_road = graph.get_road(String(bus.route_road_ids[mini(bus.route_index, bus.route_road_ids.size() - 1)]))
		if next_road != null:
			var from_layout: Dictionary = district_layout.get(String(next_road.from_id), {})
			var to_layout: Dictionary = district_layout.get(String(next_road.to_id), {})
			return Vector2(to_layout.get("center", Vector2.ZERO)) - Vector2(from_layout.get("center", Vector2.ZERO))
	return Vector2.RIGHT


func _fit_text(font_size: int, text: String, max_width: float) -> String:
	var font := get_theme_default_font()
	if font == null:
		return text
	var candidate := text
	if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_width:
		return candidate
	while candidate.length() > 4:
		candidate = "%s..." % candidate.substr(0, candidate.length() - 4)
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_width:
			return candidate
	return candidate


func _draw_text(text: String, position: Vector2, color: Color, font_size: int) -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _title_font_size() -> int:
	return int(round(15.0 * font_scale))


func _body_font_size() -> int:
	return int(round(12.0 * font_scale))
