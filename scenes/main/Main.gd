extends Control

const TITLE := "Despachante do Apocalipse"
const SUBTITLE := "Bootstrap da Fase 00"

@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	status_label.text = "%s\n%s\nEstrutura inicial pronta para as proximas fases." % [TITLE, SUBTITLE]

