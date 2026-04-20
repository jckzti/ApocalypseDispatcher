extends "res://addons/gut/test.gd"

const DeterministicRng = preload("res://scripts/core/DeterministicRng.gd")


func test_same_seed_generates_same_sequence() -> void:
	var rng_a := DeterministicRng.new(123456)
	var rng_b := DeterministicRng.new(123456)

	var sequence_a: Array = []
	var sequence_b: Array = []
	for _index in 6:
		sequence_a.append(rng_a.next_u32())
		sequence_b.append(rng_b.next_u32())

	assert_eq(sequence_a, sequence_b, "Seeds iguais devem reproduzir a mesma sequencia.")


func test_different_seed_changes_sequence() -> void:
	var rng_a := DeterministicRng.new(111)
	var rng_b := DeterministicRng.new(222)

	assert_ne(rng_a.next_u32(), rng_b.next_u32(), "Seeds diferentes nao devem gerar a mesma primeira amostra.")


func test_restore_recovers_state() -> void:
	var rng := DeterministicRng.new(77)
	rng.next_u32()
	rng.next_u32()
	var snapshot := rng.snapshot()
	var expected_next := rng.next_u32()

	var restored := DeterministicRng.new()
	restored.restore(snapshot)
	assert_eq(restored.next_u32(), expected_next, "Restaurar snapshot deve reproduzir a proxima amostra.")
