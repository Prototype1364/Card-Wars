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
var Attack_Bonus
var Cost
var Cost_Path
var Health
var Health_Bonus
var Max_Health # Presumably, the health level you reset the card to once revived? Thus, differentiating it from "Original_Health" since some effects/magic/trap cards to increase/decrease max health value during gameplay.
var Special_Edition_Text
var Rarity
var Passcode
var Deck_Capacity
var Tokens
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

func Set_Card_Variables():
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	Name = player.Deck[-1].Name
	Frame = player.Deck[-1].Frame
	Type = player.Deck[-1].Type
	Effect_Type = player.Deck[-1].Effect_Type
	if player.Deck[-1].Art == null:
		pass
	else:
		Art = load(player.Deck[-1].Art)
	Attribute = player.Deck[-1].Attribute
	Description = player.Deck[-1].Description
	Short_Description = player.Deck[-1].Short_Description
	Attack = player.Deck[-1].Attack
	Attack_Bonus = player.Deck[-1].ATK_Bonus
	Cost = player.Deck[-1].Cost
	if player.Deck[-1].Type != "Special":
		Cost_Path = load("res://Assets/Cards/Cost/Small/Small_Cost_" + Frame + "_" + str(Cost) + ".png")
	else:
		pass
	Health = player.Deck[-1].Health
	Health_Bonus = player.Deck[-1].Health_Bonus
	Max_Health = Health
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
		pass

func _on_FocusSensor_focus_entered():
	self.focusing()

func _on_FocusSensor_focus_exited():
	self.defocusing()

func focusing():
	GameData.FocusedCardName = self.name
	GameData.FocusedCardParentName = self.get_parent().name
	SignalBus.emit_signal("LookAtCard", Frame, Art, Name, Attack, Cost, Health)

func defocusing():
	GameData.FocusedCardName = ""
	GameData.FocusedCardParentName = ""
	SignalBus.emit_signal("NotLookingAtCard")


func _on_FocusSensor_pressed():
	if GameData.Current_Step == "Reposition":
		if GameData.CardFrom == "":
			GameData.CardFrom = self.get_parent().name
			GameData.CardMoved = self.name
		elif GameData.CardFrom != "":
			GameData.CardTo = self.get_parent().name
			GameData.CardSwitched = self.name
			SignalBus.emit_signal("Reposition_Field_Cards", GameData.CardTo.left(1))
	elif GameData.Current_Step == "Summon/Set":
		# These first two lines of code should be removed and added to _on_Summon_Set_pressed() func once Hand-related button display visual issues are worked out.
		GameData.CardFrom = self.get_parent().name
		GameData.CardMoved = self.name
		$Action_Button_Container/Summon.visible = true
		$Action_Button_Container/Set.visible = true
	elif GameData.Current_Step == "Flip":
		var Side_To_Set_For = "W" if GameData.Current_Turn == "Player" else "B"
		GameData.CardFrom = self.get_parent().name
		GameData.CardMoved = self.name
		SignalBus.emit_signal("Activate_Set_Card", Side_To_Set_For, self)
	elif GameData.Current_Step == "Selection":
		$Action_Button_Container/Attack.visible = true
	elif GameData.Current_Step == "Target":
		$Action_Button_Container/Target.visible = true


func _on_Summon_Set_pressed():
	$Action_Button_Container/Summon.visible = false
	$Action_Button_Container/Set.visible = false

func _on_Attacker_Selection_pressed():
	GameData.Attacker = self
	$Action_Button_Container/Attack.visible = false
	SignalBus.emit_signal("Check_For_Targets")
	

func _on_Target_pressed():
	GameData.Target = self
	$Action_Button_Container/Target.visible = false
