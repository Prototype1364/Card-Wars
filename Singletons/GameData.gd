extends Node

var CardData
var Master_Deck_List

var Current_Turn = "Player"

func _ready():
	# Loads Card Pool Into Game.
	var CardData_File = File.new()
	CardData_File.open("res://Data/CardDB.json", File.READ)
	var CardData_JSON = JSON.parse(CardData_File.get_as_text())
	CardData_File.close()
	CardData = CardData_JSON.result
	
	# Loads List of Pre-Built Decks Into Game
	# Currently DOESN'T include Player/Enemy Decks.
	# During early testing it is assumed that the Player uses Arthurian Pre-Built Deck & Enemy uses Greek Mythology.
	var MasterDeckList_File = File.new()
	MasterDeckList_File.open("res://Data/Master_Deck_List.json", File.READ)
	var MasterDeckList_JSON = JSON.parse(MasterDeckList_File.get_as_text())
	MasterDeckList_File.close()
	Master_Deck_List = MasterDeckList_JSON.result