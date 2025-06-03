extends Control

# Import Dependencies
@onready var BC = $Playmat
@onready var DC = $Playmat/CardSpots/NonHands
@onready var IC = $BoardScroller
@onready var UI = $UI
@onready var BF = $Playmat/CardSpots
@onready var Player = $UI/Duelists/HUD_W
@onready var Enemy = $UI/Duelists/HUD_B

# Set Constants
enum Phases {OPENING, STANDBY, MAIN, BATTLE, END}

# Duel Data
var CardData
var Master_Deck_List
var Side: String:
	get:
		return "W" if Current_Turn == "Player" else "B"
var Side_Opp: String:
	get:
		return "B" if Current_Turn == "Player" else "W"
var Dueler: Node:
	get:
		return Player if Current_Turn == "Player" else Enemy
var Dueler_Opp: Node:
	get:
		return Enemy if Current_Turn == "Player" else Player
var Card_Effect_Queue = []
var Victor
var Current_Turn = "Player"
var Turn_Counter = 1
var Current_Phase = Phases.OPENING
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
var CardCounter = 0 # Variable used to name Card nodes



# Potential Game Events:
	# Game-Related
		# - Game, Turn, Phase (Start/End)

	# Card-Related
		# - Drawn (Unique signals for each card type)
		# - Discarded
		# - Banished
		# - Repositioned/Moved/Stolen/Switched (Track Source & Destination Nodes in BM [Reposition for field cards, Moved for cards in hand/medbay/grave, Stolen for cards taken from opponent, Switched for unique cases like Disorient effect])
		# - Replaced (for when Equip cards are replaced on the field)
		# - Sacrificed
		# - Summoned (Unique signals for each summon type [Normal, Fusion, Recruited, Sacrificial, Revived/Retrieved {card summoned from grave/medbay directly}])
		# - Set
		# - Flipped
		# - Captured (Track Attacking/Target cards [how do we want to handle the Equip cards attached to the captured card?])
		# - Equipped/Unequipped (for when Equip cards are attached/detached [also should trigger when a card is moved into/out of a Fighter/Reinforcement slot so that stats are updated appropriately])
		# - Effect Triggered (Unique signals for when an effect is pending resolution and for after an effect has been resolved [to allow for counter effects and post-effect resolution effects])
		# - Attack Declared
	
	# Duelist-Related
		# - Dice Roll/Summon Crests Changed
		# - Deck Reloaded

	# Stat-Related
		# - Stat Changes (Attack, Health, Cost, Tokens, Attacks_Remaining, Toxicity, etc. [Might be best to just have a signal for each setter func, not all would be used currently but that's okay])
		# - Damage Dealt (Unique signals for Battle, Burn, Pierce, etc. [Track Attacking/Target cards in BM])

"""--------------------------------- Engine Functions ---------------------------------"""
func _ready():
	# Setup Signal_Bus functionality. Note: Holder Variables (_HV) serve to eliminate Debugger warnings.
	var _HV1 = SignalBus.connect("Activate_Set_Card", Callable(self, "Activate_Set_Card"))
	var _HV2 = SignalBus.connect("Capture_Card", Callable(self, "Capture_Card"))
	var _HV3 = SignalBus.connect("Discard_Card", Callable(self, "Discard_Card"))
	var _HV4 = SignalBus.connect("Update_GameState", Callable(self, "Update_Game_State"))
	var _HV5 = SignalBus.connect("Advance_Phase", Callable(self, "_on_Next_Phase_pressed"))
	var _HV6 = SignalBus.connect("Advance_Turn", Callable(self, "_on_End_Turn_pressed"))
	var _HV7 = SignalBus.connect("Activate_Summon_Effects", Callable(self, "Activate_Summon_Effects"))
	var _HV8 = SignalBus.connect("Update_HUD_Duelist", Callable(self, "Update_HUD_Duelist"))
	var _HV9 = SignalBus.connect("Summon_Affordable", Callable(self, "Summon_Affordable"))
	var _HV10 = SignalBus.connect("Reload_Deck", Callable(self, "Reload_Deck"))
	var _HV11 = SignalBus.connect("Check_For_Resolvable_Effects", Callable(self, "Check_For_Resolvable_Effects"))
	var _HV12 = SignalBus.connect("Reposition_Field_Cards", Callable(BF, "Reposition_Field_Cards").bind(Side))
	var _HV13 = SignalBus.connect("Play_Card", Callable(self, "Play_Card"))
	var _HV14 = SignalBus.connect("Draw_Card", Callable(self, "Draw_Card"))
	var _HV15 = SignalBus.connect("Reparent_Nodes", Callable(self, "Reparent_Nodes"))
	var _HV16 = SignalBus.connect("Shuffle_Deck", Callable(self, "Shuffle_Deck"))
	var _HV17 = SignalBus.connect("Sacrifice_Card", Callable(self, "Sacrifice_Card"))
	var _HV18 = SignalBus.connect("Hero_Deck_Selected", Callable(BC, "_on_Deck_Slot_pressed"))
	var _HV19 = SignalBus.connect("Cancel", Callable(self, "_on_Cancel_pressed"))
	var _HV20 = SignalBus.connect("Update_Card_Data", Callable(BC, "Update_Card_Data"))
	var _HV21 = SignalBus.connect("Update_Card_Icons", Callable(BC, "Update_Card_Icons"))
	var _HV22 = SignalBus.connect("Event_Attack_Declared", Callable(BC, "Resolve_Battle_Damage"))
	SignalBus.emit_signal("READY") # Temporary signal to ensure Card_Effects script functions as expected. See note in Card_Effects.gd for more info.
	
	Load_Card_Data()
	Setup_Game()



"""--------------------------------- GameState Functions ---------------------------------"""
func Update_Game_State(State_To_Change):
	if Card_Effect_Queue != []:
		Clear_Card_Effect_Queue()
	
	if State_To_Change == "Phase":
		Update_Game_Phase()
	elif State_To_Change == "Turn":
		Update_Game_Turn()

	# Update HUD & Card Icons
	UI.Update_HUD_GameState()
	BC.Update_Card_Data()
	BC.Update_Card_Icons()

func Update_Game_Phase():
	match Current_Phase:
		Phases.OPENING:
			Current_Phase = Phases.STANDBY
		Phases.STANDBY:
			Current_Phase = Phases.MAIN
		Phases.MAIN:
			var Field_Empty = true if BF.Get_Field_Card_Data(Side, "Fighter") + BF.Get_Field_Card_Data(Side, "R") == [] else false
			Current_Phase = Phases.END if Turn_Counter == 1 or Field_Empty else Phases.BATTLE
		Phases.BATTLE:
			BC.Set_Attacks_To_Launch()
			Current_Phase = Phases.END
		Phases.END:
			Update_Game_Turn()
			Current_Phase = Phases.OPENING

func Update_Game_Turn():
	# Complete all incomplete Phases/Steps for remainder of Turn
	while Current_Phase != Phases.END:
		Update_Game_Phase()
	
	# Check if Discard Required to avoid exceeding Hand Size Limit
	if get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand").get_child_count() <= Dueler.Hand_Size_Limit or Victor != null:
		Conduct_End_Phase()
		if Victor == null:
			BC.Reset_Turn_Variables()
			BC.Reset_Attacks_Remaining()
			BC.Set_Turn_Player()
			UI._on_SwitchSides_pressed()
			UI.Flip_Duelist_HUDs()
			
			# Opening & Standby Phases called due to currently requiring no user input
			Conduct_Opening_Phase()
			Conduct_Standby_Phase()
		else: # Eventually this'll call a Show_Victory_Screen() func.
			pass



"""--------------------------------- Utility Functions ---------------------------------"""
func Draw_Card(Turn_Player, Cards_To_Draw = 1, Deck_Type = "Main", Draw_At_Index = 0):
	var player = Player if Turn_Player == "Player" else Enemy
	
	for _i in range(Cards_To_Draw):
		var Card_Info = BC.Draw_Card(player, Deck_Type + "Deck", Draw_At_Index)
		
		if Card_Info != null:
			BF.Reparent_Nodes(Card_Info['Card_Drawn'], Card_Info['Destination_Node'])
			Card_Info['Card_Drawn'].Update_Data()

			# Activate Card Effect when Drawing a Tech Card or Activate Tech Card
			if Card_Info['Card_Drawn'].Type == "Special" or Card_Info['Card_Drawn'].Type == "Tech":
				Card_Info['Card_Drawn'].Can_Activate_Effect = true
				Card_Info['Card_Drawn'].Add_To_Queue()

func Get_Duelist_Cost_Discount(Card_Side, Type):
	var Duelist = Player if Card_Side == "W" else Enemy
	return Duelist.get_discount(Type)



"""--------------------------------- Pass-Along Functions ---------------------------------"""
func _input(event):
	IC.Resolve_Input(event)

func Update_HUD_Duelist(Node_To_Update, Dueler_To_Update):
	UI.Update_HUD_Duelist(Dueler_To_Update, Side)

func Activate_Summon_Effects(Chosen_Card): # Play Card Supporter
	BC.Activate_Summon_Effects(Chosen_Card)

func Reparent_Nodes(Source_Node, Destination_Node):
	BF.Reparent_Nodes(Source_Node, Destination_Node)

func Check_For_Resolvable_Effects(Chosen_Card = null):
	BC.Check_For_Resolvable_Effects(Chosen_Card)

func Sacrifice_Card(Card_Sacrificed):
	BC.Sacrifice_Card(Card_Sacrificed)

func Check_For_Captures():
	BC.Check_For_Captures()



"""--------------------------------- Setup Game Functions ---------------------------------"""
func Setup_Game():
	# Populate Duelist Data
	Player.set_duelist_data("Player", 5)
	Enemy.set_duelist_data("Enemy", 5)

	# Populates & Shuffles Player/Enemy Decks
	DC.Create_Deck("Arthurian", "Player")
	DC.Create_Deck("Olympians", "Enemy")
	DC.Create_Advance_Tech_Card()
	for duelist in [Player, Enemy]:
		for deck in ["MainDeck", "TechDeck", "HeroDeck"]:
			Shuffle_Deck(duelist, deck)
	
	# Set Turn Player for First Turn
	BC.Choose_Starting_Player()
	
	# Draw Opening Hands
	Draw_Card(Current_Turn, 5)
	Current_Turn = "Enemy" if Current_Turn == "Player" else "Player"
	Draw_Card(Current_Turn, 5)
	Current_Turn = "Enemy" if Current_Turn == "Player" else "Player"
	
	# Update GUI
	UI.Update_HUD_GameState()
	UI.Update_HUD_Duelist(Player, "W")
	UI.Update_HUD_Duelist(Enemy, "B")
	
	# Initiate First Turn (Opening & Standby Phase require no user input)
	Conduct_Opening_Phase()
	Conduct_Standby_Phase()



"""--------------------------------- Opening Phase ---------------------------------"""
func Conduct_Opening_Phase():
	# Opening Phase (Start -> Draw -> Roll -> Recruit)	
	Draw_Card(Current_Turn, 1)
	Dueler.set_summon_crests(BC.Dice_Roll(), "Add")
	UI.Update_HUD_Duelist(Dueler, Side)
	BC.Recruit_Hero()
	Update_Game_State("Phase")



"""--------------------------------- Standby Phase ---------------------------------"""
func Conduct_Standby_Phase():
	# Standby Phase (Effect -> Token)
	BC.Set_Field_Card_Effect_Status() # Sets the Can_Activate_Effect of all Periodic-style Hero cards on the turn player's field == True
	BC.Resolve_Damage("Burn") # Resolves Burn Damage from any active Burn Effects
	BC.Add_Tokens()
	Update_Game_State("Phase")



"""--------------------------------- Main Phase ---------------------------------"""
func Play_Card(Summon_Mode, Destination_Node, Chosen_Card):
	var Card_Is_Valid = BC.Valid_Card(Chosen_Card, Destination_Node)
	var Card_Net_Cost = BC.Calculate_Net_Cost(Dueler, Chosen_Card)
	var Destination_Is_Valid = BC.Valid_Destination(Destination_Node, Chosen_Card)
	var Card_Is_Affordable = BC.Summon_Affordable(Dueler, Card_Net_Cost)
	
	if Card_Is_Valid and Destination_Is_Valid and Card_Is_Affordable:
		BF.Play_Card(Side, Card_Net_Cost, Summon_Mode, Destination_Node, Chosen_Card)

func Activate_Set_Card(Chosen_Card):
	BC.Activate_Set_Card(Chosen_Card)
	BF.Activate_Set_Card(Side, Chosen_Card)
	Chosen_Card.Reset_Variables_After_Flip_Summon()



"""--------------------------------- Battle Phase ---------------------------------"""
func Conduct_Battle_Phase():
	# Battle Phase (Selection -> Target -> Damage -> Capture -> Repeat)
	# NOTE: Func skipped entirely due to all steps being handled by other funcs (Except Repeat step which may require some thought to implement)
	pass

func Capture_Card(Card_Captured, Capture_Type = "Normal", Reset_Stats = true):
	BC.Capture_Card(Card_Captured, Capture_Type, Reset_Stats)



"""--------------------------------- End Phase ---------------------------------"""
func Conduct_End_Phase():
	# End Phase (Discard -> Reload -> Effect -> Victory -> End)
	UI.Update_HUD_GameState()	
	BC.Check_For_Deck_Reload()
	
	if BC.Check_For_Deck_Out() or BC.Exodia_Complete():
		print("VICTORY")
		print(Victor + " wins!")
		return

	# HACK: Close out any card effects/action buttons that are still awaiting their signal
	SignalBus.emit_signal("Confirm")
	get_tree().call_group("Cards", "Remove_Action_Buttons")

func Discard_Card(Chosen_Card):
	var MedBay = get_node("Playmat/CardSpots/NonHands/" + Side + "MedBay")
	
	# Updates children for parents in From & To locations
	BF.Reparent_Nodes(Chosen_Card, MedBay)
	
	# Matches focuses of child to new parent.
	BF.Set_Focus_Neighbors("Field", Side, Chosen_Card)
	BF.Set_Focus_Neighbors("Hand", Side, get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand"))
	
	# Retry to End Turn
	while get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand").get_child_count() > Dueler.Hand_Size_Limit:
		return
	if Current_Phase == Phases.END:
		Update_Game_Turn()

func Reload_Deck(Deck_To_Reload):
	BF.Reload_Deck(Deck_To_Reload)

func Shuffle_Deck(player, deck_source):
	DC.Shuffle_Deck(player, deck_source)



"""--------------------------------- Miscellaneous Functions ---------------------------------"""
func Load_Card_Data():
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

func Clear_Card_Effect_Queue():
	for card in Card_Effect_Queue:
		card.get_node("SmallCard/Can_Activate_Effect").visible = false # Hide snake animation
	Card_Effect_Queue.clear()



#######################################
# SIGNAL FUNCTIONS
#######################################
func _on_Playmat_gui_input(event):
	IC.Scroll(event)

func _on_SwitchSides_pressed():
	UI._on_SwitchSides_pressed()

func _on_Deck_Slot_pressed():
	BC._on_Deck_Slot_pressed()

func _on_Next_Phase_pressed():
	Update_Game_State("Phase")

func _on_End_Turn_pressed():
	Update_Game_State("Turn")

func _on_Cancel_pressed():
	get_tree().call_group("Cards", "Remove_Action_Buttons")
