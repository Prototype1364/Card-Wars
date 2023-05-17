extends Control

var Name
var Frame
var Type
var Effect_Type
var Anchor_Text
var Art
var Attribute
var Description
var Short_Description
var Attacks_Remaining
var Attack
var ATK_Bonus
var Toxicity
var Cost
var Cost_Path
var Health
var Health_Bonus
var Burn_Damage
var Revival_Health # HP that a card resets to upon Capture
var Special_Edition_Text
var Rarity
var Passcode
var Deck_Capacity
var Tokens
var Token_Path = preload("res://Scenes/SupportScenes/Token_Card.tscn")
var Is_Set
var Effect_Active
var Fusion_Level
var Attack_As_Reinforcement
var Immortal
var Invincible
var Relentless
var Multi_Strike
var Target_Reinforcer
var Paralysis
var Direct_Attack
var Owner


func _ready(Base = "Normal", Card_Index = -1):
	Set_Card_Variables(Card_Index, Base)
	Set_Card_Visuals()
	Update_Data()

func Can_Attack():
	if Attacks_Remaining > 0 and ("Fighter" in get_parent().name or (Attack_As_Reinforcement and get_parent().name in ["R1", "R2", "R3"])):
		return true
	else:
		return false

func Update_Attacks_Remaining(Role):
	if Role == "Attack":
		Attacks_Remaining -= 1
	else:
		Attacks_Remaining = 1 if Relentless == false else 2

func Set_Card_Variables(Card_Index, Source):
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var Source_Deck = player.Tech_Deck if Source == "Tech" else player.Deck
	
	Name = Source_Deck[Card_Index].Name
	Frame = Source_Deck[Card_Index].Frame
	Type = Source_Deck[Card_Index].Type
	Effect_Type = Source_Deck[Card_Index].Effect_Type
	Anchor_Text = Source_Deck[Card_Index].Anchor_Text
	Art = load(Source_Deck[Card_Index].Art) if Source_Deck[Card_Index].Art != "res://Assets/Cards/Art/Special_Activate_Technology.png" else null
	Attribute = Source_Deck[Card_Index].Attribute
	Description = Source_Deck[Card_Index].Description
	Short_Description = Source_Deck[Card_Index].Short_Description
	Attacks_Remaining = Source_Deck[Card_Index].Attacks_Remaining
	Attack = Source_Deck[Card_Index].Attack if Source_Deck[Card_Index].Attack != null else ""
	ATK_Bonus = Source_Deck[Card_Index].ATK_Bonus
	Toxicity = Source_Deck[Card_Index].Toxicity
	Cost = Source_Deck[Card_Index].Cost
	Health = Source_Deck[Card_Index].Health if Source_Deck[Card_Index].Health != null else ""
	Health_Bonus = Source_Deck[Card_Index].Health_Bonus
	Burn_Damage = Source_Deck[Card_Index].Burn_Damage
	Revival_Health = Health
	Special_Edition_Text = Source_Deck[Card_Index].Special_Edition_Text
	Rarity = Source_Deck[Card_Index].Rarity
	Passcode = Source_Deck[Card_Index].Passcode
	Deck_Capacity = Source_Deck[Card_Index].Deck_Capacity
	Tokens = Source_Deck[Card_Index].Tokens
	Is_Set = Source_Deck[Card_Index].Is_Set
	Effect_Active = Source_Deck[Card_Index].Effect_Active
	Fusion_Level = Source_Deck[Card_Index].Fusion_Level
	Attack_As_Reinforcement = Source_Deck[Card_Index].Attack_As_Reinforcement
	Immortal = Source_Deck[Card_Index].Immortal
	Invincible = Source_Deck[Card_Index].Invincible
	Relentless = Source_Deck[Card_Index].Relentless
	Multi_Strike = Source_Deck[Card_Index].Multi_Strike
	Paralysis = Source_Deck[Card_Index].Paralysis
	Direct_Attack = Source_Deck[Card_Index].Direct_Attack
	Owner = Source_Deck[Card_Index].Owner
	
	if Source == "Tech":
		Cost_Path = null
	else:
		Cost_Path = load("res://Assets/Cards/Cost/Small/Small_Cost_" + Frame + "_" + str(Cost) + ".png") if player.Deck[Card_Index].Type != "Special" else null

func Set_Card_Visuals():
	if Frame != "Special":
		$Frame.texture = load("res://Assets/Cards/Frame/Small_Frame_" + Frame + ".png")
		$CostContainer/Cost.texture = Cost_Path
		$ArtContainer/Art.texture = Art
		$Attack.text = str(Attack)
		$Health.text = str(Health)
	else: # Card is the Advance Tech card (Has no Cost or custom Art).
		$Frame.texture = load("res://Assets/Cards/Frame/Small_Advance_Tech_Card.png")

func Update_Data():
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var Parent_Name = get_parent().name
	if Type == "Normal" or Type == "Hero":
		if Parent_Name in ["MedBay", "Graveyard", "Banished", "Deck"]:
			$Attack.text = str(max(0, Attack + ATK_Bonus))
			$Health.text = str(max(0, Health + Health_Bonus))
		else:
			$Attack.text = str(max(0, Attack + ATK_Bonus + player.Field_ATK_Bonus))
			$Health.text = str(max(0, Health + Health_Bonus + player.Field_Health_Bonus))
	
	# Add Token-related visuals to card
	Update_Token_Info()

func Reset_Stats_On_Capture():
	Attack = Attack * Fusion_Level
	ATK_Bonus = 0
	Health = Revival_Health * Fusion_Level
	Health_Bonus = 0
	Burn_Damage = 0

func Add_Token():
	if Type == "Trap" and "Backrow" in get_parent().name:
		Tokens += 1

func Update_Token_Info():
	var Token_Container = $TokenContainer/VBoxContainer
	if Token_Container.get_child_count() < Tokens:
		for _i in range(Tokens - Token_Container.get_child_count()):
			var InstanceToken = Token_Path.instantiate()
			InstanceToken.name = "Token" + str(Token_Container.get_child_count() + 1)
			Token_Container.add_child(InstanceToken)
	elif Token_Container.get_child_count() > Tokens:
		for i in Token_Container.get_children():
			Token_Container.remove_child(i)
			i.queue_free()
		for _i in range(Tokens - Token_Container.get_child_count()):
			var InstanceToken = Token_Path.instantiate()
			InstanceToken.name = "Token" + str(Token_Container.get_child_count() + 1)
			Token_Container.add_child(InstanceToken)

func focusing():
	GameData.FocusedCardName = self.name
	GameData.FocusedCardParentName = self.get_parent().name
	SignalBus.emit_signal("LookAtCard", self, Frame, Art, Name, Attack, Cost, Health, Attribute)

func defocusing():
	GameData.FocusedCardName = ""
	GameData.FocusedCardParentName = ""
	SignalBus.emit_signal("NotLookingAtCard")

func _on_FocusSensor_pressed():
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
	var Reposition_Zones = [Side + "Fighter", Side + "R1", Side + "R2", Side + "R3"]
	var Reposition_Zones_Opp = [Side_Opp + "Fighter", Side_Opp + "R1", Side_Opp + "R2", Side_Opp + "R3"]
	var Reinforcement_Zones = [Side + "R1", Side + "R2", Side + "R3"]
	var Parent_Name = self.get_parent().name
	
	match GameData.Current_Step:
		"Main":
			# Allows for Normal/Fusion summoning while skipping the need to press Summon/Set buttons when playing Normal/Hero card
			if "Hand" in Parent_Name and (Type == "Normal" or Type == "Hero"):
				GameData.Summon_Mode = "Summon"
				GameData.Chosen_Card = self
				if int(Passcode) in GameData.FUSION_CARDS:
					GameData.Current_Card_Effect_Step = "Clicked"
					CardEffects.call(Anchor_Text, self)
			else:
				$Action_Button_Container/Summon.visible = true
				$Action_Button_Container/Set.visible = true
		"Selection":
			if Valid_Attacker_Selection(Reposition_Zones, Reinforcement_Zones, Parent_Name, Side):
				GameData.Attacker = self
				SignalBus.emit_signal("Check_For_Targets")
		"Target":
			if ("Fighter" in Parent_Name and (Parent_Name.left(1) != Side) or (("R1" in Parent_Name or "R2" in Parent_Name or "R3" in Parent_Name) and GameData.Attacker.Target_Reinforcer)):
				$Action_Button_Container/Target.visible = true
		"Discard":
			GameData.CardFrom = Parent_Name
			GameData.CardMoved = self.name
			if "Hand" in GameData.CardFrom:
				SignalBus.emit_signal("Discard_Card", GameData.CardFrom.left(1))
	
	
	
	# Allows you to choose a card to receive effect benefits/penalties
	if (GameData.Yield_Mode and Reposition_Zones.has(Parent_Name) and (Type == "Normal" or Type == "Hero")) or (GameData.Yield_Mode and Reposition_Zones_Opp.has(Parent_Name) and (Type == "Normal" or Type == "Hero") and GameData.Resolve_On_Opposing_Card):
		GameData.Chosen_Card = self
		SignalBus.emit_signal("Card_Effect_Selection_Yield_Release", self)
	
		"""-----------------------------------------------------------------------------"""
	# Allows repositioning of cards on field (Currently doesn't allow for Exchange-like card effect [i.e. swapping 1 card of yours for one card of the opponent's on the field])
	if Reposition_Zones.has(Parent_Name) and GameData.Current_Step == "Main":
		if GameData.CardFrom == "":
			GameData.CardFrom = Parent_Name
			GameData.CardMoved = self.name
		elif GameData.CardFrom != "":
			GameData.CardTo = self.get_parent()
			GameData.CardSwitched = self.name
			SignalBus.emit_signal("Reposition_Field_Cards", GameData.CardTo.name.left(1))
		"""-----------------------------------------------------------------------------"""
	
	# Allows Flip summoning of cards from backrow
	elif "Backrow" in Parent_Name and GameData.Current_Step == "Main":
		$Action_Button_Container/Summon.text = "Flip"
		$Action_Button_Container/Summon.visible = true
		GameData.CardFrom = Parent_Name
		GameData.CardMoved = self.name

func Valid_Attacker_Selection(Reposition_Zones, Reinforcement_Zones, Parent_Name, Side):
	if (Reposition_Zones[0] in Parent_Name or (Attack_As_Reinforcement == true and Reinforcement_Zones.has(Parent_Name))) and Parent_Name.left(1) == Side and Paralysis == false:
		return true
	else:
		return false

func _on_Summon_Set_pressed(Mode):
	var Battle_Scene = load("res://Scenes/MainScenes/Battle.tscn").instantiate()
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Parent_Name = self.get_parent().name
	
	GameData.Chosen_Card = self
	
	if "Hand" in Parent_Name and Mode == "Summon":
		GameData.Summon_Mode = "Summon"
		# Automatically move Equip card to appropriate Equip slot
		if self.Attribute == "Equip":
			var slot_name = Side + "Equip" + self.Type
			GameData.CardFrom = Parent_Name
			GameData.CardMoved = self.name
			Battle_Scene._on_Card_Slot_pressed(slot_name)
	
	elif "Hand" in Parent_Name and Mode == "Set":
		GameData.Summon_Mode = "Set"
		self.Is_Set = true
	
	elif "Backrow" in Parent_Name and Mode == "Summon":
		$Action_Button_Container/Summon.text = "Summon"
		SignalBus.emit_signal("Activate_Set_Card", Side, self)
	
	elif "Hand" in Parent_Name and Mode == "Set":
		GameData.Summon_Mode = "Set"
		self.Is_Set = true
	
	GameData.CardFrom = Parent_Name
	GameData.CardMoved = self.name
	$Action_Button_Container/Summon.visible = false
	$Action_Button_Container/Set.visible = false

func _on_Target_pressed():
	GameData.Target = self
	$Action_Button_Container/Target.visible = false
	# Signal emitted twice to ensure that Damage Step is conducted following successful Target selection
	SignalBus.emit_signal("Update_GameState", "Step")
	SignalBus.emit_signal("Update_GameState", "Step")
	
	# If NO Capture happened, advance GameState (advance to Repeat Step happens automatically when card IS captured)
	if GameData.Current_Step == "Capture":
		if GameData.Attacks_To_Launch == 0:
			# Move to End Phase (no captures will happen following direct attack)
			SignalBus.emit_signal("Update_GameState", "Phase")
			# Attempt to End Turn (works if no discards are necessary)
			SignalBus.emit_signal("Update_GameState", "Turn")
		else:
			# Move to Repeat Step to prep for next attack
			SignalBus.emit_signal("Update_GameState", "Step")
	elif GameData.Current_Step == "Discard":
		# Attempt to End Turn
		SignalBus.emit_signal("Update_GameState", "Turn")

func _on_Hide_Action_Buttons_pressed(_event):
	if Input.is_action_pressed("Cancel"):
		$Action_Button_Container/Summon.visible = false
		$Action_Button_Container/Set.visible = false
		$Action_Button_Container/Target.visible = false
