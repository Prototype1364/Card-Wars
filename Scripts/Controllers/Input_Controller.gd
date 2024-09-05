extends VScrollBar

func Scroll(event):
	var Playmat = get_tree().get_root().get_node("SceneHandler/Battle/Playmat")
	if event is InputEventMouseButton:
		# Ensures board doesn't scroll when mouse is over Hand UIs
		if not ((event.position.x >= 1000 and event.position.y >= 1500) or (event.position.x <= 1860 and event.position.y <= 255)):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				self.value -= 30
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				self.value += 30
			Playmat.position.y = 0 - self.value

func Resolve_Input(event):
	var action_signal_map = {
		"next_phase": "Advance_Phase",
		"end_turn": "Advance_Turn",
		"Confirm": "Confirm",
		"Cancel": "Cancel"
	}

	for action in action_signal_map.keys():
		if event.is_action_pressed(action):
			SignalBus.emit_signal(action_signal_map[action])