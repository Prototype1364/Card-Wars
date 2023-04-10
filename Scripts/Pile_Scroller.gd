extends Control

var Cards
var SmallCardDisplay = preload("res://Scenes/SupportScenes/PseudoSmallCard.tscn")


func _ready():
	var _HV1 = SignalBus.connect("Clicked_On_A_Small_Card_Copy", Callable(self, "Close_Scroller"))

func Graveyard_Called(Dueler):
	Clear_Scroller()
	Cards = Dueler.Graveyard
	Add_Cards()

func Medical_Bay_Called(Dueler):
	Clear_Scroller()
	Cards = Dueler.MedicalBay
	Add_Cards()

func Banished_Called(Dueler):
	Clear_Scroller()
	Cards = Dueler.Banished
	Add_Cards()

func Clear_Scroller():
	#Clears all cards.
	for i in $Deck_Scroller/Deck_Container.get_children():
		i.queue_free()

func Add_Cards():
	#Adds cards based on which function was called.
	for i in Cards:
		var NewInstance = SmallCardDisplay.instantiate()
		NewInstance.Name = i.Name
		NewInstance.Frame = i.Frame
		NewInstance.Type = i.Type
		NewInstance.Effect_Type = i.Effect_Type
		NewInstance.Art = i.Art
		NewInstance.Attribute = i.Attribute
		NewInstance.Description = i.Description
		NewInstance.Short_Description = i.Short_Description
		NewInstance.Attack = i.Attack
		NewInstance.ATK_Bonus = i.ATK_Bonus
		NewInstance.Cost = i.Cost
		NewInstance.Cost_Path = i.Cost_Path
		NewInstance.Health = i.Health
		NewInstance.Health_Bonus = i.Health_Bonus
		NewInstance.Revival_Health = i.Revival_Health
		NewInstance.Special_Edition_Text = i.Special_Edition_Text
		NewInstance.Rarity = i.Rarity
		NewInstance.Passcode = i.Passcode
		NewInstance.Deck_Capacity = i.Deck_Capacity
		NewInstance.Tokens = i.Tokens
		NewInstance.Token_Path = i.Token_Path
		NewInstance.Is_Set = i.Is_Set
		NewInstance.Effect_Active = i.Effect_Active
		NewInstance.Fusion_Level = i.Fusion_Level
		NewInstance.Attack_As_Reinforcement = i.Attack_As_Reinforcement
		NewInstance.Invincible = i.Invincible
		NewInstance.Multi_Strike = i.Multi_Strike
		NewInstance.Target_Reinforcer = i.Target_Reinforcer
		NewInstance.Paralysis = i.Paralysis
		NewInstance.Owner = i.Owner
		NewInstance.Copy_Of = i
		NewInstance.Update_Card_Visuals()
		$Deck_Scroller/Deck_Container.add_child(NewInstance)

func Close_Scroller(_Copy_Of):
	if visible == true:
		Clear_Scroller()
		visible = false

func _on_button_pressed():
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	Medical_Bay_Called(player)

