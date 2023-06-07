extends Node

class_name CombatantController

"""
This script may or may not be necessary.
You may be able to use the Duelist (Instantiator) script given how small this script is.
"""

func Update_Summon_Crests(roll_result):
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	player.Summon_Crests += roll_result
