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

func Juggernaut(card):
	pass

func Invincibility(card):
	pass

func Paralysis(card):
	var Fighter_Opp = Get_Field_Card_Data("Fighter Opponent")
	
	if On_Field(card) and card.Effect_Active and Fighter_Opp.size() > 0:
		Fighter_Opp.Paralysis = true

func Poison(card):
	var Fighter = Get_Field_Card_Data("Fighter")
	
	if On_Field(card) and card.Effect_Active and card in Fighter and GameData.Current_Step == "Damage":
		GameData.Target.Burn_Damage += card.Toxicity
		GameData.Target.Update_Data()

func Relentless(card):
	if On_Field(card) and card.Effect_Active and card.Relentless == false:
		card.Relentless = true
	else:
		card.Relentless = false

func Barrage(card):
	if On_Field(card) and card.Effect_Active and card.Multi_Strike == false:
		card.Multi_Strike = true

func Retribution(card):
	var player = GameData.Player if GameData.Current_Turn == "Enemy" else GameData.Enemy
	var Fighter_Opp = Get_Field_Card_Data("Fighter") # Not "Fighter Opponent" since this effect will occur during opponent's turn!

	if On_Field(card) and GameData.Cards_Captured_This_Turn.size() > 0 and GameData.Current_Phase == "End Phase" and GameData.Current_Step == "Effect":
		Fighter_Opp.Health -= (card.Attack + card.ATK_Bonus + player.Field_ATK_Bonus)
		Fighter_Opp.Update_Data()

func Fury(card):
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	
	if On_Field(card) and card.Effect_Active:
		card.Effect_Active = false
		var MedBay_Count = player.MedicalBay.size()
		card.ATK_Bonus += MedBay_Count
		card.Update_Data()

func Guardian(card):
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
	if On_Field(card):
		GameData.Auto_Spring_Traps = true
	else:
		GameData.Auto_Spring_Traps = false

func Defiance(card):
	pass

func For_Honor_And_Glory(card):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
	var MedBay = get_node("/root/Battle/Playmat/CardSpots/NonHands" + Side + "MedBay")
	var MedBay_Opp = get_node("/root/Battle/Playmat/CardSpots/NonHands" + Side_Opp + "MedBay")
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
	var Fighter_Opp = Get_Field_Card_Data("Fighter Opponent")
	var Reinforcers_Opp = Get_Field_Card_Data("Reinforcers Opponent")
	
	if On_Field(card) and card.Effect_Active and Fighter_Opp.size() > 0 and Reinforcers_Opp.size() > 0:
		# Randomly Choose Replacement Reinforcer
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		var roll_result = rng.randi_range(1,Reinforcers_Opp.size())
		
		# Reparent Nodes
		var Fighter_Parent = Fighter_Opp.get_parent()
		var Reinforcer_Parent = Reinforcers_Opp[roll_result].get_parent()
		Fighter_Parent.remove_child(Fighter_Opp)
		Reinforcer_Parent.remove_child(Reinforcers_Opp[roll_result])
		Fighter_Parent.add_child(Reinforcers_Opp[roll_result])
		Reinforcer_Parent.add_child(Fighter_Opp)

func Moonshot(card):
	if On_Field(card) and card.Effect_Active and card.Direct_Attack == false:
		card.Direct_Attack = true

func Atrocity(card):
	pass

func Earthbound(card):
	if On_Field(card) and GameData.Muggle_Mode == false:
		GameData.Muggle_Mode = true
	else:
		GameData.Muggle_Mode = false

func TailorMade(card): # Currently just doubles ATK_Bonus (instead of Equip-specific stat boosts, like Hephestus' effect did originally). Eric claims more thinking needs to be done on this effect due to lameness.
	if On_Field(card) and card.Effect_Active:
		card.Effect_Active = false
		card.ATK_Bonus += card.ATK_Bonus
		card.Update_Data()

func Faithful(card):
	var Reinforcers = Get_Field_Card_Data("Reinforcers")
	
	if On_Field(card) and Reinforcers.size() >= 3 and card.Immortal == false:
		card.Immortal = true
	else:
		card.Immortal = false

func Inspiration(card):
	pass
