extends Control

var Token_Path = preload("res://Scenes/SupportScenes/Token_Duelist.tscn")

func _ready():
	Update_Data(GameData.Player)
	Update_Data(GameData.Enemy)

func Update_Data(Dueler):
	var ATK_Bonus = "+" + str(Dueler.Field_ATK_Bonus) if Dueler.Field_ATK_Bonus >= 0 else "-" + str(Dueler.Field_ATK_Bonus)
	var HP_Bonus = "+" + str(Dueler.Field_Health_Bonus) if Dueler.Field_Health_Bonus >= 0 else "-" + str(Dueler.Field_Health_Bonus)
	var Discount_Normal = str(Dueler.Cost_Discount_Normal) if Dueler.Cost_Discount_Normal >= 0 else "+" + str(Dueler.Cost_Discount_Normal)
	var Discount_Hero = str(Dueler.Cost_Discount_Hero) if Dueler.Cost_Discount_Hero >= 0 else "+" + str(Dueler.Cost_Discount_Hero)
	var Discount_Magic = str(Dueler.Cost_Discount_Magic) if Dueler.Cost_Discount_Magic >= 0 else "+" + str(Dueler.Cost_Discount_Magic)
	var Discount_Trap = str(Dueler.Cost_Discount_Trap) if Dueler.Cost_Discount_Trap >= 0 else "+" + str(Dueler.Cost_Discount_Trap)
	
	$BG/LP.text = "LP: " + str(Dueler.LP)
	$BG/Crests.text = "Crests: " + str(Dueler.Summon_Crests)
	$BG/ATK_Bonus.text = "ATK Bonus: " + ATK_Bonus
	$BG/Health_Bonus.text = "HP Bonus: " + HP_Bonus
	$BG/Cost_Discount.text = "Cost Discounts: " + Discount_Normal + "/" + Discount_Hero + "/" + Discount_Magic + "/" + Discount_Trap
	
	# Add Token visuals to HUD when appropriate
	var Token_Container = $BG/TokenScrollContainer/TokenContainer
	if Token_Container.get_child_count() < Dueler.Tokens:
		for _i in range(Dueler.Tokens - Token_Container.get_child_count()):
			var InstanceToken = Token_Path.instance()
			InstanceToken.name = "Token" + str(Token_Container.get_child_count() + 1)
			Token_Container.add_child(InstanceToken)
