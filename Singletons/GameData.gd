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
var Summonable_Attributes = ATTRIBUTE_LIST # Used to resolve "Immanuel Kant" Hero card effect. Initially contains all Attributes in the game, but is lowered to 1 of the player's choice when Kant is on the field.
var Cards_Captured_This_Turn = []
var Attacks_To_Launch = 0
var Attacker
var Target
var Player = Duelist.new("Player",100,0,0,0,0,0,0,0,0,0,[],[],[],[],[],[],[],[],[],[],"None")
var Enemy = Duelist.new("Enemy",100,0,0,0,0,0,0,0,0,0,[],[],[],[],[],[],[],[],[],[],"None")

# Focus Card variables
var FocusedCardName = ""
var FocusedCardParentName = ""

# Play/Reposition Card variables
var Summon_Mode = ""
var CardFrom = ""
var CardTo = ""
var CardMoved = ""
var CardSwitched = ""

# Card Effect Resolution variables
var Yield_Mode = false
var ChosenCard

# Variable used to name Card nodes
var CardCounter = 0

func _ready():
	# Loads Card Pool Into Game.
	var CardData_File = File.new()
	CardData_File.open("res://Data/CardDB.json", File.READ)
	var CardData_JSON = JSON.parse(CardData_File.get_as_text())
	CardData_File.close()
	CardData = CardData_JSON.result
	
	# Loads List of Pre-Built Decks Into Game
	# Currently DOESN'T include Player/Enemy Decks.
	# During early testing it is assumed that White uses Arthurian Pre-Built Deck & Black uses Olympian.
	var MasterDeckList_File = File.new()
	MasterDeckList_File.open("res://Data/Master_Deck_List.json", File.READ)
	var MasterDeckList_JSON = JSON.parse(MasterDeckList_File.get_as_text())
	MasterDeckList_File.close()
	Master_Deck_List = MasterDeckList_JSON.result
