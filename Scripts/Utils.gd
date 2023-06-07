extends Node

class_name Utils

static func RNGesus(lower_bound, upper_bound) -> int:
	var rng = RandomNumberGenerator.new()
	var rnd_value = rng.randi_range(lower_bound, upper_bound)
	return rnd_value

static func Dice_Roll() -> int:
	var roll_result = RNGesus(1, 6)
	return roll_result
