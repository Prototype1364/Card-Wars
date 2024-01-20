extends Node

func _ready():
	pass

"""--------------------------------- General Functions ---------------------------------"""

func On_Field(card) -> bool:
	var Parent_Name = card.get_parent().name
	var Valid_Slots = ["WFighter", "WR1", "WR2", "WR3", "BFighter", "BR1", "BR2", "BR3"]
	
	if Valid_Slots.has(Parent_Name):
		return true
	else:
		return false

func Resolvable_Card(card) -> bool:
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Parent_Name = card.get_parent().name.left(1)
	
	if card.Resolve_Side == "Both" or (card.Resolve_Side == "Self" and Side == Parent_Name) or (card.Resolve_Side == "Opponent" and Side != Parent_Name):
		return true
	else:
		return false

func Valid_GameState(card) -> bool:
	if (GameData.Current_Phase == card.Resolve_Phase and GameData.Current_Step == card.Resolve_Step) or card.Resolve_Step == "Any":
		return true
	else:
		return false

func Valid_Effect_Type(card) -> bool:
	if card.Anchor_Text not in GameData.Disabled_Effects:
		return true
	else:
		return false

func Get_Field_Card_Data(Zone):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Side_Opponent = "B" if Side == "W" else "W"
	var Fighter
	var Reinforcers = []
	var Backrow_Cards = []
	
	if Zone == "Fighter":
		var Fighter_Path = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side + "Fighter")
		if Fighter_Path.get_child_count() > 0:
			Fighter = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side + "Fighter").get_child(0)
			return Fighter
	elif Zone == "Fighter Opponent":
		var Fighter_Path = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Opponent + "Fighter")
		if Fighter_Path.get_child_count() > 0:
			Fighter = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Opponent + "Fighter").get_child(0)
			return Fighter
	elif Zone == "Reinforcers":
		for i in range(0, 3):
			var Reinforcer_Path = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side + "R" + str(i + 1))
			if Reinforcer_Path.get_child_count() > 0:
				Reinforcers.append(Reinforcer_Path.get_child(0))
		return Reinforcers
	elif Zone == "Reinforcers Opponent":
		for i in range(0, 3):
			var Reinforcer_Path_Opponent = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Opponent + "R" + str(i + 1))
			if Reinforcer_Path_Opponent.get_child_count() > 0:
				Reinforcers.append(Reinforcer_Path_Opponent.get_child(0))
		return Reinforcers
	elif Zone == "Traps":
		for i in range(0, 3):
			var Backrow_Path = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side + "Backrow" + str(i + 1))
			if Backrow_Path.get_child_count() > 0:
				var Card_To_Check = Backrow_Path.get_child(0)
				if Card_To_Check.Type == "Trap":
					Backrow_Cards.append(Backrow_Path.get_child(0))
		return Backrow_Cards
	elif Zone == "Traps Opponent":
		for i in range(0, 3):
			var Backrow_Path_Opp = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Opponent + "Backrow" + str(i + 1))
			if Backrow_Path_Opp.get_child_count() > 0:
				var Card_To_Check = Backrow_Path_Opp.get_child(0)
				if Card_To_Check.Type == "Trap":
					Backrow_Cards.append(Backrow_Path_Opp.get_child(0))
		return Backrow_Cards

func Dice_Roll(d_type: int = 6):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var roll_result = rng.randi_range(1, d_type)
	return roll_result

func Flip_Coin():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var flip_result = rng.randi_range(1,2)
	return flip_result


"""--------------------------------- Attribute Effects ---------------------------------"""
func Breakthrough(card): # Activate Tech (Special)
	var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
	var Dueler = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var opponent = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	var Dueler_Str = "Player" if GameData.Current_Turn == "Player" else "Enemy"
	var Destination_Node = get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Opp + "MedBay")

	if Dueler.Tech_Deck.size() > 0 and card.Effect_Active:
		SignalBus.emit_signal("Draw_Card", Dueler_Str, 1, "Tech")
		SignalBus.emit_signal("Reparent_Nodes", card, Destination_Node)
		opponent.MedicalBay.append(card)

func Actor(card):
	pass

func Assassin(card):
	pass

func Creature(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card and card.Effect_Active:
		# Get Field Card Data for Fighter and Reinforcers
		var Fighter = Get_Field_Card_Data("Fighter")
		var Cards_On_Field = Get_Field_Card_Data("Reinforcers")
		Cards_On_Field.append(Fighter) # Required to do in two steps due to the fact that append returns null

		# Check if a copy of the card exists on the field
		for i in Cards_On_Field:
			if i.Name == card.Name and i != card:
				# Perform Fusion Summon
				i.Attack += card.Attack
				i.Health += card.Health
				i.Fusion_Level += 1
				i.Update_Data()

				# Reparent Nodes (to MedBay)
				var Side = "W" if GameData.Current_Turn == "Player" else "B"
				var Destination_Node = get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side + "Banished")
				SignalBus.emit_signal("Reparent_Nodes", card, Destination_Node)

				# End loop
				break

func Cryptid(card):
	pass

func Engineer(card):
	pass

func Explorer(card):
	pass

func Mythological(card):
	pass

func Olympian(card):
	pass

func Outlaw(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	
	if Valid_Card and card.Effect_Active:
		var Card_Selector = load("res://Scenes/SupportScenes/card_selector.tscn").instantiate()
		var Battle_Scene = Engine.get_main_loop().get_current_scene().get_node("Battle")
		Battle_Scene.add_child(Card_Selector)
		Card_Selector.Determine_Card_List("Opponent Hand", "NonTurnHand")
		Card_Selector.Set_Action_Type("Steal")

func Philosopher(card):
	pass

func Politician(card):
	pass

func Ranged(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	
	if Valid_Card:
		var Fighter = Get_Field_Card_Data("Fighter")
		var Reinforcers = Get_Field_Card_Data("Reinforcers")
		var Ranged_On_Field = false
		
		for i in Reinforcers:
			if Reinforcers[i].Attribute == "Ranged":
				Ranged_On_Field = true
				break
		
		if Ranged_On_Field:
			Fighter.Target_Reinforcer = true
			Fighter.Attacks_Remaining += 1
		else:
			Fighter.Target_Reinforcer = false

func Rogue(card):
	pass

func Scientist(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card:
		var roll_result = Dice_Roll(12)

		if roll_result == 7:
			var Dueler = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
			var Dueler_Str = "Player" if GameData.Current_Turn == "Player" else "Enemy"

			if Dueler.Tech_Deck.size() > 0:
				SignalBus.emit_signal("Draw_Card", Dueler_Str, 1, "Tech")

func Spy(card):
	pass

func Support(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card:
		var Fighter = Get_Field_Card_Data("Fighter")
		if Fighter != null:
			# Create a popup scene to allow the selection of the amount of HP to transfer to Fighter
			var Text_Entry = load("res://Scenes/SupportScenes/text_entry.tscn").instantiate()
			var Card_Scene = Engine.get_main_loop().get_current_scene().get_node(card.get_path())
			Card_Scene.add_child(Text_Entry)

			# Wait for the Confirm signal to be emitted using await
			await SignalBus.Confirm

			# Get Health Transfer Value
			var Health_Transfer_Value = int(Text_Entry.Select_Transfer_Amount())
			if Health_Transfer_Value < 0:
				Health_Transfer_Value = 0
			if Health_Transfer_Value > card.Health:
				Health_Transfer_Value = card.Health
			
			# Remove Scene
			Text_Entry.Remove_Scene()
			
			# Update Health Values
			Fighter.Health += Health_Transfer_Value
			card.Health -= Health_Transfer_Value
			Fighter.Update_Data()
			card.Update_Data()

			# Capture card if it dies
			if card.Health <= 0:
				SignalBus.emit_signal("Capture_Card", card, "Inverted")

func Titan(card):
	pass

func Treasure_Hunter(card):
	pass

func Trickster(card):
	pass

func Warrior(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card:
		var Fighter = Get_Field_Card_Data("Fighter")
		var Reinforcers = Get_Field_Card_Data("Reinforcers")
		if Fighter != null and card != Fighter and card.Attack > 0 and len(Reinforcers) > 0:
			# Create a popup scene to allow the selection of the amount of HP to transfer to Fighter
			var Text_Entry = load("res://Scenes/SupportScenes/text_entry.tscn").instantiate()
			var Card_Scene = Engine.get_main_loop().get_current_scene().get_node(card.get_path())
			Card_Scene.add_child(Text_Entry)

			# Wait for the Confirm signal to be emitted using await
			await SignalBus.Confirm

			# Get Attack Transfer Value
			var Attack_Transfer_Value = int(Text_Entry.Select_Transfer_Amount())
			if Attack_Transfer_Value < 0:
				Attack_Transfer_Value = 0
			if Attack_Transfer_Value > card.Attack:
				Attack_Transfer_Value = card.Attack

			# Remove Scene
			Text_Entry.Remove_Scene()

			# Update Attack Values
			Fighter.Attack += Attack_Transfer_Value
			card.Attack -= Attack_Transfer_Value
			Fighter.Update_Data()
			card.Update_Data()

func Wizard(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card and card.Effect_Active:
		# Add Button_Selector scene as child of card to allow for selection
		var Button_Selector_Scene = load("res://Scenes/SupportScenes/Button_Selector.tscn").instantiate()
		var Card_Scene = Engine.get_main_loop().get_current_scene().get_node(card.get_path())
		Card_Scene.add_child(Button_Selector_Scene)

		# Wait for the Confirm signal to be emitted using await
		await SignalBus.Confirm

		# Get Disabled Effect text
		var disabled_effect = Button_Selector_Scene.Get_Text()

		# Add Disabled Effect to Disabled_Effects list
		GameData.Disabled_Effects.append(disabled_effect)
		
		# Remove Scene
		Button_Selector_Scene.Remove_Scene()


"""--------------------------------- Hero Effects ---------------------------------"""
func Absorption(card):
	pass

func Atrocity(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var Battle_Scene = Engine.get_main_loop().get_current_scene().get_node("Battle")
	var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
	var MedBay_Opp = Battle_Scene.get_node("Playmat/CardSpots/NonHands/" + Side_Opp + "MedBay")
	
	if Valid_Card and MedBay_Opp.get_child_count() > 0:
		var Card_Selector = load("res://Scenes/SupportScenes/card_selector.tscn").instantiate()
		Battle_Scene.add_child(Card_Selector)
		Card_Selector.Determine_Card_List("Opponent MedBay", "NonTurnMedBay")
		Card_Selector.Set_Action_Type("Damage")
		Card_Selector.Set_Effect_Card(card)

func Barrage(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	
	card.Multi_Strike == true if Valid_Card else false

func Behind_Enemy_Lines(card): # Name changed from Moonshot to be more descriptive of actual function.
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	
	card.Direct_Attack == true if Valid_Card else false

func Conqueror(card):
	pass

func Counter(card):
	pass

func Defiance(card):
	pass

func Detonate(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
		
	if Valid_Card:
		GameData.Auto_Spring_Traps = true
		var Trap_Cards = Get_Field_Card_Data("Traps")
		var Battle_Script = load("res://Scripts/Controllers/Battle_Controller.gd").new()
		for i in range(len(Trap_Cards)):
			Battle_Script.Activate_Set_Card(Side, Trap_Cards[i])
	else:
		GameData.Auto_Spring_Traps = false	

func Disorient(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var Fighter_Opp = Get_Field_Card_Data("Fighter Opponent")
	var Reinforcers_Opp = Get_Field_Card_Data("Reinforcers Opponent")
	
	if Fighter_Opp != null:
		if Valid_Card and Reinforcers_Opp.size() > 0:
			# Randomly Choose Replacement Reinforcer
			var rng = RandomNumberGenerator.new()
			rng.randomize()
			var roll_result = rng.randi_range(0,Reinforcers_Opp.size() - 1)
			
			# Reparent Nodes
			var Fighter_Parent = Fighter_Opp.get_parent()
			var Reinforcer_Parent = Reinforcers_Opp[roll_result].get_parent()
			Fighter_Parent.remove_child(Fighter_Opp)
			Reinforcer_Parent.remove_child(Reinforcers_Opp[roll_result])
			Fighter_Parent.add_child(Reinforcers_Opp[roll_result])
			Reinforcer_Parent.add_child(Fighter_Opp)

func Earthbound(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	
	GameData.Muggle_Mode == true if Valid_Card else false

func Expansion(card):
	pass

func Faithful(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var Reinforcers = Get_Field_Card_Data("Reinforcers")
	
	card.Immortal == true if Valid_Card and Reinforcers.size() >= 3 else false

func For_Honor_And_Glory(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var enemy = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
	var MedBay = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side + "MedBay")
	var MedBay_Opp = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Opp + "MedBay")
	var Reinforcers = Get_Field_Card_Data("Reinforcers")
	var Reinforcers_Opp = Get_Field_Card_Data("Reinforcers Opponent")
	
	if Valid_Card:
		GameData.For_Honor_And_Glory = true
		# Reparent Nodes
		for i in len(Reinforcers):
			var Reinforcer_Parent = Reinforcers[i].get_parent()
			Reinforcer_Parent.remove_child(Reinforcers[i])
			MedBay.add_child(Reinforcers[i])
			player.MedicalBay.append(Reinforcers[i])
		
		for i in len(Reinforcers_Opp):
			var Reinforcer_Parent = Reinforcers_Opp[i].get_parent()
			Reinforcer_Parent.remove_child(Reinforcers_Opp[i])
			MedBay_Opp.add_child(Reinforcers_Opp[i])
			enemy.MedicalBay.append(Reinforcers_Opp[i])
	else:
		GameData.For_Honor_And_Glory = false

func Fury(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	
	if Valid_Card and card.Effect_Active:
		card.Effect_Active = false
		var MedBay_Count = player.MedicalBay.size()
		card.ATK_Bonus += MedBay_Count
		card.Update_Data()

func Guardian(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var enemy = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	var Reinforcers = Get_Field_Card_Data("Reinforcers Opponent")
	
	if Valid_Card and GameData.Target in Reinforcers:
		GameData.Target.Health += (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + enemy.Field_ATK_Bonus)
		GameData.Attacker.Health -= (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + enemy.Field_ATK_Bonus)
		GameData.Target.Update_Data()
		GameData.Attacker.Update_Data()

func Humiliator(card):
	pass		

func Inspiration(card):
	pass

func Invincibility(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	
	card.Invincible == true if Valid_Card else false

func Juggernaut(card): # NOTE: This is just a strictly better effect than the current implementation of TailorMade (since it repeats every turn instead of just on summon)
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	if Valid_Card:
		card.ATK_Bonus += card.ATK_Bonus
		card.Update_Data()

func Mimic(card):
	pass

func Paralysis(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var Fighter_Opp = Get_Field_Card_Data("Fighter Opponent")
	
	if Valid_Card and card.Effect_Active:
		if Fighter_Opp != null:
			Fighter_Opp.Paralysis = true

func Perfect_Copy(card):
	pass

func Poison(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var Fighter = Get_Field_Card_Data("Fighter")
	
	if Valid_Card and card.Effect_Active and card == Fighter:
		GameData.Target.Burn_Damage += card.Toxicity
		GameData.Target.Health -= GameData.Target.Burn_Damage
		GameData.Target.Update_Data()

func Reformation(card):
	pass

func Reincarnation(card):
	pass

func Relentless(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	
	card.Relentless == true if Valid_Card else false

func Retribution(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var player = GameData.Player if GameData.Current_Turn == "Enemy" else GameData.Enemy
	var Fighter_Opp = Get_Field_Card_Data("Fighter") # Not "Fighter Opponent" since this effect will occur during opponent's turn!
	
	if Valid_Card and GameData.Cards_Captured_This_Turn.size() > 0:
		Fighter_Opp.Health -= (card.Attack + card.ATK_Bonus + player.Field_ATK_Bonus)
		Fighter_Opp.Update_Data()

func Spawn(card):
	pass

func Tailor_Made(card): # Currently just doubles ATK_Bonus when summoned (instead of Equip-specific stat boosts, like Hephestus' effect did originally). Eric claims more thinking needs to be done on this effect due to lameness.
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	
	if Valid_Card and card.Effect_Active:
		card.Effect_Active = false
		card.ATK_Bonus += card.ATK_Bonus
		card.Update_Data()

func Taunt(card):
	pass


"""--------------------------------- Magic/Trap Effects ---------------------------------"""
func Blade_Song(card):
	pass

func Deep_Pit(card):
	pass

func Disable(card):
	pass

func Excalibur(card):
	pass

func Heart_of_the_Underdog(card):
	pass

func Last_Stand(card):
	pass

func Miraculous_Recovery(card):
	pass

func Morale_Boost(card):
	pass

func Prayer(card):
	pass

func Resurrection(card):
	pass

func Runetouched(card):
	pass

func Sword(card):
	pass


"""--------------------------------- Tech Effects ---------------------------------"""
# Note: Eliminating the Valid_Card check here means the effect will only ever trigger once.
# I'm not sure if this was how we wanted it to be for Tech Cards, but if not we can just add the check back in.
func Fire(card):
	if card.Effect_Active:
		var Side = "W" if GameData.Current_Turn == "Player" else "B"
		var Dueler = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
		var Node_To_Update = get_tree().get_root().get_node("SceneHandler/Battle/HUD_" + Side)

		Dueler.Field_Health_Bonus += 5

		SignalBus.emit_signal("Update_HUD_Duelist", Node_To_Update, Dueler)

func The_Wheel(card):	
	if card.Effect_Active:
		var Side = "W" if GameData.Current_Turn == "Player" else "B"
		var Dueler = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
		var Node_To_Update = get_tree().get_root().get_node("SceneHandler/Battle/HUD_" + Side)
		
		Dueler.Update_Cost_Discount_Normal(-1)
		Dueler.Update_Cost_Discount_Hero(-1)
		Dueler.Update_Cost_Discount_Magic(-1)
		Dueler.Update_Cost_Discount_Trap(-1)

		SignalBus.emit_signal("Update_HUD_Duelist", Node_To_Update, Dueler)
