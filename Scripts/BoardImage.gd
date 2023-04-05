extends Sprite2D

var BoardImage = preload("res://Assets/Playmat/BoardImage.png")
var BoardImageReverse = preload("res://Assets/Playmat/BoardImageReverse.png")

var WhiteLifePoints
var BlackLifePoints

var DrawnCard = preload("res://Scenes/SupportScenes/SmallCard.tscn")

func _ready():
	# Setup Signal_Bus functionality. Note: Holder Variables (_HV) serve to eliminate Debugger warnings.
	var _HV1 = SignalBus.connect("MoveInProgress", Callable(self, "MoveInProgress"))
	var _HV2 = SignalBus.connect("SwitchInProgress", Callable(self, "SwitchInProgress"))

func _on_VScrollBar_value_changed(value):
	self.position.y = 0 - value

func _on_SwitchSides_pressed():
	if self.flip_v == true:
		self.flip_v = false
	else: 
		self.flip_v = true
	if self.texture == BoardImage:
		self.texture = BoardImageReverse
	else:
		self.texture = BoardImage
	self.get_node("CardSpots").rotation += 180
	

func MoveInProgress():
	var MoveFrom # Grabs the parent of the selected scene instance.
	var MoveTo # Reparents the selected scene instance only if said parent has no children (i.e. cannot multistack in Fighter slot).
	var CardMoved # From GameData singleton, indicates the specific instance of the SmallCard scene that has been selected.
	if GameData.CardFrom == "BHand":
		MoveFrom = self.get_node("CardSpots/BHandScroller/BHand")
	elif GameData.CardFrom == "WHand":
		MoveFrom = self.get_node("CardSpots/WHandScroller/WHand")
	elif GameData.CardFrom == "WBanished" or GameData.CardFrom == "WGraveyard" or GameData.CardFrom == "BBanished" or GameData.CardFrom == "BGraveyard":
		return
	else:
		MoveFrom = self.get_node("CardSpots/NonHands/" + GameData.CardFrom)
	if GameData.CardTo == "BHand":
		MoveTo = self.get_node("CardSpots/BHandScroller/BHand")
	elif GameData.CardTo == "WHand":
		MoveTo = self.get_node("CardSpots/WHandScroller/WHand")
	else:
		MoveTo = self.get_node("CardSpots/NonHands/" + GameData.CardTo)
	CardMoved = MoveFrom.get_node(GameData.CardMoved)
	# Fixes bug regarding auto-updating of rect_pos of selected scene when moving from slot to slot.
	CardMoved.position.x = 0
	CardMoved.position.y = 0
	
	# Updates children for parents in From & To locations.
	MoveFrom.remove_child(CardMoved)
	MoveTo.add_child(CardMoved)
	
	# Matches focuses of child to new parent.
	var Moved = MoveTo.get_node(GameData.CardMoved)
	Moved.focus_neighbor_left = Moved.get_parent().focus_neighbor_left
	Moved.focus_neighbor_top = Moved.get_parent().focus_neighbor_top
	Moved.focus_neighbor_right = Moved.get_parent().focus_neighbor_right
	Moved.focus_neighbor_bottom = Moved.get_parent().focus_neighbor_bottom
	Moved.focus_next = Moved.get_parent().focus_next
	Moved.focus_previous = Moved.get_parent().focus_previous
	
	# Resets GameData variables for next movement.
	GameData.CardMoved = ""
	GameData.CardFrom = ""
	GameData.CardTo = ""

func SwitchInProgress(): # Basically the same as the MoveInProgress func, except it allows you to Reposition cards already slotted on the field.
	var MoveFrom
	var MoveTo
	var CardMoved
	var CardSwitched 
	var MoveWithoutSwitching = true
	if GameData.CardFrom == "WBanished" or GameData.CardFrom == "WGraveyard" or GameData.CardFrom == "BBanished" or GameData.CardFrom == "BGraveyard" or GameData.CardTo == "WBanished" or GameData.CardTo == "WGraveyard" or GameData.CardTo == "BBanished" or GameData.CardTo == "BGraveyard": # W/B MedicalBay should also be in this chain.
		MoveWithoutSwitching = false
	if GameData.CardFrom == "BHand":
		MoveFrom = self.get_node("CardSpots/BHandScroller/BHand")
	elif GameData.CardFrom == "WHand":
		MoveFrom = self.get_node("CardSpots/WHandScroller/WHand")
	else:
		MoveFrom = self.get_node("CardSpots/NonHands/" + GameData.CardFrom)
	if GameData.CardTo == "BHand":
		MoveTo = self.get_node("CardSpots/BHandScroller/BHand")
	elif GameData.CardTo == "WHand":
		MoveTo = self.get_node("CardSpots/WHandScroller/WHand")
	else:
		MoveTo = self.get_node("CardSpots/NonHands/" + GameData.CardTo)
	CardMoved = MoveFrom.get_node(GameData.CardMoved)
	if GameData.CardSwitched == "BHand" or GameData.CardSwitched == "WHand":
		return
	CardSwitched = MoveTo.get_node(GameData.CardSwitched)
	if not GameData.CardMoved == GameData.CardSwitched: # Ensures that you aren't switching a card with itself (same instance of scene). If this isn't here weird errors get thrown, particularly in CardExaminer scene/script.
		CardMoved.position.x = 0
		CardMoved.position.y = 0
		CardSwitched.position.x = 0
		CardSwitched.position.y = 0
		MoveFrom.remove_child(CardMoved)
		if MoveWithoutSwitching == true: # If FALSE, indicates that the zone targeted is meant for multistacking, thus no card switching occurs.
			MoveTo.remove_child(CardSwitched)
			MoveFrom.add_child(CardSwitched)
		MoveTo.add_child(CardMoved)
	var Moved = MoveTo.get_node(GameData.CardMoved)
	Moved.focus_neighbor_left = Moved.get_parent().focus_neighbor_left
	Moved.focus_neighbor_top = Moved.get_parent().focus_neighbor_top
	Moved.focus_neighbor_right = Moved.get_parent().focus_neighbor_right
	Moved.focus_neighbor_bottom = Moved.get_parent().focus_neighbor_bottom
	Moved.focus_next = Moved.get_parent().focus_next
	Moved.focus_previous = Moved.get_parent().focus_previous
	Moved = MoveFrom.get_node(GameData.CardSwitched)
	Moved.focus_neighbor_left = Moved.get_parent().focus_neighbor_left
	Moved.focus_neighbor_top = Moved.get_parent().focus_neighbor_top
	Moved.focus_neighbor_right = Moved.get_parent().focus_neighbor_right
	Moved.focus_neighbor_bottom = Moved.get_parent().focus_neighbor_bottom
	Moved.focus_next = Moved.get_parent().focus_next
	Moved.focus_previous = Moved.get_parent().focus_previous
	GameData.CardMoved = ""
	GameData.CardFrom = ""
	GameData.CardTo = ""
	GameData.CardSwitched = ""

func _on_WAttacker_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "WAttacker"
		self.MoveToSpot()

func _on_WEquip1_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "WEquip1"
		self.MoveToSpot()

func _on_WEquip2_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "WEquip2"
		self.MoveToSpot()

func _on_WR1_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "WR1"
		self.MoveToSpot()

func _on_WR2_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "WR2"
		self.MoveToSpot()

func _on_WR3_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "WR3"
		self.MoveToSpot()

func _on_WTrap1_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "WTrap1"
		self.MoveToSpot()

func _on_WTrap2_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "WTrap2"
		self.MoveToSpot()

func _on_WTrap3_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "WTrap3"
		self.MoveToSpot()

func _on_WTech_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "WTech"
		self.MoveToSpot()

func _on_WTechDeck_pressed():
	# Not sure this part needs to be here... func just adds a tech card from tech deck to tech zone.
	GameData.CardMoved = ""
	GameData.CardFrom = ""
	GameData.CardTo = ""
	GameData.CardSwitched = ""
	var WTech = self.get_node("CardSpots/NonHands/WTech")
	var InstanceCard = DrawnCard.instantiate()
	InstanceCard.name = "Card " + str(GameData.CardCounter)
	GameData.CardCounter += 1
	WTech.add_child(InstanceCard)

func _on_WMedBay_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "WMedBay"
		self.MoveToSpot()

func _on_WMainDeck_pressed():
	# Still not sure this part needs to be here... func just adds card to hand, while also updating focus data for all cards in hand.
	GameData.CardMoved = ""
	GameData.CardFrom = ""
	GameData.CardTo = ""
	GameData.CardSwitched = ""
	
	# Doesn't currently account for focus setting on empty hand (including at start of duel).
	var WHand = self.get_node("CardSpots/WHandScroller/WHand")
	var InstanceCard = DrawnCard.instantiate()
	InstanceCard.name = "Card " + str(GameData.CardCounter)
	GameData.CardCounter += 1
	WHand.add_child(InstanceCard)
	var PreviousCard = "Empty"
	var WhiteHand = WHand.get_children()
	for i in WhiteHand:
		if not str(PreviousCard) == "Empty":
			WHand.get_node(i.name).focus_neighbor_left = PreviousCard.get_path()
			WHand.get_node(i.name).focus_previous = PreviousCard.get_path()
		else:
			var LastCard = WhiteHand.back()
			WHand.get_node(i.name).focus_neighbor_left = LastCard.get_path()
			WHand.get_node(i.name).focus_previous = LastCard.get_path()
		PreviousCard = i
	var NextCard = "Empty"
	WhiteHand.invert()
	for i in WhiteHand:
		if not str(NextCard) == "Empty":
			WHand.get_node(i.name).focus_neighbor_right = NextCard.get_path()
			WHand.get_node(i.name).focus_next = NextCard.get_path()
		else:
			var LastCard = WhiteHand.back()
			WHand.get_node(i.name).focus_neighbor_left = LastCard.get_path()
			WHand.get_node(i.name).focus_previous = LastCard.get_path()
		NextCard = i
	WhiteHand.invert()
	# Changes bottom focus of MainDeck to first card in Hand.
	self.get_node("CardSpots/NonHands/WMainDeck").focus_neighbor_bottom = WhiteHand.front().get_path()

func _on_WBanished_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "WBanished"
		self.MoveToSpot()

func _on_WGraveyard_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "WGraveyard"
		self.MoveToSpot()

func _on_BAttacker_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "BAttacker"
		self.MoveToSpot()

func _on_BEquip1_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "BEquip1"
		self.MoveToSpot()

func _on_BEquip2_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "BEquip2"
		self.MoveToSpot()

func _on_BR1_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "BR1"
		self.MoveToSpot()

func _on_BR2_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "BR2"
		self.MoveToSpot()

func _on_BR3_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "BR3"
		self.MoveToSpot()

func _on_BTrap1_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "BTrap1"
		self.MoveToSpot()

func _on_BTrap2_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "BTrap2"
		self.MoveToSpot()

func _on_BTrap3_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "BTrap3"
		self.MoveToSpot()

func _on_BTech_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "BTech"
		self.MoveToSpot()

func _on_BTechDeck_pressed():
	GameData.CardMoved = ""
	GameData.CardFrom = ""
	GameData.CardTo = ""
	GameData.CardSwitched = ""
	var BTech = self.get_node("CardSpots/NonHands/BTech")
	var InstanceCard = DrawnCard.instantiate()
	InstanceCard.name = "Card " + str(GameData.CardCounter)
	GameData.CardCounter += 1
	BTech.add_child(InstanceCard)

func _on_BMedBay_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "BMedBay"
		self.MoveToSpot()

func _on_BMainDeck_pressed():
	GameData.CardMoved = ""
	GameData.CardFrom = ""
	GameData.CardTo = ""
	GameData.CardSwitched = ""
	var BHand = self.get_node("CardSpots/BHandScroller/BHand")
	var InstanceCard = DrawnCard.instantiate()
	InstanceCard.name = "Card " + str(GameData.CardCounter)
	GameData.CardCounter += 1
	BHand.add_child(InstanceCard)
	var PreviousCard = "Empty"
	var BlackHand = BHand.get_children()
	for i in BlackHand:
		if not str(PreviousCard) == "Empty":
			BHand.get_node(i.name).focus_neighbor_left = PreviousCard.get_path()
			BHand.get_node(i.name).focus_previous = PreviousCard.get_path()
		else:
			var LastCard = BlackHand.back()
			BHand.get_node(i.name).focus_neighbor_left = LastCard.get_path()
			BHand.get_node(i.name).focus_previous = LastCard.get_path()
		PreviousCard = i
	var NextCard = "Empty"
	BlackHand.invert()
	for i in BlackHand:
		if not str(NextCard) == "Empty":
			BHand.get_node(i.name).focus_neighbor_right = NextCard.get_path()
			BHand.get_node(i.name).focus_next = NextCard.get_path()
		else:
			var LastCard = BlackHand.back()
			BHand.get_node(i.name).focus_neighbor_left = LastCard.get_path()
			BHand.get_node(i.name).focus_previous = LastCard.get_path()
		NextCard = i
	BlackHand.invert()
	self.get_node("CardSpots/NonHands/BMainDeck").focus_neighbor_bottom = BlackHand.front().get_path()

func _on_BBanished_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "BBanished"
		self.MoveToSpot()

func _on_BGraveyard_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "BGraveyard"
		self.MoveToSpot()

func MoveToSpot():
	SignalBus.emit_signal("MoveInProgress")
