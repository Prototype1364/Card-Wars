extends Sprite

var BoardImage = preload("res://Assets/Playmat/BoardImage.png")
var BoardImageReverse = preload("res://Assets/Playmat/BoardImageReverse.png")

var WhiteLifePoints
var BlackLifePoints

var DrawnCard = preload("res://Scenes/SupportScenes/SmallCard.tscn")

func _ready():
	# Setup Signal_Bus functionality. Note: Holder Variables (_HV) serve to eliminate Debugger warnings.
	var _HV1 = SignalBus.connect("MoveInProgress", self, "MoveInProgress")
	var _HV2 = SignalBus.connect("SwitchInProgress", self, "SwitchInProgress")

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
	self.get_node("CardSpots").rect_rotation += 180
	

func MoveInProgress():
	var MoveFrom
	var MoveTo
	var CardMoved
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
	CardMoved.rect_position.x = 0
	CardMoved.rect_position.y = 0
	MoveFrom.remove_child(CardMoved)
	MoveTo.add_child(CardMoved)
	GameData.CardMoved = ""
	GameData.CardFrom = ""
	GameData.CardTo = ""

func SwitchInProgress():
	var MoveFrom
	var MoveTo
	var CardMoved
	var CardSwitched
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
	if not GameData.CardMoved == GameData.CardSwitched:
		CardMoved.rect_position.x = 0
		CardMoved.rect_position.y = 0
		CardSwitched.rect_position.x = 0
		CardSwitched.rect_position.y = 0
		MoveFrom.remove_child(CardMoved)
		MoveTo.remove_child(CardSwitched)
		MoveFrom.add_child(CardSwitched)
		MoveTo.add_child(CardMoved)
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
	GameData.CardMoved = ""
	GameData.CardFrom = ""
	GameData.CardTo = ""
	GameData.CardSwitched = ""
	var WTech = self.get_node("CardSpots/NonHands/WTech")
	var InstanceCard = DrawnCard.instance()
	InstanceCard.name = "Card " + str(GameData.CardCounter)
	GameData.CardCounter += 1
	WTech.add_child(InstanceCard)

func _on_WMedBay_pressed():
	if GameData.CardFrom != "":
		GameData.CardTo = "WMedBay"
		self.MoveToSpot()

func _on_WMainDeck_pressed():
	GameData.CardMoved = ""
	GameData.CardFrom = ""
	GameData.CardTo = ""
	GameData.CardSwitched = ""
	var WHand = self.get_node("CardSpots/WHandScroller/WHand")
	var InstanceCard = DrawnCard.instance()
	InstanceCard.name = "Card " + str(GameData.CardCounter)
	GameData.CardCounter += 1
	WHand.add_child(InstanceCard)

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
	var InstanceCard = DrawnCard.instance()
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
	var InstanceCard = DrawnCard.instance()
	InstanceCard.name = "Card " + str(GameData.CardCounter)
	GameData.CardCounter += 1
	BHand.add_child(InstanceCard)

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
