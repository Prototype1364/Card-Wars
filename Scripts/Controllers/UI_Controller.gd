extends Node

var SelectedCard
@onready var BM = get_tree().get_root().get_node("SceneHandler/Battle")
@onready var BigCardNode = get_parent().get_node("CardExaminer/BigCard")

func _ready():
	# Setup Signal_Bus functionality. Note: Holder Variables (_HV) serve to eliminate Debugger warnings.
	var _HV1 = SignalBus.connect("Flip_Duelist_HUDs", Callable(self, "Flip_Duelist_HUDs"))
	var _HV2 = SignalBus.connect("Update_HUD_GameState", Callable(self, "Update_HUD_GameState"))
	var _HV3 = SignalBus.connect("LookAtCard", Callable(self, "LookAtCard"))
	var _HV4 = SignalBus.connect("NotLookingAtCard", Callable(self, "NotLookingAtCard"))



"""--------------------------------- Pre-Filled Functions ---------------------------------"""
func Update_HUD_GameState():
	var Phases_Map = {BM.Phases.OPENING: "Opening Phase", BM.Phases.STANDBY: "Standby Phase", BM.Phases.MAIN: "Main Phase", BM.Phases.BATTLE: "Battle Phase", BM.Phases.END: "End Phase"}
	get_node("HUD/HUD_GameState/BG/Player").text = BM.Current_Turn
	get_node("HUD/HUD_GameState/BG/GameState").text = Phases_Map[BM.Current_Phase]
	get_node("HUD/HUD_GameState/BG/Turn_Count").text = "#" + str(BM.Turn_Counter)

func Flip_Duelist_HUDs(HUD_W = $Duelists/HUD_W, HUD_B = $Duelists/HUD_B):
	var HUD_W_Pos = HUD_W.position
	var HUD_B_Pos = HUD_B.position
	
	HUD_W.position = HUD_B_Pos
	HUD_B.position = HUD_W_Pos

func Update_Deck_Counts(_node, Deck_Source: String):
	var deck_node = BM.get_node("Playmat/CardSpots/NonHands/" + Deck_Source + "Deck")
	var label_node = BM.get_node("Playmat/CardSpots/" + Deck_Source + "DeckCardCount")
	label_node.text = str(len(deck_node.get_children()) - 1)

func _on_SwitchSides_pressed(Playmat = $"../Playmat"):
	var BoardImage = preload("res://Assets/Playmat/BoardImage.png")
	var BoardImageReverse = preload("res://Assets/Playmat/BoardImageReverse.png")

	Playmat.flip_v = not Playmat.flip_v
	Playmat.texture = BoardImage if not Playmat.flip_v else BoardImageReverse
	Playmat.get_node("CardSpots").rotation += deg_to_rad(180)



"""--------------------------------- Unfilled Functions ---------------------------------"""
func Update_HUD_Duelist(Dueler, Side):
	get_node("Duelists/HUD_" + Side + "/BG/LP").text = "LP: " + str(Dueler.LP)
	get_node("Duelists/HUD_" + Side + "/BG/Crests").text = "Crests: " + str(Dueler.Summon_Crests)
	get_node("Duelists/HUD_" + Side + "/BG/ATK_Bonus").text = "ATK Bonus: " + str(Dueler.Field_ATK_Bonus)
	get_node("Duelists/HUD_" + Side + "/BG/Health_Bonus").text = "HP Bonus: " + str(Dueler.Field_Health_Bonus)
	get_node("Duelists/HUD_" + Side + "/BG/Cost_Discount").text = "Cost Discounts: " + str(Dueler.Cost_Discount_Normal) + "/" + str(Dueler.Cost_Discount_Hero) + "/" + str(Dueler.Cost_Discount_Magic) + "/" + str(Dueler.Cost_Discount_Trap)
	
	Update_HUD_Duelist_Token(Dueler, Side)

func Update_HUD_Duelist_Token(Dueler, Side):
	var Token_Path = preload("res://Scenes/SupportScenes/Token_Duelist.tscn")
	var Token_Container = get_node("Duelists/HUD_" + Side + "/BG/TokenScrollContainer/TokenContainer")
	
	for _i in range(Dueler.Tokens - Token_Container.get_child_count()):
		var InstanceToken = Token_Path.instantiate()
		InstanceToken.name = "Token" + str(Token_Container.get_child_count() + 1)
		Token_Container.add_child(InstanceToken)



"""--------------------------------- Card Display Functions ---------------------------------"""
func LookAtCard(CardNode, TypeData, ArtData, NameData, CostTexture, AttributeData):
	SelectedCard = CardNode
	BigCardNode.visible = true
	
	if SelectedCard != null:
		if TypeData != "Special": # Card is NOT Advance Tech card
			const TEXT_OUTLINE_NODE_NAMES = ["NameContainer/Name", "Description", "Attack", "Health"]
			const TEXT_OUTLINE_COLOR_DICT_MAP = {"Normal": "676767", "Hero": "cdaf2f", "Magic": "7a51a0", "Trap": "ff0000", "Tech": "1f8742", "Status": "000000", "Equip": "9e4400"}
			const TEXT_COLOR_DICT_MAP = {"Normal": "000000", "Hero": "000000", "Magic": "000000", "Trap": "000000", "Tech": "000000", "Status": "ffffff", "Equip": "000000"}
			var Text_Outline_Color = Color(TEXT_OUTLINE_COLOR_DICT_MAP[TypeData])
			var Text_Color = Color(TEXT_COLOR_DICT_MAP[TypeData])
			
			BigCardNode.get_node("Frame").texture = load("res://Assets/Cards/Frame/Large_Frame_" + TypeData + ".png")
			BigCardNode.get_node("ArtContainer/Art").texture = load(ArtData) # ImageContainer/CardImage of BigCard scene MUST REMAIN as a TEXTURE_BUTTON node type as it allows for auto-expansion of image proportions, thus cutting Eric's card art work in half.
			BigCardNode.get_node("CostContainer/Cost").texture = CostTexture
			BigCardNode.get_node("NameContainer/Name").text = NameData
			BigCardNode.get_node("Description").text = "[" + SelectedCard.Anchor_Text + "] " + SelectedCard.Short_Description if SelectedCard.Anchor_Text != null and SelectedCard.Short_Description != null else "This card has no Short Description." if SelectedCard.Short_Description == null else SelectedCard.Short_Description
			BigCardNode.get_node("Attack").text = str(max(SelectedCard.Total_Attack, 0)) if SelectedCard.Type in ["Normal", "Hero"] else ""
			BigCardNode.get_node("Health").text = str(max(SelectedCard.Total_Health, 0)) if SelectedCard.Type in ["Normal", "Hero"] else ""
			BigCardNode.get_node("Attribute").texture = load("res://Assets/Cards/Attribute/Attribute_" + AttributeData + ".png") if SelectedCard.Type in ["Normal", "Hero"] else null
			for node in TEXT_OUTLINE_NODE_NAMES:
				BigCardNode.get_node(node).set("theme_override_colors/font_outline_color", Text_Outline_Color)
				if node != "Health":
					BigCardNode.get_node(node).set("theme_override_colors/font_color", Text_Color)
		else: # Card is Advance Tech card
			const ADVANCE_TECH_TEXTURES = {"Frame": "res://Assets/Cards/Frame/Large_Advance_Tech_Card.png", "ArtContainer/Art": null, "CostContainer/Cost": null, "NameContainer/Name": "", "Description": "", "Attack": "", "Health": "", "Attribute": null}
			
			for key in ADVANCE_TECH_TEXTURES.keys():
				if key in ["Frame", "ArtContainer/Art", "CostContainer/Cost", "Attribute"]:
					BigCardNode.get_node(key).texture = load(ADVANCE_TECH_TEXTURES[key]) if ADVANCE_TECH_TEXTURES[key] != null else null
				else:
					BigCardNode.get_node(key).text = ADVANCE_TECH_TEXTURES[key]
		
func NotLookingAtCard():
	BigCardNode.visible = false
