extends Node

var CardData
var Master_Deck_List

# Duel Data
var Victor
var Current_Turn = "Player"
var Turn_Counter = 1
var Current_Phase = "Opening Phase"
var Current_Step = "Start"
const ATTRIBUTE_LIST = ["Creature","Cryptid","Explorer","Mythological","Olympian","Outlaw","Philosopher","Pirate","Politician","Ranged","Scientist","Spy","Support","Titan","Warrior","Wizard"] # A list of all Normal/Hero card Attributes in the game. Used to reset Summonable_Attributes variable value when "Immanuel Kant" leaves the field.
var Disabled_Effects = [] # A list of all effects that have had their effects disabled by "Immanuel Kant" Hero card effect.
var Summonable_Attributes = ATTRIBUTE_LIST # Used to resolve "Immanuel Kant" Hero card effect. Initially contains all Attributes in the game, but is lowered to 1 of the player's choice when Kant is on the field.
var Cards_Summoned_This_Turn = []
var Cards_Captured_This_Turn = []
var Last_Equip_Card_Replaced = []
var Attacks_To_Launch = 0
var Attacker
var Target
var For_Honor_And_Glory = false

# Variable used to name Card nodes
var CardCounter = 0

func _ready():
	# Loads Card Pool Into Game.
	var CardData_File = FileAccess.open("res://Data/CardDB.json", FileAccess.READ)
	var CardData_JSON = JSON.new()
	CardData_JSON.parse(CardData_File.get_as_text())
	CardData = CardData_JSON.get_data()
	
	# Loads List of Pre-Built Decks Into Game
	# Currently DOESN'T include Player/Enemy Decks.
	# During early testing it is assumed that White uses Arthurian Pre-Built Deck & Black uses Olympian.
	var MasterDeckList_File = FileAccess.open("res://Data/Master_Deck_List.json", FileAccess.READ)
	var MasterDeckList_JSON = JSON.new()
	MasterDeckList_JSON.parse(MasterDeckList_File.get_as_text())
	Master_Deck_List = MasterDeckList_JSON.get_data()
