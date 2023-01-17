extends Node

func _ready():
	var MainMenu = preload("res://Scenes/MainScenes/Main_Menu.tscn").instance()
	self.add_child(MainMenu, true)
