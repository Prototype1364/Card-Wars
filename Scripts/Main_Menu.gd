extends Control

func _ready():
	print("READY")
	$"VBoxContainer/Button_Container/Quick Play".grab_focus()

func _On_Quick_Play_Pressed():
	SignalBus.emit_signal("Load_Battle_Scene")


func _On_Campaign_Pressed():
	pass # Replace with function body.


func _On_Options_Pressed():
	pass # Replace with function body.


func _On_Deck_Editor_Pressed():
	pass # Replace with function body.


func _On_Credits_Pressed():
	pass # Replace with function body.


func _On_Exit_Pressed():
	get_tree().quit()
