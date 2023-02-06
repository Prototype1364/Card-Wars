extends Control

var Name = "Barbarian"
var Frame = "Normal"
var Art = "res://Assets/Cards/Art/Barbarian_NEW.png"
var Type = "Normal"
var Effect_Type = "None"
var Attribute = "Barbarian"
var Description = "This is a TEST for the card description."
var Short_Description = "TEMP Test Description."
var Attack = 3
var Attack_Bonus = 0
var Cost = 1
var Health = 5
var Health_Bonus = 0
var Max_Health = 0 # Presumably, the health level you reset the card to once revived? Thus, differentiating it from "Original_Health" since some effects/magic/trap cards to increase/decrease max health value during gameplay.
var Special_Edition_Text = "Standard"
var Rarity = "Common"
var Passcode = 50430881
var Deck_Capacity = 0
var Tokens = 0
var Is_Set = false
var Effect_Active = false
var Fusion_Level = 1
var Attack_As_Reinforcement = false
var Invincible = false
var Multi_Strike = false
var Paralysis = false
var Owner = "White"
var Copyright = null


func _ready():
	self.focus_neighbour_left = self.get_parent().focus_neighbour_left
	self.focus_neighbour_top = self.get_parent().focus_neighbour_top
	self.focus_neighbour_right = self.get_parent().focus_neighbour_right
	self.focus_neighbour_bottom = self.get_parent().focus_neighbour_bottom
	self.focus_next = self.get_parent().focus_next
	self.focus_previous = self.get_parent().focus_previous

func _on_FocusSensor_focus_entered():
	self.focusing()

func _on_FocusSensor_focus_exited():
	self.defocusing()

func focusing():
	GameData.FocusedCardName = self.name
	GameData.FocusedCardParentName = self.get_parent().name
	SignalBus.emit_signal("LookAtCard", Frame, Cost)

func defocusing():
	GameData.FocusedCardName = ""
	GameData.FocusedCardParentName = ""
	SignalBus.emit_signal("NotLookingAtCard")

func _on_FocusSensor_pressed():
	if GameData.CardFrom == "":
		GameData.CardFrom = self.get_parent().name
		GameData.CardMoved = self.name
	elif GameData.CardFrom != "":
		GameData.CardTo = self.get_parent().name
		GameData.CardSwitched = self.name
		SignalBus.emit_signal("SwitchInProgress", GameData.CardTo.left(1))
