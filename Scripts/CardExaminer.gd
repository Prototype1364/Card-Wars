extends Control

var NormalFrame = preload("res://Assets/Cards/Frame/Large_Frame_Normal.png")
var HeroFrame = preload("res://Assets/Cards/Frame/Large_Frame_Hero.png")
var MagicFrame = preload("res://Assets/Cards/Frame/Large_Frame_Magic.png")
var TrapFrame = preload("res://Assets/Cards/Frame/Large_Frame_Trap.png")
var TechFrame = preload("res://Assets/Cards/Frame/Large_Frame_Tech.png")
var AdvanceTechImage = preload("res://Assets/Cards/Frame/Large_Advance_Tech_Card.png")

var S1N = preload("res://Assets/Cards/Cost/Large/Large_Cost_Normal_1.png")
var S2N = preload("res://Assets/Cards/Cost/Large/Large_Cost_Normal_2.png")
var S3N = preload("res://Assets/Cards/Cost/Large/Large_Cost_Normal_3.png")
var S4N = preload("res://Assets/Cards/Cost/Large/Large_Cost_Normal_4.png")
var S5N = preload("res://Assets/Cards/Cost/Large/Large_Cost_Normal_5.png")
var S6N = preload("res://Assets/Cards/Cost/Large/Large_Cost_Normal_6.png")
var S1H = preload("res://Assets/Cards/Cost/Large/Large_Cost_Hero_1.png")
var S2H = preload("res://Assets/Cards/Cost/Large/Large_Cost_Hero_2.png")
var S3H = preload("res://Assets/Cards/Cost/Large/Large_Cost_Hero_3.png")
var S4H = preload("res://Assets/Cards/Cost/Large/Large_Cost_Hero_4.png")
var S5H = preload("res://Assets/Cards/Cost/Large/Large_Cost_Hero_5.png")
var S6H = preload("res://Assets/Cards/Cost/Large/Large_Cost_Hero_6.png")
var S1M = preload("res://Assets/Cards/Cost/Large/Large_Cost_Magic_1.png")
var S2M = preload("res://Assets/Cards/Cost/Large/Large_Cost_Magic_2.png")
var S3M = preload("res://Assets/Cards/Cost/Large/Large_Cost_Magic_3.png")
var S4M = preload("res://Assets/Cards/Cost/Large/Large_Cost_Magic_4.png")
var S5M = preload("res://Assets/Cards/Cost/Large/Large_Cost_Magic_5.png")
var S6M = preload("res://Assets/Cards/Cost/Large/Large_Cost_Magic_6.png")
var S1T = preload("res://Assets/Cards/Cost/Large/Large_Cost_Trap_1.png")
var S2T = preload("res://Assets/Cards/Cost/Large/Large_Cost_Trap_2.png")
var S3T = preload("res://Assets/Cards/Cost/Large/Large_Cost_Trap_3.png")
var S4T = preload("res://Assets/Cards/Cost/Large/Large_Cost_Trap_4.png")
var S5T = preload("res://Assets/Cards/Cost/Large/Large_Cost_Trap_5.png")
var S6T = preload("res://Assets/Cards/Cost/Large/Large_Cost_Trap_6.png")

var SelectedCard

# Called when the node enters the scene tree for the first time.
func _ready():
# Setup Signal_Bus functionality. Note: Holder Variables (_HV) serve to eliminate Debugger warnings.
	var _HV1 = SignalBus.connect("LookAtCard", self, "LookAtCard")
	var _HV2 = SignalBus.connect("NotLookingAtCard", self, "NotLookingAtCard")

func GetCardData():
	if GameData.FocusedCardParentName == "BHand":
		SelectedCard = self.get_parent().get_parent().get_node("BoardImage/CardSpots/BHandScroller/BHand").get_node(GameData.FocusedCardName)
	elif GameData.FocusedCardParentName == "WHand":
		SelectedCard = self.get_parent().get_parent().get_node("BoardImage/CardSpots/WHandScroller/WHand").get_node(GameData.FocusedCardName)
	else:
		SelectedCard = self.get_parent().get_parent().get_node("BoardImage/CardSpots/NonHands/" + GameData.FocusedCardParentName + "/").get_node(GameData.FocusedCardName)

func LookAtCard():
	self.GetCardData()
	self.visible = true
	if SelectedCard != null:
		if SelectedCard.get_node("Frame").texture_normal == load("res://Assets/Cards/Frame/Small_Frame_Normal.png"):
			self.get_node("Frame").texture = NormalFrame
			if SelectedCard.Cost == 1:
				self.get_node("SummonContainer/SummonCounters").texture = S1N
			elif SelectedCard.Cost == 2:
				self.get_node("SummonContainer/SummonCounters").texture = S2N
			elif SelectedCard.Cost == 3:
				self.get_node("SummonContainer/SummonCounters").texture = S3N
			elif SelectedCard.Cost == 4:
				self.get_node("SummonContainer/SummonCounters").texture = S4N
			elif SelectedCard.Cost == 5:
				self.get_node("SummonContainer/SummonCounters").texture = S5N
			elif SelectedCard.Cost == 6:
				self.get_node("SummonContainer/SummonCounters").texture = S6N
			self.get_node("Text").set("custom_colors/font_outline_modulate", Color("676767"))
			self.get_node("Damage").set("custom_colors/font_outline_modulate", Color("676767"))
			self.get_node("Health").set("custom_colors/font_outline_modulate", Color("676767"))
		elif SelectedCard.get_node("Frame").texture_normal == load("res://Assets/Cards/Frame/Small_Frame_Hero.png"):
			self.get_node("Frame").texture = HeroFrame
			if SelectedCard.Cost == 1:
				self.get_node("SummonContainer/SummonCounters").texture = S1H
			elif SelectedCard.Cost == 2:
				self.get_node("SummonContainer/SummonCounters").texture = S2H
			elif SelectedCard.Cost == 3:
				self.get_node("SummonContainer/SummonCounters").texture = S3H
			elif SelectedCard.Cost == 4:
				self.get_node("SummonContainer/SummonCounters").texture = S4H
			elif SelectedCard.Cost == 5:
				self.get_node("SummonContainer/SummonCounters").texture = S5H
			elif SelectedCard.Cost == 6:
				self.get_node("SummonContainer/SummonCounters").texture = S6H
			self.get_node("Text").set("custom_colors/font_outline_modulate", Color("cdaf2f"))
			self.get_node("Damage").set("custom_colors/font_outline_modulate", Color("cdaf2f"))
			self.get_node("Health").set("custom_colors/font_outline_modulate", Color("cdaf2f"))
		elif SelectedCard.get_node("Frame").texture_normal == load("res://Assets/Cards/Frame/Small_Frame_Magic.png"):
			self.get_node("Frame").texture = MagicFrame
			if SelectedCard.Cost == 1:
				self.get_node("SummonContainer/SummonCounters").texture = S1M
			elif SelectedCard.Cost == 2:
				self.get_node("SummonContainer/SummonCounters").texture = S2M
			elif SelectedCard.Cost == 3:
				self.get_node("SummonContainer/SummonCounters").texture = S3M
			elif SelectedCard.Cost == 4:
				self.get_node("SummonContainer/SummonCounters").texture = S4M
			elif SelectedCard.Cost == 5:
				self.get_node("SummonContainer/SummonCounters").texture = S5M
			elif SelectedCard.Cost == 6:
				self.get_node("SummonContainer/SummonCounters").texture = S6M
			self.get_node("Text").set("custom_colors/font_outline_modulate", Color("7a51a0"))
			self.get_node("Damage").set("custom_colors/font_outline_modulate", Color("7a51a0"))
			self.get_node("Health").set("custom_colors/font_outline_modulate", Color("7a51a0"))
		elif SelectedCard.get_node("Frame").texture_normal == load("res://Assets/Cards/Frame/Small_Frame_Trap.png"):
			self.get_node("Frame").texture = TrapFrame
			if SelectedCard.Cost == 1:
				self.get_node("SummonContainer/SummonCounters").texture = S1T
			elif SelectedCard.Cost == 2:
				self.get_node("SummonContainer/SummonCounters").texture = S2T
			elif SelectedCard.Cost == 3:
				self.get_node("SummonContainer/SummonCounters").texture = S3T
			elif SelectedCard.Cost == 4:
				self.get_node("SummonContainer/SummonCounters").texture = S4T
			elif SelectedCard.Cost == 5:
				self.get_node("SummonContainer/SummonCounters").texture = S5T
			elif SelectedCard.Cost == 6:
				self.get_node("SummonContainer/SummonCounters").texture = S6T
			self.get_node("Text").set("custom_colors/font_outline_modulate", Color("ff0000"))
			self.get_node("Damage").set("custom_colors/font_outline_modulate", Color("ff0000"))
			self.get_node("Health").set("custom_colors/font_outline_modulate", Color("ff0000"))
		elif SelectedCard.get_node("Frame").texture_normal == load("res://Assets/Cards/Frame/Small_Frame_Tech.png"):
			self.get_node("Frame").texture = TechFrame
			self.get_node("Text").set("custom_colors/font_outline_modulate", Color("1f8742"))
			self.get_node("Damage").set("custom_colors/font_outline_modulate", Color("1f8742"))
			self.get_node("Health").set("custom_colors/font_outline_modulate", Color("1f8742"))
		elif SelectedCard.get_node("Frame").texture_normal == load("res://Assets/Cards/Frame/Small_Advance_Tech_Card.png"):
			self.get_node("Frame").texture = AdvanceTechImage
		self.get_node("ImageContainer/CardImage").texture_normal = SelectedCard.get_node("ImageContainer/CardImage").texture
		self.get_node("Text").text = SelectedCard.Text
		self.get_node("Damage").text = SelectedCard.get_node("Damage").text
		self.get_node("Health").text = SelectedCard.get_node("Health").text
	
func NotLookingAtCard():
	self.visible = false
