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
			var Left_Neighbor = Hand[(i - 1 + len(Hand)) % len(Hand)]
			var Right_Neighbor = Hand[(i + 1) % len(Hand)]
			Current_Node.focus_neighbor_left = Left_Neighbor.get_path()
			Current_Node.focus_previous = Left_Neighbor.get_path()
			Current_Node.focus_neighbor_right = Right_Neighbor.get_path()
			Current_Node.focus_next = Right_Neighbor.get_path()
		
		# Changes bottom focus of MainDeck to first card in Hand.
		if len(Hand) > 0:
			Node_To_Set_For.get_parent().get_parent().get_node("NonHands/" + Side + "MainDeck").focus_neighbor_bottom = Hand.front().get_path()
		
	elif Focus_To_Set == "Field":
		var Parent = Node_To_Set_For.get_parent()
		Node_To_Set_For.focus_neighbor_left = Parent.focus_neighbor_left
		Node_To_Set_For.focus_neighbor_right = Parent.focus_neighbor_right
		Node_To_Set_For.focus_neighbor_top = Parent.focus_neighbor_top
		Node_To_Set_For.focus_neighbor_bottom = Parent.focus_neighbor_bottom
		Node_To_Set_For.focus_previous = Parent.focus_previous
		Node_To_Set_For.focus_next = Parent.focus_next

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

func Reposition_Field_Cards(Side) -> void:
	var CardSwitched # Indicates the card instance that got switched out of its spot (i.e. the one that was replaced by the CardMoved).
	var Slots_To_Avoid = [Side + "Banished", Side + "Graveyard", Side + "MedBay", Side + "Hand", Side + "TechZone"]
	var Chosen_Card_Parent_Name = GameData.Chosen_Card.get_parent().name
	var Clean_CardTo_Name = Get_Clean_Slot_Name(GameData.CardTo.name)
	var failed_slot_validation_check = {
		"involves_ineligible_slot": Chosen_Card_Parent_Name in Slots_To_Avoid or GameData.CardTo.name in Slots_To_Avoid or "Hand" in Chosen_Card_Parent_Name or GameData.CardSwitched == Side + "Hand",
		"is_wrong_turn": (GameData.Current_Turn == "Player" and GameData.CardTo.name.left(1) == "B") or (GameData.Current_Turn == "Enemy" and GameData.CardTo.name.left(1) == "W")}
	var failed_type_and_situation_check = {
		"Fighter": GameData.Chosen_Card.Type != "Hero",
		"R": GameData.For_Honor_And_Glory,
		"EquipMagic": ("Magic" in GameData.CardTo.name and (GameData.Chosen_Card.Attribute != "Equip" or GameData.Chosen_Card.Type != "Magic")),
		"EquipTrap": ("Trap" in GameData.CardTo.name and (GameData.Chosen_Card.Attribute != "Equip" or GameData.Chosen_Card.Type != "Trap")),
		"Backrow": GameData.Chosen_Card.Type not in ["Magic", "Trap"]}
	
	# Ensures Cards aren't moved into/out of ineligible hand/field slots (or sides of the field) & into valid slots based on Card Type/Attribute, Game-related variables
	if true in failed_slot_validation_check.values() or failed_type_and_situation_check[Clean_CardTo_Name]:
		SignalBus.emit_signal("Reset_Reposition_Card_Variables")
		return
	
	# Ensures that card switching behavior only happens when switching (as opposed to merely moving) cards.
	if GameData.CardSwitched != "":
		CardSwitched = GameData.CardTo.get_node(str(GameData.CardSwitched))
	
	if GameData.Chosen_Card.name != GameData.CardSwitched: # Ensures that you aren't switching a card with itself (same instance of scene). If this isn't here weird errors get thrown, particularly in CardExaminer scene/script.
		if CardSwitched != null: # Ensures switching only happens when performing a valid switch.
			Reparent_Nodes(CardSwitched, GameData.Chosen_Card.get_parent())
		Reparent_Nodes(GameData.Chosen_Card, GameData.CardTo)
	
	# Set Focus Neighbour values for repositioned card(s).
	if GameData.CardSwitched != "":
		Set_Focus_Neighbors("Field", Side, CardSwitched)
	Set_Focus_Neighbors("Field", Side, GameData.Chosen_Card)
	
	# Resets variables to avoid game crashing if you try to switch multiple times in a single turn.
	SignalBus.emit_signal("Reset_Reposition_Card_Variables")

func Play_Card(Side, Net_Cost):
	var Dueler = BM.Player if GameData.CardTo.name.left(1) == "W" else BM.Enemy
	var Equip_Slot = get_node("NonHands/" + Side + "EquipMagic") if GameData.Chosen_Card.Type == "Magic" else get_node("NonHands/" + Side + "EquipTrap")
	var Graveyard = get_node("NonHands/" + Side + "Graveyard")
	
	# Deducts Net Cost from Dueler's Summon Crests
	Dueler.set_summon_crests(Net_Cost, "Remove")
	
	# Reparents played card (and any previous equip cards, if applicable) and resolves any summon/card effects
	if Equip_Slot.get_child_count() > 0 and GameData.Chosen_Card.Attribute == "Equip" and "Backrow" not in GameData.CardTo.name:
		GameData.Last_Equip_Card_Replaced.append(Equip_Slot.get_child(0))
		Reparent_Nodes(Equip_Slot.get_child(0), Graveyard)
	Reparent_Nodes(GameData.Chosen_Card, GameData.CardTo)
	Set_Focus_Neighbors("Field", Side, GameData.CardTo.get_child(0))
	Set_Focus_Neighbors("Hand", Side, get_node(Side + "HandScroller/" + Side + "Hand"))
	SignalBus.emit_signal("Activate_Summon_Effects", GameData.Chosen_Card)
		
	# Ensures that a card summoned to Equip slot is not immediately sent to Graveyard.
	if GameData.Chosen_Card.Type == "Magic" and not ("Equip" in GameData.Chosen_Card.get_parent().name) and GameData.Chosen_Card.Is_Set == false:
		Reparent_Nodes(GameData.Chosen_Card, Graveyard)
	
	# Updates Card Summoned This Turn Array, Resolves Card Effects that occur during Summon/Set (i.e. Deep Pit), Updates Card Data, Resets Reposition Variables, & Updates Duelist HUD
	GameData.Cards_Summoned_This_Turn.append(GameData.Chosen_Card)	
	SignalBus.emit_signal("Resolve_Card_Effects")
	GameData.Chosen_Card.Update_Data()
	SignalBus.emit_signal("Reset_Reposition_Card_Variables")	
	SignalBus.emit_signal("Update_HUD_Duelist", get_parent().get_parent().get_node("UI/Duelists/HUD_" + Side), Dueler)

func Activate_Set_Card(Side, Chosen_Card):
	# Replaces current Equip card with activated card & Reparents appropriate Nodes
	var Graveyard = get_node("NonHands/" + Side + "Graveyard")
	var EquipSlot = get_node("NonHands/" + Side + "Equip" + Chosen_Card.Type)
	var New_Equip_Card = get_node("NonHands/" + str(GameData.CardFrom) + "/" + str(GameData.CardMoved))
	
	if Chosen_Card.Attribute == "Equip":
		if EquipSlot.get_child_count() > 0:
			GameData.Last_Equip_Card_Replaced.append(EquipSlot.get_child(0))
			Reparent_Nodes(EquipSlot.get_child(0), Graveyard)
			BC.Activate_Set_Card(EquipSlot.get_child(0)) # Ensures that any effects that trigger upon being sent to the Graveyard are resolved (i.e. Last Stand).
		Reparent_Nodes(New_Equip_Card, EquipSlot)
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

#######################################
# SIGNAL FUNCTIONS
#######################################
func _on_Card_Slot_pressed(slot_name):
	var converted_slot_name = Get_Clean_Slot_Name(slot_name)
	var Destination_Node = Find_Open_Slot(converted_slot_name)

	if GameData.Chosen_Card != null and Destination_Node != null:
		if "Hand" in GameData.Chosen_Card.get_parent().name and GameData.Current_Step == "Main" and GameData.Summon_Mode != "":
			GameData.Summon_Mode = ""
			GameData.CardTo = get_node(Destination_Node)
			SignalBus.emit_signal("Play_Card", GameData.Chosen_Card.get_parent().name.left(1))
		elif GameData.Current_Step == "Main":
			if GameData.Chosen_Card.get_parent().name != "":
				GameData.CardTo = get_node(Destination_Node)
				Reposition_Field_Cards(GameData.CardTo.name.left(1))
