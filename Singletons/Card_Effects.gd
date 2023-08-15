extends Node

func _ready():
	pass

func On_Field(card):
	var Parent_Name = card.get_parent().name
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Valid_Slots = [Side + "Fighter", Side + "R1", Side + "R2", Side + "R3"]
	
	if Valid_Slots.has(Parent_Name):
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

func Dice_Roll():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var roll_result = rng.randi_range(1,6)
	return roll_result

func Flip_Coin():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var flip_result = rng.randi_range(1,2)
	return flip_result

"""--------------------------------- Attribute Effects ---------------------------------"""
func Breakthrough(card): # Activate Tech (Special)
	pass

func Creature(card):
	pass

func Cryptid(card):
	pass

func Explorer(card):
	pass

func Mythological(card):
	pass

func Olympian(card):
	pass

func Outlaw(card):
	pass

func Philosopher(card):
	pass

func Politician(card):
	pass

func Ranged(card):
	pass

func Scientist(card):
	pass

func Spy(card):
	pass

func Support(card):
	pass

func Titan(card):
	pass

func Warrior(card):
	pass

func Wizard(card):
	pass


"""--------------------------------- Hero Effects ---------------------------------"""
func Conqueror(card):
	pass

func Juggernaut(card): # NOTE: This is just a strictly better effect than the current implementation of TailorMade (since it repeats every turn instead of just on summon)
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	if Side != card_current_owner:
		return
	
	if On_Field(card) and GameData.Current_Phase == "Standby Phase" and GameData.Current_Step == "Effect":
		card.ATK_Bonus += card.ATK_Bonus
		card.Update_Data()

func Invincibility(card):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	if Side != card_current_owner:
		return
	
	if On_Field(card) and card.Invincible == false:
		card.Invincible = true
	else:
		card.Invincible = false

func Paralysis(card):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	if Side != card_current_owner:
		return
	
	var Fighter_Opp = Get_Field_Card_Data("Fighter Opponent")
	
	if On_Field(card) and card.Effect_Active:
		if Fighter_Opp != null:
			Fighter_Opp.Paralysis = true

func Poison(card):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	if Side != card_current_owner:
		return
	
	var Fighter = Get_Field_Card_Data("Fighter")
	
	if On_Field(card) and card.Effect_Active and card == Fighter and GameData.Current_Step == "Damage":
		GameData.Target.Burn_Damage += card.Toxicity
		GameData.Target.Health -= GameData.Target.Burn_Damage
		GameData.Target.Update_Data()

func Relentless(card):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	if Side != card_current_owner:
		return
	
	if On_Field(card) and card.Relentless == false:
		card.Relentless = true
	else:
		card.Relentless = false

func Barrage(card):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	if Side != card_current_owner:
		return
	
	if On_Field(card) and card.Multi_Strike == false:
		card.Multi_Strike = true
	else:
		card.Multi_Strike = false

func Retribution(card):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	if Side != card_current_owner:
		return
		
	var player = GameData.Player if GameData.Current_Turn == "Enemy" else GameData.Enemy
	var Fighter_Opp = Get_Field_Card_Data("Fighter") # Not "Fighter Opponent" since this effect will occur during opponent's turn!
	
	if On_Field(card) and GameData.Cards_Captured_This_Turn.size() > 0 and GameData.Current_Phase == "End Phase" and GameData.Current_Step == "Effect":
		Fighter_Opp.Health -= (card.Attack + card.ATK_Bonus + player.Field_ATK_Bonus)
		Fighter_Opp.Update_Data()

func Fury(card):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	if Side != card_current_owner:
		return
		
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	
	if On_Field(card) and card.Effect_Active:
		card.Effect_Active = false
		var MedBay_Count = player.MedicalBay.size()
		print(card.ATK_Bonus)
		card.ATK_Bonus += MedBay_Count
		print(card.ATK_Bonus)
		card.Update_Data()

func Guardian(card):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	
	if Side != card_current_owner:
		return
	
	var enemy = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	var Reinforcers = Get_Field_Card_Data("Reinforcers Opponent")
	
	if On_Field(card) and GameData.Current_Step == "Damage" and GameData.Target in Reinforcers:
		GameData.Target.Health += (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + enemy.Field_ATK_Bonus)
		GameData.Attacker.Health -= (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + enemy.Field_ATK_Bonus)
		GameData.Target.Update_Data()
		GameData.Attacker.Update_Data()

func Absorption(card):
	pass

func Expansion(card):
	pass

func Spawn(card):
	pass

func Reincarnation(card):
	pass

func Reformation(card):
	pass

func Detonate(card):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	if Side != card_current_owner:
		return
		
	if On_Field(card):
		GameData.Auto_Spring_Traps = true
		var Trap_Cards = Get_Field_Card_Data("Traps")
		var Battle_Script = load("res://Scripts/Battle.gd").new()
		for i in range(len(Trap_Cards)):
			Battle_Script.Activate_Set_Card(Side, Trap_Cards[i])
	else:
		GameData.Auto_Spring_Traps = false

func Defiance(card):
	pass

func For_Honor_And_Glory(card):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	if Side != card_current_owner:
		return
	
	var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
	var MedBay = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side + "MedBay")
	var MedBay_Opp = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Opp + "MedBay")
	var Reinforcers = Get_Field_Card_Data("Reinforcers")
	var Reinforcers_Opp = Get_Field_Card_Data("Reinforcers Opponent")
	
	if On_Field(card):
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

func Humiliator(card):
	pass

func Counter(card):
	pass

func Perfect_Copy(card):
	pass

func Mimic(card):
	pass

func Taunt(card):
	pass

func Disorient(card):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	if Side != card_current_owner:
		return
	
	var Fighter_Opp = Get_Field_Card_Data("Fighter Opponent")
	var Reinforcers_Opp = Get_Field_Card_Data("Reinforcers Opponent")
	
	if Fighter_Opp != null:
		if On_Field(card) and Reinforcers_Opp.size() > 0 and GameData.Current_Step == "Selection":
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

func Behind_Enemy_Lines(card): # Name changed from Moonshot to be more descriptive of actual function.
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	if Side != card_current_owner:
		return

	if On_Field(card) and card.Direct_Attack == false:
		card.Direct_Attack = true
	elif On_Field(card) == false:
		card.Direct_Attack = false

func Atrocity(card):
	pass

func Earthbound(card):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	if Side != card_current_owner:
		return
	
	if On_Field(card) and GameData.Muggle_Mode == false:
		GameData.Muggle_Mode = true
	else:
		GameData.Muggle_Mode = false

func Tailor_Made(card): # Currently just doubles ATK_Bonus when summoned (instead of Equip-specific stat boosts, like Hephestus' effect did originally). Eric claims more thinking needs to be done on this effect due to lameness.
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	if Side != card_current_owner:
		return
	
	if On_Field(card) and card.Effect_Active:
		card.Effect_Active = false
		card.ATK_Bonus += card.ATK_Bonus
		card.Update_Data()

func Faithful(card):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	if Side != card_current_owner:
		return
	
	var Reinforcers = Get_Field_Card_Data("Reinforcers")
	
	if On_Field(card) and Reinforcers.size() >= 3 and card.Immortal == false:
		card.Immortal = true
	else:
		card.Immortal = false

func Inspiration(card):
	pass


"""--------------------------------- Magic/Trap Effects ---------------------------------"""
