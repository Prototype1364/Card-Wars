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
	SignalBus.emit_signal("LookAtCard", Frame, Art, Name, Attack, Cost, Health)

func defocusing():
	GameData.FocusedCardName = ""
	GameData.FocusedCardParentName = ""
	SignalBus.emit_signal("NotLookingAtCard")

func _on_FocusSensor_focus_entered():
	self.focusing()

func _on_FocusSensor_focus_exited():
	self.defocusing()

func _on_FocusSensor_pressed():
	if GameData.Current_Step == "Reposition":
		if GameData.CardFrom == "":
			GameData.CardFrom = self.get_parent().name
			GameData.CardMoved = self.name
		elif GameData.CardFrom != "":
			GameData.CardTo = self.get_parent().name
			GameData.CardSwitched = self.name
			SignalBus.emit_signal("Reposition_Field_Cards", GameData.CardTo.left(1))
	elif GameData.Current_Step == "Summon/Set" and "Hand" in self.get_parent().name:
		$Action_Button_Container/Summon.visible = true
		$Action_Button_Container/Set.visible = true
	elif GameData.Current_Step == "Flip":
		$Action_Button_Container/Summon.text = "Flip"
		$Action_Button_Container/Summon.visible = true
		GameData.CardFrom = self.get_parent().name
		GameData.CardMoved = self.name
	elif GameData.Current_Step == "Selection":
		$Action_Button_Container/Attack.visible = true
	elif GameData.Current_Step == "Target":
		$Action_Button_Container/Target.visible = true
	elif GameData.Current_Step == "Discard":
		GameData.CardFrom = self.get_parent().name
		GameData.CardMoved = self.name
		if "Hand" in GameData.CardFrom:
			SignalBus.emit_signal("Discard_Card", GameData.CardFrom.left(1))

func _on_Summon_Set_pressed(Mode):
	if "Hand" in self.get_parent().name and Mode == "Summon":
		GameData.Summon_Mode = "Summon"
	elif GameData.Current_Step == "Flip" and Mode == "Summon":
		$Action_Button_Container/Summon.text = "Summon"
		var Side = "W" if GameData.Current_Turn == "Player" else "B"
		SignalBus.emit_signal("Activate_Set_Card", Side, self)
	elif "Hand" in self.get_parent().name and Mode == "Set":
		GameData.Summon_Mode = "Set"
		self.Is_Set = true
	
	GameData.CardFrom = self.get_parent().name
	GameData.CardMoved = self.name
	$Action_Button_Container/Summon.visible = false
	$Action_Button_Container/Set.visible = false

func _on_Attacker_Selection_pressed():
	GameData.Attacker = self
	$Action_Button_Container/Attack.visible = false
	SignalBus.emit_signal("Check_For_Targets")

func _on_Target_pressed():
	GameData.Target = self
	$Action_Button_Container/Target.visible = false
	# Signal emitted twice to ensure that Damage Step is conducted following successful Target selection
	SignalBus.emit_signal("Update_GameState", "Step")
	SignalBus.emit_signal("Update_GameState", "Step")
	
	# Checks if Target was captured. If not, move to Repeat Step (this happens automatically when card IS captured)
	if GameData.Current_Step == "Capture":
		SignalBus.emit_signal("Update_GameState", "Step")

func _on_Hide_Action_Buttons_pressed(_event):
	if Input.is_action_pressed("Cancel"):
		$Action_Button_Container/Summon.visible = false
		$Action_Button_Container/Set.visible = false
		$Action_Button_Container/Attack.visible = false
		$Action_Button_Container/Target.visible = false
