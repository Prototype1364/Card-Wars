extends Node

func _ready():
	# Setup Signal_Bus functionality. Note: Holder Variables (_HV) serve to eliminate Debugger warnings.
	var _HV1 = SignalBus.connect("Load_Battle_Scene", self, "Load_Battle_Scene")
	
	var MainMenu = preload("res://Scenes/MainScenes/Main_Menu.tscn").instance()
	self.add_child(MainMenu, true)

func Remove_Children():
	for i in self.get_children():
		self.remove_child(i)
		i.queue_free()

func Load_Battle_Scene():
	Remove_Children()
	var Battle_Scene = preload("res://Scenes/MainScenes/Battle.tscn").instance()
	self.add_child(Battle_Scene, true)
