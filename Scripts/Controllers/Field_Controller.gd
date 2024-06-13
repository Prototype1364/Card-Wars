extends Node

class_name FieldController

var Node_CardSpots = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots")

func Add_Card_Node_To_Hand(Deck_ID, InstanceCard, Deck_Reloaded = false, Base_Node = Node_CardSpots):
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var Hand = Base_Node.get_node(Deck_ID.left(1) + "HandScroller/" + Deck_ID.left(1) + "Hand")
	
	if Deck_Reloaded == false:
		if "MainDeck" in Deck_ID and GameData.Current_Step == "Draw":
			if player.Deck[-1].get_class() == "Control":
				Hand.add_child(player.Deck[-1])
			else:
				SignalBus.emit_signal("Reset_Reposition_Card_Variables")
				Hand.add_child(InstanceCard)
				Set_Focus_Neighbors("Hand", Deck_ID.left(1), Hand)
	else:
		Reparent_Nodes(InstanceCard, Hand)

func Add_Card_Node_To_Tech_Zone(Deck_ID, InstanceCard, Base_Node = Node_CardSpots):
	var TechZone = Base_Node.get_node("NonHands/" + Deck_ID.left(1) + "TechZone")
	InstanceCard.set_position(Vector2.ZERO) # Choosing to manually set position here instead of calling Reparent_Nodes() because InstanceCard has no parent (SourceNode) yet.
	TechZone.add_child(InstanceCard)
	Set_Focus_Neighbors("Field", Deck_ID.left(1), TechZone)

func Reparent_Nodes(Source_Node, Destination_Node):
	Source_Node.set_position(Vector2.ZERO)
	Source_Node.get_parent().remove_child(Source_Node)
	Destination_Node.add_child(Source_Node)
	Source_Node.set_position(Vector2.ZERO)

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

func Get_Field_Card_Data(Base_Node, Side, Zone) -> Array:
	var Zone_Count = Get_Zone_Count(Zone)
	var Field_Card_Data = []
	
	for i in range(0, Zone_Count):
		var Parent = Base_Node.get_node(Side + Zone) if Zone_Count == 1 else Base_Node.get_node(Side + Zone + str(i + 1))
		if Parent.get_child_count() > 0:
			Field_Card_Data.append(Parent.get_child(0))
	return Field_Card_Data

func Get_Zone_Count(Zone: String) -> int:
	if Zone == "Fighter":
		return 1
	elif Zone == "R" or Zone == "Backrow":
		return 3
	else:
		return 0

func Reposition_Field_Cards(Side) -> void:
	var CardSwitched # Indicates the card instance that got switched out of its spot (i.e. the one that was replaced by the CardMoved).
	var Slots_To_Avoid = [Side + "Banished", Side + "Graveyard", Side + "MedBay", Side + "Hand", Side + "TechZone"]
	
	# Ensures Cards aren't moved into/out of ineligible hand/field slots (or sides of the field)
	if (("Hand" in GameData.Chosen_Card.get_parent().name) or
		(GameData.Chosen_Card.get_parent().name in Slots_To_Avoid or GameData.CardTo.name in Slots_To_Avoid) or
		(GameData.Current_Turn == "Player" and GameData.CardTo.name.left(1) == "B") or (GameData.Current_Turn == "Enemy" and GameData.CardTo.name.left(1) == "W") or 
		(GameData.CardSwitched == Side + "Hand")):
		SignalBus.emit_signal("Reset_Reposition_Card_Variables")
		return
	
	# Ensures Cards are only repositioned into valid slots based on Card Type/Attribute, Game-related variables
	match GameData.CardTo.name:
		"WFighter", "BFighter":
			if GameData.Chosen_Card.Type not in ["Normal", "Hero"]:
				SignalBus.emit_signal("Reset_Reposition_Card_Variables")
				return
		"WR1", "WR2", "WR3", "BR1", "BR2", "BR3":
			if GameData.For_Honor_And_Glory:
				SignalBus.emit_signal("Reset_Reposition_Card_Variables")
				return
		"WEquipMagic", "WEquipTrap", "BEquipMagic", "BEquipTrap":
			if ("Magic" in GameData.CardTo.name and (GameData.Chosen_Card.Attribute != "Equip" or GameData.Chosen_Card.Type != "Magic")) or ("Trap" in GameData.CardTo.name and (GameData.Chosen_Card.Attribute != "Equip" or GameData.Chosen_Card.Type != "Trap")):
				SignalBus.emit_signal("Reset_Reposition_Card_Variables")
				return
		"WBackrow1", "WBackrow2", "WBackrow3", "BBackrow1", "BBackrow2", "BBackrow3":
			if GameData.Chosen_Card.Type not in ["Magic", "Trap"]:
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
		Set_Focus_Neighbors("Field",Side,CardSwitched)
	Set_Focus_Neighbors("Field",Side,GameData.Chosen_Card)
	
	# Resets variables to avoid game crashing if you try to switch multiple times in a single turn.
	SignalBus.emit_signal("Reset_Reposition_Card_Variables")

func Play_Card(Base_Node, Side, Net_Cost):
	var Dueler = GameData.Player if GameData.CardTo.name.left(1) == "W" else GameData.Enemy
	var Enemy = GameData.Enemy if GameData.CardTo.name.left(1) == "W" else GameData.Player
	var Reparent_Variables = [GameData.Chosen_Card.get_parent(), GameData.CardTo, GameData.Chosen_Card]
	var Equip_Slot = Base_Node.get_node(Side + "EquipMagic") if Reparent_Variables[2].Type == "Magic" else Base_Node.get_node(Side + "EquipTrap")
	var Graveyard = Base_Node.get_node(Side + "Graveyard")
	var Parent_Name = GameData.CardTo.name
	var Source_Name = GameData.Chosen_Card.get_parent().name
	
	Dueler.Summon_Crests -= Net_Cost
	
	# Reparents Previous Equip Card Node (if applicable)
	if Equip_Slot.get_child_count() > 0 and Reparent_Variables[2].Attribute == "Equip":
		Dueler.Graveyard.append(Equip_Slot.get_child(0))
		Reparent_Nodes(Equip_Slot.get_child(0), Graveyard)
	
	Reparent_Nodes(Reparent_Variables[2], Reparent_Variables[1])
	Set_Focus_Neighbors("Field",Side,Reparent_Variables[1].get_child(0))
	Set_Focus_Neighbors("Hand",Side,Base_Node.get_parent().get_node(Side + "HandScroller/" + Side + "Hand"))
	SignalBus.emit_signal("Activate_Summon_Effects", GameData.Chosen_Card)
		
	# Ensures that card summoned to Equip slot is not immediately sent to Graveyard.
	if GameData.Chosen_Card.Type == "Magic" and not ("Equip" in GameData.Chosen_Card.get_parent().name) and GameData.Chosen_Card.Is_Set == false:
		Dueler.Graveyard.append(Reparent_Variables[2])
		Reparent_Nodes(Reparent_Variables[2], Graveyard)
	
	# Updates Card Summoned This Turn Array
	GameData.Cards_Summoned_This_Turn.append(GameData.Chosen_Card)
	SignalBus.emit_signal("Card_Summoned", GameData.Chosen_Card)
	
	# Allows card effects that resolve during Summon/Set to occur (i.e. Deep Pit)
	GameData.Current_Card_Effect_Step = "Resolving"
	SignalBus.emit_signal("Resolve_Card_Effects")
	GameData.Current_Card_Effect_Step = null

	# Update Card Data
	GameData.Chosen_Card.Update_Data()

	# Append card to appropriate array when a card is played
	if "Fighter" in Parent_Name:
		Dueler.Fighter.append(GameData.Chosen_Card)
	elif "EquipMagic" in Parent_Name:
		Dueler.Equip_Magic.append(GameData.Chosen_Card)
	elif "EquipTrap" in Parent_Name:
		Dueler.Equip_Trap.append(GameData.Chosen_Card)
	elif "R1" in Parent_Name or "R2" in Parent_Name or "R3" in Parent_Name:
		Dueler.Reinforcement.append(GameData.Chosen_Card)
	elif "Backrow" in Parent_Name:
		Dueler.Backrow.append(GameData.Chosen_Card)

	# Erase card from appropriate array
	if Source_Name.left(1) == Side:
		Dueler.Hand.erase(GameData.Chosen_Card)
	elif Source_Name.left(1) != Side:
		Enemy.Hand.erase(GameData.Chosen_Card)
	
	# Resets GameData variables for next movement.
	SignalBus.emit_signal("Reset_Reposition_Card_Variables")
	
	# Updates Duelist HUD (Places at end of func so that summon effects resolve before update)
	SignalBus.emit_signal("Update_HUD_Duelist", Base_Node.get_parent().get_parent().get_parent().get_node("HUD_" + Side), Dueler)

func Activate_Set_Card(Side, Chosen_Card):
	# Replaces current Equip card with activated card & Reparents appropriate Nodes
	var Graveyard = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/NonHands/" + Side + "Graveyard")
	var EquipSlot = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/NonHands/" + Side + "Equip" + Chosen_Card.Type)
	var New_Equip_Card = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/NonHands/" + str(GameData.CardFrom) + "/" + str(GameData.CardMoved))
	
	if Chosen_Card.Attribute == "Equip":
		if EquipSlot.get_child_count() > 0:
			Reparent_Nodes(EquipSlot.get_child(0), Graveyard)
		Reparent_Nodes(New_Equip_Card, EquipSlot)
	else:
		Reparent_Nodes(Chosen_Card, Graveyard)

func Reload_Deck(MedBay):
	# Reparent Nodes from MedBay to MainDeck (Base_Node is Medbay)
	var Dueler = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var MainDeck = Node_CardSpots.get_node("NonHands/" + Side + "MainDeck")

	# Shuffle Deck
	SignalBus.emit_signal("Shuffle_Deck", Dueler)
	await Engine.get_main_loop().create_timer(0.05) # Wait for 0.05 seconds to ensure deck is shuffled before continuing (can't await SignalBus signals since this script isn't attached to a node on the node tree) (E is dubious, since what we're awaiting isn't even a timeout.)

	# Reparents all children of MedBay to MainDeck
	for i in MedBay.get_children():
		Reparent_Nodes(i, MainDeck)

	# Reorder MainDeck Children to match Deck Array order
	for i in range(MainDeck.get_child_count()):
		MainDeck.move_child(Dueler.Deck[i], i)

	# Set Card Visuals for MainDeck
	for i in range(MainDeck.get_child_count()):
		MainDeck.get_child(i).Set_Card_Visuals()

	# Resets Deck Reloaded variable
	Dueler.Deck_Reloaded = true

func Find_Open_Slot(Base_Node, Zone):
	var Zone_Count = Get_Zone_Count(Zone)
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	
	for i in range(0, Zone_Count):
		var Parent = Base_Node.get_node(Side + Zone) if Zone_Count == 1 else Base_Node.get_node(Side + Zone + str(i + 1))
		if Parent.get_child_count() == 0:
			return Parent.get_path()
	return null

#######################################
# SIGNAL FUNCTIONS
#######################################
func _on_Card_Slot_pressed(Base_Node, slot_name):
	if slot_name == "Backrow":
		slot_name = Find_Open_Slot(Base_Node, slot_name)

	if GameData.Chosen_Card != null:
		if "Hand" in GameData.Chosen_Card.get_parent().name and GameData.Current_Step == "Main" and GameData.Summon_Mode != "":
			GameData.Summon_Mode = ""
			GameData.CardTo = Base_Node.get_node(slot_name)
			SignalBus.emit_signal("Play_Card", Base_Node, GameData.Chosen_Card.get_parent().name.left(1))
		elif GameData.Current_Step == "Main":
			if GameData.Chosen_Card.get_parent().name != "":
				GameData.CardTo = Base_Node.get_node(slot_name)
				Reposition_Field_Cards(GameData.CardTo.name.left(1))
