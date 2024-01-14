extends Control

var Name
var Frame
var Type
var Effect_Type
var Anchor_Text
var Resolve_Side
var Resolve_Phase
var Resolve_Step
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

func _ready(Base = "TurnMainDeck", Card_Index = -1):
	Set_Card_Variables(Card_Index, Base)
	Set_Card_Visuals()
	Update_Data()

func Can_Attack() -> bool:
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
	var enemy = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	
	var card_sources = {
	"TurnHand": player.Hand,
	"TurnMainDeck": player.Deck,
	"TurnTechDeck": player.Tech_Deck,
	"NonTurnHand": enemy.Hand,
	"NonTurnMainDeck": enemy.Deck,
	"NonTurnTechDeck": enemy.Tech_Deck}

	if card_sources.has(Source):
		Name = card_sources[Source][Card_Index].Name
		Frame = card_sources[Source][Card_Index].Frame
		Type = card_sources[Source][Card_Index].Type
		Effect_Type = card_sources[Source][Card_Index].Effect_Type
		Anchor_Text = card_sources[Source][Card_Index].Anchor_Text
		Resolve_Side = card_sources[Source][Card_Index].Resolve_Side
		Resolve_Phase = card_sources[Source][Card_Index].Resolve_Phase
		Resolve_Step = card_sources[Source][Card_Index].Resolve_Step
		Art = load(card_sources[Source][Card_Index].Art) if card_sources[Source][Card_Index].Art != "res://Assets/Cards/Art/Special_Activate_Technology.png" else null
		Attribute = card_sources[Source][Card_Index].Attribute
		Description = card_sources[Source][Card_Index].Description
		Short_Description = card_sources[Source][Card_Index].Short_Description
		Attacks_Remaining = card_sources[Source][Card_Index].Attacks_Remaining
		Attack = card_sources[Source][Card_Index].Attack if card_sources[Source][Card_Index].Attack != null else ""
		ATK_Bonus = card_sources[Source][Card_Index].ATK_Bonus
		Toxicity = card_sources[Source][Card_Index].Toxicity
		Cost = card_sources[Source][Card_Index].Cost
		Health = card_sources[Source][Card_Index].Health if card_sources[Source][Card_Index].Health != null else ""
		Health_Bonus = card_sources[Source][Card_Index].Health_Bonus
		Burn_Damage = card_sources[Source][Card_Index].Burn_Damage
		Revival_Health = Health
		Special_Edition_Text = card_sources[Source][Card_Index].Special_Edition_Text
		Rarity = card_sources[Source][Card_Index].Rarity
		Passcode = card_sources[Source][Card_Index].Passcode
		Deck_Capacity = card_sources[Source][Card_Index].Deck_Capacity
		Tokens = card_sources[Source][Card_Index].Tokens
		Is_Set = card_sources[Source][Card_Index].Is_Set
		Effect_Active = card_sources[Source][Card_Index].Effect_Active
		Fusion_Level = card_sources[Source][Card_Index].Fusion_Level
		Attack_As_Reinforcement = card_sources[Source][Card_Index].Attack_As_Reinforcement
		Immortal = card_sources[Source][Card_Index].Immortal
		Invincible = card_sources[Source][Card_Index].Invincible
		Relentless = card_sources[Source][Card_Index].Relentless
		Multi_Strike = card_sources[Source][Card_Index].Multi_Strike
		Paralysis = card_sources[Source][Card_Index].Paralysis
		Direct_Attack = card_sources[Source][Card_Index].Direct_Attack
		Owner = card_sources[Source][Card_Index].Owner
		
	if Source == "Tech":
		Cost_Path = null
	else:
		Cost_Path = load("res://Assets/Cards/Cost/Small/Small_Cost_" + Frame + "_" + str(Cost) + ".png") if card_sources[Source][Card_Index].Type != "Special" else null

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

func Reset_Variables_After_Flip_Summon():
	Is_Set = false
	Effect_Active = false # Ensures effects aren't triggered from Graveyard.
	Tokens = 0
	Update_Token_Info()

func Add_Token():
	if Type == "Trap" and "Backrow" in get_parent().name:
		Tokens += 1

func Update_Token_Info():
	var Token_Container = $TokenContainer/VBoxContainer
	if Token_Container.get_child_count() < Tokens: # Add Token(s) up to the number of Tokens on the card
		for _i in range(Tokens - Token_Container.get_child_count()):
			var InstanceToken = Token_Path.instantiate()
			InstanceToken.name = "Token" + str(Token_Container.get_child_count() + 1)
			Token_Container.add_child(InstanceToken)
	elif Token_Container.get_child_count() > Tokens: # Remove excess Token(s)
		while Token_Container.get_child_count() > Tokens:
			var i = Token_Container.get_child(Token_Container.get_child_count() - 1)
			Token_Container.remove_child(i)
			i.queue_free()

func focusing():
	GameData.FocusedCardName = self.name
	GameData.FocusedCardParentName = self.get_parent().name
	SignalBus.emit_signal("LookAtCard", self, Frame, Art, Name, Attack, Cost, Health, Attribute)

func defocusing():
	GameData.FocusedCardName = ""
	GameData.FocusedCardParentName = ""
	SignalBus.emit_signal("NotLookingAtCard")

func _on_FocusSensor_pressed(): # FIXME: Might need to be split into multiple functions to follow SOLID Principles
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Reposition_Zones = [Side + "Fighter", Side + "R1", Side + "R2", Side + "R3"]
	var Reinforcement_Zones = [Side + "R1", Side + "R2", Side + "R3"]
	var Parent_Name = self.get_parent().name
	
	match GameData.Current_Step:
		"Main":
			# Allows for Normal/Fusion summoning while skipping the need to press Summon/Set buttons when playing Normal/Hero card
			if "Hand" in Parent_Name and (Type == "Normal" or Type == "Hero"):
				GameData.Summon_Mode = "Summon"
				GameData.Chosen_Card = self
				if int(Passcode) in GameData.FUSION_CARDS: # Fusion summon
					GameData.Current_Card_Effect_Step = "Clicked"
					CardEffects.call(Anchor_Text, self)
			elif "Hand" in Parent_Name:
				$Action_Button_Container/Summon.visible = true
				$Action_Button_Container/Set.visible = true
			elif Parent_Name in Reposition_Zones and GameData.Chosen_Card == null:
				GameData.Chosen_Card = self
			elif "Effect_Target_List" in Parent_Name: # For Card Selector scene
				SignalBus.emit_signal("EffectTargetSelected", self)
		"Selection":
			if Valid_Attacker_Selection(Reposition_Zones, Reinforcement_Zones, Parent_Name, Side):
				GameData.Attacker = self
				SignalBus.emit_signal("Check_For_Targets")
		"Target":
			if ("Fighter" in Parent_Name and (Parent_Name.left(1) != Side)) or (("R1" in Parent_Name or "R2" in Parent_Name or "R3" in Parent_Name) and GameData.Attacker.Target_Reinforcer):
				$Action_Button_Container/Target.visible = true
		"Discard":
			GameData.CardFrom = Parent_Name
			GameData.CardMoved = self.name
			if "Hand" in GameData.CardFrom:
				SignalBus.emit_signal("Discard_Card", GameData.CardFrom.left(1))
	
	# Allows repositioning of cards on own field
	if Reposition_Zones.has(Parent_Name) and GameData.Current_Step == "Main":
		if GameData.CardFrom == "":
			GameData.CardFrom = Parent_Name
			GameData.CardMoved = self.name
		elif GameData.CardFrom != "":
			GameData.CardTo = self.get_parent()
			GameData.CardSwitched = self.name
			SignalBus.emit_signal("Reposition_Field_Cards", GameData.CardTo.name.left(1))
	
	# Allows Flip summoning of cards from backrow
	elif Side + "Backrow" in Parent_Name and GameData.Current_Step == "Main":
		$Action_Button_Container/Summon.text = "Flip"
		$Action_Button_Container/Summon.visible = true
		GameData.CardFrom = Parent_Name
		GameData.CardMoved = self.name

func Valid_Attacker_Selection(Reposition_Zones, Reinforcement_Zones, Parent_Name, Side) -> bool:
	if (Reposition_Zones[0] in Parent_Name or (Attack_As_Reinforcement == true and Reinforcement_Zones.has(Parent_Name))) and Parent_Name.left(1) == Side and Paralysis == false:
		return true
	else:
		return false

func _on_Summon_Set_pressed(Mode):
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
			SignalBus.emit_signal("Summon_Set_Pressed", slot_name)
	
	elif "Hand" in Parent_Name and Mode == "Set":
		GameData.Summon_Mode = "Set"
		self.Is_Set = true
	
	elif "Backrow" in Parent_Name and Mode == "Summon":
		$Action_Button_Container/Summon.text = "Summon"
		SignalBus.emit_signal("Activate_Set_Card", Side, self)
	
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
