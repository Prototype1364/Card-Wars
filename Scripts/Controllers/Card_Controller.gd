extends Control

class_name Card

# Member variables
@onready var BM = get_tree().get_root().get_node("SceneHandler/Battle")
var Frame: String
var Art: String
var Name: String
var Type: String
var Effect_Type: String
var Anchor_Text: String
var Resolve_Side: String
var Resolve_Phase: String
var Resolve_Step: String
var Attribute: String
var Description: String
var Short_Description: String
var Attacks_Remaining: int
var Attack: int
var ATK_Bonus: int # Used to keep track of Equip card bonuses specifically.
var Total_Attack: int
var Toxicity: int # The amount of Burn_Damage per turn you add to the Target card's Burn_Damage variable.
var Cost: int
var Cost_Path: String
var Health: int
var Health_Bonus: int # Used to keep track of Equip card bonuses specifically.
var Total_Health: int
var Burn_Damage: int # Damage taken by card each turn due to Poison (and other) burn-damage style ailments.
var Revival_Health: int # HP that a card resets to upon Capture.
var Special_Edition_Text: String
var Rarity: String
var Passcode: int
var Deck_Capacity: int
var Tokens: int
var Token_Path: Resource
var Is_Set: bool
var Can_Activate_Effect: bool # Primarily used to determine if cards with Summon Effects have been activitated to ensure they don't trigger each turn.
var Fusion_Level: int # Refers to the number of cards it is Fused with (defaults to 1 as it'll allow for easier multiplication of Attack/Health stats). Knights of the Round Table is the first card to have this ability.
var Attack_As_Reinforcement: bool # Refers to a card's ability to launch an attack from a Reinforcement slot. Mongols (when led by Ghenghis Khan) is the first card to have this ability.
var Immortal: bool # Refers to whether a card can be captured with 0 HP. Demeter (in SAP version) is the first card to have this effect.
var Invincible: bool # Refers to a card that cannot take Battle Damage. It must be defeated by a Hero/Magic/Trap/Tech card's effects. "The Level Beyond" is the first card to have this ability.
var Relentless: bool # Refers to a card that gains double bonus on any alteration to its Attacks_Remaining variable (including the turn reset). King Leonidas was the first card to have this ability.
var Multi_Strike: bool # Refers to a card's ability to deal damage to cards in the opponent's Reinforcement zone (Zeus is the first card to have this ability).
var Target_Reinforcer: bool # Refers to a card's ability to choose to target an opponent in a reinforcement slot instead of the opposing Fighter (Poseidon is the first card to have this ability).
var Paralysis: bool # Refers to a card's ability to launch an attack. Lancelot is the first card to utilize this Attribute (there's a 1/3 chance that his effect will result in him being unable to attack during that turn's Battle Phase).
var Direct_Attack: bool
var Effects_Disabled: Array # An Array of all effects disabled by this card.
var Owner: String # Refers to the card's original Owner (Player or Enemy). Used as part of Mordred's Hero card effect.
var Can_Attack: bool
var Targetable: bool # Refers to whether a card can be targeted by an attacking card.

# Initialization
func _init(Card_Frame, Card_Art, Card_Name, Card_Type, Card_EffectType, Card_Anchor_Text, Card_Resolve_Side, Card_Resolve_Phase, Card_Resolve_Step, Card_Attribute, Card_Description, Card_Short_Description, Card_Attack, Card_ATK_Bonus, Card_Toxicity, Card_Cost, Card_Health, Card_Health_Bonus, Card_Burn_Damage, Card_Special_Edition_Text, Card_Rarity, Card_Passcode, Card_Deck_Capacity, Card_Tokens, Card_Is_Set, Card_Can_Activate_Effect, Card_Fusion_Level, Card_Attack_As_Reinforcement, Card_Immortal, Card_Invincible, Card_Relentless, Card_Multi_Strike, Card_Target_Reinforcer, Card_Paralysis, Card_Direct_Attack, Card_Owner):
	Frame = Card_Frame
	Art = Card_Art
	Name = Card_Name
	Type = Card_Type
	Effect_Type = Card_EffectType
	Anchor_Text = Card_Anchor_Text
	Resolve_Side = Card_Resolve_Side
	Resolve_Phase = Card_Resolve_Phase
	Resolve_Step = Card_Resolve_Step
	Attribute = Card_Attribute
	Description = Card_Description if Card_Description != null else ""
	Short_Description = Card_Short_Description
	Attack = Card_Attack if Card_Attack != null else 0
	ATK_Bonus = Card_ATK_Bonus if Card_ATK_Bonus != null else 0
	Total_Attack = Attack + ATK_Bonus
	Cost = Card_Cost if Card_Cost != null else 0
	Cost_Path = ""
	if Type != "Special" and "Tech" not in Type:
		Cost_Path = "res://Assets/Cards/Cost/Small/Small_Cost_" + Frame + "_" + str(Cost) + ".png"
	Health = Card_Health if Card_Health != null else 0
	Health_Bonus = Card_Health_Bonus if Card_Health_Bonus != null else 0
	Total_Health = Health + Health_Bonus
	Revival_Health = Card_Health if Card_Health != null else 0
	Special_Edition_Text = Card_Special_Edition_Text
	Rarity = Card_Rarity
	Passcode = Card_Passcode
	Deck_Capacity = Card_Deck_Capacity
	Tokens = Card_Tokens
	Token_Path = preload("res://Scenes/SupportScenes/Token_Card.tscn")
	Is_Set = Card_Is_Set
	Can_Activate_Effect = Card_Can_Activate_Effect 
	Fusion_Level = Card_Fusion_Level
	Attack_As_Reinforcement = Card_Attack_As_Reinforcement
	Immortal = Card_Immortal
	Invincible = Card_Invincible
	Relentless = Card_Relentless
	Attacks_Remaining = 1 if Relentless == false else 2
	Multi_Strike = Card_Multi_Strike
	Target_Reinforcer = Card_Target_Reinforcer
	Paralysis = Card_Paralysis
	Direct_Attack = Card_Direct_Attack
	Toxicity = Card_Toxicity if Card_Toxicity != null else 0
	Burn_Damage = Card_Burn_Damage
	Effects_Disabled = []
	Owner = Card_Owner
	Can_Attack = false

func _ready():
	Update_Data()
	var _HV1 = $SmallCard/FocusSensor.pressed.connect(Callable(self, "on_FocusSensor_pressed"))
	var _HV2 = $SmallCard/Action_Button_Container/Target.pressed.connect(Callable(self, "_on_Target_pressed"))
	var _HV3 = $SmallCard/FocusSensor.gui_input.connect(Callable(self, "_on_Hide_Action_Buttons_pressed"))
	var _HV4 = $SmallCard/FocusSensor.mouse_entered.connect(Callable(self, "focusing"))
	var _HV5 = $SmallCard/FocusSensor.mouse_exited.connect(Callable(self, "defocusing"))
	var _HV6 = $SmallCard/Action_Button_Container/Summon.pressed.connect(Callable(self, "_on_Summon_Set_pressed").bind("Summon"))
	var _HV7 = $SmallCard/Action_Button_Container/Set.pressed.connect(Callable(self, "_on_Summon_Set_pressed").bind("Set"))


# Setters
func set_frame(frame: String):
	if "Deck" in get_parent().name:
		$SmallCard/Frame.texture = load("res://Assets/Cards/Frame/Small_Card_Back.png")
	else:
		if Frame != "Special":
			$SmallCard/Frame.texture = load("res://Assets/Cards/Frame/Small_Frame_" + frame + ".png")
		else:
			$SmallCard/Frame.texture = load("res://Assets/Cards/Frame/Small_Advance_Tech_Card.png")

func set_art():
	var Formatted_Name: String = Name.replace(" ", "_")
	var Equip_Card_Format: String = "Equip_" + Type + "_" + Formatted_Name if Attribute == "Equip" else Formatted_Name
	var Finalized_Name: String = Equip_Card_Format if Attribute == "Equip" else Type + "_" + Formatted_Name
	Art = "res://Assets/Cards/Art/" + Finalized_Name + ".png" if Type != "Special" else ""
	if "Deck" not in get_parent().name:
		if Frame != "Special":
			$SmallCard/ArtContainer/Art.texture = load(Art)
		else:
			$SmallCard/ArtContainer/Art.texture = null
	else:
		$SmallCard/ArtContainer/Art.texture = null

func set_attacks_remaining(value: int, role: String):
	if role == "Attack":
		Attacks_Remaining += value
	else:
		Attacks_Remaining = 1 if Relentless == false else 2

func set_attack(value: int, context: String = "Initialize"):
	if context == "Add":
		Attack -= value
	elif context == "Remove":
		Attack += value
	else:
		Attack = value
	set_total_attack()

func set_attack_bonus(value: int, context: String = "Initialize"):
	if get_parent().name in ["MedBay", "Graveyard", "Banished", "Deck"]:
		ATK_Bonus = 0
	else:
		if context == "Add":
			ATK_Bonus += value
		elif context == "Remove":
			ATK_Bonus -= value
		else:
			ATK_Bonus = value
	set_total_attack()

func set_total_attack(_value: int = 0, _context: String = "Initialize"):
	var Parent_Name: String = get_parent().name
	var Player_Field_Slot_Names: Array = ["WFighter", "WR1", "WR2", "WR3"]
	var Enemy_Field_Slot_Names: Array = ["BFighter", "BR1", "BR2", "BR3"]
	var Field_Bonus: int = 0
	if Parent_Name in Player_Field_Slot_Names or Parent_Name in Enemy_Field_Slot_Names:
		if Parent_Name.left(1) == "W":
			Field_Bonus = BM.Player.Field_ATK_Bonus
		else:
			Field_Bonus = BM.Enemy.Field_ATK_Bonus
	Total_Attack = (Attack * Fusion_Level) + ATK_Bonus + Field_Bonus
	if "Deck" not in get_parent().name:
		if Type == "Normal" or Type == "Hero":
			$SmallCard/Attack.text = str(max(0, Total_Attack))
		else:
			Total_Attack = 0
			$SmallCard/Attack.text = ""
	else:
		$SmallCard/Attack.text = ""

func set_cost(value: int):
	Cost = value
	if Type != "Special" and "Tech" not in Type and "Deck" not in get_parent().name and Cost > 0:
		$SmallCard/CostContainer/Cost.texture = load(Cost_Path)
	else:
		$SmallCard/CostContainer/Cost.texture = null

func set_cost_path(node_name: String):
	Cost_Path = "res://Assets/Cards/Cost/Small/Small_Cost_" + Frame + "_" + str(node_name) + ".png"

func set_health(value: int, context: String = "Initialize"):
	if context == "Add":
		Health -= value
	elif context == "Remove":
		Health += value
	elif context == "Capture":
		Health = Revival_Health
	else:
		Health = value
	set_total_health()

func set_health_bonus(value: int, context: String = "Initialize"):
	if get_parent().name in ["MedBay", "Graveyard", "Banished", "Deck"]:
		Health_Bonus = 0
	else:
		if context == "Add":
			Health_Bonus += value
		elif context == "Remove":
			Health_Bonus -= value
		else:
			Health_Bonus = value
	set_total_health()

func set_total_health():
	var Parent_Name: String = get_parent().name
	var Player_Field_Slot_Names: Array = ["WFighter", "WR1", "WR2", "WR3"]
	var Enemy_Field_Slot_Names: Array = ["BFighter", "BR1", "BR2", "BR3"]
	var Field_Bonus: int = 0
	if Parent_Name in Player_Field_Slot_Names or Parent_Name in Enemy_Field_Slot_Names:
		if Parent_Name.left(1) == "W":
			Field_Bonus = BM.Player.Field_Health_Bonus
		else:
			Field_Bonus = BM.Enemy.Field_Health_Bonus
	Total_Health = (Health * Fusion_Level) + Health_Bonus + Field_Bonus
	if "Deck" not in get_parent().name:
		if Type == "Normal" or Type == "Hero":
			if get_parent().name in ["MedBay", "Graveyard", "Banished", "Deck"]:
				$SmallCard/Health.text = str(max(0, Total_Health))
			else:
				$SmallCard/Health.text = str(max(0, Total_Health))
		else:
			Total_Health = 0
			$SmallCard/Health.text = ""
	else:
		$SmallCard/Health.text = ""

func set_burn_damage(value: int, context: String = "Initialize"):
	if get_parent().name in ["MedBay", "Graveyard", "Banished", "Deck"]:
		Burn_Damage = 0
	else:
		if context == "Add":
			Burn_Damage += value
		elif context == "Remove":
			Burn_Damage -= value
		else:
			Burn_Damage = value

func set_revival_health(_value: int):
	Revival_Health = Health

func set_tokens(value: int, context: String = "Initialize"):
	if context == "Add":
		Tokens += value
	elif context == "Remove":
		Tokens -= value
	else:
		Tokens = 0
	var Token_Container: VBoxContainer = $SmallCard/TokenContainer/VBoxContainer
	if Token_Container.get_child_count() < Tokens: # Add Token(s) up to the number of Tokens on the card
		for _i in range(Tokens - Token_Container.get_child_count()):
			var InstanceToken: Node = Token_Path.instance()
			InstanceToken.name = "Token" + str(Token_Container.get_child_count() + 1)
			Token_Container.add_child(InstanceToken)
	elif Token_Container.get_child_count() > Tokens: # Remove excess Token(s)
		while Token_Container.get_child_count() > Tokens:
			var i: Node = Token_Container.get_child(Token_Container.get_child_count() - 1)
			Token_Container.remove_child(i)
			i.queue_free()

func set_is_set(_value: bool, context: String = "Initialize"):
	if context == "Set":
		Is_Set = true
	else:
		Is_Set = false

func set_can_activate_effect(_value: bool):
	var Parent_Name: String = get_parent().name
	var Side: String = "W" if GameData.Current_Turn == "Player" else "B"
	var Resolvable_Side: bool = true if Resolve_Side == "Both" or Side == Parent_Name.left(1) else false
	
	if Parent_Name in ["Fighter", "R1", "R2", "R3", "Backrow1", "Backrow2", "Backrow3"]: # Card is on field
		if Is_Set == false: # Ensures that set magic/trap cards don't have their ability to activate effects disabled.            
			if Resolvable_Side: # Ensures that the card can only set its ability to activate effects when on the valid side of the field.
				if Effect_Type == "Summon": # Ensures that cards with Summon effects can only activate their effects once (on initial summon), while allowing periodic/event/continuous effects to resolve multiple times.
					Can_Activate_Effect = false
				else:
					Can_Activate_Effect = true
	else: # Card is NOT on field and thus cannot activate effects.
		Can_Activate_Effect = false

func set_fusion_level(value: int, context: String = "Initialize"):
	if context == "Add":
		Fusion_Level += value
	elif context == "Remove":
		Fusion_Level -= value
	else:
		Fusion_Level = 1
	set_total_attack()
	set_total_health()

func set_effects_disabled(value: Array, context: String = "Initialize"):
	if context == "Initialize":
		Effects_Disabled = value
	else:
		if context == "Add":
			Effects_Disabled.append(value)
		elif context == "Remove":
			Effects_Disabled.erase(value)
		elif context == "Reset":
			Effects_Disabled.clear()
		else:
			Effects_Disabled = value

func set_can_attack():
	var Side: String = "W" if GameData.Current_Turn == "Player" else "B"
	var Reinforcement_Zones: Array = ["R1", "R2", "R3"]
	var Parent_Name: String = get_parent().name
	if ("Fighter" in Parent_Name or (Attack_As_Reinforcement and Reinforcement_Zones.has(Parent_Name))) and Parent_Name.left(1) == Side and Paralysis == false and Attacks_Remaining > 0:
		Can_Attack = true
	else:
		Can_Attack = false

func set_targetable(attacking_card: Node):
	var Reinforcement_Zones: Array = ["R1", "R2", "R3"]
	var Parent_Name: String = get_parent().name

	if "Fighter" in Parent_Name or (Parent_Name in Reinforcement_Zones and (attacking_card.Multi_Strike == true or attacking_card.Target_Reinforcer == true)):
		Targetable = true
	else:
		Targetable = false

# Primary Functions
func Update_Data():
	set_frame(Frame)
	set_art()
	set_attack(Attack)
	set_cost(Cost)
	set_health(Health)
	set_tokens(Tokens)

func Reset_Stats_On_Capture():
	set_attack(Attack)
	set_attack_bonus(0)
	set_health(0, "Capture")
	set_health_bonus(0)
	set_burn_damage(0)

func Valid_Attacker_Selection(Reposition_Zones, Reinforcement_Zones, Parent_Name, Side) -> bool:
	if (Reposition_Zones[0] in Parent_Name or (Attack_As_Reinforcement == true and Reinforcement_Zones.has(Parent_Name))) and Parent_Name.left(1) == Side and Paralysis == false:
		return true
	else:
		return false

func Update_Attacks_Remaining(Role):
	if Role == "Attack":
		Attacks_Remaining -= 1
	else:
		Attacks_Remaining = 1 if Relentless == false else 2

func Get_Total_Health():
	var Dueler = null
	Total_Health = 0
	var Parent_Name = self.get_parent().name
	var Player_Field_Slot_Names = ["WFighter", "WR1", "WR2", "WR3"]
	var Enemy_Field_Slot_Names = ["BFighter", "BR1", "BR2", "BR3"]
	
	if Parent_Name in Player_Field_Slot_Names:
		Dueler = BM.Player
	elif Parent_Name in Enemy_Field_Slot_Names:
		Dueler = BM.Enemy

	if Dueler != null:
		Total_Health = Health + Health_Bonus + Dueler.Field_Health_Bonus
	else:
		Total_Health = Health + Health_Bonus

	return Total_Health

# Signal-Related Functions
func focusing():
	GameData.FocusedCardName = self.name
	GameData.FocusedCardParentName = self.get_parent().name
	if "Deck" not in self.get_parent().name:
		SignalBus.emit_signal("LookAtCard", self, Frame, Art, Name, Cost, Attribute)

func defocusing():
	GameData.FocusedCardName = ""
	GameData.FocusedCardParentName = ""
	SignalBus.emit_signal("NotLookingAtCard")

func on_FocusSensor_pressed(): # FIXME: Might need to be split into multiple functions to follow SOLID Principles
	var Side: String = "W" if GameData.Current_Turn == "Player" else "B"
	var Reposition_Zones: Array = [Side + "Fighter", Side + "R1", Side + "R2", Side + "R3"]
	var Reinforcement_Zones: Array = [Side + "R1", Side + "R2", Side + "R3"]
	var Parent_Name: String = self.get_parent().name
	
	match GameData.Current_Step:
		"Main":
			# Allows for Normal/Fusion summoning while skipping the need to press Summon/Set buttons when playing Normal/Hero card
			if "Hand" in Parent_Name and (Type == "Normal" or Type == "Hero"):
				GameData.Summon_Mode = "Summon"
				GameData.Chosen_Card = self
				if int(Passcode) in GameData.FUSION_CARDS: # Fusion summon
					GameData.Current_Card_Effect_Step = "Clicked"
					CardEffects.call(Anchor_Text, self)
			elif "Hand" in Parent_Name and Type == "Trap":
				if self.Attribute == "Equip":
					$SmallCard/Action_Button_Container/Summon.visible = true
					$SmallCard/Action_Button_Container/Set.visible = false
				else:
					$SmallCard/Action_Button_Container/Summon.visible = false
					$SmallCard/Action_Button_Container/Set.visible = true
			elif "Hand" in Parent_Name:
				$SmallCard/Action_Button_Container/Summon.visible = true 
				$SmallCard/Action_Button_Container/Set.visible = true
			elif Parent_Name in Reposition_Zones and GameData.Chosen_Card == null:
				GameData.Chosen_Card = self
			elif "Effect_Target_List" in Parent_Name: # For Card Selector scene
				SignalBus.emit_signal("EffectTargetSelected", self)
		"Selection":
			if Valid_Attacker_Selection(Reposition_Zones, Reinforcement_Zones, Parent_Name, Side):
				GameData.Attacker = self
				SignalBus.emit_signal("Check_For_Targets")
			elif "Effect_Target_List" in Parent_Name: # For Card Selector scene
				SignalBus.emit_signal("EffectTargetSelected", self)
		"Target":
			if ("Fighter" in Parent_Name and (Parent_Name.left(1) != Side)) or (("R1" in Parent_Name or "R2" in Parent_Name or "R3" in Parent_Name) and GameData.Attacker.Target_Reinforcer):
				$SmallCard/Action_Button_Container/Target.visible = true
			elif "Effect_Target_List" in Parent_Name: # For Card Selector scene
				SignalBus.emit_signal("EffectTargetSelected", self)
		"Discard":
			GameData.CardFrom = Parent_Name
			GameData.CardMoved = self.name
			if "Hand" in GameData.CardFrom:
				SignalBus.emit_signal("Discard_Card", GameData.CardFrom.left(1))
			elif "Effect_Target_List" in Parent_Name: # For Card Selector scene
				SignalBus.emit_signal("EffectTargetSelected", self)
	
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
		$SmallCard/Action_Button_Container/Summon.text = "Flip"
		$SmallCard/Action_Button_Container/Summon.visible = true
		GameData.CardFrom = Parent_Name
		GameData.CardMoved = self.name

	# Allows user to re-open card Effect scenes during turn
	if Parent_Name.left(1) == Side:
		CardEffects.call(Anchor_Text, self)

func _on_Summon_Set_pressed(Mode):
	var Side: String = "W" if GameData.Current_Turn == "Player" else "B"
	var Parent_Name: String = self.get_parent().name
	
	GameData.Chosen_Card = self
	
	if "Hand" in Parent_Name and Mode == "Summon":
		GameData.Summon_Mode = "Summon"
		# Automatically move Equip card to appropriate Equip slot
		if self.Attribute == "Equip":
			$SmallCard/Action_Button_Container/Summon.visible = false
			$SmallCard/Action_Button_Container/Set.visible = false
			var slot_name: String = Side + "Equip" + self.Type
			GameData.CardFrom = Parent_Name
			GameData.CardMoved = self.name
			SignalBus.emit_signal("Summon_Set_Pressed", slot_name)
		else:
			$SmallCard/Action_Button_Container/Summon.visible = false
			$SmallCard/Action_Button_Container/Set.visible = false
			SignalBus.emit_signal("Summon_Set_Pressed", "Backrow")
	
	elif "Hand" in Parent_Name and Mode == "Set":
		GameData.Summon_Mode = "Set"
		self.Is_Set = true
		$SmallCard/Action_Button_Container/Summon.visible = false
		$SmallCard/Action_Button_Container/Set.visible = false
		SignalBus.emit_signal("Summon_Set_Pressed", "Backrow")
	
	elif "Backrow" in Parent_Name and Mode == "Summon":
		$SmallCard/Action_Button_Container/Summon.visible = false
		$SmallCard/Action_Button_Container/Summon.text = "Summon"
		SignalBus.emit_signal("Activate_Set_Card", Side, self)

func _on_Target_pressed():
	GameData.Target = self
	$SmallCard/Action_Button_Container/Target.visible = false
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
		$SmallCard/Action_Button_Container/Summon.visible = false
		$SmallCard/Action_Button_Container/Set.visible = false
		$SmallCard/Action_Button_Container/Target.visible = false


# Card_Controller.gd:
	# 1) setter/getter funcs for all variables
	# 2) focusing() / defocusing() funcs
	# 3) _on_FocusSensor_pressed()
	# 4) card button related funcs (summon, set, target, hide)
	# 5) text editors for card stat transfers, etc.
	# 6) Add functions for setters that improved/replaced previous funcs (like Valid_Attacker_Selection, which is missing from this script intentionally.)
