extends RefCounted
class_name MapDef

const DistrictDef = preload("res://scripts/data/DistrictDef.gd")
const RoadDef = preload("res://scripts/data/RoadDef.gd")

var id: String = ""
var name: String = ""
var description: String = ""
var districts: Array = []
var roads: Array = []


func _init(data: Dictionary = {}) -> void:
	apply_dictionary(data)


func apply_dictionary(data: Dictionary) -> void:
	id = String(data.get("id", ""))
	name = String(data.get("name", ""))
	description = String(data.get("description", ""))
	districts = []
	for district_data in Array(data.get("districts", [])):
		if district_data is Dictionary:
			districts.append(DistrictDef.new(district_data))
	roads = []
	for road_data in Array(data.get("roads", [])):
		if road_data is Dictionary:
			roads.append(RoadDef.new(road_data))


func to_dictionary() -> Dictionary:
	var district_data: Array = []
	for district in districts:
		district_data.append(district.to_dictionary())

	var road_data: Array = []
	for road in roads:
		road_data.append(road.to_dictionary())

	return {
		"id": id,
		"name": name,
		"description": description,
		"districts": district_data,
		"roads": road_data,
	}


func validate() -> Array:
	var errors: Array = []
	if id.is_empty():
		errors.append("MapDef sem campo obrigatorio 'id'.")
	if name.is_empty():
		errors.append("MapDef '%s' sem campo obrigatorio 'name'." % id)
	if districts.is_empty():
		errors.append("MapDef '%s' precisa de ao menos um distrito." % id)
	if roads.is_empty():
		errors.append("MapDef '%s' precisa de ao menos uma estrada." % id)

	var district_ids := {}
	for district in districts:
		errors.append_array(district.validate())
		if district_ids.has(district.id):
			errors.append("MapDef '%s' possui distrito duplicado '%s'." % [id, district.id])
		district_ids[district.id] = true

	var road_ids := {}
	for road in roads:
		errors.append_array(road.validate())
		if road_ids.has(road.id):
			errors.append("MapDef '%s' possui estrada duplicada '%s'." % [id, road.id])
		road_ids[road.id] = true
		if not district_ids.has(road.from_id):
			errors.append("MapDef '%s' possui estrada '%s' com origem inexistente '%s'." % [id, road.id, road.from_id])
		if not district_ids.has(road.to_id):
			errors.append("MapDef '%s' possui estrada '%s' com destino inexistente '%s'." % [id, road.id, road.to_id])
	return errors
