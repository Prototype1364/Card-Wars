extends Node

@onready var BM = get_tree().get_root().get_node("SceneHandler/Battle")
@onready var BC = get_tree().get_root().get_node("SceneHandler/Battle/Playmat")

func Reparent_Nodes(Source_Node, Destination_Node):
	Source_Node.set_position(Vector2.ZERO)
	Source_Node.get_parent().remove_child(Source_Node)
	Destination_Node.add_child(Source_Node)
	Source_Node.set_position(Vector2.ZERO)
	Source_Node.get_node("SmallCard").set_position(Vector2.ZERO)

func Set_Focus_Neighbors(Focus_To_Set, Side, Node_To_Set_For):
	if Focus_To_Set == "Hand":
		var Hand_Node = Node_To_Set_For
		var Hand = Hand_Node.get_children()
		for i in range(len(Hand)):
			var Current_Node = Hand_Node.get_node(str(Hand[i].name))
			var Left_Neighbor = Hand[(i - 1 + len(Hand)) % len(Hand)].get_path()
			var Right_Neighbor = Hand[(i + 1) % len(Hand)].get_path()
			for focus_property in ["focus_neighbor_left", "focus_previous"]:
				Current_Node.set(focus_property, Left_Neighbor)
			for focus_property in ["focus_neighbor_right", "focus_next"]:
				Current_Node.set(focus_property, Right_Neighbor)
		
		# Changes bottom focus of MainDeck to first card in Hand.
		if len(Hand) > 0:
			get_node("NonHands/" + Side + "MainDeck").focus_neighbor_bottom = Hand.front().get_path()
		
	elif Focus_To_Set == "Field":
		var Parent = Node_To_Set_For.get_parent()
		for focus_property in ["focus_neighbor_left", "focus_neighbor_right", "focus_neighbor_top", "focus_neighbor_bottom", "focus_previous", "focus_next"]:
			Node_To_Set_For.set(focus_property, Parent.get(focus_property))

func Get_Field_Card_Data(Side, Zone) -> Array:
	var Zone_Count = Get_Zone_Count(Zone)
	var Field_Card_Data = []
	var Zone_Exclusions = ["MainDeck", "HeroDeck", "TechDeck", "MedBay", "TechZone", "Banished", "Graveyard"]

	if Zone == "Hand":
		for child in get_node(Side + "HandScroller/" + Side + "Hand").get_children():
			Field_Card_Data.append(child)
	elif Zone == "Global_Card_Holder":
		for child in BM.get_node("Global_Card_Holder").get_children():
			Field_Card_Data.append(child)
	elif Zone not in Zone_Exclusions:
		for i in range(0, Zone_Count):
			var Parent = get_node("NonHands/" + Side + Zone) if Zone_Count == 1 else get_node("NonHands/" + Side + Zone + str(i + 1))
			if Parent.get_child_count() > 0:
				Field_Card_Data.append(Parent.get_child(0))
	else:
		for child in get_node("NonHands/" + Side + Zone).get_children():
			Field_Card_Data.append(child)
	
	return Field_Card_Data

func Get_Zone_Count(Zone: String) -> int:
	if Zone in ["Fighter", "EquipMagic", "EquipTrap"]:
		return 1
	elif Zone in ["R", "Backrow"]:
		return 3
	else:
		return 0

func Reposition_Field_Cards(card) -> void:
	var Side = card.get_parent().name.left(1)
	var Side_Opp = "B" if Side == "W" else "W"
	var card_list = "Reinforcers" if card.Type == "Normal" else "Field (All)"
	var desired_types = ["Hero"] if card.Type == "Hero" else ["Normal", "Hero"]
	var Chosen_Card_Node = await CardEffects.Get_Card_Selected(card, card_list, Side, Side_Opp, null, [], desired_types, [], card) # FIXME (NOTE): This function should technically exist in the BC, not the CardEffects script. Update its location and all references in the CardEffects script (and here) appropriately.
	var Destination_Node = Chosen_Card_Node.get_parent()
	
	Reparent_Nodes(Chosen_Card_Node, card.get_parent())
	Reparent_Nodes(card, Destination_Node)
	Set_Focus_Neighbors("Field", Chosen_Card_Node.get_parent().name.left(1), Chosen_Card_Node)
	Set_Focus_Neighbors("Field", card.get_parent().name.left(1), card)

func Play_Card(Side, Net_Cost, Summon_Mode, Destination_Node, Chosen_Card):
	var Dueler = BM.Player if Destination_Node.name.left(1) == "W" else BM.Enemy
	var Equip_Slot = get_node("NonHands/" + Side + "EquipMagic") if Chosen_Card.Type == "Magic" else get_node("NonHands/" + Side + "EquipTrap")
	var Graveyard = get_node("NonHands/" + Side + "Graveyard")
	
	# Deducts Net Cost from Dueler's Summon Crests
	Dueler.set_summon_crests(Net_Cost, "Remove")
	
	# Reparents played card (and any previous equip cards, if applicable) and resolves any summon/card effects
	if Equip_Slot.get_child_count() > 0 and Chosen_Card.Attribute == "Equip" and "Backrow" not in Destination_Node.name:
		GameData.Last_Equip_Card_Replaced.append(Equip_Slot.get_child(0))
		Reparent_Nodes(Equip_Slot.get_child(0), Graveyard)
	Reparent_Nodes(Chosen_Card, Destination_Node)
	Set_Focus_Neighbors("Field", Side, Destination_Node.get_child(0))
	Set_Focus_Neighbors("Hand", Side, get_node(Side + "HandScroller/" + Side + "Hand"))
	if "Backrow" in Destination_Node.name and Summon_Mode == "Set":
		Chosen_Card.set_is_set("Set")
	SignalBus.emit_signal("Activate_Summon_Effects", Chosen_Card)
		
	# Ensures that a card summoned to Equip slot is not immediately sent to Graveyard.
	if Chosen_Card.Type == "Magic" and not ("Equip" in Chosen_Card.get_parent().name) and Chosen_Card.Is_Set == false:
		Reparent_Nodes(Chosen_Card, Graveyard)
	
	# Updates Card Summoned This Turn Array, Resolves Card Effects that occur during Summon/Set (i.e. Deep Pit), Resets Reposition Variables, & Updates Duelist HUD
	GameData.Cards_Summoned_This_Turn.append(Chosen_Card)	
	#SignalBus.emit_signal("Resolve_Card_Effects")
	SignalBus.emit_signal("Check_For_Resolvable_Effects", Chosen_Card)
	SignalBus.emit_signal("Update_HUD_Duelist", get_parent().get_parent().get_node("UI/Duelists/HUD_" + Side), Dueler)

func Activate_Set_Card(Side, Chosen_Card):
	# Replaces current Equip card with activated card & Reparents appropriate Nodes
	var Graveyard = get_node("NonHands/" + Side + "Graveyard")
	var EquipSlot = get_node("NonHands/" + Side + "Equip" + Chosen_Card.Type)
	
	if Chosen_Card.Attribute == "Equip":
		if EquipSlot.get_child_count() > 0:
			GameData.Last_Equip_Card_Replaced.append(EquipSlot.get_child(0))
			Reparent_Nodes(EquipSlot.get_child(0), Graveyard)
			BC.Activate_Set_Card(EquipSlot.get_child(0)) # Ensures that any effects that trigger upon being sent to the Graveyard are resolved (i.e. Last Stand).
		Reparent_Nodes(Chosen_Card, EquipSlot)
	else:
		Reparent_Nodes(Chosen_Card, Graveyard)

func Reload_Deck(Deck_To_Reload):
	# Reparent Nodes from MedBay to appropriate Deck
	var Dueler = BM.Player if GameData.Current_Turn == "Player" else BM.Enemy
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Deck = get_node("NonHands/" + Side + Deck_To_Reload)
	var MedBay = get_node("NonHands/" + Side + "MedBay")

	# Reparents all children of MedBay to Deck
	for card in MedBay.get_children():
		if card.Type == "Hero" and Deck_To_Reload == "HeroDeck":
			Reparent_Nodes(card, Deck)
		elif card.Type != "Hero" and Deck_To_Reload == "MainDeck":
			Reparent_Nodes(card, Deck)

	# Set Card Visuals for both Decks
	for card in range(Deck.get_child_count()):
		Deck.get_child(card).Update_Data()

	# Shuffle the Deck
	SignalBus.emit_signal("Shuffle_Deck", Dueler, Deck_To_Reload)

func Find_Open_Slot(Zone: String, Default_Side = null):
	var Side = Default_Side if Default_Side != null else ("W" if GameData.Current_Turn == "Player" else "B")
	var Zone_Count = Get_Zone_Count(Zone)

	for i in range(0, Zone_Count):
		var Parent = get_node("NonHands/" + Side + Zone) if Zone_Count == 1 else get_node("NonHands/" + Side + Zone + str(i + 1))
		var Clean_Parent_Name = Get_Clean_Slot_Name(Parent.name)
		if Parent.get_child_count() == 0 or Clean_Parent_Name in ["EquipMagic", "EquipTrap"]:
			return Parent.get_path()
	return null

func Get_Clean_Slot_Name(Slot_Name):
	if Slot_Name != "Global_Card_Holder":
		return Slot_Name.right(-1).left(len(Slot_Name.right(-1)) - 1) if Slot_Name.right(1).is_valid_int() else Slot_Name.right(-1)
	else:
		return Slot_Name
