extends Control

# Used when interacting with Pile_Scroller scene (it's basically a simplified version of the smallcard scene).

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
var Target_Reinforcer
var Paralysis
var Owner
var Copy_Of

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func Update_Card_Visuals():
	$Frame.texture = load("res://Assets/Cards/Frame/Small_Frame_" + Frame + ".png")
	$CostContainer/Cost.texture = Cost_Path
	$ArtContainer/Art.texture = Art
	if Type == "Normal" or Type == "Hero":
		var ATK = Attack if Attack >= 0 and (Type == "Normal" or Type == "Hero") else 0
		var HP = Health if Health >= 0 and (Type == "Normal" or Type == "Hero") else 0
		$Attack.text = str(ATK + ATK_Bonus)
		$Health.text = str(HP + Health_Bonus)
	var Token_Container = $TokenContainer/VBoxContainer
	if Token_Container.get_child_count() < self.Tokens:
		for _i in range(self.Tokens - Token_Container.get_child_count()):
			var InstanceToken = Token_Path.instantiate()
			InstanceToken.name = "Token" + str(Token_Container.get_child_count() + 1)
			Token_Container.add_child(InstanceToken)
	elif Token_Container.get_child_count() > self.Tokens:
		for i in Token_Container.get_children():
			Token_Container.remove_child(i)
			i.queue_free()
		for _i in range(self.Tokens - Token_Container.get_child_count()):
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

func _on_FocusSensor_focus_entered():
	self.focusing()

func _on_FocusSensor_focus_exited():
	self.defocusing()

func Card_Clicked():
	SignalBus.emit_signal("Clicked_On_A_Small_Card_Copy", Copy_Of)
