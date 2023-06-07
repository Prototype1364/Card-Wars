extends Node

class_name UIController

var Node_Playmat = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat")
var Node_HUD_GameState = Engine.get_main_loop().get_current_scene().get_node("Battle/HUD_GameState")
var Node_HUD_W = Engine.get_main_loop().get_current_scene().get_node("Battle/HUD_W")
var Node_HUD_B = Engine.get_main_loop().get_current_scene().get_node("Battle/HUD_B")
var Node_Deck_Count_WMain = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/WMainDeckCardCount")
var Node_Deck_Count_WTech = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/WTechDeckCardCount")
var Node_Deck_Count_BMain = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/BMainDeckCardCount")
var Node_Deck_Count_BTech = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/BTechDeckCardCount")

func _ready(): 
	var _HV1 = SignalBus.connect("Flip_Field", Callable(self, "_on_SwitchSides_pressed"))
	var _HV2 = SignalBus.connect("Flip_Duelist_HUDs", Callable(self, "Flip_Duelist_HUDs"))
	var _HV3 = SignalBus.connect("Update_HUD_GameState", Callable(self, "Update_HUD_GameState"))
	
	Update_HUD_GameState()
	Update_HUD_Duelist(get_node("/root/SceneHandler/Battle/HUD_W"), GameData.Player)
	Update_HUD_Duelist(get_node("/root/SceneHandler/Battle/HUD_B"), GameData.Enemy)



"""--------------------------------- Pre-Filled Functions ---------------------------------"""
func Update_HUD_GameState(Node_To_Update = Node_HUD_GameState):
	Node_To_Update.get_node("BG/Player").text = GameData.Current_Turn
	Node_To_Update.get_node("BG/GameState").text = GameData.Current_Phase + ", " + GameData.Current_Step
	Node_To_Update.get_node("BG/Turn_Count").text = "#" + str(GameData.Turn_Counter)

func Flip_Duelist_HUDs(HUD_W = Node_HUD_W, HUD_B = Node_HUD_B):
	var HUD_W_Pos = HUD_W.position
	var HUD_B_Pos = HUD_B.position
	
	HUD_W.position = HUD_B_Pos
	HUD_B.position = HUD_W_Pos

func Update_Deck_Counts(W_Main = Node_Deck_Count_WMain, W_Tech = Node_Deck_Count_WTech, B_Main = Node_Deck_Count_BMain, B_Tech = Node_Deck_Count_BTech):
	W_Main.text = str(GameData.Player.Deck.size())
	W_Tech.text = str(GameData.Player.Tech_Deck.size())
	B_Main.text = str(GameData.Enemy.Deck.size())
	B_Tech.text = str(GameData.Enemy.Tech_Deck.size())

func _on_SwitchSides_pressed(Playmat = Node_Playmat):
	var BoardImage = preload("res://Assets/Playmat/BoardImage.png")
	var BoardImageReverse = preload("res://Assets/Playmat/BoardImageReverse.png")
	
	if Playmat.flip_v == true:
			Playmat.flip_v = false
			Playmat.texture = BoardImage
	else: 
		Playmat.flip_v = true
		Playmat.texture = BoardImageReverse
	
	Playmat.get_node("CardSpots").rotation += deg_to_rad(180)



"""--------------------------------- Unfilled Functions ---------------------------------"""
func Update_HUD_Duelist(Node_To_Update, Dueler):
	var ATK_Bonus = "+" + str(Dueler.Field_ATK_Bonus) if Dueler.Field_ATK_Bonus >= 0 else "-" + str(Dueler.Field_ATK_Bonus)
	var HP_Bonus = "+" + str(Dueler.Field_Health_Bonus) if Dueler.Field_Health_Bonus >= 0 else "-" + str(Dueler.Field_Health_Bonus)
	var Discount_Normal = "+" + str(Dueler.Cost_Discount_Normal) if Dueler.Cost_Discount_Normal >= 0 else str(Dueler.Cost_Discount_Normal)
	var Discount_Hero = "+" + str(Dueler.Cost_Discount_Hero) if Dueler.Cost_Discount_Hero >= 0 else str(Dueler.Cost_Discount_Hero)
	var Discount_Magic = "+" + str(Dueler.Cost_Discount_Magic) if Dueler.Cost_Discount_Magic >= 0 else str(Dueler.Cost_Discount_Magic)
	var Discount_Trap = "+" + str(Dueler.Cost_Discount_Trap) if Dueler.Cost_Discount_Trap >= 0 else str(Dueler.Cost_Discount_Trap)
	
	Node_To_Update.get_node("BG/LP").text = "LP: " + str(Dueler.LP)
	Node_To_Update.get_node("BG/Crests").text = "Crests: " + str(Dueler.Summon_Crests)
	Node_To_Update.get_node("BG/ATK_Bonus").text = "ATK Bonus: " + ATK_Bonus
	Node_To_Update.get_node("BG/Health_Bonus").text = "HP Bonus: " + HP_Bonus
	Node_To_Update.get_node("BG/Cost_Discount").text = "Cost Discounts: " + Discount_Normal + "/" + Discount_Hero + "/" + Discount_Magic + "/" + Discount_Trap
	
	Update_HUD_Duelist_Token(Node_To_Update, Dueler)

func Update_HUD_Duelist_Token(Node_To_Update, Dueler):
	var Token_Path = preload("res://Scenes/SupportScenes/Token_Duelist.tscn")
	var Token_Container = Node_To_Update.get_node("BG/TokenScrollContainer/TokenContainer")
	
	if Token_Container.get_child_count() < Dueler.Tokens:
		for _i in range(Dueler.Tokens - Token_Container.get_child_count()):
			var InstanceToken = Token_Path.instantiate()
			InstanceToken.name = "Token" + str(Token_Container.get_child_count() + 1)
			Token_Container.add_child(InstanceToken)
