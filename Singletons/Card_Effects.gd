extends Node

var BM

func _ready():
	var _HV1 = SignalBus.connect("READY", Callable(self, "Set_Battle_Manager"))

func Set_Battle_Manager(): # A temporary function to fix the issue of the BM variable not being available/ready when this script is loaded due to Card_Effects being a singleton. If this script is changed to a non-singleton, this function (and the accompanying signal in the BM & SignalBus can be removed)
	BM = get_tree().get_root().get_node("SceneHandler/Battle")


"""--------------------------------- General Functions ---------------------------------"""

func On_Field(card) -> bool:
	var Parent_Name = card.get_parent().name
	var Valid_Slots = ["WFighter", "WR1", "WR2", "WR3", "WBackrow1", "WBackrow2", "WBackrow3", "WEquipTrap", "WEquipMagic", "BFighter", "BR1", "BR2", "BR3", "BBackrow1", "BBackrow2", "BBackrow3", "BEquipTrap", "BEquipMagic"]
	
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
	var MedBay_Cards = []
	
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
	elif Zone == "MedBay":
		var MedBay_Path = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side + "MedBay")
		if MedBay_Path.get_child_count() > 0:
			for i in range(MedBay_Path.get_child_count()):
				MedBay_Cards.append(MedBay_Path.get_child(i))
		return MedBay_Cards
	elif Zone == "MedBay Opponent":
		var MedBay_Path_Opp = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Opponent + "MedBay")
		if MedBay_Path_Opp.get_child_count() > 0:
			for i in range(MedBay_Path_Opp.get_child_count()):
				MedBay_Cards.append(MedBay_Path_Opp.get_child(i))
		return MedBay_Cards

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
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
	var Dueler_Str = "Player" if GameData.Current_Turn == "Player" else "Enemy"
	var Dueler_Tech_Deck = get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side + "TechDeck")
	var Destination_Node = get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Opp + "MedBay")

	if len(Dueler_Tech_Deck.get_children()) > 0 and card.Can_Activate_Effect:
		SignalBus.emit_signal("Draw_Card", Dueler_Str, 1, "Tech")
		SignalBus.emit_signal("Reparent_Nodes", card, Destination_Node)

func Actor(card):
	pass

func Assassin(card):
	pass

func Creature(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card and card.Can_Activate_Effect:
		# Get Field Card Data for Fighter and Reinforcers
		var Fighter = Get_Field_Card_Data("Fighter")
		var Cards_On_Field = Get_Field_Card_Data("Reinforcers")
		if Fighter != null:
			Cards_On_Field.append(Fighter) # Required to do in two steps due to the fact that append returns null

		# Check if a copy of the card exists on the field
		if Cards_On_Field.size() > 0:
			for i in Cards_On_Field:
				if i.Name == card.Name and i != card:
					# Perform Fusion Summon
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
	
	if Valid_Card and card.Can_Activate_Effect:
		var Side = "W" if GameData.Current_Turn == "Player" else "B"
		var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
		var Card_Selector = load("res://Scenes/SupportScenes/Card_Selector.tscn").instantiate()
		var Battle_Scene = Engine.get_main_loop().get_current_scene().get_node("Battle")
		Battle_Scene.add_child(Card_Selector)
		Card_Selector.Determine_Card_List("Opponent Hand", "NonTurnHand")
		Card_Selector.Set_Effect_Card(card)

		# Wait for the Confirm signal to be emitted using await
		await SignalBus.Confirm

		# Get Chosen Target
		var Chosen_Card = Card_Selector.Get_Card()

		# Get Dueler Hands
		var Source_Hand = Battle_Scene.get_node("Playmat/CardSpots/" + Side_Opp + "HandScroller/" + Side_Opp + "Hand")
		var Destination_Hand = Battle_Scene.get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")

		# Find original copy of Chosen_Card
		var Chosen_Card_Node
		for i in range(Source_Hand.get_child_count()):
			if Source_Hand.get_child(i).name == Chosen_Card.name:
				Chosen_Card_Node = Source_Hand.get_child(i)
				break

		# Update Hands
		Source_Hand.remove_child(Chosen_Card_Node)
		Destination_Hand.add_child(Chosen_Card_Node)

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
			if Fighter.Relentless: # To account for the fact that relentless double the value of attacks remaining alterations
				Fighter.Attacks_Remaining += 2
			else:
				Fighter.Attacks_Remaining += 1
		else:
			Fighter.Target_Reinforcer = false

func Rogue(card):
	pass

func Scientist(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card:
		var roll_result = Dice_Roll(6)
		var roll_result2 = Dice_Roll(6)
		var sum_of_rolls = roll_result + roll_result2

		if sum_of_rolls == 7:
			var Side = "W" if GameData.Current_Turn == "Player" else "B"
			var Dueler_Str = "Player" if GameData.Current_Turn == "Player" else "Enemy"
			var Dueler_Tech_Deck = get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side + "TechDeck")

			if len(Dueler_Tech_Deck.get_children()) > 0:
				SignalBus.emit_signal("Draw_Card", Dueler_Str, 1, "Tech")

func Spy(card):
	pass

func Support(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card:
		var Fighter = Get_Field_Card_Data("Fighter")
		if Fighter != null:
			# Create a popup scene to allow the selection of the amount of HP to transfer to Fighter
			var Text_Entry = load("res://Scenes/SupportScenes/Text_Entry.tscn").instantiate()
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
			if card.Get_Total_Health() <= 0:
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
			var Text_Entry = load("res://Scenes/SupportScenes/Text_Entry.tscn").instantiate()
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

	if Valid_Card and card.Can_Activate_Effect:
		# Add Button_Selector scene as child of card to allow for selection
		var Button_Selector_Scene = load("res://Scenes/SupportScenes/Button_Selector.tscn").instantiate()
		var Card_Scene = Engine.get_main_loop().get_current_scene().get_node(card.get_path())
		Card_Scene.add_child(Button_Selector_Scene)
		
		Button_Selector_Scene.Get_Active_Card_Effects()
		Button_Selector_Scene.Add_Buttons()

		# Wait for the Confirm signal to be emitted using await
		await SignalBus.Confirm

		# Get Disabled Effect text
		var disabled_effect = Button_Selector_Scene.Get_Text()

		# Add Disabled Effect to Disabled_Effects list & this card's Disabled_Effects list
		GameData.Disabled_Effects.append(disabled_effect)
		card.Effects_Disabled.append(disabled_effect)

		
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
	
	if Valid_Card and MedBay_Opp.get_child_count() > 0 and card.Can_Activate_Effect:
		var Card_Selector = load("res://Scenes/SupportScenes/Card_Selector.tscn").instantiate()
		Battle_Scene.add_child(Card_Selector)
		Card_Selector.Determine_Card_List("Opponent MedBay", "NonTurnMedBay")
		Card_Selector.Set_Effect_Card(card)
		card.Can_Activate_Effect = false

		# Wait for the Confirm signal to be emitted using await
		await SignalBus.Confirm

		# Get Chosen_Card
		var Chosen_Card = Card_Selector.Get_Card()

		# Find original copy of Chosen_Card
		var Chosen_Card_Node
		for i in range(MedBay_Opp.get_child_count()):
			if MedBay_Opp.get_child(i).name == Chosen_Card.name:
				Chosen_Card_Node = MedBay_Opp.get_child(i)
				break

		# Calculate Damage
		var Damage_Modifier = 0.2
		var Parent_Name = Chosen_Card_Node.get_parent().name
		var Dueler = BM.Player if Parent_Name.left(1) == "W" else BM.Enemy
		var damage_dealt = int(floor((card.Attack + card.ATK_Bonus + Dueler.Field_ATK_Bonus) * Damage_Modifier))
		Chosen_Card_Node.Health = max(0, Chosen_Card_Node.Health - damage_dealt)
		Chosen_Card_Node.Update_Data()

func Barrage(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	
	if Valid_Card:
		card.Multi_Strike = true

func Behind_Enemy_Lines(card): # Name changed from Moonshot to be more descriptive of actual function.
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	
	if card.Can_Activate_Effect:
		if Valid_Card:
			card.Direct_Attack = true
		else:
			card.Direct_Attack = false

func Conqueror(card):
	pass

func Counter(card):
	pass

func Defiance(card):
	pass

func Detonate(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
		
	if Valid_Card:
		var Trap_Cards = Get_Field_Card_Data("Traps")
		for i in range(len(Trap_Cards)):
			Trap_Cards[i].Tokens += 1

func Disorient(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var Fighter_Opp = Get_Field_Card_Data("Fighter Opponent")
	var Reinforcers_Opp = Get_Field_Card_Data("Reinforcers Opponent")

	if Fighter_Opp != null:
		if Valid_Card:
			# Load Card Selector Scene if more than 1 target is available
			if Reinforcers_Opp.size() > 1:
				# Create a popup scene to allow the selection of the target to switch
				var Card_Selector = load("res://Scenes/SupportScenes/Card_Selector.tscn").instantiate()
				var Battle_Scene = Engine.get_main_loop().get_current_scene().get_node("Battle")
				Battle_Scene.add_child(Card_Selector)
				Card_Selector.Determine_Card_List("Opponent Reinforcers", "NonTurnReinforcers")
				Card_Selector.Set_Effect_Card(card)

				# Wait for the Confirm signal to be emitted using await
				await SignalBus.Confirm

				# Get Chosen Target
				var chosen_target = Card_Selector.Get_Card()
				var Valid_Target = false

				# Find original copy of chosen_target
				for i in range(len(Reinforcers_Opp)):
					if chosen_target.name == Reinforcers_Opp[i].name:
						chosen_target = Reinforcers_Opp[i]
						Valid_Target = true
						break

				# Resolve Effect, Reparent Nodes, and Update Dueler Arrays
				if Valid_Target:
					var Dueler_Opp = BM.Enemy if GameData.Current_Turn == "Player" else BM.Player
					var Fighter_Parent = Fighter_Opp.get_parent()
					var Reinforcer_Parent = chosen_target.get_parent()
					Dueler_Opp.Fighter.erase(Fighter_Opp)
					Dueler_Opp.Fighter.append(chosen_target)
					Dueler_Opp.Reinforcement.erase(chosen_target)
					Dueler_Opp.Reinforcement.append(Fighter_Opp)
					Fighter_Parent.remove_child(Fighter_Opp)
					Reinforcer_Parent.remove_child(chosen_target)
					Fighter_Parent.add_child(chosen_target)
					Reinforcer_Parent.add_child(Fighter_Opp)
			else: # Automates selection process if only 1 target is available
				if Reinforcers_Opp.size() > 0:
					var Dueler_Opp = BM.Enemy if GameData.Current_Turn == "Player" else BM.Player
					var Fighter_Parent = Fighter_Opp.get_parent()
					var Reinforcer_Parent = Reinforcers_Opp[0].get_parent()
					Dueler_Opp.Fighter.erase(Fighter_Opp)
					Dueler_Opp.Fighter.append(Reinforcers_Opp[0])
					Dueler_Opp.Reinforcement.erase(Reinforcers_Opp[0])
					Dueler_Opp.Reinforcement.append(Fighter_Opp)
					Fighter_Parent.remove_child(Fighter_Opp)
					Reinforcer_Parent.remove_child(Reinforcers_Opp[0])
					Fighter_Parent.add_child(Reinforcers_Opp[0])
					Reinforcer_Parent.add_child(Fighter_Opp)

func Earthbound(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	
	GameData.Muggle_Mode == true if Valid_Card else false

func Expansion(card):
	pass

func Faithful(card):
	var Valid_Card = true if On_Field(card) && Valid_Effect_Type(card) else false
	var Reinforcers = Get_Field_Card_Data("Reinforcers")
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Parent_Name = card.get_parent().name.left(1)
	
	if (Valid_Card and Reinforcers.size() >= 3) and Side == Parent_Name:
		card.Immortal = true
	elif (Reinforcers.size() < 3 or On_Field(card) == false) and Side == Parent_Name:
		card.Immortal = false

func For_Honor_And_Glory(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
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
		
		for i in len(Reinforcers_Opp):
			var Reinforcer_Parent = Reinforcers_Opp[i].get_parent()
			Reinforcer_Parent.remove_child(Reinforcers_Opp[i])
			MedBay_Opp.add_child(Reinforcers_Opp[i])
	else:
		GameData.For_Honor_And_Glory = false

func Fury(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	
	if Valid_Card and card.Can_Activate_Effect:
		card.Can_Activate_Effect = false
		var MedBay_Count = len(Get_Field_Card_Data("MedBay"))
		card.ATK_Bonus += MedBay_Count
		card.Update_Data()

func Guardian(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var enemy = BM.Enemy if GameData.Current_Turn == "Player" else BM.Player
	var Reinforcers = Get_Field_Card_Data("Reinforcers Opponent")
	
	if Valid_Card and GameData.Target in Reinforcers:
		GameData.Target.Health += (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + enemy.Field_ATK_Bonus - (GameData.Target.Fusion_Level - 1))
		GameData.Attacker.Health -= (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + enemy.Field_ATK_Bonus - (GameData.Target.Fusion_Level - 1))
		GameData.Target.Update_Data()
		GameData.Attacker.Update_Data()

func Humiliator(card):
	pass		

func Inspiration(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card and card.Can_Activate_Effect:
		var Side = "W" if GameData.Current_Turn == "Player" else "B"
		var Dueler_Str = "Player" if GameData.Current_Turn == "Player" else "Enemy"
		var Dueler_Tech_Deck = get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side + "TechDeck")
		var Card_Index = Dice_Roll(len(Dueler_Tech_Deck.get_children)) - 1 # -1 to account for 0-indexing

		# Add selected Tech card to Tech Zone
		if len(Dueler_Tech_Deck.get_children()) > 0:
			SignalBus.emit_signal("Draw_Card", Dueler_Str, 1, "Tech", Card_Index)

func Invincibility(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	
	if Valid_Card:
		card.Invincible = true
	elif On_Field(card) == false or Valid_Effect_Type(card) == false:
		card.Invincible = false

func Juggernaut(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card:
		card.Attack *= 2
		card.Update_Data()

func Mimic(card):
	pass

func Paralysis(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var Fighter_Opp = Get_Field_Card_Data("Fighter Opponent")
	
	if Valid_Card and card.Can_Activate_Effect:
		if Fighter_Opp != null:
			Fighter_Opp.Paralysis = true

func Perfect_Copy(card):
	pass

func Poison(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card and card.Can_Activate_Effect:
		# Add Button_Selector scene as child of card to allow for selection
		var Button_Selector_Scene = load("res://Scenes/SupportScenes/Button_Selector.tscn").instantiate()
		var Card_Scene = Engine.get_main_loop().get_current_scene().get_node(card.get_path())
		Card_Scene.add_child(Button_Selector_Scene)

		# Choose to Heal or Poison a Target
		Button_Selector_Scene.Get_Custom_Options(['Heal', 'Poison'])
		Button_Selector_Scene.Add_Buttons()

		# Wait for the Confirm signal to be emitted using await
		await SignalBus.Confirm

		# Get Chosen Effect text
		var chosen_effect = Button_Selector_Scene.Get_Text()

		if chosen_effect == "Heal":
			# Populate Cards_On_Field array
			var Fighter = Get_Field_Card_Data("Fighter")
			var Reinforcers = Get_Field_Card_Data("Reinforcers")
			var Cards_On_Field = Reinforcers
			if Fighter != null:
				Cards_On_Field.append(Fighter) # Required to do in two steps due to the fact that append returns null
			
			# Load Card Selector Scene if more than 1 target is available
			if Cards_On_Field.size() > 1:
				# Create a popup scene to allow the selection of the target to heal
				var Card_Selector = load("res://Scenes/SupportScenes/Card_Selector.tscn").instantiate()
				var Battle_Scene = Engine.get_main_loop().get_current_scene().get_node("Battle")
				Battle_Scene.add_child(Card_Selector)
				Card_Selector.Determine_Card_List("Field (All)", "TurnField")
				Card_Selector.Set_Effect_Card(card)

				# Wait for the Confirm signal to be emitted using await
				await SignalBus.Confirm

				# Get Chosen Target
				var chosen_target = Card_Selector.Get_Card()
				var Valid_Target = false

				# Find parent of chosen_target
				if chosen_target.name == Fighter.name:
					chosen_target = Fighter
					Valid_Target = true
				else:
					for i in range(len(Reinforcers)):
						if chosen_target.name == Reinforcers[i].name:
							chosen_target = Reinforcers[i]
							Valid_Target = true
							break

				# Resolve Effect if chosen_target is valid
				if Valid_Target:
					chosen_target.Health += card.Toxicity
					chosen_target.Update_Data()
			else: # Automates selection process if only 1 target is available
				if Cards_On_Field.size() > 0:
					Cards_On_Field[0].Health += card.Toxicity
					Cards_On_Field[0].Update_Data()
		elif chosen_effect == "Poison":
			# Populate Cards_On_Field array
			var Fighter_Opp = Get_Field_Card_Data("Fighter Opponent")
			var Reinforcers_Opp = Get_Field_Card_Data("Reinforcers Opponent")
			var Cards_On_Field = Reinforcers_Opp
			if Fighter_Opp != null:
				Cards_On_Field.append(Fighter_Opp) # Required to do in two steps due to the fact that append returns null
			
			# Load Card Selector Scene if more than 1 target is available
			if Cards_On_Field.size() > 1:
				# Create a popup scene to allow the selection of the target to poison
				var Card_Selector = load("res://Scenes/SupportScenes/Card_Selector.tscn").instantiate()
				var Battle_Scene = Engine.get_main_loop().get_current_scene().get_node("Battle")
				Battle_Scene.add_child(Card_Selector)
				Card_Selector.Determine_Card_List("Opponent Field (All)", "NonTurnField")
				Card_Selector.Set_Effect_Card(card)

				# Wait for the Confirm signal to be emitted using await
				await SignalBus.Confirm

				# Get Chosen Target
				var chosen_target = Card_Selector.Get_Card()
				var Valid_Target = false

				# Find parent of chosen_target
				if chosen_target.name == Fighter_Opp.name:
					chosen_target = Fighter_Opp
					Valid_Target = true
				else:
					for i in range(len(Reinforcers_Opp)):
						if chosen_target.name == Reinforcers_Opp[i].name:
							chosen_target = Reinforcers_Opp[i]
							Valid_Target = true
							break

				# Resolve Effect if chosen_target is valid
				if Valid_Target:
					chosen_target.Burn_Damage += card.Toxicity
					chosen_target.Health -= chosen_target.Burn_Damage
					chosen_target.Update_Data()

					# Capture card if it dies
					if chosen_target.Get_Total_Health() <= 0 and chosen_target.Immortal == false:
						SignalBus.emit_signal("Capture_Card", chosen_target, "Inverted")
			else: # Automates selection process if only 1 target is available
				var Fighter = Get_Field_Card_Data("Fighter")
				if Cards_On_Field.size() > 0:
					if Fighter != null:
						if Valid_Card and card.Can_Activate_Effect and card == Fighter:
							Cards_On_Field[0].Burn_Damage += card.Toxicity
							Cards_On_Field[0].Health -= Cards_On_Field[0].Burn_Damage
							Cards_On_Field[0].Update_Data()

							# Capture card if it dies
							if Cards_On_Field[0].Get_Total_Health() <= 0 and Cards_On_Field[0].Immortal == false:
								SignalBus.emit_signal("Capture_Card", Cards_On_Field[0], "Inverted")
		
		# Remove Scene
		Button_Selector_Scene.Remove_Scene()

		# Ensures that the effect is only used once per turn (after the turn it was first summoned)
		card.Can_Activate_Effect = false

func Reformation(card):
	pass

func Reincarnation(card):
	pass

func Relentless(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	
	card.Relentless == true if Valid_Card else false

func Retribution(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var player = BM.Player if GameData.Current_Turn == "Enemy" else BM.Enemy
	var Fighter_Opp = Get_Field_Card_Data("Fighter") # Not "Fighter Opponent" since this effect will occur during opponent's turn!
	var Combatants_Captured = 0

	# Ensures that at least 1 Normal/Hero card was captured this turn
	if GameData.Cards_Captured_This_Turn.size() > 0:
		for i in range(len(GameData.Cards_Captured_This_Turn)):
			if GameData.Cards_Captured_This_Turn[i].Type == "Normal" or GameData.Cards_Captured_This_Turn[i].Type == "Hero":
				Combatants_Captured += 1
				break
	
	# Resolve Effect
	if Valid_Card and Combatants_Captured > 0:
		Fighter_Opp.Health -= (card.Attack + card.ATK_Bonus + player.Field_ATK_Bonus - (Fighter_Opp.Fusion_Level - 1))
		Fighter_Opp.Update_Data()

func Spawn(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card and card.Can_Activate_Effect:
		# Add Token to card
		card.Tokens += 1
		card.Update_Token_Info()

		# Reduce Fighter_Opp's Health by 1 for every Token on card and capture if applicable
		var Fighter_Opp = Get_Field_Card_Data("Fighter Opponent")
		
		if Fighter_Opp != null:
			Fighter_Opp.Health -= card.Tokens
			Fighter_Opp.Update_Data()

			if Fighter_Opp.Get_Total_Health() <= 0:
				SignalBus.emit_signal("Capture_Card", Fighter_Opp)
	
	# Neutralize damage taken using spawned tokens as shields. Barrage attacks will destroy all tokens simultaneously (and damage card).
	elif On_Field(card) && Valid_Effect_Type(card):
		if GameData.Current_Step == "Damage":
			if card == GameData.Target and card.Tokens > 0:
				var enemy = BM.Enemy if GameData.Current_Turn == "Player" else BM.Player
				if GameData.Attacker.Multi_Strike == false:
					GameData.Target.Health += (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + enemy.Field_ATK_Bonus - (GameData.Target.Fusion_Level - 1))
					card.Tokens -= 1
				else:
					card.Tokens = 0
				GameData.Target.Update_Data()
				card.Update_Token_Info()

func Tailor_Made(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card and card.Can_Activate_Effect:
		# Find all Equip cards
		var options = []
		for i in range(len(GameData.CardData)):
			if (GameData.CardData[i]["CardType"] == "Magic" or GameData.CardData[i]["CardType"] == "Trap") and GameData.CardData[i]["Attribute"] == "Equip":
				options.append(GameData.CardData[i])

		# Choose 3 random cards from options array
		var chosen_cards = []
		for i in range(3):
			var random_index = randi() % len(options)
			chosen_cards.append(options[random_index])
			options.pop_at(random_index)

		# Instantiate and add chosen cards to Global_Card_Holder using passcode values from chosen_cards array
		for i in range(len(chosen_cards)):
			var DC = get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands")
			var Destination_Deck = GameData.Global_Deck
			var Equip_Card = DC.Create_Card(chosen_cards[i]["Passcode"])
			Destination_Deck.append(Equip_Card)
			Engine.get_main_loop().get_current_scene().get_node("Battle/Global_Card_Holder/").add_child(Equip_Card)

		# Add Card Selector Scene
		var Card_Selector = load("res://Scenes/SupportScenes/Card_Selector.tscn").instantiate()
		var Battle_Scene = Engine.get_main_loop().get_current_scene().get_node("Battle")
		var Side = "W" if GameData.Current_Turn == "Player" else "B"
		Battle_Scene.add_child(Card_Selector)
		Card_Selector.Determine_Card_List("Global Cards", "AllCardsDB")
		Card_Selector.Set_Effect_Card(card)

		# Wait for the Confirm signal before clearing Global_Card_Holder array & Node
		await SignalBus.Confirm

		# Find original copy of Chosen Card
		var Chosen_Card = Card_Selector.Get_Card()
		var Chosen_Card_Node
		for i in range(Battle_Scene.get_node("Global_Card_Holder/").get_child_count()):
			if Battle_Scene.get_node("Global_Card_Holder/").get_child(i).name == Chosen_Card.name:
				Chosen_Card_Node = Battle_Scene.get_node("Global_Card_Holder/").get_child(i)
				break

		# Move Chosen_Card to proper hand
		var Source_Node = Battle_Scene.get_node("Global_Card_Holder/")
		var Destination_Hand = Battle_Scene.get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")
		Source_Node.remove_child(Chosen_Card_Node)
		Destination_Hand.add_child(Chosen_Card_Node)

		# Fix Positioning Bug
		Chosen_Card_Node.get_node("SmallCard").set_position(Vector2.ZERO)

		# Remove items from Global_Card_Holder array & Node
		GameData.Global_Deck.clear()
		var Global_Card_Holder = Battle_Scene.get_node("Global_Card_Holder/")
		for i in range(Global_Card_Holder.get_child_count()):
			Global_Card_Holder.get_child(0).queue_free()

func Taunt(card):
	pass


"""--------------------------------- Magic/Trap Effects ---------------------------------"""
func Blade_Song(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card and card.Can_Activate_Effect:
		var Card_Selector = load("res://Scenes/SupportScenes/Card_Selector.tscn").instantiate()
		var Battle_Scene = Engine.get_main_loop().get_current_scene().get_node("Battle")
		var Side = "W" if GameData.Current_Turn == "Player" else "B"
		Battle_Scene.add_child(Card_Selector)
		Card_Selector.Determine_Card_List("Graveyard", "TurnGraveyard", "Graveyard", "Equip")
		Card_Selector.Set_Effect_Card(card)

		# Wait for the Confirm signal to be emitted using await
		await SignalBus.Confirm

		# Get Chosen Target
		var Chosen_Card = Card_Selector.Get_Card()

		# Get Dueler Hands
		if Chosen_Card.Attribute == "Equip":
			var Source_Graveyard = Battle_Scene.get_node("Playmat/CardSpots/NonHands/" + Side + "Graveyard")
			var Destination_Hand = Battle_Scene.get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")

			# Find original copy of Chosen_Card
			var Chosen_Card_Node
			for i in range(Source_Graveyard.get_child_count()):
				if Source_Graveyard.get_child(i).name == Chosen_Card.name:
					Chosen_Card_Node = Source_Graveyard.get_child(i)
					break

			# Update Grave/Hand
			Source_Graveyard.remove_child(Chosen_Card_Node)
			Destination_Hand.add_child(Chosen_Card_Node)

		# Reparent Nodes
		var Destination_Node = get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side + "Graveyard")
		SignalBus.emit_signal("Reparent_Nodes", card, Destination_Node)

func Deep_Pit(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var Side = "B" if GameData.Current_Turn == "Player" else "W"

	if Valid_Card and card.Tokens > 0 and GameData.Cards_Summoned_This_Turn.size() > 0:
		for i in range(len(GameData.Cards_Summoned_This_Turn)):
			var Parent_Name = GameData.Cards_Summoned_This_Turn[i].get_parent().name
			if "Fighter" in Parent_Name:
				SignalBus.emit_signal("Capture_Card", GameData.Cards_Summoned_This_Turn[i], "Inverted")
				SignalBus.emit_signal("Activate_Set_Card", Side, card) # Duelist Arrays are updated here
				break

func Disable(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var Fighter_Opp = Get_Field_Card_Data("Fighter Opponent")

	if Valid_Card and Fighter_Opp != null and card.Can_Activate_Effect:
		Fighter_Opp.Paralysis = true

func Excalibur(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card and card.Can_Activate_Effect:
		var Fighter = Get_Field_Card_Data("Fighter")
		var Reinforcers = Get_Field_Card_Data("Reinforcers")
		var Fighter_Opp = Get_Field_Card_Data("Fighter Opponent")
		var Reinforcers_Opp = Get_Field_Card_Data("Reinforcers Opponent")
		var Cards_On_Field = []
		var Cards_On_Field_Opp = []

		# Populate Cards On Field Arrays
		if Fighter != null:
			Cards_On_Field.append(Fighter)
		if Reinforcers.size() > 0:
			for i in Reinforcers:
				Cards_On_Field.append(i)
		if Fighter_Opp != null:
			Cards_On_Field_Opp.append(Fighter_Opp)
		if Reinforcers_Opp.size() > 0:
			for i in Reinforcers_Opp:
				Cards_On_Field_Opp.append(i)

		# Resolve Effect if equipped to King Arthur
		if Fighter != null:
			if Fighter.Name == "King Arthur":
				for i in Cards_On_Field:
					if i.Attribute == "Warrior":
						i.ATK_Bonus += 3
						i.Update_Data()
				for i in Cards_On_Field_Opp:
					if i.Attribute == "Warrior":
						i.ATK_Bonus -= 2
						i.Update_Data()

func Heart_of_the_Underdog(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var Defending_Fighter = Get_Field_Card_Data("Fighter Opponent") # Not "Fighter" since this effect will occur during opponent's turn!

	if Valid_Card and GameData.Attacker != null and GameData.Target == Defending_Fighter and card.Tokens > 0:
		var attacking_player = BM.Player if GameData.Current_Turn == "Player" else BM.Enemy
		var damage_dealt = (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + attacking_player.Field_ATK_Bonus - (GameData.Target.Fusion_Level - 1))
		if damage_dealt >= GameData.Target.Health and damage_dealt < GameData.Target.Health + 7: # Ensures trap only activates when it would save the Target from Capture
			var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
			var Destination_Node = get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Opp + "Graveyard")
			GameData.Target.Health += 7
			GameData.Target.Update_Data()

			SignalBus.emit_signal("Reparent_Nodes", card, Destination_Node)
			SignalBus.emit_signal("Activate_Set_Card", Side_Opp, card) # Duelist Arrays are updated here

func Last_Stand(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var Valid_But_Off_Field = true if Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var Parent_Name = card.get_parent().name
	var Fighter = Get_Field_Card_Data("Fighter")
	var Reinforcers = Get_Field_Card_Data("Reinforcers")

	# Get Cards on Field (accounting for possibility of null values in Fighter and Reinforcers)
	var Cards_On_Field = []
	if Fighter != null:
		Cards_On_Field.append(Fighter)
	if Reinforcers.size() > 0:
		for i in Reinforcers:
			Cards_On_Field.append(i)

	# Reset card's Can_Activate_Effect value to allow for resolving the effect from Graveyard
	if card in GameData.Cards_Captured_This_Turn and card.Can_Activate_Effect == false:
		card.Can_Activate_Effect = true

	if Valid_Card and card.Can_Activate_Effect:
		if len(Cards_On_Field) > 0:
			for i in Cards_On_Field:
				i.ATK_Bonus += 5
				i.Update_Data()
	elif Valid_But_Off_Field and "Graveyard" in Parent_Name and card.Can_Activate_Effect:
		card.Can_Activate_Effect = false
		if len(Cards_On_Field) > 0:
			for i in Cards_On_Field:
				i.ATK_Bonus -= 8
				i.Update_Data()

func Miraculous_Recovery(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	# Check if there are any cards in the MedBay
	var MedBay = Get_Field_Card_Data("MedBay")
	var MedBay_Opp = Get_Field_Card_Data("MedBay Opponent")
	var MedBay_Cards = []
	var MedBay_Cards_Opp = []
	if MedBay != null:
		MedBay_Cards.append(MedBay)
	if MedBay_Opp != null:
		MedBay_Cards_Opp.append(MedBay_Opp)

	# Loop through both medbays and remove any cards that have the name 'Advance Tech'
	for i in range(len(MedBay_Cards)):
		for j in range(len(MedBay_Cards[i])):
			if MedBay_Cards[i][j].Name == "Activate Technology":
				MedBay_Cards[i].erase(MedBay_Cards[i][j])
				break
	for i in range(len(MedBay_Cards_Opp)):
		for j in range(len(MedBay_Cards_Opp[i])):
			if MedBay_Cards_Opp[i][j].Name == "Activate Technology":
				MedBay_Cards_Opp[i].erase(MedBay_Cards_Opp[i][j])
				break

	# Resolve Effect
	if Valid_Card and card.Can_Activate_Effect and len(MedBay_Cards[0] + MedBay_Cards_Opp[0]) > 0:
		var Card_Selector = load("res://Scenes/SupportScenes/Card_Selector.tscn").instantiate()
		var Battle_Scene = Engine.get_main_loop().get_current_scene().get_node("Battle")
		Battle_Scene.add_child(Card_Selector)
		Card_Selector.Determine_Card_List("All MedBays", "AllMedBays", "MedBay")
		Card_Selector.Set_Effect_Card(card)

		# Wait for the Confirm signal to be emitted using await
		await SignalBus.Confirm

		# Get Chosen Target
		var Chosen_Card = Card_Selector.Get_Card()

		# Find original copy of Chosen_Card
		var Chosen_Card_Node = null
		var Side = "W" if GameData.Current_Turn == "Player" else "B"
		var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
		var Source_MedBay = null
		var Destination_Hand = Battle_Scene.get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")
		for i in range(len(MedBay)):
			if MedBay[i].name == Chosen_Card.name:
				Chosen_Card_Node = MedBay[i]
				Source_MedBay = Battle_Scene.get_node("Playmat/CardSpots/NonHands/" + Side + "MedBay")
				break
		if Chosen_Card_Node == null:
			for i in range(len(MedBay_Opp)):
				if MedBay_Opp[i].name == Chosen_Card.name:
					Chosen_Card_Node = MedBay_Opp[i]
					Source_MedBay = Battle_Scene.get_node("Playmat/CardSpots/NonHands/" + Side_Opp + "MedBay")
					break
		
		# Move Chosen_Card to proper hand
		Source_MedBay.remove_child(Chosen_Card_Node)
		Destination_Hand.add_child(Chosen_Card_Node)

		# Reparent Nodes
		var Destination_Node = get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side + "Graveyard")
		SignalBus.emit_signal("Reparent_Nodes", card, Destination_Node)

func Morale_Boost(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card and card.Can_Activate_Effect:
		var Card_Selector = load("res://Scenes/SupportScenes/Card_Selector.tscn").instantiate()
		var Battle_Scene = Engine.get_main_loop().get_current_scene().get_node("Battle")
		Battle_Scene.add_child(Card_Selector)
		Card_Selector.Determine_Card_List("Field", "TurnFighter", "Fighter")
		Card_Selector.Set_Effect_Card(card)

		# Wait for the Confirm signal to be emitted using await
		await SignalBus.Confirm

		# Get Chosen Target
		var Chosen_Card = Card_Selector.Get_Card()

		# Find original copy of Chosen_Card
		var Chosen_Card_Node
		var Fighter = Get_Field_Card_Data("Fighter")
		var Cards_On_Field = Get_Field_Card_Data("Reinforcers")
		if Fighter != null:
			Cards_On_Field.append(Fighter)

		for i in Cards_On_Field:
			if i.name == Chosen_Card.name:
				Chosen_Card_Node = i
				break

		# Resolve Effect
		if Chosen_Card_Node.Type == "Normal" or Chosen_Card_Node.Type == "Hero":
			Chosen_Card_Node.Attack += 1
			Chosen_Card_Node.Update_Data()

		# Reparent Nodes
		var Side = "W" if GameData.Current_Turn == "Player" else "B"
		var Destination_Node = get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side + "Graveyard")
		SignalBus.emit_signal("Reparent_Nodes", card, Destination_Node)

func Prayer(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card and card.Can_Activate_Effect:
		var Fighter = Get_Field_Card_Data("Fighter")
		var Fighter_Opp = Get_Field_Card_Data("Fighter Opponent")
		var roll_result = Dice_Roll(6)

		match roll_result:
			1:
				if Fighter_Opp != null:
					Fighter_Opp.Attack += 3
					Fighter_Opp.Update_Data()
			2:
				if Fighter != null:
					Fighter.Attack += 3
					Fighter.Update_Data()
			3:
				if Fighter_Opp != null:
					Fighter_Opp.Health = Fighter_Opp.Revival_Health
					Fighter_Opp.Update_Data()
			4:
				if Fighter != null:
					Fighter.Health = Fighter.Revival_Health
					Fighter.Update_Data()
			5:
				if Fighter != null:
					Fighter.Paralysis = true
			6:
				if Fighter != null:
					Fighter.Invincible = true

func Resurrection(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	
	if Valid_Card and card.Can_Activate_Effect:
		var Card_Selector = load("res://Scenes/SupportScenes/Card_Selector.tscn").instantiate()
		var Battle_Scene = Engine.get_main_loop().get_current_scene().get_node("Battle")
		Battle_Scene.add_child(Card_Selector)
		Card_Selector.Determine_Card_List("MedBay", "TurnMedBay")
		Card_Selector.Set_Effect_Card(card)

		# Wait for the Confirm signal to be emitted using await
		await SignalBus.Confirm

		# Get Chosen Target
		var Chosen_Card = Card_Selector.Get_Card()

		# Find original copy of Chosen_Card
		var Chosen_Card_Node
		var Side = "W" if GameData.Current_Turn == "Player" else "B"
		var Source_MedBay = Battle_Scene.get_node("Playmat/CardSpots/NonHands/" + Side + "MedBay")
		var Fighter_Open = true if Battle_Scene.get_node("Playmat/CardSpots/NonHands/" + Side + "Fighter").get_child_count() == 0 else false
		var R1_Open = true if Battle_Scene.get_node("Playmat/CardSpots/NonHands/" + Side + "R1").get_child_count() == 0 else false
		var R2_Open = true if Battle_Scene.get_node("Playmat/CardSpots/NonHands/" + Side + "R2").get_child_count() == 0 else false
		var R3_Open = true if Battle_Scene.get_node("Playmat/CardSpots/NonHands/" + Side + "R3").get_child_count() == 0 else false
		var Destination_Slot = "Fighter" if Fighter_Open else "R1" if R1_Open else "R2" if R2_Open else "R3" if R3_Open else "Hand"
		var Destination_Node = null
		if Destination_Slot != "Hand":
			Destination_Node = Battle_Scene.get_node("Playmat/CardSpots/NonHands/" + Side + Destination_Slot)
		else:
			Destination_Node = Battle_Scene.get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")
		for i in range(Source_MedBay.get_child_count()):
			if Source_MedBay.get_child(i).name == Chosen_Card.name:
				Chosen_Card_Node = Source_MedBay.get_child(i)
				break

		# Update MedBay/Hand
		Source_MedBay.remove_child(Chosen_Card_Node)
		Destination_Node.add_child(Chosen_Card_Node)

func Runetouched(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false

	if Valid_Card and card.Can_Activate_Effect:
		var Side = "W" if GameData.Current_Turn == "Player" else "B"
		var Dueler = BM.Player if GameData.Current_Turn == "Player" else BM.Enemy
		var Node_To_Update = get_tree().get_root().get_node("SceneHandler/Battle/HUD_" + Side)
		
		Dueler.Update_Cost_Discount_Magic(-1)

		SignalBus.emit_signal("Update_HUD_Duelist", Node_To_Update, Dueler)

func Sword(card):
	var Valid_Card = true if On_Field(card) && Resolvable_Card(card) && Valid_GameState(card) && Valid_Effect_Type(card) else false
	var Fighter = Get_Field_Card_Data("Fighter")

	if Valid_Card and Fighter != null and card.Can_Activate_Effect:
		Fighter.ATK_Bonus += 3
		Fighter.Update_Data()

"""--------------------------------- Tech Effects ---------------------------------"""
func Fire(card):
	if card.Can_Activate_Effect:
		var Side = "W" if GameData.Current_Turn == "Player" else "B"
		var Dueler = BM.Player if GameData.Current_Turn == "Player" else BM.Enemy
		var Node_To_Update = get_tree().get_root().get_node("SceneHandler/Battle/HUD_" + Side)

		Dueler.Field_Health_Bonus += 5

		SignalBus.emit_signal("Update_HUD_Duelist", Node_To_Update, Dueler)

func The_Wheel(card):	
	if card.Can_Activate_Effect:
		var Side = "W" if GameData.Current_Turn == "Player" else "B"
		var Dueler = BM.Player if GameData.Current_Turn == "Player" else BM.Enemy
		var Node_To_Update = get_tree().get_root().get_node("SceneHandler/Battle/HUD_" + Side)
		
		Dueler.Update_Cost_Discount_Normal(-1)
		Dueler.Update_Cost_Discount_Hero(-1)
		Dueler.Update_Cost_Discount_Magic(-1)
		Dueler.Update_Cost_Discount_Trap(-1)

		SignalBus.emit_signal("Update_HUD_Duelist", Node_To_Update, Dueler)


"""--------------------------------- Unused Effects ---------------------------------"""
func Cannon(card):
	pass

func Death_Ray(card):
	pass

func Fists(card):
	pass

func Gun(card):
	pass

func Missile_Launcher(card):
	pass

func Power_Up(card):
	pass

func Rock(card):
	pass

func Rocket_Launcher(card):
	pass
