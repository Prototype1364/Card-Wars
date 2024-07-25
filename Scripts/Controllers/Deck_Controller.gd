extends Node

func Create_Card(cardPasscode):
	for card in GameData.CardData:
		if card["Passcode"] == cardPasscode:
			var Created_Card = Card.new(card["CardType"], card["CardArt"], card["CardName"], card["CardType"], card["EffectType"], card["AnchorText"], card["ResolveSide"], card["ResolvePhase"], card["ResolveStep"], card["Attribute"], card["Description"], card["ShortDescription"], card["Attack"], 0, card["Toxicity"], card["Cost"], card["Health"], 0, 0, card["SpecialEditionText"], card["Rarity"], card["Passcode"], card["DeckCapacity"], 0, false, false, 1, false, false, false, false, false, false, false, false, "Game")
			var Card_Controller = load('Scenes/SupportScenes/SmallCard.tscn').instantiate()
			Created_Card.add_child(Card_Controller)
			Created_Card.name = "Card" + str(GameData.CardCounter)
			GameData.CardCounter += 1
			Created_Card.custom_minimum_size = Vector2(120,180)
			return Created_Card

func Create_Deck(Deck_List, Current_Duelist):	
	for card in GameData.CardData:
		if card["Passcode"] in GameData.Master_Deck_List["Decks"][Deck_List]:
			var Passcode = card["Passcode"]
			for _copies in range(0,GameData.Master_Deck_List["Decks"][Deck_List].count(Passcode)):
				var Side = "W" if Current_Duelist == "Player" else "B"
				var Created_Card = Create_Card(card["Passcode"])

				# Ensures that Tech cards go into the Tech Deck.
				if Created_Card.Type == "Tech":
					var Deck_Node = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/NonHands/" + Side + "TechDeck")
					Deck_Node.add_child(Created_Card)
				else:
					var Deck_Node = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/NonHands/" + Side + "MainDeck")
					Deck_Node.add_child(Created_Card)
				
				# Fix Positioning Bug
				Created_Card.get_node("SmallCard").set_position(Vector2.ZERO)

func Create_Advance_Tech_Card():
	var Created_Card
	for card in GameData.CardData:
		if card["Passcode"] == 42489363:
			Created_Card = Create_Card(card["Passcode"])

	var random_number = Utils.RNGesus(1, 2)
	var Deck_Node = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/NonHands/WMainDeck") if random_number == 1 else Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/NonHands/BMainDeck")
	Deck_Node.add_child(Created_Card)

	# Fix Positioning Bug
	Created_Card.get_node("SmallCard").set_position(Vector2.ZERO)

func Shuffle_Deck(player):
	# Get the deck
	var Deck = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/NonHands/WMainDeck").get_children() if player.Name == "Player" else Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/NonHands/BMainDeck").get_children()
	var wMainDeck = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/NonHands/WMainDeck")
	var bMainDeck = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/NonHands/BMainDeck")
	var mainDeckUsed = wMainDeck if player.Name == "Player" else bMainDeck
	
	# Create a new array to shuffle the deck
	var NewArray = []
	for i in range(len(Deck)):
		var random_number = Utils.RNGesus(0, len(Deck) - 1)
		while random_number in NewArray:
			random_number = Utils.RNGesus(0, len(Deck) - 1)
		NewArray.append(random_number)
	
	# Loop through the deck and shuffle the cards based on the new array
	for i in range(len(Deck)):
		var card_index = NewArray[i]
		var card = mainDeckUsed.get_child(card_index)
		mainDeckUsed.move_child(card, i)
