extends Control

func _ready():
	Update_Data()

func Update_Data():
	$BG/Player.text = GameData.Current_Turn
	$BG/GameState.text = GameData.Current_Phase + ", " + GameData.Current_Step
	$BG/Turn_Count.text = "#" + str(GameData.Turn_Counter)
