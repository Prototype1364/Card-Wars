extends Node

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

func c42489363(card): # Activate Tech (Special)
	print(card.Name)

func c61978912(card): # King Arthur (Hero)
	print(card.Name)

func c26432104(card): # Merlin (Hero)
	print(card.Name)

func c79248843(card): # Knight of the Round Table (Hero)
	print(card.Name)

func c28269385(card): # Morgan le Fay (Hero)
	print(card.Name)

func c67892655(card): # Lancelot (Hero)
	print(card.Name)

func c22716806(card): # Mordred (Hero)
	print(card.Name)

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
	print(card.Name)

func c17369913(card): # Last Stand (Magic/Equip)
	print(card.Name)

func c42151268(card): # Blade Song (Magic)
	print(card.Name)

func c39573503(card): # Runetouched (Magic)
	print(card.Name)

func c74496062(card): # Miraculous Recovery (Magic)
	print(card.Name)

func c73282505(card): # Heart of the Underdog (Trap)
	print(card.Name)

func c58494934(card): # Disable (Trap/Equip)
	print(card.Name)

func c82697165(card): # The Wheel (Tech)
	print(card.Name)

func c50316560(card): # Hades (Hero)
	print(card.Name)

func c72430176(card): # Zeus (Hero)
	print(card.Name)

func c25486317(card): # Ares (Hero)
	print(card.Name)

func c47338587(card): # Aphrodite (Hero)
	print(card.Name)

func c93958804(card): # Hephaestus (Hero)
	print(card.Name)

func c34658370(card): # Poseidon (Hero)
	print(card.Name)

func c31289091(card): # Hera (Hero)
	print(card.Name)

func c80932559(card): # Demeter (Hero)
	print(card.Name)

func c96427990(card): # Athena (Hero)
	print(card.Name)

func c86042533(card): # Artemis (Hero)
	print(card.Name)

func c97850313(card): # Hermes (Hero)
	print(card.Name)

func c15996549(card): # Hestia (Hero)
	print(card.Name)

func c17171263(card): # Dionysus (Hero)
	print(card.Name)

func c68754341(card): # Prayer (Magic)
	print(card.Name)

func c68535761(card): # Ressurection (Magic)
	print(card.Name)

func c83893341(card): # Deep Pit (Trap)
	print(card.Name)

func c30093650(card): # Fire (Tech)
	print(card.Name)
