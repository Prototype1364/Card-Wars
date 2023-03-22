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

func c42489363(card): # Activate Tech (Special)
	pass

func c61978912(card): # King Arthur (Hero)
	pass

func c26432104(card): # Merlin (Hero)
	pass

func c79248843(card): # Knight of the Round Table (Hero)
	pass

func c28269385(card): # Morgan le Fay (Hero)
	pass

func c67892655(card): # Lancelot (Hero)
	pass

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
	pass

func c42151268(card): # Blade Song (Magic)
	pass

func c39573503(card): # Runetouched (Magic)
	pass

func c74496062(card): # Miraculous Recovery (Magic)
	pass

func c73282505(card): # Heart of the Underdog (Trap)
	pass

func c58494934(card): # Disable (Trap/Equip)
	pass

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
	pass

func c68754341(card): # Prayer (Magic)
	pass

func c68535761(card): # Ressurection (Magic)
	pass

func c83893341(card): # Deep Pit (Trap)
	pass

func c30093650(card): # Fire (Tech)
	pass
