extends Control

var Current_Scene = Engine.get_main_loop().get_current_scene()
var Card_Selected = null

func _ready():
	var _HV1 = SignalBus.connect("EffectTargetSelected", Callable(self, "On_Card_Selection"))

func Determine_Card_List(selection_type, slot = null):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
	var Selection_Source = null

	match selection_type:
		"Deck":
			Selection_Source = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side + "NonHands/" + Side + "MainDeck")
		"Tech Deck":
			Selection_Source = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side + "NonHands/" + Side + "TechDeck")
		"Field":
			Selection_Source = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side + "NonHands/" + Side + slot)
		"Medbay":
			Selection_Source = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side + "NonHands/" + Side + "Medbay")
		"Grave":
			Selection_Source = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side + "NonHands/" + Side + "Graveyard")
		"Hand":
			Selection_Source = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")
		"Opponent Deck":
			Selection_Source = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side_Opp + "NonHands/" + Side_Opp + "MainDeck")
		"Opponent Tech Deck":
			Selection_Source = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side_Opp + "NonHands/" + Side_Opp + "TechDeck")
		"Opponent Field":
			Selection_Source = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side_Opp + "NonHands/" + Side_Opp + slot)
		"Opponent Medbay":
			Selection_Source = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side_Opp + "NonHands/" + Side_Opp + "Medbay")
		"Opponent Grave":
			Selection_Source = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side_Opp + "NonHands/" + Side_Opp + "Graveyard")
		"Opponent Hand":
			Selection_Source = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side_Opp + "HandScroller/" + Side_Opp + "Hand")

	# Populate the list of cards to choose from
	var Card_List = []
	for i in Selection_Source.get_children():
		Card_List.append(i)
	
	Populate_Card_Options_List(Card_List)

func Populate_Card_Options_List(Card_List):
	for i in len(Card_List):
		if Card_List[i].Frame == "Special":
			continue
		else:
			var original = Card_List[i]
			var copy = original.duplicate()
			$ScrollContainer/Effect_Target_List.add_child(copy)
			for n in original.get_property_list():
				var PropertyName = n["name"]
				var value = original.get_indexed(PropertyName)
				copy.set_indexed(PropertyName,value)
			copy.Set_Card_Variables(i, "NonTurnHand")
			copy.Set_Card_Visuals()
			copy.Update_Data()

func On_Card_Selection(card):
	Card_Selected = card

func _on_confirm_button_pressed():
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
	
	# Find index of card in current hand (Defaults to last card in hand if no card is selected)
	var Card_Index = $ScrollContainer/Effect_Target_List.get_children().find(Card_Selected)

	if Card_Index != -1:
		var Card_Node = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side_Opp + "HandScroller/" + Side_Opp + "Hand").get_child(Card_Index)

		# Move Card to proper hand
		var Source_Hand = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side_Opp + "HandScroller/" + Side_Opp + "Hand")
		var Destination_Hand = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")

		# Update Hands
		Source_Hand.remove_child(Card_Node)
		Destination_Hand.add_child(Card_Node)

	# Queue free the Card Selector scene from the scene tree
	var Card_Selector_Scene = Engine.get_main_loop().get_current_scene().get_node("Battle/CardSelector")
	Card_Selector_Scene.queue_free()
