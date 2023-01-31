extends Control

var Name
var Summon_Counters = 0
var Text = ""
var Max_Health = 0
var Health = 0
var Damage = 0

func _on_FocusSensor_focus_entered():
	self.focusing()

func _on_FocusSensor_mouse_entered():
	self.focusing()

func _on_FocusSensor_focus_exited():
	self.defocusing()

func _on_FocusSensor_mouse_exited():
	self.defocusing()

func focusing():
	GameData.FocusedCardName = self.name
	GameData.FocusedCardParentName = self.get_parent().name
	SignalBus.emit_signal("LookAtCard")

func defocusing():
	GameData.FocusedCardName = ""
	SignalBus.emit_signal("NotLookingAtCard")

func _on_FocusSensor_pressed():
	if GameData.CardFrom == "":
		GameData.CardFrom = self.get_parent().name
		GameData.CardMoved = self.name
	elif GameData.CardFrom != "":
		GameData.CardTo = self.get_parent().name
		GameData.CardSwitched = self.name
		SignalBus.emit_signal("SwitchInProgress")
