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
const FUSION_CARDS = [79248843]
var Cards_Summoned_This_Turn = []
var Cards_Captured_This_Turn = []
var Attacks_To_Launch = 0
var Attacker
var Target
var For_Honor_And_Glory = false
var Player = Duelist.new("Player",100,50,0,0,0,0,0,0,0,0,false,[],[],[],[],[],[],[],[],[],[],"None")
var Enemy = Duelist.new("Enemy",100,50,0,0,0,0,0,0,0,0,false,[],[],[],[],[],[],[],[],[],[],"None")

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
var Resolve_On_Opposing_Card = false
var Muggle_Mode = false
var Auto_Spring_Traps = false
var ChosenCard

# Variable used to name Card nodes
var CardCounter = 0

# Variable used to indicate which Card Effects are being used.
var Current_Card_Effect_Step

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
