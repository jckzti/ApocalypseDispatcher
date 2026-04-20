extends Node

const PROJECT_NAME := "Despachante do Apocalipse"
const CURRENT_PHASE := "Fase 24"

func get_bootstrap_summary() -> Dictionary:
	return {
		"project_name": PROJECT_NAME,
		"phase": CURRENT_PHASE,
	}
