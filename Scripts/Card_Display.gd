extends Control

var SelectedCard

func _ready():
	# Setup Signal_Bus functionality. Note: Holder Variables (_HV) serve to eliminate Debugger warnings.
	var _HV1 = SignalBus.connect("LookAtCard", self, "LookAtCard")
	var _HV2 = SignalBus.connect("NotLookingAtCard", self, "NotLookingAtCard")

func GetCardData():
	if GameData.FocusedCardParentName == "BHand":
		SelectedCard = self.get_parent().get_parent().get_node("Playmat/CardSpots/BHandScroller/BHand").get_node(GameData.FocusedCardName)
	elif GameData.FocusedCardParentName == "WHand":
		SelectedCard = self.get_parent().get_parent().get_node("Playmat/CardSpots/WHandScroller/WHand").get_node(GameData.FocusedCardName)
	else:
		SelectedCard = self.get_parent().get_parent().get_node("Playmat/CardSpots/NonHands/" + GameData.FocusedCardParentName).get_node(GameData.FocusedCardName)

func LookAtCard(FrameData, ArtData, NameData, AttackData, CostData, HealthData):
	self.GetCardData()
	self.visible = true
	
	if SelectedCard != null:
		if FrameData != "Special": # Card is NOT Advance Tech card
			var Frame_Texture = load("res://Assets/Cards/Frame/Large_Frame_" + FrameData + ".png")
			var Cost_Texture = load("res://Assets/Cards/Cost/Large/Large_Cost_" + FrameData + "_" + str(CostData) + ".png")
			var Text_Outline_Color
			if FrameData == "Normal":
				Text_Outline_Color = Color("676767")
			elif FrameData == "Hero":
				Text_Outline_Color = Color("cdaf2f")
			elif FrameData == "Magic":
				Text_Outline_Color = Color("7a51a0")
			elif FrameData == "Trap":
				Text_Outline_Color = Color("ff0000")
			elif FrameData == "Tech":
				Text_Outline_Color = Color("1f8742")
			
			$Frame.texture = Frame_Texture
			$CostContainer/Cost.texture = Cost_Texture
			$NameContainer/Name.text = NameData
			$NameContainer/Name.set("custom_colors/font_outline_modulate", Text_Outline_Color)
			$Description.set("custom_colors/font_outline_modulate", Text_Outline_Color)
			$Attack.set("custom_colors/font_outline_modulate", Text_Outline_Color)
			$Health.set("custom_colors/font_outline_modulate", Text_Outline_Color)
			if SelectedCard.Short_Description == null:
				$Description.text = "This card has no Short Description."
			else:
				$Description.text = SelectedCard.Short_Description
			if SelectedCard.Type == "Normal" or SelectedCard.Type == "Hero":
				$Attack.text = str(max(AttackData, 0))
				$Health.text = str(max(HealthData, 0))
			else:
				$Attack.text = ""
				$Health.text = ""
		else: # Card is Advance Tech card
			$Frame.texture = load("res://Assets/Cards/Frame/Large_Advance_Tech_Card.png")
			$CostContainer/Cost.texture = null
			$NameContainer/Name.text = ""
			$Description.text = ""
			$Attack.text = ""
			$Health.text = ""
		
		# ImageContainer/CardImage of BigCard scene MUST REMAIN as a TEXTURE_BUTTON node type as it allows for auto-expansion of image proportions, thus cutting Eric's card art work in half.
		$ArtContainer/Art.texture = ArtData

func NotLookingAtCard():
	self.visible = false
