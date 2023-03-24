extends Node

var Has_Yielded = false

func _ready():
	pass

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

func Check_Yield_Status():
	if Has_Yielded == false:
		Has_Yielded = true
		return true
	else:
		return false

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


func c42489363(card): # Activate Tech (Special)
	pass

func c61978912(card): # King Arthur (Hero)
	pass

func c26432104(card): # Merlin (Hero)
	var Parent_Name = card.get_parent().name
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Valid_Slots = [Side + "R1", Side + "R2", Side + "R3"]
	var Fighter = Get_Field_Card_Data("Fighter")
	
	if Fighter != null:
		if Valid_Slots.has(Parent_Name) and GameData.Current_Phase == "Standby Phase" and GameData.Current_Step == "Effect" and Fighter.Name == "King Arthur":
			# Roll two dice, if sum of rolls is >= 8 & Merlin is reinforcing King Arthur, grant King Arthur Invincibility
			var Roll_1 = Dice_Roll()
			var Roll_2 = Dice_Roll()
			var Roll_Result = Roll_1 + Roll_2
			
			if Roll_Result >= 8:
				Fighter.Invincible = true
			else:
				Fighter.Invincible = false
			
			# Update Card Visuals
			card.Update_Data()

func c79248843(card): # Knight of the Round Table (Hero)
	pass

func c28269385(card): # Morgan le Fay (Hero)
	var Parent_Name = card.get_parent().name
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Valid_Slots = [Side + "Fighter", Side + "R1", Side + "R2", Side + "R3"]
	
	if Valid_Slots.has(Parent_Name) and GameData.Current_Phase == "Standby Phase" and GameData.Current_Step == "Effect":
		var Flip_Result = Flip_Coin()
		
		GameData.Yield_Mode = true
		
		# Check if card selected is first selection
		if Check_Yield_Status():
			Has_Yielded = false
			
			# Resolve card's Effect
			if Flip_Result == 1:
				yield(SignalBus, "Card_Effect_Selection_Yield_Release")
				GameData.ChosenCard.Health += 5
				GameData.ChosenCard.Update_Data()
			else:
				GameData.Resolve_On_Opposing_Card = true
				yield(SignalBus, "Card_Effect_Selection_Yield_Release")
				GameData.ChosenCard.Health -= 5
				GameData.ChosenCard.Update_Data()
				# Check for Capture
				if GameData.ChosenCard.Health <= 0:
					SignalBus.emit_signal("Capture_Card", GameData.ChosenCard, GameData.ChosenCard.get_parent())
			
			# Reset GameData variables for next card effect
			GameData.Yield_Mode = false
			GameData.Resolve_On_Opposing_Card = false
			GameData.ChosenCard = null

func c67892655(card): # Lancelot (Hero)
	var Parent_Name = card.get_parent().name
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Valid_Slots = [Side + "Fighter", Side + "R1", Side + "R2", Side + "R3"]
	var Field_Card_Names = []
	
	if Valid_Slots.has(Parent_Name) and GameData.Current_Phase == "Standby Phase" and GameData.Current_Step == "Effect":
		"""----------- Primary Effect -----------"""
		# If Lancelot is on the field and rolls a 1/6, resolve effect... otherwise reset paralysis status
		var Roll_Result = Dice_Roll()
		if Roll_Result == 1 or Roll_Result == 6:
			print("PARALYZED")
			card.Paralysis = true
			card.Attack += 3
		else:
			card.Paralysis = false
	
		"""----------- Secondary Effect -----------"""
		var Fighter = Get_Field_Card_Data("Fighter")
		var Reinforcers = Get_Field_Card_Data("Reinforcers")
		
		# Add Names of Normal/Hero cards on field to Field_Card Names
		Field_Card_Names.append(Fighter.Name)
		for i in range(len(Reinforcers)):
			Field_Card_Names.append(Reinforcers[i].Name)
		
		# Resolve effect when joined on the field by King Arthur
		if "King Arthur" in Field_Card_Names:
			card.Attack += 1
	
		# Update Card Visuals
		card.Update_Data()

func c22716806(card): # Mordred (Hero)
	pass

func c15178943(card): # Sword (Magic/Equip)
	var Fighter = Get_Field_Card_Data("Fighter")
	
	if Fighter != null and card.Effect_Active:
		if Fighter.Attribute == "Warrior":
			Fighter.ATK_Bonus += 3
			Fighter.Update_Data()
			card.Effect_Active = false

func c53003369(card): # Excalibur (Magic/Equip)
	if GameData.Current_Phase == "Main Phase" and (GameData.Current_Step == "Summon/Set" or GameData.Current_Step == "Flip") and card.Effect_Active:
		var Fighter = Get_Field_Card_Data("Fighter")
		if Fighter.Name == "King Arthur":
			card.Effect_Active = false
			var Reinforcers_Player = Get_Field_Card_Data("Reinforcers")
			var Fighter_Opponent = Get_Field_Card_Data("Fighter Opponent")
			var Reinforcers_Opponent = Get_Field_Card_Data("Reinforcers Opponent")
			
			Fighter.ATK_Bonus += 3
			Fighter.Update_Data()
			
			for i in range(len(Reinforcers_Player)):
				if Reinforcers_Player[i] != null and Reinforcers_Player[i].Attribute == "Warrior":
					Reinforcers_Player[i].ATK_Bonus += 3
					Reinforcers_Player[i].Update_Data()
			
			if Fighter_Opponent != null and Fighter_Opponent.Attribute == "Warrior":
				Fighter_Opponent.ATK_Bonus -= 2
				Fighter_Opponent.Update_Data()
			
			for i in range(len(Reinforcers_Opponent)):
				if Reinforcers_Opponent[i] != null and Reinforcers_Opponent[i].Attribute == "Warrior":
					Reinforcers_Opponent[i].ATK_Bonus -= 2
					Reinforcers_Opponent[i].Update_Data()

func c13925137(card): # Morale Boost (Magic/Equip)
	if "EquipMagic" in card.get_parent().name and card.Effect_Active:
		GameData.Yield_Mode = true
		card.Effect_Active = false
	
		# Check if card selected is first selection
		if Check_Yield_Status():
			yield(SignalBus, "Card_Effect_Selection_Yield_Release")
			Has_Yielded = false
			
			# Resolve card's Effect
			GameData.ChosenCard.Attack += 1
			GameData.ChosenCard.Update_Data()
			
			# Reset GameData variables for next card effect
			GameData.Yield_Mode = false
			GameData.ChosenCard = null

func c17369913(card): # Last Stand (Magic/Equip)
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var enemy = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	
	if "EquipMagic" in card.get_parent().name and card.Effect_Active:
		player.Field_ATK_Bonus += 5
	elif card in GameData.Cards_Captured_This_Turn:
		enemy.Field_ATK_Bonus -= 8
	
	card.Effect_Active = false

func c42151268(card): # Blade Song (Magic)
	pass

func c39573503(card): # Runetouched (Magic)
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	if card.Effect_Active:
		player.Cost_Discount_Magic -= 1
		card.Effect_Active = false

func c74496062(card): # Miraculous Recovery (Magic)
	pass

func c73282505(card): # Heart of the Underdog (Trap)
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Fighter_Path = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side + "Fighter")
	var Fighter
	var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
	var Fighter_Opp_Path = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Opp + "Fighter")
	var Fighter_Opp
	
	# Get Node of both Fighters for ATK stat comparison
	if Fighter_Path.get_child_count() > 0 and Fighter_Opp_Path.get_child_count() > 0:
		Fighter = Fighter_Path.get_child(0)
		Fighter_Opp = Fighter_Opp_Path.get_child(0)
	
		# Compare ATK stats, resolving effect if valid
		if (Fighter.Attack < Fighter_Opp.Attack and card.Tokens > 0) or (GameData.Auto_Spring_Traps and "Backrow" in card.get_parent().name):
			Fighter.Attack += 7
			Fighter.Update_Data()

func c58494934(card): # Disable (Trap/Equip)
	var Parent_Name = card.get_parent().name
	
	if "EquipTrap" in Parent_Name and card.Effect_Active:
		card.Effect_Active = false
		var Fighter_Opp = Get_Field_Card_Data("Fighter Opponent")
		if Fighter_Opp != null:
			Fighter_Opp.Paralysis = true

func c82697165(card): # The Wheel (Tech)
	pass

func c50316560(card): # Hades (Hero)
	pass

func c72430176(card): # Zeus (Hero)
	pass

func c25486317(card): # Ares (Hero)
	pass

func c47338587(card): # Aphrodite (Hero)
	pass

func c93958804(card): # Hephaestus (Hero)
	pass

func c34658370(card): # Poseidon (Hero)
	pass

func c31289091(card): # Hera (Hero)
	pass

func c80932559(card): # Demeter (Hero)
	pass

func c96427990(card): # Athena (Hero)
	pass

func c86042533(card): # Artemis (Hero)
	pass

func c97850313(card): # Hermes (Hero)
	pass

func c15996549(card): # Hestia (Hero)
	pass

func c17171263(card): # Dionysus (Hero)
	var Parent_Name = card.get_parent().name
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Valid_Slots = [Side + "Fighter", Side + "R1", Side + "R2", Side + "R3"]
	
	if Valid_Slots.has(Parent_Name):
		GameData.Auto_Spring_Traps = true
	else:
		GameData.Auto_Spring_Traps = false

func c68754341(card): # Prayer (Magic)
	pass

func c68535761(card): # Ressurection (Magic)
	pass

func c83893341(card): # Deep Pit (Trap)
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var player = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	
	# Activate Trap card if Opp summoned Fighter during Main Phase with 1+ Token on Trap card
	if (Side != card.get_parent().name.left(1) and Side + "Fighter" in GameData.CardTo and GameData.Current_Phase == "Main Phase" and card.Tokens > 0) or (GameData.Auto_Spring_Traps and "Backrow" in card.get_parent().name):
		# Defaults to capture "Fighter" instead of "Fighter Opponent" since it'll be the opposing player's turn when the trap is triggered (unless triggered automatically)
		var Card_Captured = Get_Field_Card_Data("Fighter") if GameData.Auto_Spring_Traps == false else Get_Field_Card_Data("Fighter Opponent")
		if Card_Captured != null and (Side == card.get_parent().name.left(1) or GameData.Auto_Spring_Traps == false):
			var Graveyard = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/BGraveyard") if GameData.Current_Turn == "Player" else get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/WGraveyard")
			if GameData.Auto_Spring_Traps:
				SignalBus.emit_signal("Capture_Card", Card_Captured, Card_Captured.get_parent(), "Normal")
			else:
				SignalBus.emit_signal("Capture_Card", Card_Captured, Card_Captured.get_parent(), "Inverted")
			
			# Move captured card to appropriate MedBay
			card.get_parent().remove_child(card)
			Graveyard.add_child(card)
			
			# Update Duelist's MedicalBay Array
			player.Graveyard.append(card)
			
			# Update Card Visuals
			card.Tokens = 0
			card.Update_Data()

func c30093650(card): # Fire (Tech)
	pass
