extends Control

var Current_Scene = Engine.get_main_loop().get_current_scene()
var Card_Selected = null
var Card_ID = null
var Effect_Card = null
var Card_Slot = null

func _ready():
	var _HV1 = SignalBus.connect("EffectTargetSelected", Callable(self, "On_Card_Selection"))

func Determine_Card_List(selection_type, Card_Source, slot = null, Desired_Attribute = null):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
	var Selection_Source = []

	# Set Card_Slot if not null
	if slot != null:
		Card_Slot = slot

	match selection_type:
		"Deck":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side + "MainDeck"))
		"Tech Deck":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side + "TechDeck"))
		"Field":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side + slot))
		"Field (All)":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side + "Fighter"))
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side + "R1"))
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side + "R2"))
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side + "R3"))
		"Reinforcers":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side + "R1"))
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side + "R2"))
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side + "R3"))
		"MedBay":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side + "MedBay"))
		"Graveyard":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side + "Graveyard"))
		"Hand":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand"))
		"Opponent Deck":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side_Opp + "MainDeck"))
		"Opponent Tech Deck":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side_Opp + "TechDeck"))
		"Opponent Field":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side_Opp + slot))
		"Opponent Field (All)":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side_Opp + "Fighter"))
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side_Opp + "R1"))
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side_Opp + "R2"))
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side_Opp + "R3"))
		"Opponent Reinforcers":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side_Opp + "R1"))
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side_Opp + "R2"))
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side_Opp + "R3"))
		"Opponent MedBay":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side_Opp + "MedBay"))
		"Opponent Graveyard":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side_Opp + "Graveyard"))
		"Opponent Hand":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side_Opp + "HandScroller/" + Side_Opp + "Hand"))
		"All MedBays":
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side + "MedBay"))
			Selection_Source.append(Current_Scene.get_node("Battle/Playmat/CardSpots/" + "NonHands/" + Side_Opp + "MedBay"))
		"Global Cards":
			Selection_Source.append(Current_Scene.get_node("Battle/Global_Card_Holder"))


	# Populate the list of cards to choose from
	var Card_List = []
	for source in Selection_Source:
		if source.get_child_count() > 0:
			for i in source.get_children():
				if Desired_Attribute != null:
					if i.Attribute == Desired_Attribute:
						Card_List.append(i)
				else:
					Card_List.append(i)
	
	if len(Card_List) == 0:
		return
	
	Populate_Card_Options_List(Card_List, Card_Source)

func Populate_Card_Options_List(Card_List, Card_Source):
	for i in len(Card_List):
		var original = Card_List[i]
		var copy = original.duplicate()
		$ScrollContainer/Effect_Target_List.add_child(copy)
		for n in original.get_property_list():
			var PropertyName = n["name"]
			var value = original.get_indexed(PropertyName)
			copy.set_indexed(PropertyName,value)
		copy.Set_Card_Variables(i, Card_Source)
		copy.Set_Card_Visuals()
		copy.Update_Data()
		
		# Hides Advance Tech Card from list (but still spawns it to ensure correct card is chosen from Card_Selector scene)
		if original.Frame == "Special":
			copy.visible = false
		
		# Hide Button Selector Scene if present
		if copy.has_node("ButtonSelector"):
			copy.get_node("ButtonSelector").visible = false

func On_Card_Selection(card):
	Card_Selected = card
	Card_ID = card.name

func Get_Card():
	return Card_Selected

func Set_Effect_Card(card):
	Effect_Card = card

func _on_confirm_button_pressed():
	# Emit signal to confirm card selection
	SignalBus.emit_signal("Confirm")
	
	# Queue free the Card Selector scene from the scene tree
	var Card_Selector_Scene = Engine.get_main_loop().get_current_scene().get_node("Battle/CardSelector")
	Card_Selector_Scene.queue_free()
