extends Node

class_name DeckController

func Create_Deck(Deck_List, Current_Duelist):
	for card in GameData.CardData:
		if card["Passcode"] in GameData.Master_Deck_List["Decks"][Deck_List]:
			var Passcode = card["Passcode"]
			for _copies in range(0,GameData.Master_Deck_List["Decks"][Deck_List].count(Passcode)):
				var Created_Card = Card.new(card["CardType"], card["CardArt"], card["CardName"], card["CardType"], card["EffectType"], card["AnchorText"], card["Attribute"], card["Description"], card["ShortDescription"], card["Attack"], 0, 0, card["Cost"], card["Health"], 0, 0, card["SpecialEditionText"], card["Rarity"], card["Passcode"], card["DeckCapacity"], 0, false, false, 1, false, false, false, false, false, false, false, false, Current_Duelist)
				
				# Ensures that Tech cards go into the Tech Deck.
				var player = GameData.Player if Current_Duelist == "Player" else GameData.Enemy
				if Created_Card.Type == "Tech":
					player.Tech_Deck.append(Created_Card)
				else:
					player.Deck.append(Created_Card)

func Create_Advance_Tech_Card():
	var Created_Card
	for card in GameData.CardData:
		if card["Passcode"] == 42489363:
			Created_Card = Card.new(card["CardType"], card["CardArt"], card["CardName"], card["CardType"], card["EffectType"], card["AnchorText"], card["Attribute"], card["Description"], card["ShortDescription"], card["Attack"], 0, 0, card["Cost"], card["Health"], 0, 0, card["SpecialEditionText"], card["Rarity"], card["Passcode"], card["DeckCapacity"], 0, false, false, 1, false, false, false, false, false, false, false, false, "Game")
	
	var random_number = Utils.RNGesus(1, 2)
	if random_number == 1:
		GameData.Player.Deck.append(Created_Card)
	else:
		GameData.Enemy.Deck.append(Created_Card)

func Shuffle_Deck(player):
	player.Deck.shuffle()

func Pop_Deck(Deck_To_Pop):
	Deck_To_Pop.Deck.pop_back()

func Reload_Deck(Deck_ID, MedBay_ID):
	if len(Deck_ID) == 0 and len(MedBay_ID) > 0:
		for i in range(len(MedBay_ID)):
			Deck_ID.append(MedBay_ID[i])
		MedBay_ID.clear()
		SignalBus.emit_signal("Clear_MedBay")
