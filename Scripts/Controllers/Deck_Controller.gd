extends Node

@onready var BC = get_parent().get_parent()
@onready var BM = get_tree().get_root().get_node("SceneHandler/Battle")

func Create_Card(cardPasscode):
	for card in BM.CardData:
		if card["Passcode"] == cardPasscode:
			var card_data = {
				"Art": card["CardArt"],
				"Name": card["CardName"],
				"Type": card["CardType"],
				"Effect_Type": card["EffectType"],
				"Anchor_Text": card["AnchorText"],
				"Auto_Resolve_Effect": card["AutoResolveEffect"],
				"Resolve_Side": card["ResolveSide"],
				"Resolve_Phase": card["ResolvePhase"],
				"Resolve_Phase_String": card["ResolvePhaseString"],
				"ValidationRequired": {'On Field': card["CheckField"],'Resolvable Card': card["CheckSide"],'Valid GameState': card["CheckGameState"],'Valid Effect Type': card["CheckDisabledEffects"]},
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
			var Card_Controller = load('res://Scenes/SupportScenes/SmallCard.tscn').instantiate()
			Created_Card.add_child(Card_Controller)
			Created_Card.name = "Card" + str(BM.CardCounter)
			BM.CardCounter += 1
			Created_Card.custom_minimum_size = Vector2(120,180)
			Created_Card.add_to_group("Cards")
			return Created_Card

func Create_Deck(Deck_List, Current_Duelist):	
	for card in BM.CardData:
		if card["Passcode"] in BM.Master_Deck_List["Decks"][Deck_List]:
			var Passcode = card["Passcode"]
			for _copies in range(0,BM.Master_Deck_List["Decks"][Deck_List].count(Passcode)):
				var Side = "W" if Current_Duelist == "Player" else "B"
				var Created_Card = Create_Card(card["Passcode"])

				# Ensures that cards go into the appriate Deck based on card type
				var Deck_Node = get_node(Side + {"Tech": "TechDeck", "Hero": "HeroDeck"}.get(Created_Card.Type, "MainDeck"))
				Deck_Node.add_child(Created_Card)
				
				# Fix Positioning Bug
				Created_Card.get_node("SmallCard").set_position(Vector2.ZERO)

func Create_Advance_Tech_Card():
	var Created_Card
	for card in BM.CardData:
		if card["Passcode"] == 42489363:
			Created_Card = Create_Card(card["Passcode"])

	var random_number = BC.RNGesus(1, 2)
	var Deck_Node = get_node("WMainDeck") if random_number == 1 else get_node("BMainDeck")
	Deck_Node.add_child(Created_Card)

	# Fix Positioning Bug
	Created_Card.get_node("SmallCard").set_position(Vector2.ZERO)

func Shuffle_Deck(player, Deck_Source = "MainDeck"):
	var Deck = get_node("W" + Deck_Source) if player.Name == "Player" else get_node("B" + Deck_Source)
	
	# Create an array of all child nodes
	var deck_children = []
	for i in range(Deck.get_child_count()):
		deck_children.append(Deck.get_child(i))

	# Shuffle the array, then re-arrange the children in the Deck node based on the shuffled array order
	deck_children.shuffle()
	for i in range(deck_children.size()):
		Deck.move_child(deck_children[i], i)
