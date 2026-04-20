extends RefCounted
class_name GameConstants

const SAVE_VERSION := 1
const GAME_VERSION := "0.1.0-dev"

const MINUTES_PER_HOUR := 60
const HOURS_PER_DAY := 24
const MINUTES_PER_DAY := MINUTES_PER_HOUR * HOURS_PER_DAY

const DEFAULT_TICK_MINUTES := 1
const DEFAULT_SIMULATION_SPEED := 1.0
const DEFAULT_MAX_ADVANCE_MINUTES := 1440

const DEFAULT_CRISIS_LEVEL := 0
const MAX_STAT := 100.0
const HIGH_DANGER_THRESHOLD := 65.0
const COLLAPSE_THRESHOLD := 100.0

const CONTENT_ROOT := "res://data"
const CONTENT_DIRS := {
	"cards": "cards",
	"events": "events",
	"game_modes": "game_modes",
	"maps": "maps",
	"scenarios": "scenarios",
}

const COHORT_VULNERABILITY := {
	"adults": 1.0,
	"children": 1.4,
	"elderly": 1.6,
	"patients": 2.0,
	"essential_staff": 1.0,
	"volunteer_drivers": 1.0,
	"high_influence": 1.0,
}

const COHORT_SCORE_WEIGHT := {
	"adults": 1.0,
	"children": 1.8,
	"elderly": 1.6,
	"patients": 2.2,
	"essential_staff": 1.4,
	"volunteer_drivers": 1.2,
	"high_influence": 0.8,
}

const DEFAULT_GLOBAL_METRICS := {
	"saved_population": 0,
	"dead_population": 0,
	"evacuated_population": 0,
	"political_pressure": 0.0,
	"moral_debt": 0.0,
}

const DEFAULT_SCORE_STATE := {
	"score": 0,
	"run_over": false,
	"end_reason": "",
	"grade": "",
}
