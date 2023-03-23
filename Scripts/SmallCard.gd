extends Control

var Name
var Frame
var Type
var Effect_Type
var Art
var Attribute
var Description
var Short_Description
var Attack
var ATK_Bonus
var Cost
var Cost_Path
var Health
var Health_Bonus
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
var Invincible
var Multi_Strike
var Paralysis
var Owner


func _ready():
	Set_Card_Variables()
	Update_Card_Visuals()
	Update_Data()

func Set_Card_Variables():
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	Name = player.Deck[-1].Name
	Frame = player.Deck[-1].Frame
	Type = player.Deck[-1].Type
	Effect_Type = player.Deck[-1].Effect_Type
	Art = load(player.Deck[-1].Art) if player.Deck[-1].Art != "res://Assets/Cards/Art/Special_Activate_Technology.png" else null
	Attribute = player.Deck[-1].Attribute
	Description = player.Deck[-1].Description
	Short_Description = player.Deck[-1].Short_Description
	Attack = player.Deck[-1].Attack if player.Deck[-1].Attack != null else ""
	ATK_Bonus = player.Deck[-1].ATK_Bonus
	Cost = player.Deck[-1].Cost
	Cost_Path = load("res://Assets/Cards/Cost/Small/Small_Cost_" + Frame + "_" + str(Cost) + ".png") if player.Deck[-1].Type != "Special" else null
	Health = player.Deck[-1].Health if player.Deck[-1].Health != null else ""
	Health_Bonus = player.Deck[-1].Health_Bonus
	Revival_Health = Health
	Special_Edition_Text = player.Deck[-1].Special_Edition_Text
	Rarity = player.Deck[-1].Rarity
	Passcode = player.Deck[-1].Passcode
	Deck_Capacity = player.Deck[-1].Deck_Capacity
	Tokens = player.Deck[-1].Tokens
	Is_Set = player.Deck[-1].Is_Set
	Effect_Active = player.Deck[-1].Effect_Active
	Fusion_Level = player.Deck[-1].Fusion_Level
	Attack_As_Reinforcement = player.Deck[-1].Attack_As_Reinforcement
	Invincible = player.Deck[-1].Invincible
	Multi_Strike = player.Deck[-1].Multi_Strike
	Paralysis = player.Deck[-1].Paralysis
	Owner = player.Deck[-1].Owner

func Update_Card_Visuals():
	if self.Frame != "Special":
		$Frame.texture = load("res://Assets/Cards/Frame/Small_Frame_" + Frame + ".png")
		$CostContainer/Cost.texture = Cost_Path
		$ArtContainer/Art.texture = Art
		$Attack.text = str(Attack)
		$Health.text = str(Health)
	else: # Card is the Advance Tech card (Has no Cost or custom Art).
		$Frame.texture = load("res://Assets/Cards/Frame/Small_Advance_Tech_Card.png")

func Update_Data():
	if Type == "Normal" or Type == "Hero":
		var ATK = Attack if Attack >= 0 and (Type == "Normal" or Type == "Hero") else 0
		var HP = Health if Health >= 0 and (Type == "Normal" or Type == "Hero") else 0
	
		$Attack.text = str(ATK + ATK_Bonus)
		$Health.text = str(HP + Health_Bonus)
	else:
		pass
	
	# Add Token-related visuals to card
	var Token_Container = $TokenContainer/VBoxContainer
	if Token_Container.get_child_count() < self.Tokens:
		for _i in range(self.Tokens - Token_Container.get_child_count()):
			var InstanceToken = Token_Path.instance()
			InstanceToken.name = "Token" + str(Token_Container.get_child_count() + 1)
			Token_Container.add_child(InstanceToken)
	elif Token_Container.get_child_count() > self.Tokens:
		for i in Token_Container.get_children():
			Token_Container.remove_child(i)
			i.queue_free()
		for _i in range(self.Tokens - Token_Container.get_child_count()):
			var InstanceToken = Token_Path.instance()
			InstanceToken.name = "Token" + str(Token_Container.get_child_count() + 1)
			Token_Container.add_child(InstanceToken)

func focusing():
	GameData.FocusedCardName = self.name
	GameData.FocusedCardParentName = self.get_parent().name
	SignalBus.emit_signal("LookAtCard", Frame, Art, Name, Attack, Cost, Health, Attribute)

func defocusing():
	GameData.FocusedCardName = ""
	GameData.FocusedCardParentName = ""
	SignalBus.emit_signal("NotLookingAtCard")

func _on_FocusSensor_focus_entered():
	self.focusing()

func _on_FocusSensor_focus_exited():
	self.defocusing()

func _on_FocusSensor_pressed():
	var Parent_Name = self.get_parent().name
	
	# Allows you to choose a card to receive effect benefits/penalties
	if GameData.Yield_Mode == true:
		GameData.ChosenCard = self
		SignalBus.emit_signal("Card_Effect_Selection_Yield_Release", self)
	
	# Allows repositioning of cards on field
	if ("Fighter" in Parent_Name or "R1" in Parent_Name or "R2" in Parent_Name or "R3" in Parent_Name) and GameData.Current_Step == "Main":
		if GameData.CardFrom == "":
			GameData.CardFrom = Parent_Name
			GameData.CardMoved = self.name
		elif GameData.CardFrom != "":
			GameData.CardTo = Parent_Name
			GameData.CardSwitched = self.name
			SignalBus.emit_signal("Reposition_Field_Cards", GameData.CardTo.left(1))
	
	# Allows you to Summon/Set cards to field
	elif "Hand" in Parent_Name and GameData.Current_Step == "Main":
		# Allows you to skip pressing Summon/Set buttons when playing Normal/Hero card
		if self.Type == "Normal" or self.Type == "Hero":
			GameData.Summon_Mode = "Summon"
			GameData.CardFrom = Parent_Name
			GameData.CardMoved = self.name
		else:
			$Action_Button_Container/Summon.visible = true
			$Action_Button_Container/Set.visible = true
	
	# Allows Flip summoning of cards from backrow
	elif "Backrow" in Parent_Name and GameData.Current_Step == "Main":
		$Action_Button_Container/Summon.text = "Flip"
		$Action_Button_Container/Summon.visible = true
		GameData.CardFrom = Parent_Name
		GameData.CardMoved = self.name
	
	# Allows for selection of Attacker
	elif GameData.Current_Step == "Selection":
		if ("Fighter" in Parent_Name or (Attack_As_Reinforcement and ("R1" in Parent_Name or "R2" in Parent_Name or "R3" in Parent_Name))) and ((Parent_Name.left(1) == "W" and GameData.Current_Turn == "Player") or Parent_Name.left(1) == "B" and GameData.Current_Turn == "Enemy"):
			GameData.Attacker = self
			SignalBus.emit_signal("Check_For_Targets")
			if GameData.Target == GameData.Player or GameData.Target == GameData.Enemy:
				# Signal emitted twice to ensure that Damage Step is conducted following successful Target selection
				SignalBus.emit_signal("Update_GameState", "Step")
				SignalBus.emit_signal("Update_GameState", "Step")
				if GameData.Attacks_To_Launch == 0:
					# Move to End Phase (no captures will happen following direct attack)
					SignalBus.emit_signal("Update_GameState", "Phase")
					# Attempt to End Turn (works if no discards are necessary)
					SignalBus.emit_signal("Update_GameState", "Turn")
				else:
					# Move to Repeat Step to prep for next attack
					SignalBus.emit_signal("Update_GameState", "Step")
	
	# Allows for selection of Target
	elif GameData.Current_Step == "Target":
		if "Fighter" in Parent_Name and ((Parent_Name.left(1) == "W" and GameData.Current_Turn != "Player") or Parent_Name.left(1) == "B" and GameData.Current_Turn != "Enemy"):
			$Action_Button_Container/Target.visible = true
	
	# Allows for selection of cards to discard from hand
	elif GameData.Current_Step == "Discard":
		GameData.CardFrom = Parent_Name
		GameData.CardMoved = self.name
		if "Hand" in GameData.CardFrom:
			SignalBus.emit_signal("Discard_Card", GameData.CardFrom.left(1))

func _on_Summon_Set_pressed(Mode):
	var Battle_Scene = load("res://Scenes/MainScenes/Battle.tscn").instance()
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Parent_Name = self.get_parent().name
	
	if "Hand" in Parent_Name and Mode == "Summon":
		GameData.Summon_Mode = "Summon"
		# Automatically move Equip card to appropriate Equip slot
		if self.Attribute == "Equip":
			var slot_name = Side + "Equip" + self.Type
			GameData.CardFrom = Parent_Name
			GameData.CardMoved = self.name
			Battle_Scene._on_Card_Slot_pressed(slot_name)
	
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
