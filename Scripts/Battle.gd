extends Control

var BoardImage = preload("res://Assets/Playmat/BoardImage.png")
var BoardImageReverse = preload("res://Assets/Playmat/BoardImageReverse.png")
var Card_Drawn = preload("res://Scenes/SupportScenes/SmallCard.tscn")

func _ready():
	# Setup Signal_Bus functionality. Note: Holder Variables (_HV) serve to eliminate Debugger warnings.
	var _HV1 = SignalBus.connect("MoveInProgress", self, "MoveInProgress")
	var _HV2 = SignalBus.connect("SwitchInProgress", self, "Reposition_Cards")
	set_focus_mode(true)

func Reposition_Cards(Side_To_Set_For):
	var MoveFrom # Grabs the parent of the selected scene instance.
	var MoveTo # Reparents the selected scene instance only if said parent has no children (i.e. cannot multistack in Fighter slot).
	var CardMoved # From GameData singleton, indicates the specific instance of the SmallCard scene that has been selected.
	var CardSwitched # Indicates the card instance that got switched out of its spot (i.e. the one that was replaced by the CardMoved).
	var MoveWithoutSwitching = true
	
	# Ensures that cards are not switched out of the MedBay, Graveyard, or Banished piles.
	if ("Banished" in GameData.CardTo or "Graveyard" in GameData.CardTo or "MedBay" in GameData.CardTo) or ("Banished" in GameData.CardFrom or "Graveyard" in GameData.CardFrom or "MedBay" in GameData.CardFrom):
		if "Banished" in GameData.CardFrom or "Graveyard" in GameData.CardFrom or "MedBay" in GameData.CardFrom:
			Reset_Reposition_Card_Variables()
			return
		else:
			MoveWithoutSwitching = false
	# Sets MoveFrom/To variable values for repositioning.
	if GameData.CardFrom == Side_To_Set_For + "Hand":
		MoveFrom = self.get_node("Playmat/CardSpots/" + Side_To_Set_For + "HandScroller/" + Side_To_Set_For + "Hand")
	else:
		MoveFrom = self.get_node("Playmat/CardSpots/NonHands/" + GameData.CardFrom)
	if GameData.CardTo == Side_To_Set_For + "Hand":
		MoveTo = self.get_node("Playmat/CardSpots/" + Side_To_Set_For + "HandScroller/" + Side_To_Set_For + "Hand")
	else:
		MoveTo = self.get_node("Playmat/CardSpots/NonHands/" + GameData.CardTo)
	CardMoved = MoveFrom.get_node(GameData.CardMoved)
	
	# Ensures cards are not switched around from within the Hand.
	if GameData.CardSwitched == Side_To_Set_For + "Hand":
		return
	# Ensures that card switching behavior only happens when switching (as opposed to merely moving) cards.
	if GameData.CardSwitched != "":
		CardSwitched = MoveTo.get_node(GameData.CardSwitched)
	
	if GameData.CardMoved != GameData.CardSwitched: # Ensures that you aren't switching a card with itself (same instance of scene). If this isn't here weird errors get thrown, particularly in CardExaminer scene/script.
		# Fixes bug regarding auto-updating of rect_pos of selected scene when moving from slot to slot.
		CardMoved.rect_position.x = 0
		CardMoved.rect_position.y = 0
		if CardSwitched != null: # Ensures that card switching behavior only happens when switching (as opposed to merely moving) cards.
			CardSwitched.rect_position.x = 0
			CardSwitched.rect_position.y = 0
		MoveFrom.remove_child(CardMoved)
		if MoveWithoutSwitching == true and CardSwitched != null: # Ensures switching only happens when performing a valid switch.
			MoveTo.remove_child(CardSwitched)
			MoveFrom.add_child(CardSwitched)
		MoveTo.add_child(CardMoved)
	
	# Set Focus Neighbour values for repositioned card(s).
	var Moved = MoveTo.get_node(GameData.CardMoved)
	Set_Focus_Neighbors("Field",Side_To_Set_For,Moved)
	if GameData.CardSwitched != "":
		Moved = MoveFrom.get_node(GameData.CardSwitched)
		Set_Focus_Neighbors("Field",Side_To_Set_For,Moved)
	
	# Resets variables to avoid game crashing if you try to switch multiple times in a single turn.
	Reset_Reposition_Card_Variables()

func Reset_Reposition_Card_Variables():
	GameData.CardMoved = ""
	GameData.CardFrom = ""
	GameData.CardTo = ""
	GameData.CardSwitched = ""

func Set_Focus_Neighbors(Focus_To_Set, Side_To_Set_For, Node_To_Set_For):
	if Focus_To_Set == "Hand":
		var Hand_Node = get_node("Playmat/CardSpots/" + Side_To_Set_For + "HandScroller/" + Side_To_Set_For + "Hand")
		var Hand = Hand_Node.get_children()
		
		for i in len(Hand):
			if i == 0 and i < len(Hand) - 1:
				Hand_Node.get_node(Hand[i].name).focus_neighbour_left = Hand[-1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_previous = Hand[-1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_neighbour_right = Hand[i + 1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_next = Hand[i + 1].get_path()
			elif i + 1 >= len(Hand):
				Hand_Node.get_node(Hand[i].name).focus_neighbour_left = Hand[i - 1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_previous = Hand[i - 1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_neighbour_right = Hand[0].get_path()
				Hand_Node.get_node(Hand[i].name).focus_next = Hand[0].get_path()
			elif i > 0:
				Hand_Node.get_node(Hand[i].name).focus_neighbour_left = Hand[i - 1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_previous = Hand[i - 1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_neighbour_right = Hand[i + 1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_next = Hand[i + 1].get_path()
		
		# Changes bottom focus of MainDeck to first card in Hand.
		self.get_node("Playmat/CardSpots/NonHands/" + Side_To_Set_For + "MainDeck").focus_neighbour_bottom = Hand.front().get_path()
	elif Focus_To_Set == "Field":
		Node_To_Set_For.focus_neighbour_left = Node_To_Set_For.get_parent().focus_neighbour_left
		Node_To_Set_For.focus_neighbour_right = Node_To_Set_For.get_parent().focus_neighbour_right
		Node_To_Set_For.focus_neighbour_top = Node_To_Set_For.get_parent().focus_neighbour_top
		Node_To_Set_For.focus_neighbour_bottom = Node_To_Set_For.get_parent().focus_neighbour_bottom
		Node_To_Set_For.focus_previous = Node_To_Set_For.get_parent().focus_previous
		Node_To_Set_For.focus_next = Node_To_Set_For.get_parent().focus_next


func _on_VScrollBar_value_changed(value):
	$Playmat.rect_position.y = 0 - value

func _on_SwitchSides_pressed():
	if $Playmat.flip_v == true:
		$Playmat.flip_v = false
		$Playmat.texture = BoardImage
	else: 
		$Playmat.flip_v = true
		$Playmat.texture = BoardImageReverse
	
	$Playmat.get_node("CardSpots").rect_rotation += 180

func _on_Card_Slot_pressed(slot_name):
	if "MainDeck" in slot_name:
		Reset_Reposition_Card_Variables()
		var Hand = self.get_node("Playmat/CardSpots/" + slot_name.left(1) + "HandScroller/" + slot_name.left(1) + "Hand")
		var InstanceCard = Card_Drawn.instance()
		InstanceCard.name = "Card" + str(GameData.CardCounter)
		GameData.CardCounter += 1
		Hand.add_child(InstanceCard)
		Set_Focus_Neighbors("Hand", slot_name.left(1), "")
	elif "TechDeck" in slot_name:
		Reset_Reposition_Card_Variables()
		var TechZone = self.get_node("Playmat/CardSpots/NonHands/" + slot_name.left(5) + "Zone")
		var InstanceCard = Card_Drawn.instance()
		InstanceCard.name = "Card" + str(GameData.CardCounter)
		GameData.CardCounter += 1
		TechZone.add_child(InstanceCard)
	else:
		if GameData.CardFrom != "":
			GameData.CardTo = slot_name
			SignalBus.emit_signal("SwitchInProgress", GameData.CardTo.left(1))
