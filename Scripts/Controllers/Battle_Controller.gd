extends Node

class_name BattleController

var Card_Drawn = preload("res://Scenes/SupportScenes/SmallCard.tscn")
var Node_CardSpots = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots")
var Node_WMedBay = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/NonHands/WMedBay")
var Node_BMedBay = Engine.get_main_loop().get_current_scene().get_node("Battle/Playmat/CardSpots/NonHands/BMedBay")



"""--------------------------------- Pre-Filled Functions ---------------------------------"""
func Resolve_Card_Effects(Base_Node = Node_CardSpots):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
	var Available_Zones = Base_Node.get_node("NonHands").get_children() + Base_Node.get_node(Side + "HandScroller/").get_children() + Base_Node.get_node("NonHands").get_children() + Base_Node.get_node(Side_Opp + "HandScroller/").get_children()
	var Zones_To_Check = []
	var AnchorText
	
	# Populate Zones_To_Check Array
	for i in Available_Zones.size():
		if Available_Zones[i].name.left(1) == Side or ! Available_Zones[i].name in [Side + "Hand", "Backrow"]:
			if ! Available_Zones[i].name in ["Deck", "Banished"]:
				Zones_To_Check.append(Available_Zones[i])
	
	# Resolve Card Effects
	for zone in range(len(Zones_To_Check)): # Zone loop enables you to check all zones with just a single Item (card) loop.
		for item in range(len(Zones_To_Check[zone].get_children())):
			AnchorText = Zones_To_Check[zone].get_child(item).Anchor_Text
			if AnchorText != null:
				if Zones_To_Check[zone].get_child(item).Type != "Normal": # Eliminates the need to have blank funcs for Normal cards in Card_Effects Singleton to avoid crashing game
					var Chosen_Card = Zones_To_Check[zone].get_child(item)
					CardEffects.call(AnchorText, Chosen_Card)

func Check_For_Victor_LP(player = GameData.Player, enemy = GameData.Enemy) -> bool:
	if player.LP <= 0:
		GameData.Victor = enemy.Name
		return true
	elif enemy.LP <= 0:
		GameData.Victor = player.Name
		return true
	else:
		return false

func Check_For_Victor_Deck_Out(player = GameData.Player, enemy = GameData.Enemy) -> bool:
	if len(player.Deck) == 0:
		GameData.Victor = enemy.Name
		return true
	elif len(enemy.Deck) == 0:
		GameData.Victor = player.Name
		return true
	else:
		return false



"""--------------------------------- Unfilled Functions ---------------------------------"""
func Instantiate_Card() -> Node:
	var InstanceCard = Card_Drawn.instantiate()
	InstanceCard.name = "Card" + str(GameData.CardCounter)
	GameData.CardCounter += 1
	return InstanceCard

func Draw_Card(Turn_Player, Cards_To_Draw = 1):
	for _i in range(Cards_To_Draw):
		Turn_Player.Hand.append(Turn_Player.Deck[-1])

func Reset_Reposition_Card_Variables():
	GameData.Chosen_Card = null
	GameData.CardMoved = ""
	GameData.CardFrom = ""
	GameData.CardTo = ""
	GameData.CardSwitched = ""

func Summon_Affordable(Dueler, Net_Cost) -> bool:
	if Net_Cost <= Dueler.Summon_Crests:
		return true
	else:
		return false

func Valid_Destination(Side, Destination, Chosen_Card) -> bool:
	var Valid_Combat_Zones = [Side + "Fighter", Side + "R1", Side + "R2", Side + "R3"]
	var Valid_Backrow_Zones = [Side + "Backrow1", Side + "Backrow2", Side + "Backrow3"]
	
	if (Destination.name in Valid_Combat_Zones) and (Chosen_Card.Type in ["Normal", "Hero"]):
		return true
	elif Destination.name == Side + "EquipTrap" and (Chosen_Card.Type == "Trap"):
		return true
	elif Destination.name == Side + "EquipMagic" and (Chosen_Card.Type == "Magic"):
		return true
	elif (Destination.name in Valid_Backrow_Zones) and (Chosen_Card.Type in ["Magic", "Trap"]):
		return true
	elif Destination.name == Side + "TechZone" and Chosen_Card.Type == "Tech":
		return true
	else:
		return false

func Calculate_Net_Cost(player, Chosen_Card) -> int:
	const DISCOUNT_TYPES = {"Normal": "Cost_Discount_Normal", "Hero": "Cost_Discount_Hero", "Magic": "Cost_Discount_Magic", "Trap": "Cost_Discount_Trap"}
	var Discount_Used = DISCOUNT_TYPES.get(Chosen_Card.Type, 0)
	
	if Discount_Used:
		return Chosen_Card.Cost + player.get(Discount_Used)
	else:
		return 0

func Valid_Card(Base_Node, Side, Chosen_Card) -> bool:
	var Valid_Reinforcer_Zones = ["R1", "R2", "R3"]
	# ID Card Played
	if GameData.CardFrom == Side + "Hand":
		Chosen_Card = Base_Node.get_node(Side + "HandScroller/" + Side + "Hand/" + str(GameData.CardMoved))
	
	# Checks for the following: Card played is from Turn Player's Hand, Card is not being played in Equip slot (unless it IS an Equip card), Card is not a reinforcer being played while "For Honor And Glory" is in effect.
	if (((Side == "W" and GameData.Current_Turn == "Enemy") or (Side == "B" and GameData.Current_Turn == "Player")) or (Chosen_Card.Attribute != "Equip" and "Equip" in GameData.CardTo.name) or ((GameData.CardTo.name in Valid_Reinforcer_Zones) and GameData.For_Honor_And_Glory)):
		Reset_Reposition_Card_Variables()
		return false
	else:
		return true

func Add_Tokens(Backrow_Slots):
	if Backrow_Slots != null:
		for i in len(Backrow_Slots):
			Backrow_Slots[i].Add_Token()
			Backrow_Slots[i].Update_Data()

func Activate_Summon_Effects(Chosen_Card):
	var AnchorText = Chosen_Card.Anchor_Text
	
	if Chosen_Card.Type == "Hero" or (Chosen_Card.Type == "Magic" and Chosen_Card.Is_Set == false and GameData.Muggle_Mode == false) or (Chosen_Card.Type == "Trap" and Chosen_Card.Attribute == "Equip" and Chosen_Card.Is_Set == false):
		Chosen_Card.Effect_Active = true
		GameData.Current_Card_Effect_Step = "Activation"
		CardEffects.call(AnchorText, Chosen_Card)
		# Resets Effect_Active status to ensure card doesn't activate from Graveyard
		Chosen_Card.Effect_Active = false

func Check_For_Targets(Fighter_Opp):
	var player = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	
	if len(Fighter_Opp) == 0:
		GameData.Target = player
	
	GameData.Current_Step = "Target"
	
	if GameData.Target == player:
		Direct_Attack_Automation()

func Direct_Attack_Automation():
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	# Signal emitted twice to ensure that Damage Step is conducted following successful Target selection
	SignalBus.emit_signal("Update_GameState", "Step")
	SignalBus.emit_signal("Update_GameState", "Step")
	if player.Valid_Attackers == 0:
		# Move to End Phase (no captures will happen following direct attack)
		SignalBus.emit_signal("Update_GameState", "Phase")
		# Attempt to End Turn (works if no discards are necessary)
		SignalBus.emit_signal("Update_GameState", "Turn")
	else:
		# Move to Repeat Step to prep for next attack
		SignalBus.emit_signal("Update_GameState", "Step")

func Set_Attacks_To_Launch(Fighter, Reinforcers):
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	
	if Fighter != null:
		player.Valid_Attackers += 1
	for i in len(Reinforcers):
		if Reinforcers[i].Attack_As_Reinforcement:
			player.Valid_Attackers += 1

func Reset_Turn_Variables(PHASES, STEPS):
	GameData.Player.Valid_Attackers = 0
	GameData.Enemy.Valid_Attackers = 0
	GameData.Cards_Summoned_This_Turn.clear()
	GameData.Cards_Captured_This_Turn.clear()
	GameData.Turn_Counter += 1
	GameData.Current_Phase = PHASES[0]
	GameData.Current_Step = STEPS[0]
	GameData.Attacker = null
	GameData.Target = null

func Set_Turn_Player():
	if GameData.Turn_Counter != 1: # Ensures that the program doesn't switch the Turn_Player on the first Opening Phase of the Game.
		GameData.Current_Turn = "Player" if GameData.Current_Turn == "Enemy" else "Enemy"

func Choose_Starting_Player():
#	var random_number = Utils.RNGesus(1, 2)
	var random_number = 1
	GameData.Current_Turn = "Player" if random_number == 1 else "Enemy"
	
	# Flip field (if Black goes first)
	if random_number == 2:
		SignalBus.emit_signal("Flip_Field", $Playmat)
		SignalBus.emit_signal("Flip_Duelist_HUDs", $HUD_W, $HUD_B)
		SignalBus.emit_signal("Update_HUD_GameState", $HUD_GameState)

func Set_Hero_Card_Effect_Status():
	if GameData.Current_Turn == "Player":
		for card in GameData.Player.Frontline:
			if card.Type == "Hero":
				card.Effect_Active = true
	else:
		for card in GameData.Enemy.Frontline:
			if card.Type == "Hero":
				card.Effect_Active = true

func Activate_Set_Card(Chosen_Card):
	if (Chosen_Card.Type == "Magic" and GameData.Muggle_Mode == false) or ((Chosen_Card.Type == "Trap" and (Chosen_Card.Tokens > 0 or GameData.Auto_Spring_Traps))):
		var AnchorText = Chosen_Card.Anchor_Text
		CardEffects.call(AnchorText, Chosen_Card)

func Resolve_Battle_Damage(Reinforcers_Opp, player, enemy):
	if GameData.Attacker != null and GameData.Target != null: # Ensures no error is thrown when func is called with empty player field.
		player.Valid_Attackers -= 1
		if GameData.Target == enemy:
			for _i in range(GameData.Attacker.Attacks_Remaining):
				GameData.Attacker.Update_Attacks_Remaining("Attack")
				enemy.LP -= (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + player.Field_ATK_Bonus)
		else:
			if GameData.Target.Invincible == false:
				for _i in range(GameData.Attacker.Attacks_Remaining):
					GameData.Attacker.Update_Attacks_Remaining("Attack")
					GameData.Target.Health -= (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + player.Field_ATK_Bonus)
					GameData.Target.Update_Data()
					if GameData.Attacker.Multi_Strike:
						for i in range(len(Reinforcers_Opp)):
							Reinforcers_Opp[i].Health -= (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + player.Field_ATK_Bonus)
							Reinforcers_Opp[i].Update_Data()
							if Reinforcers_Opp[i].Health <= 0 and Reinforcers_Opp[i].Immortal == false:
								GameData.Current_Step = "Capture"
								SignalBus.emit_signal("Capture_Card", Reinforcers_Opp[i])
								GameData.Current_Step = "Damage"
			
			# Capture Step
			if GameData.Target.Health <= 0 and GameData.Target.Immortal == false:
				GameData.Current_Step = "Capture"
				SignalBus.emit_signal("Capture_Card", GameData.Target)

func Capture_Card(attacking_player, Card_Captured):
	GameData.Cards_Captured_This_Turn.append(Card_Captured)
	attacking_player.MedicalBay.append(Card_Captured)

func Get_Destination_MedBay_on_Capture(Capture_Type) -> Node:
	if Capture_Type == "Normal":
		var Destination_MedBay = Node_WMedBay if GameData.Current_Turn == "Player" else Node_BMedBay
		return Destination_MedBay
	else:
		var Destination_MedBay = Node_BMedBay if GameData.Current_Turn == "Player" else Node_WMedBay
		return Destination_MedBay
