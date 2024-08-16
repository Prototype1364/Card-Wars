extends Node

@onready var BC = get_parent().get_parent()

func Create_Card(cardPasscode):
	for card in GameData.CardData:
		if card["Passcode"] == cardPasscode:
			var card_data = {
				"Frame": card["CardType"],
				"Art": card["CardArt"],
				"Name": card["CardName"],
				"Type": card["CardType"],
				"Effect_Type": card["EffectType"],
				"Anchor_Text": card["AnchorText"],
				"Resolve_Side": card["ResolveSide"],
				"Resolve_Phase": card["ResolvePhase"],
				"Resolve_Step": card["ResolveStep"],
				"Attribute": card["Attribute"],
				"Description": card["Description"],
				"Short_Description": card["ShortDescription"],
				"Attack": card["Attack"],
				"Toxicity": card["Toxicity"],
				"Cost": card["Cost"],
				"Health": card["Health"],
				"Special_Edition_Text": card["SpecialEditionText"],
				"Rarity": card["Rarity"],
				"Passcode": card["Passcode"],
				"Deck_Capacity": card["DeckCapacity"],
			}
			var Created_Card = Card.new(card_data)
			var Card_Controller = load('Scenes/SupportScenes/SmallCard.tscn').instantiate()
			Created_Card.add_child(Card_Controller)
			Created_Card.name = "Card" + str(GameData.CardCounter)
			GameData.CardCounter += 1
			Created_Card.custom_minimum_size = Vector2(120,180)
			Created_Card.add_to_group("Cards")
			return Created_Card

func Create_Deck(Deck_List, Current_Duelist):	
	for card in GameData.CardData:
		if card["Passcode"] in GameData.Master_Deck_List["Decks"][Deck_List]:
			var Passcode = card["Passcode"]
			for _copies in range(0,GameData.Master_Deck_List["Decks"][Deck_List].count(Passcode)):
				var Side = "W" if Current_Duelist == "Player" else "B"
				var Created_Card = Create_Card(card["Passcode"])

				# Ensures that cards go into the appriate Deck based on card type
				var Deck_Node = get_node(Side + {"Tech": "TechDeck", "Hero": "HeroDeck"}.get(Created_Card.Type, "MainDeck"))
				Deck_Node.add_child(Created_Card)
				
				# Fix Positioning Bug
				Created_Card.get_node("SmallCard").set_position(Vector2.ZERO)

func Create_Advance_Tech_Card():
	var Created_Card
	for card in GameData.CardData:
		if card["Passcode"] == 42489363:
			Created_Card = Create_Card(card["Passcode"])

	var random_number = BC.RNGesus(1, 2)
	var Deck_Node = get_node("WMainDeck") if random_number == 1 else get_node("BMainDeck")
	Deck_Node.add_child(Created_Card)

	# Fix Positioning Bug
	Created_Card.get_node("SmallCard").set_position(Vector2.ZERO)

func Shuffle_Deck(player, Deck_Source = "MainDeck"):
	var Deck = get_node("W" + Deck_Source) if player.Name == "Player" else get_node("B" + Deck_Source)
	
	# Create a new array to shuffle the deck
	var NewArray = []
	for i in range(Deck.get_child_count()):
		var random_number = BC.RNGesus(0, Deck.get_child_count() - 1)
		while random_number in NewArray:
			random_number = BC.RNGesus(0, Deck.get_child_count() - 1)
		NewArray.append(random_number)
	
	# Loop through the deck and shuffle the cards based on the new array order
	for i in range(Deck.get_child_count()):
		var card_index = NewArray[i]
		var card = Deck.get_child(card_index)
		Deck.move_child(card, i)
