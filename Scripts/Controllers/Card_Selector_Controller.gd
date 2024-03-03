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
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"

	if Effect_Card.Anchor_Text == "Outlaw":
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
	elif Effect_Card.Anchor_Text == "Atrocity":
		var Card_Index = $ScrollContainer/Effect_Target_List.get_children().find(Card_Selected)

		if Card_Index != -1:
			var Card_Node = Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side_Opp + "MedBay").get_child(Card_Index)

			# Calculate Damage
			var Damage_Modifier = 0.2
			var Parent_Name = Card_Node.get_parent().name
			var Dueler = GameData.Player if Parent_Name.left(1) == "W" else GameData.Enemy
			var damage_dealt = int(floor((Effect_Card.Attack + Effect_Card.ATK_Bonus + Dueler.Field_ATK_Bonus) * Damage_Modifier))
			Card_Node.Health = max(0, Card_Node.Health - damage_dealt)
			Card_Node.Update_Data()
	elif Effect_Card.Anchor_Text == "Morale_Boost":
		var Card_Index = $ScrollContainer/Effect_Target_List.get_children().find(Card_Selected)

		if Card_Index != -1:
			var Card_Node = Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side + Card_Slot).get_child(Card_Index)

			# Add Attack if card is a Normal/Hero type
			if Card_Node.Type == "Normal" or Card_Node.Type == "Hero":
				Card_Node.Attack += 1
				Card_Node.Update_Data()
	elif Effect_Card.Anchor_Text == "Blade_Song":
		var Card_Index = $ScrollContainer/Effect_Target_List.get_children().find(Card_Selected)

		if Card_Index != -1:
			var Card_Node = Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side + Card_Slot).get_child(Card_Index)

			# Move Equip Card to proper hand
			if Card_Node.Attribute == "Equip":
				var Source_Graveyard = Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side + "Graveyard")
				var Destination_Hand = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")

				# Update Graveyard/Hand
				Source_Graveyard.remove_child(Card_Node)
				Destination_Hand.add_child(Card_Node)
	elif Effect_Card.Anchor_Text == "Miraculous_Recovery":
		var Card_Index = $ScrollContainer/Effect_Target_List.get_children().find(Card_Selected)
		
		if Card_Index != -1:
			var player_MedBay_Size = Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side + "MedBay").get_child_count()
			if Card_Index > player_MedBay_Size - 1:
				var Array_Of_Card_Names = []
				for i in Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side_Opp + "MedBay").get_children():
					Array_Of_Card_Names.append(i.name)
				var Inner_Card_Index = Array_Of_Card_Names.find(Card_ID)
				var Card_Node = Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side_Opp + "MedBay").get_child(Inner_Card_Index)
				var Source_MedBay = Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side_Opp + "MedBay")
				var Destination_Hand = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")
				var Dueler_Opp = GameData.Enemy if Side == "W" else GameData.Player
				Source_MedBay.remove_child(Card_Node)
				Destination_Hand.add_child(Card_Node)
				Dueler_Opp.MedicalBay.erase(Card_Node)
				Dueler_Opp.Hand.append(Card_Node)
			else:
				var Array_Of_Card_Names = []
				for i in Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side_Opp + "MedBay").get_children():
					Array_Of_Card_Names.append(i.name)
				var Inner_Card_Index = Array_Of_Card_Names.find(Card_ID)
				var Card_Node = Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side + "MedBay").get_child(Inner_Card_Index)
				var Source_MedBay = Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side + "MedBay")
				var Destination_Hand = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")
				var Dueler = GameData.Player if Side == "W" else GameData.Enemy
				Source_MedBay.remove_child(Card_Node)
				Destination_Hand.add_child(Card_Node)
				Dueler.MedicalBay.erase(Card_Node)
				Dueler.Hand.append(Card_Node)
	elif Effect_Card.Anchor_Text == "Resurrection":
		var Card_Index = $ScrollContainer/Effect_Target_List.get_children().find(Card_Selected)

		if Card_Index != -1:
			var Card_Node = Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side + "MedBay").get_child(Card_Index)

			# Check for open field slots
			var Fighter_Open = true if Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side + "Fighter").get_child_count() == 0 else false
			var R1_Open = true if Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side + "R1").get_child_count() == 0 else false
			var R2_Open = true if Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side + "R2").get_child_count() == 0 else false
			var R3_Open = true if Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side + "R3").get_child_count() == 0 else false

			# Set proper field slot or hand source/destination
			var Source_MedBay = Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side + "MedBay")
			var Destination_Slot = "Fighter" if Fighter_Open else "R1" if R1_Open else "R2" if R2_Open else "R3" if R3_Open else "Hand"
			var Destination_Node = null
			if Destination_Slot != "Hand":
				Destination_Node = Current_Scene.get_node("Battle/Playmat/CardSpots/NonHands/" + Side + Destination_Slot)
			else:
				Destination_Node = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")

			# Update MedBay/Hand
			Source_MedBay.remove_child(Card_Node)
			Destination_Node.add_child(Card_Node)

			# Update Dueler Arrays
			var Dueler = GameData.Player if Side == "W" else GameData.Enemy
			Dueler.MedicalBay.erase(Card_Node)
			match Destination_Slot:
				"Fighter":
					Dueler.Fighter.append(Card_Node)
				"R1", "R2", "R3":
					Dueler.Reinforcement.append(Card_Node)
				"Hand":
					Dueler.Hand.append(Card_Node)
	elif Effect_Card.Anchor_Text == "Tailor_Made":
		# Find index of card in current hand (Defaults to last card in hand if no card is selected)
		var Card_Index = $ScrollContainer/Effect_Target_List.get_children().find(Card_Selected)

		if Card_Index != -1:
			var Card_Node = Current_Scene.get_node("Battle/Global_Card_Holder").get_child(Card_Index)
			print(Card_Index)
			print(Card_Node.Name)

			# Move Card to proper hand
			var Source_Node = Engine.get_main_loop().get_current_scene().get_node("Battle/Global_Card_Holder/")
			var Destination_Hand = Current_Scene.get_node("Battle/Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")

			# Update Hands
			Source_Node.remove_child(Card_Node)
			Destination_Hand.add_child(Card_Node)
	
	# Emit signal to confirm card selection
	SignalBus.emit_signal("Confirm")
	
	# Queue free the Card Selector scene from the scene tree
	var Card_Selector_Scene = Engine.get_main_loop().get_current_scene().get_node("Battle/CardSelector")
	Card_Selector_Scene.queue_free()
