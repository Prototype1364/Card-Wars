extends Control

class_name Card

# Member variables
@onready var BM = get_tree().get_root().get_node("SceneHandler/Battle")
@onready var BF = get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots")
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
var Base_Attack: int
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
var Rejuvenation: bool # Refers to a card that cannot take Burn Damage. It must be defeated by a Hero/Magic/Trap/Tech card's effects or through battle. Used in Juggernaut cards.
var Relentless: bool # Refers to a card that gains double bonus on any alteration to its Attacks_Remaining variable (including the turn reset). King Leonidas was the first card to have this ability.
var Multi_Strike: bool # Refers to a card's ability to deal damage to cards in the opponent's Reinforcement zone (Zeus is the first card to have this ability).
var Target_Reinforcer: bool # Refers to a card's ability to choose to target an opponent in a reinforcement slot instead of the opposing Fighter (Poseidon is the first card to have this ability).
var Paralysis: bool # Refers to a card's ability to launch an attack. Lancelot is the first card to utilize this Attribute (there's a 1/3 chance that his effect will result in him being unable to attack during that turn's Battle Phase).
var Unstoppable: bool # Refers to a card that cannot be Paralyzed.
var Direct_Attack: bool
var Effects_Disabled: Array # An Array of all effects disabled by this card.
var Owner: String # Refers to the card's original Owner (Player or Enemy). Used as part of Mordred's Hero card effect.
var Can_Attack: bool
var Targetable: bool # Refers to whether a card can be targeted by an attacking card.
var Immunity: Dictionary # Refers to the types, attributes, and effects that this card is immune to (and locations where it's immune to card effects or other events [i.e. Battle Damage]).

# Initialization
func _init(card_data):
	# Set standard variables based on parameters passed in card_data
	for key in card_data.keys():
		if card_data[key] != null:
			self.set(key, card_data[key])
		else:
			if key == "Description":
				self.set(key, "")
			else:
				self.set(key, 0)

	# Set default values that are common across all cards
	var defaults = {
		"0": ["ATK_Bonus", "Health_Bonus", "Tokens", "Burn_Damage"],
		"1": ["Fusion_Level", "Attacks_Remaining"],
		"False": ["Is_Set", "Can_Activate_Effect", "Attack_As_Reinforcement", "Immortal", "Invincible", "Rejuvenation", "Relentless", "Multi_Strike", "Target_Reinforcer", "Paralysis", "Unstoppable", "Direct_Attack", "Can_Attack", "Targetable"],
	}

	for key in defaults.keys():
		for value in defaults[key]:
			if key == "False":
				self.set(value, false)
			else:
				self.set(value, int(key))
	
	# Set non-standard variables
	Base_Attack = Attack
	Revival_Health = Health
	Total_Attack = Attack + ATK_Bonus
	Total_Health = Health + Health_Bonus
	Cost_Path = "res://Assets/Cards/Cost/Small/Small_Cost_" + Frame + "_" + str(Cost) + ".png" if Type != "Special" and "Tech" not in Type else ""
	Token_Path = preload("res://Scenes/SupportScenes/Token_Card.tscn")
	Effects_Disabled = []
	Immunity = {"Type": [], "Attribute": [], "Effect": [], "Location": []}
	Owner = "Game"

func _ready():
	Update_Data()
	var _HV1 = $SmallCard/FocusSensor.pressed.connect(Callable(self, "on_FocusSensor_pressed"))
	var _HV2 = $SmallCard/FocusSensor.gui_input.connect(Callable(self, "_on_Hide_Action_Buttons_pressed"))
	var _HV3 = $SmallCard/FocusSensor.mouse_entered.connect(Callable(self, "focusing"))
	var _HV4 = $SmallCard/FocusSensor.mouse_exited.connect(Callable(self, "defocusing"))


# Setters
func set_frame(frame: String):
	var texture_path = "res://Assets/Cards/Frame/Small_Card_Back.png" if "Deck" in get_parent().name else ("res://Assets/Cards/Frame/Small_Frame_" + frame + ".png" if Frame != "Special" else "res://Assets/Cards/Frame/Small_Advance_Tech_Card.png")
	$SmallCard/Frame.texture = load(texture_path)

func set_art():
	$SmallCard/ArtContainer/Art.texture = load(Art) if "Deck" not in get_parent().name and Frame != "Special" else null

func set_attacks_remaining(value: int = 1, context: String = "Initialize"):
	if context == "Attack":
		Attacks_Remaining -= value
	elif context == "Add":
		Attacks_Remaining += value * 2 if Relentless else value
	elif context == "Remove":
		Attacks_Remaining -= value * 2 if Relentless else value
	else:
		Attacks_Remaining = 1 if Relentless == false else 2

func set_attack(value: int, context: String = "Initialize"):
	if context == "Add":
		Attack += value
	elif context == "Remove":
		Attack -= value
	else:
		Attack = value
	set_total_attack()

func set_attack_bonus(value: int, context: String = "Initialize"):
	if BF.Get_Clean_Slot_Name(get_parent().name) in ["MedBay", "Graveyard", "Banished", "Deck"]:
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
	var Field_Slot_Names: Array = ["Fighter", "R"]
	var Field_Bonus: int = 0

	# Calculate Total Attack based on card's Attack, Attack Bonus, Fusion Level, and Field Attack Bonus
	if BF.Get_Clean_Slot_Name(get_parent().name) in Field_Slot_Names:
		Field_Bonus = BM.Player.Field_ATK_Bonus if Parent_Name.left(1) == "W" else BM.Enemy.Field_ATK_Bonus
	Total_Attack = (Attack * Fusion_Level) + ATK_Bonus + Field_Bonus

	# Update Attack text on card (NOTE: Total Attack is set to 0 automatically for all non-Normal/Hero cards [meaning things like Status cards that use this stat will always do 0 damage. Figure out how you want to address this visually/statistically.])
	if "Deck" not in Parent_Name:
		if Type in ["Normal", "Hero"]:
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

func set_health(value: int, context: String = "Initialize"):
	if context == "Add":
		Health += value
	elif context == "Remove":
		Health -= value
	elif context == "Capture":
		Health = Revival_Health
	else:
		Health = value
	set_total_health()

func set_health_bonus(value: int, context: String = "Initialize"):
	if BF.Get_Clean_Slot_Name(get_parent().name) in ["MedBay", "Graveyard", "Banished", "Deck"]:
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
	var Clean_Parent_Name: String = BF.Get_Clean_Slot_Name(Parent_Name)
	var Field_Slot_Names: Array = ["Fighter", "R1", "R2", "R3"]
	var Field_Bonus: int = 0

	# Calculate Total Health based on card's Health, Health Bonus, Fusion Level, and Field Health Bonus
	if Clean_Parent_Name in Field_Slot_Names:
		Field_Bonus = BM.Player.Field_Health_Bonus if Parent_Name.left(1) == "W" else BM.Enemy.Field_Health_Bonus
	Total_Health = max(0, (Health * Fusion_Level) + Health_Bonus + Field_Bonus)

	# Update Health text on card
	if "Deck" not in Parent_Name:
		if Type in ["Normal", "Hero"]:
			$SmallCard/Health.text = str(Total_Health)
		else:
			Total_Health = 0
			$SmallCard/Health.text = ""
	else:
		$SmallCard/Health.text = ""

func set_burn_damage(value: int, context: String = "Initialize"):
	if BF.Get_Clean_Slot_Name(get_parent().name) in ["MedBay", "Graveyard", "Banished", "Deck"] or Anchor_Text == "Juggernaut":
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
			var InstanceToken: Node = Token_Path.instantiate()
			InstanceToken.name = "Token" + str(Token_Container.get_child_count() + 1)
			Token_Container.add_child(InstanceToken)
	elif Token_Container.get_child_count() > Tokens: # Remove excess Token(s)
		while Token_Container.get_child_count() > Tokens:
			var i: Node = Token_Container.get_child(Token_Container.get_child_count() - 1)
			Token_Container.remove_child(i)
			i.queue_free()

func set_is_set(context: String = "Initialize"):
	Is_Set = true if context == "Set" else false

func set_can_activate_effect():
	var Parent_Name: String = get_parent().name
	var Side: String = "W" if GameData.Current_Turn == "Player" else "B"
	var Resolvable_Side: bool = true if Resolve_Side == "Both" or Side == Parent_Name.left(1) else false

	# Ensures that only cards on the field (on correct side), that aren't set, and haven't already activated their summon effect can activate their effects.
	if BF.Get_Clean_Slot_Name(Parent_Name) in ["Fighter", "R", "Backrow"] and not Is_Set and Resolvable_Side and Effect_Type != "Summon":
		Can_Activate_Effect = true
	else:
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

func set_effects_disabled(value: String, context: String = "Initialize"):
	if context == "Initialize":
		Effects_Disabled = [value]
	else:
		if context == "Add":
			Effects_Disabled.append(value)
		elif context == "Remove":
			Effects_Disabled.erase(value)
		elif context == "Reset":
			Effects_Disabled.clear()
		else:
			Effects_Disabled = [value]

func set_can_attack():
	var Side: String = "W" if GameData.Current_Turn == "Player" else "B"
	var Clean_Parent_Name: String = BF.Get_Clean_Slot_Name(get_parent().name)
	var in_valid_slot = (Clean_Parent_Name == "Fighter" or (Clean_Parent_Name == "R" and Attack_As_Reinforcement)) and get_parent().name.left(1) == Side

	Can_Attack = true if in_valid_slot and Paralysis == false and Attacks_Remaining > 0 else false

func set_targetable(attacking_card: Node):
	var Clean_Parent_Name: String = BF.Get_Clean_Slot_Name(get_parent().name)

	Targetable = true if Clean_Parent_Name == "Fighter" or (Clean_Parent_Name == "R" and (attacking_card.Multi_Strike or attacking_card.Target_Reinforcer)) else false

func set_paralysis(value: bool, context: String = "Initialize"):
	if Unstoppable:
		Paralysis = false
	else:
		if context == "Add":
			Paralysis = true
		elif context == "Remove":
			Paralysis = false
		else:
			Paralysis = value

# Primary Functions
func Update_Data():
	set_frame(Frame)
	set_art()
	set_attack(Attack)
	set_attack_bonus(ATK_Bonus)
	set_cost(Cost)
	set_health(Health)
	set_health_bonus(Health_Bonus)
	set_tokens(Tokens)

func Reset_Stats_On_Capture():
	set_attack(Attack)
	set_attack_bonus(0)
	set_health(0, "Capture")
	set_health_bonus(0)
	set_burn_damage(0)

func Reset_Variables_After_Flip_Summon():
	set_is_set()
	set_can_activate_effect() # Ensures effects aren't triggered from the Graveyard
	set_tokens(0, "Reset")

func hide_action_buttons():
	$SmallCard/Action_Button_Container/Summon.visible = false
	$SmallCard/Action_Button_Container/Set.visible = false
	$SmallCard/Action_Button_Container/Target.visible = false

func is_immune(action_type: String, trigger_card: Node) -> bool:
	var Clean_Parent_Name = BF.Get_Clean_Slot_Name(get_parent().name)
	
	# Check for Immunity based on action type
	if action_type == "Card Effect": # NOTE: Since there's currently no check to see if the trigger_card is on the same side of the field as your card, immunity means the card is unaffected regardless of whether the opponent is trying to resolve an effect on the card or the player is.
		# Card Effect Immunity Guide:
		# - Type-based: For cards that are immune to all effects of a certain type [e.g. Jinzo with Trap cards])
		# - Attribute-based: For cards that are immune to all effects of a certain attribute [e.g. a card that is immune to all Warrior effects, whether Normal or Hero]. Weaker protection than Type effects, but stronger than singular effect immunity due to being immune to some Hero effects based on their Attribute)
		# - Effect-based: For cards that are immune to specific effects [e.g. a card that is immune to the life-draining effects of Behind_Enemy_Lines])
		# - Location-based: For cards that are immune to effects based on their location [e.g. a card that is immune to all effects while in the Medical Bay])
		if trigger_card.Type in Immunity["Type"] or trigger_card.Attribute in Immunity["Attribute"] or trigger_card.Anchor_Text in Immunity["Effect"] or Clean_Parent_Name in Immunity["Location"]:
			return true
	elif action_type == "Battle Damage":
		if (Clean_Parent_Name == "R" and "Multi_Strike" in Immunity["Effect"]) or Invincible:
			return true
	elif action_type == "Burn Damage":
		if Rejuvenation:
			return true
	elif action_type == "Capture":
		if Immortal:
			return true

	# No immunity found
	return false

func get_net_damage() -> int:
	var Dueler_Opp = BM.Enemy if get_parent().name.left(1) == "W" else BM.Player
	var Dueler_Side_Opp = "W" if Dueler_Opp == BM.Player else "B"
	var Reinforcers_Opp = BF.Get_Field_Card_Data(Dueler_Side_Opp, "R")
	var Shield_Wall_Active = Dueler_Opp.Shield_Wall_Active
	var Shield_Wall_Damage_Reduction = len(Reinforcers_Opp) * 5 if Shield_Wall_Active else 0
	return Total_Attack - Shield_Wall_Damage_Reduction

func Spawn_Action_Buttons():
	var Side: String = "W" if GameData.Current_Turn == "Player" else "B"
	var Parent_Name: String = get_parent().name
	var Reposition_Zones: Array = [Side + "Fighter", Side + "R1", Side + "R2", Side + "R3"]
	var Fighter = BF.Get_Field_Card_Data(Side, "Fighter")[0] if BF.Get_Field_Card_Data(Side, "Fighter") != [] else null
	var Reinforcer_Field_Cards = BF.Get_Field_Card_Data(Side, "R")
	var buttons_to_spawn_map = {"Normal": ["Summon"], "Hero": ["Summon"], "Trap": ["Set"], "Magic": ["Summon", "Set"]}
	var buttons_to_spawn = null

	# Check for Hero in Reinforcer zone (needed for repositioning logic)
	var Hero_In_Reinforcements = false
	for card in Reinforcer_Field_Cards:
		if card.Type == "Hero" and card != self:
			Hero_In_Reinforcements = true
			break
	
	# Determine which buttons to spawn based on card's location, type, attribute, and game conditions
	if "Hand" in Parent_Name:
		buttons_to_spawn = buttons_to_spawn_map[Type] if Attribute != "Equip" else ["Summon"]
	elif Parent_Name in Reposition_Zones:
		if (Type == "Normal" and BF.Find_Open_Slot("R") == null) or (Type == "Hero" and (Hero_In_Reinforcements and (BF.Find_Open_Slot("R") == null or Fighter == self))) or (Type == "Hero" and BF.Find_Open_Slot("Fighter") == null and Fighter != self):
			buttons_to_spawn = ["Reposition", "Sacrifice"]
		else:
			buttons_to_spawn = ["Sacrifice"]
	elif Side + "Backrow" in Parent_Name:
		buttons_to_spawn = ["Flip"]
	elif ("Fighter" in Parent_Name and Parent_Name.left(1) != Side) or (("R1" in Parent_Name or "R2" in Parent_Name or "R3" in Parent_Name) and GameData.Attacker.Target_Reinforcer):
		buttons_to_spawn = ["Target"]

	# Spawn buttons
	if buttons_to_spawn != null:
		var button_container = $SmallCard/Action_Button_Container
		for button in buttons_to_spawn:
			var action_button_scene = preload("res://Scenes/SupportScenes/Action_Button_Controller.tscn").instantiate()
			var Mode = "Summon" if button in ["Summon", "Flip"] else button
			button_container.add_child(action_button_scene)
			action_button_scene.name = button
			action_button_scene.text = button
			action_button_scene.pressed.connect(Callable(self, "_on_Action_Button_pressed").bind(Mode))

func Remove_Action_Buttons():
	var button_container = $SmallCard/Action_Button_Container
	for button in button_container.get_children():
		button_container.remove_child(button)
		button.queue_free()

func On_Target_Selection():
	# Signal emitted twice to ensure that Damage Step is conducted following successful Target selection
	SignalBus.emit_signal("Update_GameState", "Step")
	SignalBus.emit_signal("Update_GameState", "Step")
	
	# If NO Capture happened, advance GameState (advance to Repeat Step happens automatically when card IS captured)
	if GameData.Current_Step == "Capture":
		if GameData.Attacks_To_Launch == 0:
			# Attempt to End Turn (works if no discards are necessary)
			SignalBus.emit_signal("Update_GameState", "Turn")
		else:
			# Move to Repeat Step to prep for next attack
			SignalBus.emit_signal("Update_GameState", "Step")
	elif GameData.Current_Step == "Discard":
		# Attempt to End Turn
		SignalBus.emit_signal("Update_GameState", "Turn")

# Signal-Related Functions
func focusing():
	if "Deck" not in get_parent().name:
		SignalBus.emit_signal("LookAtCard", self, Frame, Art, Name, Cost, Attribute)

func defocusing():
	SignalBus.emit_signal("NotLookingAtCard")

func on_FocusSensor_pressed():
	var Side: String = "W" if GameData.Current_Turn == "Player" else "B"
	var Side_Opp: String = "B" if GameData.Current_Turn == "Player" else "W"
	var Turn_Side_Field_And_Hand_Cards: Array = BF.Get_Field_Card_Data(Side, "Fighter") + BF.Get_Field_Card_Data(Side, "R") + BF.Get_Field_Card_Data(Side, "Backrow") + BF.Get_Field_Card_Data(Side, "Hand")
	var Parent_Name: String = get_parent().name
	
	if "Effect_Target_List" in Parent_Name:
		SignalBus.emit_signal("EffectTargetSelected", self)
	else:
		match GameData.Current_Step:
			"Main":
				if self in Turn_Side_Field_And_Hand_Cards: # Allows for repositioning, sacrificing and Normal/Flip/Fusion summoning
					Spawn_Action_Buttons()
				elif "HeroDeck" in Parent_Name: # Allows for manual Hero summoning
					SignalBus.emit_signal("Hero_Deck_Selected")
			"Selection":
				set_can_attack()
				if Can_Attack:
					GameData.Attacker = self
					var Fighter_Opp = BF.Get_Field_Card_Data(Side_Opp, "Fighter")
					if len(Fighter_Opp) > 0:
						SignalBus.emit_signal("Update_GameState", "Step")
			"Target":
				Spawn_Action_Buttons()
			"Discard":
				if "Hand" in Parent_Name:
					SignalBus.emit_signal("Discard_Card", Parent_Name.left(1), self)
	
	# Allows user to re-open card Effect scenes during turn
	if Parent_Name.left(1) == Side:
		CardEffects.call(Anchor_Text, self)

func _on_Action_Button_pressed(Mode):
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Reposition_Zones = [Side + "Fighter", Side + "R1", Side + "R2", Side + "R3"]
	var Parent_Name = get_parent().name
	var Destination_Node_Map = {"Hero": BF.Find_Open_Slot("Fighter") if BF.Find_Open_Slot("Fighter") != null else BF.Find_Open_Slot("R"), "Normal": BF.Find_Open_Slot("R"), "Magic": BF.Find_Open_Slot("Backrow"), "Trap": BF.Find_Open_Slot("Backrow")}
	var Destination_Node_Path = Destination_Node_Map[Type] if Attribute != "Equip" else BF.Find_Open_Slot("Equip" + Type)
	var Destination_Node = get_tree().get_root().get_node(Destination_Node_Path) if Destination_Node_Path != null else null
	Remove_Action_Buttons()

	if "Hand" in Parent_Name and Destination_Node != null:
		SignalBus.emit_signal("Play_Card", Side, Mode, Destination_Node, self)
	elif "Backrow" in Parent_Name and Mode == "Summon":
		SignalBus.emit_signal("Activate_Set_Card", Side, self)
	elif Parent_Name in Reposition_Zones and Mode == "Sacrifice":
		SignalBus.emit_signal("Sacrifice_Card", self)
	elif Parent_Name in Reposition_Zones and Mode == "Reposition":
		SignalBus.emit_signal("Reposition_Field_Cards", self)
	elif Mode == "Target":
		GameData.Target = self
		On_Target_Selection()
