extends VScrollBar

func Advance_GameState(event):
	if event.is_action_pressed("next_phase"):
		SignalBus.emit_signal("Advance_Phase")
	if event.is_action_pressed("end_turn"):
		SignalBus.emit_signal("Advance_Turn")

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

func Confirm(event):
	if event.is_action_pressed("Confirm"):
		SignalBus.emit_signal("Confirm")
