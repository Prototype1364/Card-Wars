extends TextureRect

@onready var BM = get_tree().get_root().get_node("SceneHandler/Battle")
@onready var BF = get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots")

"""--------------------------------- Pre-Filled Functions ---------------------------------"""
func Check_For_Resolvable_Effects(card_to_check: Node = null):
	if card_to_check != null:
		print(card_to_check.Name)
	else:
		print("Null card")

	var Card_Is_Valid

	if card_to_check == null:
		for card in get_tree().get_nodes_in_group("Cards"):
			Card_Is_Valid = true if CardEffects.On_Field(card) && CardEffects.Resolvable_Card(card) && CardEffects.Valid_GameState(card) && CardEffects.Valid_Effect_Type(card) else false
			if Card_Is_Valid:
				Animate_Card_Effect_Availability(card)
	else:
		Card_Is_Valid = true if CardEffects.On_Field(card_to_check) && CardEffects.Resolvable_Card(card_to_check) && CardEffects.Valid_GameState(card_to_check) && CardEffects.Valid_Effect_Type(card_to_check) else false
		if Card_Is_Valid:
			Animate_Card_Effect_Availability(card_to_check)

func Animate_Card_Effect_Availability(card: Node):
	card.set_can_activate_effect()

func Remove_Card_Effect_Availability(card: Node):
	card.set_can_activate_effect()



"""--------------------------------- Unfilled Functions ---------------------------------"""
func RNGesus(lower_bound, upper_bound) -> int:
	var rng = RandomNumberGenerator.new()
	var rnd_value = rng.randi_range(lower_bound, upper_bound)
	return rnd_value

func Dice_Roll(d_type: int = 6) -> int:
	var roll_result = RNGesus(1, d_type)
	return roll_result

func Draw_Card(Turn_Player, Deck_Source = "MainDeck", Draw_At_Index = 0) -> Dictionary:
	var Side = "W" if Turn_Player.Name == "Player" else "B"

	if get_node("CardSpots/NonHands/" + Side + Deck_Source).get_child_count() >= Draw_At_Index:
		var Card_Drawn = get_node("CardSpots/NonHands/" + Side + Deck_Source).get_child(Draw_At_Index)
		var Destinations = {"Hero": get_node("CardSpots/NonHands/" + Side + "Fighter"), "Tech": get_node("CardSpots/NonHands/" + Side + "TechZone")}
		var Destination_Node = Destinations.get(Card_Drawn.Type, get_node("CardSpots/" + Side + "HandScroller/" + Side + "Hand"))
		return {'Card_Drawn': Card_Drawn, 'Destination_Node': Destination_Node}
	else:
		return {'Card_Drawn': null, 'Destination_Node': null}

func Summon_Affordable(Dueler, Net_Cost) -> bool:
	if Net_Cost <= Dueler.Summon_Crests:
		return true
	else:
		return false

func Valid_Destination(Destination, Chosen_Card) -> bool:
	var zone_mapping = {
		BM.Side + "Fighter": ["Hero"],
		BM.Side + "R1": ["Normal", "Hero"],
		BM.Side + "R2": ["Normal", "Hero"],
		BM.Side + "R3": ["Normal", "Hero"],
		BM.Side + "EquipTrap": ["Trap"],
		BM.Side + "EquipMagic": ["Magic"],
		BM.Side + "Backrow1": ["Magic", "Trap"],
		BM.Side + "Backrow2": ["Magic", "Trap"],
		BM.Side + "Backrow3": ["Magic", "Trap"],
		BM.Side + "TechZone": ["Tech"]
	}

	if Destination.name in zone_mapping and Chosen_Card.Type in zone_mapping[Destination.name]:
		return true
	else:
		return false

func Calculate_Net_Cost(player, Chosen_Card) -> int:
	const DISCOUNT_TYPES = {"Normal": "Cost_Discount_Normal", "Hero": "Cost_Discount_Hero", "Magic": "Cost_Discount_Magic", "Trap": "Cost_Discount_Trap"}
	var Discount_Used = DISCOUNT_TYPES.get(Chosen_Card.Type, 0)
	
	if Discount_Used:
		return max(0, Chosen_Card.Cost + player.get(Discount_Used)) # Adding max function to ensure that the Net Cost is never negative.
	else:
		return 0

func Valid_Card(Chosen_Card, Destination_Node) -> bool:
	# Define conditions for invalid card play
	var is_not_turn_player = (BM.Side == "W" and BM.Current_Turn == "Enemy") or (BM.Side == "B" and BM.Current_Turn == "Player")
	var is_invalid_equip_slot = Chosen_Card.Attribute != "Equip" and "Equip" in Destination_Node.name
	var is_restricted_reinforcer = Destination_Node.name in ["R1", "R2", "R3"] and BM.For_Honor_And_Glory

	# Check if any invalid condition is met
	if is_not_turn_player or is_invalid_equip_slot or is_restricted_reinforcer:
		return false
	else:
		return true

func Add_Tokens():
	var Backrow_Cards = BF.Get_Field_Card_Data(BM.Side, "Backrow")

	for card in Backrow_Cards:
		if card.Type == "Trap":
			card.set_tokens(1, "Add")

func Activate_Summon_Effects(Chosen_Card):
	# Define conditions for activating summon effects
	var Dueler = BM.Player if Chosen_Card.get_parent().name.left(1) == "W" else BM.Enemy
	var is_valid_type = Chosen_Card.Type in ["Normal", "Hero", "Tech", "Special"]
	var is_magic_not_set_or_disabled = Chosen_Card.Type == "Magic" and not Chosen_Card.Is_Set and not Dueler.Muggle_Mode
	var is_equipped_trap = Chosen_Card.Type == "Trap" and not Chosen_Card.Is_Set and Chosen_Card.Attribute == "Equip"
	var is_valid_summon_effect = is_valid_type or is_magic_not_set_or_disabled or is_equipped_trap

	# Check if any condition for activating effects is met
	if is_valid_summon_effect:
		Check_For_Resolvable_Effects(Chosen_Card)
		#Chosen_Card.Can_Activate_Effect = true
		#CardEffects.call(Chosen_Card.Anchor_Text, Chosen_Card)
		#Chosen_Card.Can_Activate_Effect = false # Reset to ensure card doesn't activate from Graveyard

func Set_Attacks_To_Launch():
	var player = BM.Player if BM.Current_Turn == "Player" else BM.Enemy
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")
	var Reinforcers = BF.Get_Field_Card_Data(BM.Side, "R")

	for card in Fighter + Reinforcers:
		if card in Fighter or (card.Attack_As_Reinforcement and card in Reinforcers):
			player.Valid_Attackers += 1

func Reset_Turn_Variables():
	BM.Player.Valid_Attackers = 0
	BM.Enemy.Valid_Attackers = 0
	BM.Cards_Summoned_This_Turn.clear()
	BM.Cards_Captured_This_Turn.clear()
	BM.Last_Equip_Card_Replaced.clear()
	BM.Turn_Counter += 1
	BM.Attacker = null
	BM.Target = null

func Reset_Attacks_Remaining():
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")
	var Reinforcers = BF.Get_Field_Card_Data(BM.Side, "R")

	for card in Fighter + Reinforcers:
		card.set_attacks_remaining(1, "Reset")

func Set_Turn_Player():
	if BM.Turn_Counter != 1: # Ensures that the program doesn't switch the Turn_Player on the first Opening Phase of the Game.
		BM.Current_Turn = "Player" if BM.Current_Turn == "Enemy" else "Enemy"

func Choose_Starting_Player():
	var random_number = 2
	#var random_number = RNGesus(1, 2)
	BM.Current_Turn = "Player" if random_number == 1 else "Enemy"
	
	# Flip field (if Black goes first)
	if random_number == 2:
		var Switch_Sides_Button = $SwitchSides
		Switch_Sides_Button.emit_signal("pressed")
		SignalBus.emit_signal("Flip_Duelist_HUDs")
		SignalBus.emit_signal("Update_HUD_GameState")

func Set_Field_Card_Effect_Status():
	var Cards_On_Field = BF.Get_Field_Card_Data(BM.Side, "Fighter") + BF.Get_Field_Card_Data(BM.Side, "R")

	if Cards_On_Field != []:
		for card in Cards_On_Field:
			card.Can_Activate_Effect = true

func Resolve_Burn_Damage():
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")
	var Reinforcers = BF.Get_Field_Card_Data(BM.Side, "R")
	var Cards_On_Field = Fighter + Reinforcers

	# Loop through all cards on appropriate side of field, apply burn damage, and capture if applicable
	for card in Cards_On_Field:
		if not card.is_immune("Burn Damage", null): # Ensures that cards immune to any kind of burn damage are not affected.
			card.set_health(card.Burn_Damage, "Remove")
			# if card.Total_Health <= 0 and not card.is_immune("Capture", null):
			# 	Capture_Card(card)

func Resolve_Battle_Damage():
	var player = BM.Player if BM.Current_Turn == "Player" else BM.Enemy
	var Reinforcers_Opp = BF.Get_Field_Card_Data(BM.Side_Opp, "R")

	if BM.Attacker != null and BM.Target != null: # Ensures no error is thrown when func is called with empty player field.
		player.Valid_Attackers -= 1
		var Targets = Reinforcers_Opp + [BM.Target] if BM.Attacker.Multi_Strike else [BM.Target]

		for _i in range(BM.Attacker.Attacks_Remaining):
			BM.Attacker.set_attacks_remaining(1, "Attack")
			for card in Targets:
				if not card.is_immune("Battle Damage", BM.Attacker):
					var Overflow_Damage = max(0, BM.Attacker.get_net_damage() - card.Total_Health)
					card.set_health(BM.Attacker.get_net_damage(), "Remove")
					CardEffects.call(card.Anchor_Text, card) # Call any effects that may trigger on damage (Defiance, Kinship, etc.)
					# if card.Total_Health <= 0 and not card.is_immune("Capture", BM.Attacker):
					# 	Capture_Card(card)
					if card.Total_Health <= 0 and BM.Attacker.Can_Deal_Overflow_Damage and Overflow_Damage > 0:
						Resolve_Overflow_Damage(BM.Attacker, BM.Target, Overflow_Damage)

func Resolve_Overflow_Damage(Attacker, Target, Overflow_Damage):
	var Cards_On_Field_Opp = BF.Get_Field_Card_Data(BM.Side_Opp, "Fighter") + BF.Get_Field_Card_Data(BM.Side_Opp, "R")
	Cards_On_Field_Opp.erase(Target)

	for card in Cards_On_Field_Opp:
		if not card.is_immune("Overflow Damage", Attacker):
			card.set_health(Overflow_Damage, "Remove")
			Overflow_Damage = max(0, Overflow_Damage - card.Total_Health)
			# if card.Total_Health <= 0 and not card.is_immune("Capture", Attacker):
			# 	Capture_Card(card)
			if Overflow_Damage == 0:
				break

func Check_For_Captures(trigger_card: Node = null): # FIXME: This func is meant to ensure that all captures (including weird ones like Morgan le Fay poison captures) are handled. Currently it's never called/connected to anything, but here as a placeholder.
	for card in get_tree().get_nodes_in_group("Cards"):
		if card.Total_Health <= 0 and not card.is_immune("Capture", trigger_card) and card.Type in ["Normal", "Hero"]:
			Capture_Card(card)

func Activate_Set_Card(Chosen_Card):
	var Dueler = BM.Player if Chosen_Card.get_parent().name.left(1) == "W" else BM.Enemy

	if (Chosen_Card.Type == "Magic" and Dueler.Muggle_Mode == false) or ((Chosen_Card.Type == "Trap" and Chosen_Card.Tokens > 0)):
		Chosen_Card.Can_Activate_Effect = true
		CardEffects.call(Chosen_Card.Anchor_Text, Chosen_Card)
		Chosen_Card.Can_Activate_Effect = false # Reset to ensure card doesn't activate from Graveyard

func Resolve_Damage(damage_type: String):
	# Resolve Damage based on damage type
	if damage_type == "Battle":
		Resolve_Battle_Damage()
	elif damage_type == "Burn":
		Resolve_Burn_Damage()

func Capture_Card(Card_Captured, Capture_Type = "Normal", Reset_Stats = true):
	var Destination_Node = Get_Destination_Node_On_Capture(Capture_Type, Card_Captured)
	var Parent_Name = Card_Captured.get_parent().name
	var Fighter_Captured = true if "Fighter" in Parent_Name else false
	
	# Capture Targeted Card, remove effects disabled by the card, and Reparent Nodes
	BM.Cards_Captured_This_Turn.append(Card_Captured)
	BF.Reparent_Nodes(Card_Captured, Destination_Node)

	# Move Equips to Graveyard when Fighter is Captured
	if Fighter_Captured:
		var Captured_Card_Side = Parent_Name.left(1)
		var Equip_Magic_Cards = BF.Get_Field_Card_Data(Captured_Card_Side, "EquipMagic")
		var Equip_Trap_Cards = BF.Get_Field_Card_Data(Captured_Card_Side, "EquipTrap")

		for card in Equip_Magic_Cards + Equip_Trap_Cards:
			BM.Cards_Captured_This_Turn.append(card)
			BF.Reparent_Nodes(card, Destination_Node)

		# Recruit new Hero if own Fighter slot is empty
		Recruit_Hero()

	# Reset Captured Card's Stats/Visuals
	if Reset_Stats:
		Card_Captured.Reset_Stats_On_Capture()
		Card_Captured.Update_Data()
	
func Get_Destination_Node_On_Capture(Capture_Type, Card_Captured) -> Node:
	var Destination_Node
	var Duelist = BM.Player if BM.Current_Turn == "Player" else BM.Enemy
	var Destination_Node_Name = Duelist.Capture_Destination
	
	if Capture_Type == "Normal":
		Destination_Node = get_node("CardSpots/NonHands/" + BM.Side + "Graveyard") if Card_Captured.Type in ["Hero", "Magic", "Trap"] else get_node("CardSpots/NonHands/" + BM.Side + Destination_Node_Name)
	else:
		Destination_Node = get_node("CardSpots/NonHands/" + BM.Side_Opp + "Graveyard") if Card_Captured.Type in ["Hero", "Magic", "Trap"] else get_node("CardSpots/NonHands/" + BM.Side_Opp + Destination_Node_Name)
	
	return Destination_Node

func Recruit_Hero(): # FIXME: Heroes are not recruited immediately after the previous hero is captured. This could lead to issues with cards that have multiple attacks per turn effects (since if the Hero is captured on the first attack, the second attack has no impact [in theory it should hit the next Hero that gets recruited]). If this is something we want to address, some small tweaks may be needed in this function as well as the Capture_Card func (and the associated BM.Target setting logic).
	# Recruit new Hero if own Fighter slot is empty
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")
	var HeroDeck = BF.Get_Field_Card_Data(BM.Side, "HeroDeck")
	var Player = BM.Player if BM.Current_Turn == "Player" else BM.Enemy

	if Fighter == [] and HeroDeck != []:
		var Drawn_Card = Draw_Card(Player, "HeroDeck")
		SignalBus.emit_signal("Reparent_Nodes", Drawn_Card['Card_Drawn'], Drawn_Card['Destination_Node'])
		Drawn_Card['Card_Drawn'].Update_Data()
		BM.Cards_Summoned_This_Turn.append(Drawn_Card['Card_Drawn'])
	
		# Ensures that Summon type effect heroes can activate their effects (Periodic effects are activated in Set_Field_Card_Effect_Status() func)
		if Drawn_Card['Card_Drawn'].Effect_Type in ["Summon"]:
			Drawn_Card['Card_Drawn'].Can_Activate_Effect = true
	elif Fighter == [] and HeroDeck == []:
		var Reinforcers = BF.Get_Field_Card_Data(BM.Side, "R")
		var Replacement_Fighter_Found = false
		for card in Reinforcers:
			if card.Type == "Hero":
				Replacement_Fighter_Found = true
				SignalBus.emit_signal("Reparent_Nodes", card, get_node("CardSpots/NonHands/" + BM.Side + "Fighter"))
				break
		if not Replacement_Fighter_Found:
			BM.Victor = BM.Enemy.Name if BM.Current_Turn == "Player" else BM.Player.Name
			SignalBus.emit_signal("Update_GameState", "Turn")

func Sacrifice_Card(Chosen_Card):
	# Reparent Nodes
	var Source_Node = Chosen_Card
	var Destination_Node = get_node("CardSpots/NonHands/" + BM.Side + "Banished")
	SignalBus.emit_signal("Reparent_Nodes", Source_Node, Destination_Node)

	# Increase Summon Power
	var summon_power_label = get_node("CardSpots/" + BM.Side + "SacrificePower")
	var summon_power = int(summon_power_label.text)
	summon_power += Chosen_Card.Cost
	summon_power_label.text = str(summon_power)

	# Update Data
	Chosen_Card.set_effects_disabled("", "Reset")
	Chosen_Card.Update_Data()

func Check_For_Deck_Out() -> bool:
	# Collect field card data
	var Player_Heroes = BF.Get_Field_Card_Data("W", "HeroDeck") + BF.Get_Field_Card_Data("W", "Fighter") + BF.Get_Field_Card_Data("W", "R")
	var Enemy_Heroes = BF.Get_Field_Card_Data("B", "HeroDeck") + BF.Get_Field_Card_Data("B", "Fighter") + BF.Get_Field_Card_Data("B", "R")

	# Check for any uncaptured heroes (if none, declare victor)
	var player_hero_found = false
	var enemy_hero_found = false
	for card in Player_Heroes:
		if card.Type == "Hero":
			player_hero_found = true
			break
	for card in Enemy_Heroes:
		if card.Type == "Hero":
			enemy_hero_found = true
			break

	if not player_hero_found:
		BM.Victor = BM.Enemy.Name
		return true
	elif not enemy_hero_found:
		BM.Victor = BM.Player.Name
		return true
	else:
		return false
	
func Exodia_Complete() -> bool:
	# Collect field card data
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")
	var Reinforcers = BF.Get_Field_Card_Data(BM.Side, "R")

	# Check if all cards in Fighter and Reinforcer slots are heroes
	var hero_count = 0
	for card in Fighter + Reinforcers:
		if card.Type != "Hero":
			return false
		else:
			hero_count += 1

	# Ensure that all 4 slots are filled with heroes
	if hero_count == 4:
		BM.Victor = BM.Player.Name if BM.Current_Turn == "Player" else BM.Enemy.Name
		return true
	else:
		return false

func Check_For_Deck_Reload():
	# Collect field card data
	var MainDeck = BF.Get_Field_Card_Data(BM.Side, "MainDeck")
	var HeroDeck = BF.Get_Field_Card_Data(BM.Side, "HeroDeck")

	if len(MainDeck) == 0:
		SignalBus.emit_signal("Reload_Deck", "MainDeck")
	if len(HeroDeck) == 0:
		SignalBus.emit_signal("Reload_Deck", "HeroDeck")

func Update_Card_Icons():
	print("Updating Card Icons...")
	for card in get_tree().get_nodes_in_group("Cards"):
		card.Update_Icons()

func Update_Card_Data():
	print("Updating Card Data...")
	for card in get_tree().get_nodes_in_group("Cards"):
		card.Update_Data()


#######################################
# SIGNAL FUNCTIONS
#######################################
func _on_Deck_Slot_pressed():
	# Get children of deck & sort by Cost (descending)
	var Deck_Children = BF.Get_Field_Card_Data(BM.Side, "HeroDeck")
	Deck_Children.sort_custom(func(a,b): return a.Cost > b.Cost)

	# Get Sacrifice Power
	var summon_power_label = get_node("CardSpots/" + BM.Side + "SacrificePower")
	var summon_power_check = int(summon_power_label.text)

	# Check for card cost == Sacrifice Power (if multiple, choose randomly between them, if none, reduce cost search by 1 and repeat)
	while summon_power_check > 0:
		var Valid_Cards = []
		for child in Deck_Children:
			if child.Cost == summon_power_check:
				Valid_Cards.append(child)
		
		# Summon card (if applicable)
		if len(Valid_Cards) == 0:
			summon_power_check -= 1
		else:
			var Hero_Card_Summoned = Valid_Cards[RNGesus(0, len(Valid_Cards) - 1)]
			var Fighter_Slot_Open = BF.Find_Open_Slot("Fighter")
			var Reinforcer_Slot_Open = BF.Find_Open_Slot("R")
			var Slot_Used = Fighter_Slot_Open if Fighter_Slot_Open != null else Reinforcer_Slot_Open

			if Slot_Used != null:
				var Destination_Node = get_tree().get_root().get_node(Slot_Used)
				SignalBus.emit_signal("Reparent_Nodes", Hero_Card_Summoned, Destination_Node)
				Hero_Card_Summoned.Update_Data()
				BM.Cards_Summoned_This_Turn.append(Hero_Card_Summoned)
				var starting_summon_power = int(summon_power_label.text)
				starting_summon_power -= Hero_Card_Summoned.Cost
				summon_power_label.text = str(starting_summon_power)
			return
