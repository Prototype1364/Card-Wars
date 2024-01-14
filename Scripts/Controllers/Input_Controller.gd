extends Node

class_name InputController

var Node_Playmat = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat")
var Node_BoardScroller = Engine.get_main_loop().get_current_scene().get_node("Battle/BoardScroller")

func Advance_GameState(event):
	if event.is_action_pressed("next_phase"):
		SignalBus.emit_signal("Advance_Phase")
	if event.is_action_pressed("end_turn"):
		SignalBus.emit_signal("Advance_Turn")

func Scroll(event, Playmat = Node_Playmat, BoardScroller = Node_BoardScroller):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			BoardScroller.value -= 30
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			BoardScroller.value += 30
		Playmat.position.y = 0 - BoardScroller.value

func Confirm(event):
	if event.is_action_pressed("Confirm"):
		SignalBus.emit_signal("Confirm")
