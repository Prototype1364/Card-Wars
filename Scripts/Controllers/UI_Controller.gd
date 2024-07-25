extends Node

func _ready(): 
	var _HV1 = SignalBus.connect("Flip_Duelist_HUDs", Callable(self, "Flip_Duelist_HUDs"))
	var _HV2 = SignalBus.connect("Update_HUD_GameState", Callable(self, "Update_HUD_GameState"))



"""--------------------------------- Pre-Filled Functions ---------------------------------"""
func Update_HUD_GameState():
	get_node("HUD/HUD_GameState/BG/Player").text = GameData.Current_Turn
	get_node("HUD/HUD_GameState/BG/GameState").text = GameData.Current_Phase + ", " + GameData.Current_Step
	get_node("HUD/HUD_GameState/BG/Turn_Count").text = "#" + str(GameData.Turn_Counter)

func Flip_Duelist_HUDs(HUD_W = $Duelists/HUD_W, HUD_B = $Duelists/HUD_B):
	var HUD_W_Pos = HUD_W.position
	var HUD_B_Pos = HUD_B.position
	
	HUD_W.position = HUD_B_Pos
	HUD_B.position = HUD_W_Pos

func Update_Deck_Counts(_node, Deck_Source: String):
	var BM = get_tree().get_root().get_node("SceneHandler/Battle")
	var deck_node = BM.get_node("Playmat/CardSpots/NonHands/" + Deck_Source + "Deck")
	var label_node = BM.get_node("Playmat/CardSpots/" + Deck_Source + "DeckCardCount")
	label_node.text = str(len(deck_node.get_children()))



	#W_Main.text = str(GameData.Player.Deck.size())
	#W_Tech.text = str(GameData.Player.Tech_Deck.size())
	#B_Main.text = str(GameData.Enemy.Deck.size())
	#B_Tech.text = str(GameData.Enemy.Tech_Deck.size())

func _on_SwitchSides_pressed(Playmat = $"../Playmat"):
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
func Update_HUD_Duelist(Dueler, Side):
	var ATK_Bonus = "+" + str(Dueler.Field_ATK_Bonus) if Dueler.Field_ATK_Bonus >= 0 else "-" + str(Dueler.Field_ATK_Bonus)
	var HP_Bonus = "+" + str(Dueler.Field_Health_Bonus) if Dueler.Field_Health_Bonus >= 0 else "-" + str(Dueler.Field_Health_Bonus)
	var Discount_Normal = "+" + str(Dueler.Cost_Discount_Normal) if Dueler.Cost_Discount_Normal >= 0 else str(Dueler.Cost_Discount_Normal)
	var Discount_Hero = "+" + str(Dueler.Cost_Discount_Hero) if Dueler.Cost_Discount_Hero >= 0 else str(Dueler.Cost_Discount_Hero)
	var Discount_Magic = "+" + str(Dueler.Cost_Discount_Magic) if Dueler.Cost_Discount_Magic >= 0 else str(Dueler.Cost_Discount_Magic)
	var Discount_Trap = "+" + str(Dueler.Cost_Discount_Trap) if Dueler.Cost_Discount_Trap >= 0 else str(Dueler.Cost_Discount_Trap)
	
	get_node("Duelists/HUD_" + Side + "/BG/LP").text = "LP: " + str(Dueler.LP)
	get_node("Duelists/HUD_" + Side + "/BG/Crests").text = "Crests: " + str(Dueler.Summon_Crests)
	get_node("Duelists/HUD_" + Side + "/BG/ATK_Bonus").text = "ATK Bonus: " + ATK_Bonus
	get_node("Duelists/HUD_" + Side + "/BG/Health_Bonus").text = "HP Bonus: " + HP_Bonus
	get_node("Duelists/HUD_" + Side + "/BG/Cost_Discount").text = "Cost Discounts: " + Discount_Normal + "/" + Discount_Hero + "/" + Discount_Magic + "/" + Discount_Trap
	
	Update_HUD_Duelist_Token(Dueler, Side)

func Update_HUD_Duelist_Token(Dueler, Side):
	var Token_Path = preload("res://Scenes/SupportScenes/Token_Duelist.tscn")
	var Token_Container = get_node("Duelists/HUD_" + Side + "/BG/TokenScrollContainer/TokenContainer")
	
	if Token_Container.get_child_count() < Dueler.Tokens:
		for _i in range(Dueler.Tokens - Token_Container.get_child_count()):
			var InstanceToken = Token_Path.instantiate()
			InstanceToken.name = "Token" + str(Token_Container.get_child_count() + 1)
			Token_Container.add_child(InstanceToken)


func _on_b_main_deck_child_entered_tree(node):
	pass # Replace with function body.
