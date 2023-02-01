extends Node

var Player_Deck = []
var Enemy_Deck = []

func _ready():
	Load_Game_Decks()
#	Draw_Card(5)

func Load_Game_Decks():
	# Loads Player & Enemy Decks for Battle into Game.
	for i in GameData.CardData.size():
		# Load Player Deck (Currently defaults to Arthurian Pre-Built Deck).
		if GameData.CardData[i]["Passcode"] in GameData.Master_Deck_List["Decks"]["Arthurian"]:
			# Checks to ensure that cards with more than 1 copy in the Deck List are added in properly.
			for copies in GameData.Master_Deck_List["Decks"]["Arthurian"].count(GameData.CardData[i]["Passcode"]):
				Player_Deck.append(GameData.CardData[i])
		
		# Load Enemy Deck (Currently defaults to Greek Mythology Pre-Built Deck).
		if GameData.CardData[i]["Passcode"] in GameData.Master_Deck_List["Decks"]["Greek Mythology"]:
			# Checks to ensure that cards with more than 1 copy in the Deck List are added in properly.
			for copies in GameData.Master_Deck_List["Decks"]["Greek Mythology"].count(GameData.CardData[i]["Passcode"]):
				Enemy_Deck.append(GameData.CardData[i])

#func Draw_Card(Cards_To_Draw = 1):
#	# Draws cards from back of Deck based on number supplied, or 1 card if no number is supplied.
#	for i in range(1,Cards_To_Draw + 1):
#		var Card_Scene = preload("res://Scenes/SupportScenes/Card.tscn").instance() # WILL THROW ERRORS IN OUTPUT WINDOW DUE TO CARD SCENE BEING DELETED. JUST UPDATE TO WHICHEVER SCENE REPLACES ITS FUNCTION IN BATTLE SCENE.
#		Card_Scene.name = "Card" + str(i)
#		Card_Scene.set_variable_values(Player_Deck[-i]["Card_ID"])
#		Card_Scene.set_card_text()
#		if GameData.Current_Turn == "Player":
#			$PlayerHand.add_child(Card_Scene, true)
#		elif GameData.Current_Turn == "Enemy":
#			$EnemyHand.add_child(Card_Scene, true)
	
#	# Updates Decks to remove freshly drawn cards
#	for _i in range(0,Cards_To_Draw):
#		if GameData.Current_Turn == "Player":
#			Player_Deck.pop_back()
#		elif GameData.Current_Turn == "Enemy":
#			Enemy_Deck.pop_back()
