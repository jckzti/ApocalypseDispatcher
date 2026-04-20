extends RefCounted
class_name GameEnums

enum CommandType {
	CREATE_EVACUATION_ORDER,
	CANCEL_EVACUATION_ORDER,
	ASSIGN_BUS_TO_ORDER,
	UNASSIGN_BUS_FROM_ORDER,
	CHANGE_PRIORITY_POLICY,
	SPEND_BUDGET_ON_REROLL,
	CHOOSE_CARD,
	CHOOSE_EVENT_OPTION,
	PAUSE_SIMULATION,
	SET_SIMULATION_SPEED,
	REPAIR_BUS,
	BUY_EMERGENCY_FUEL,
}

enum PriorityPolicy {
	BALANCED,
	CHILDREN_FIRST,
	MEDICAL_FIRST,
	ESSENTIAL_STAFF_FIRST,
	FASTEST_BOARDING,
	POLITICAL_PRESSURE,
}

enum BusState {
	IDLE,
	TO_PICKUP,
	LOADING,
	TO_DROPOFF,
	UNLOADING,
	RETURNING,
	REPAIRING,
	DISABLED,
}

const COMMAND_TYPE_KEYS := [
	"create_evacuation_order",
	"cancel_evacuation_order",
	"assign_bus_to_order",
	"unassign_bus_from_order",
	"change_priority_policy",
	"spend_budget_on_reroll",
	"choose_card",
	"choose_event_option",
	"pause_simulation",
	"set_simulation_speed",
	"repair_bus",
	"buy_emergency_fuel",
]

const PRIORITY_POLICY_KEYS := [
	"balanced",
	"children_first",
	"medical_first",
	"essential_staff_first",
	"fastest_boarding",
	"political_pressure",
]

const BUS_STATE_KEYS := [
	"idle",
	"to_pickup",
	"loading",
	"to_dropoff",
	"unloading",
	"returning",
	"repairing",
	"disabled",
]

const POPULATION_COHORT_KEYS := [
	"adults",
	"children",
	"elderly",
	"patients",
	"essential_staff",
	"volunteer_drivers",
	"high_influence",
]

const GLOBAL_RESOURCE_KEYS := [
	"budget",
	"fuel",
	"order",
	"trust",
	"communication",
	"intelligence",
	"medical_supplies",
	"parts",
	"authority",
]


static func priority_policy_to_key(value: int) -> String:
	return _enum_to_key(value, PRIORITY_POLICY_KEYS)


static func bus_state_to_key(value: int) -> String:
	return _enum_to_key(value, BUS_STATE_KEYS)


static func command_type_to_key(value: int) -> String:
	return _enum_to_key(value, COMMAND_TYPE_KEYS)


static func parse_priority_policy(value: Variant) -> int:
	return _parse_enum_value(value, PRIORITY_POLICY_KEYS, PriorityPolicy.BALANCED)


static func parse_bus_state(value: Variant) -> int:
	return _parse_enum_value(value, BUS_STATE_KEYS, BusState.IDLE)


static func parse_command_type(value: Variant) -> int:
	return _parse_enum_value(value, COMMAND_TYPE_KEYS, CommandType.CREATE_EVACUATION_ORDER)


static func create_empty_population() -> Dictionary:
	var population := {}
	for cohort_key in POPULATION_COHORT_KEYS:
		population[cohort_key] = 0
	return population


static func create_empty_resources() -> Dictionary:
	var resources := {}
	for resource_key in GLOBAL_RESOURCE_KEYS:
		resources[resource_key] = 0
	return resources


static func _enum_to_key(value: int, keys: Array) -> String:
	if value < 0 or value >= keys.size():
		return ""
	return String(keys[value])


static func _parse_enum_value(value: Variant, keys: Array, default_value: int) -> int:
	if value is int:
		return clampi(value, 0, keys.size() - 1)
	var as_string := String(value)
	var index := keys.find(as_string)
	if index == -1:
		return default_value
	return index
