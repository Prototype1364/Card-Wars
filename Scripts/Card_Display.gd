extends Control

var SelectedCard

func _ready():
	# Setup Signal_Bus functionality. Note: Holder Variables (_HV) serve to eliminate Debugger warnings.
	var _HV1 = SignalBus.connect("LookAtCard", Callable(self, "LookAtCard"))
	var _HV2 = SignalBus.connect("NotLookingAtCard", Callable(self, "NotLookingAtCard"))

func LookAtCard(CardNode, FrameData, ArtData, NameData, AttackData, CostData, HealthData, AttributeData):
	SelectedCard = CardNode
	self.visible = true
	
	if SelectedCard != null:
		if FrameData != "Special": # Card is NOT Advance Tech card
			var Frame_Texture = load("res://Assets/Cards/Frame/Large_Frame_" + FrameData + ".png")
			var Cost_Texture
			if FrameData != "Tech":
				Cost_Texture = load("res://Assets/Cards/Cost/Large/Large_Cost_" + FrameData + "_" + str(CostData) + ".png")
			var Attribute_Texture
			if SelectedCard.Type == "Normal" or SelectedCard.Type == "Hero":
				Attribute_Texture = load("res://Assets/Cards/Attribute/Attribute_" + AttributeData + ".png")
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
			$NameContainer/Name.set("theme_override_colors/font_outline_color", Text_Outline_Color)
			$Description.set("theme_override_colors/font_outline_color", Text_Outline_Color)
			$Attack.set("theme_override_colors/font_outline_color", Text_Outline_Color)
			$Health.set("theme_override_colors/font_outline_color", Text_Outline_Color)
			if SelectedCard.Short_Description == null:
				$Description.text = "This card has no Short Description."
			else:
				if SelectedCard.Anchor_Text != null:
					$Description.text = "[" + SelectedCard.Anchor_Text + "] " + SelectedCard.Short_Description
				else:
					$Description.text = SelectedCard.Short_Description
			if SelectedCard.Type == "Normal" or SelectedCard.Type == "Hero":
				if GameData.FocusedCardParentName.left(1) == "W":
					$Attack.text = str(max(SelectedCard.Attack + SelectedCard.ATK_Bonus + GameData.Player.Field_ATK_Bonus, 0))
					$Health.text = str(max(SelectedCard.Health + SelectedCard.Health_Bonus + GameData.Player.Field_Health_Bonus, 0))
				else:
					$Attack.text = str(max(SelectedCard.Attack + SelectedCard.ATK_Bonus + GameData.Enemy.Field_ATK_Bonus, 0))
					$Health.text = str(max(SelectedCard.Health + SelectedCard.Health_Bonus + GameData.Enemy.Field_Health_Bonus, 0))
				$Attribute.texture = Attribute_Texture
			else:
				$Attack.text = ""
				$Health.text = ""
				$Attribute.texture = null
		else: # Card is Advance Tech card
			$Frame.texture = load("res://Assets/Cards/Frame/Large_Advance_Tech_Card.png")
			$CostContainer/Cost.texture = null
			$NameContainer/Name.text = ""
			$Description.text = ""
			$Attack.text = ""
			$Health.text = ""
			$Attribute.texture = null
		
		# ImageContainer/CardImage of BigCard scene MUST REMAIN as a TEXTURE_BUTTON node type as it allows for auto-expansion of image proportions, thus cutting Eric's card art work in half.
		$ArtContainer/Art.texture = ArtData

func NotLookingAtCard():
	self.visible = false
