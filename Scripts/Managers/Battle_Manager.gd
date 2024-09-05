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
const PHASES = ["Opening Phase", "Standby Phase", "Main Phase", "Battle Phase", "End Phase"]
const PHASE_THRESHOLDS = [3, 5, 6, 11, 16]
const STEPS = ["Start", "Draw", "Roll", "Recruit", "Effect", "Token", "Main", "Selection", "Target", "Damage", "Capture", "Repeat", "Discard", "Reload", "Effect", "Victory", "End"]
const EFFECT_STEPS = ["Start", "Effect", "Selection", "Damage", "Capture", "Discard"] # Discard may/may not end up being an Effect Step. You just added it, just in case.
const FUNC_STEPS = ["Damage"]

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
	var _HV11 = SignalBus.connect("Resolve_Card_Effects", Callable(self, "Resolve_Card_Effects"))
	var _HV12 = SignalBus.connect("Reposition_Field_Cards", Callable(self, "Reposition_Field_Cards"))
	var _HV13 = SignalBus.connect("Play_Card", Callable(self, "Play_Card"))
	var _HV14 = SignalBus.connect("Draw_Card", Callable(self, "Draw_Card"))
	var _HV15 = SignalBus.connect("Reparent_Nodes", Callable(self, "Reparent_Nodes"))
	var _HV16 = SignalBus.connect("Shuffle_Deck", Callable(self, "Shuffle_Deck"))
	var _HV17 = SignalBus.connect("Sacrifice_Card", Callable(self, "Sacrifice_Card"))
	var _HV18 = SignalBus.connect("Hero_Deck_Selected", Callable(self, "Hero_Deck_Selected"))
	var _HV19 = SignalBus.connect("Cancel", Callable(self, "_on_Cancel_pressed"))
	SignalBus.emit_signal("READY") # Temporary signal to ensure Card_Effects script functions as expected. See note in Card_Effects.gd for more info.
	
	Setup_Game()



"""--------------------------------- GameState Functions ---------------------------------"""
func Update_Game_State(State_To_Change):
	if State_To_Change == "Step":
		Update_Game_Step()
	elif State_To_Change == "Phase":
		Update_Game_Phase()
	elif State_To_Change == "Turn":
		Update_Game_Turn()

	# Update HUD
	UI.Update_HUD_GameState()
	
	# Print DEBUG
	print(GameData.Current_Phase + " - " + GameData.Current_Step)

func Update_Game_Step():
	var player = Player if GameData.Current_Turn == "Player" else Enemy
	var Side = "W" if GameData.Current_Turn == "Player" else "B"	
	
	# Call required funcs at appropriate Steps (and contain step values within bounds of current Phase)
	if GameData.Current_Step in EFFECT_STEPS: # Ensures that Card Effects are resolved when appropriate (moved to first if statement to ensure effects are resolved before step is handled [important for Damage step-related card efffects])
		BC.Resolve_Card_Effects()
	if STEPS.find(GameData.Current_Step) == 9: # Current Step is Damage Step
		BC.Resolve_Damage("Battle")
	if STEPS.find(GameData.Current_Step) == 12 and get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand").get_child_count() > player.Hand_Size_Limit and GameData.Victor == null: # Ensures cards are discarded when appropriate
		return
	
	# Update Step value
	if STEPS.find(GameData.Current_Step) + 1 > len(STEPS): # Resets index to start of New Turn.
		GameData.Current_Step = STEPS[0]
	elif STEPS.find(GameData.Current_Step) in PHASE_THRESHOLDS: # Ensures that you can't advance to a Step that belongs to a different Phase
		return
	elif STEPS.find(GameData.Current_Step) == 4 and GameData.Current_Phase == "End Phase": # Fixes bug where Step state would reset to Standby Phases' Effect Step (instead of End Phases' Effect Step)
		GameData.Current_Step = STEPS[15]
	elif STEPS.find(GameData.Current_Step) == 10 and player.Valid_Attackers == 0: # Skips Repeat Step if no valid attackers remain
		GameData.Current_Phase = PHASES[4]
		GameData.Current_Step = STEPS[12]
	else:
		GameData.Current_Step = STEPS[STEPS.find(GameData.Current_Step) + 1]

func Update_Game_Phase():
	if PHASES.find(GameData.Current_Phase) + 1 >= len(PHASES): # Ensures game doesn't crash when trying to advance to a non-existent Phase.
		return
	elif GameData.Turn_Counter == 1 and PHASES.find(GameData.Current_Phase) == 2: # Skips Battle Phase on first turn of game
		GameData.Current_Phase = PHASES[PHASES.find(GameData.Current_Phase) + 2]
		GameData.Current_Step = STEPS[12]
	else:
		GameData.Current_Phase = PHASES[PHASES.find(GameData.Current_Phase) + 1]
		GameData.Current_Step = STEPS[PHASE_THRESHOLDS[PHASES.find(GameData.Current_Phase) - 1] + 1]
	
	# Ensures that Attacks to Launch is set at start of each Battle Phase
	if GameData.Current_Phase == "Battle Phase":
		BC.Set_Attacks_To_Launch()
	
	# Skips Battle Phase if no cards are in player's Fighter/Reinforcement slots
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Fighter = BF.Get_Field_Card_Data(Side, "Fighter")
	var Reinforcers = BF.Get_Field_Card_Data(Side, "R")

	if GameData.Current_Phase == "Battle Phase" and Fighter + Reinforcers == []:
		Update_Game_Phase()

func Update_Game_Turn():
	var player = Player if GameData.Current_Turn == "Player" else Enemy
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	
	# Complete all incomplete Phases/Steps for remainder of Turn
	while GameData.Current_Phase != "End Phase":
		if STEPS.find(GameData.Current_Step) in PHASE_THRESHOLDS:
			Update_Game_Phase()
		else:
			Update_Game_Step()
	
	# Check if Discard Required to avoid exceeding Hand Size Limit
	if get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand").get_child_count() <= player.Hand_Size_Limit or GameData.Victor != null:
		Conduct_End_Phase()
		if GameData.Victor == null:
			BC.Reset_Turn_Variables(PHASES, STEPS)
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
		BF.Reparent_Nodes(Card_Info['Card_Drawn'], Card_Info['Destination_Node'])
		Card_Info['Card_Drawn'].Update_Data()

		# Activate Card Effect when Drawing a Tech Card or Activate Tech Card
		if Card_Info['Card_Drawn'].Type == "Special" or Card_Info['Card_Drawn'].Type == "Tech":
			BC.Activate_Summon_Effects(Card_Info['Card_Drawn'])



"""--------------------------------- Pass-Along Functions ---------------------------------"""
func _input(event):
	IC.Resolve_Input(event)

func Update_HUD_Duelist(Node_To_Update, Dueler):
	var Side = "W" if Dueler.Name == "Player" else "B"
	UI.Update_HUD_Duelist(Dueler, Side)

func Activate_Summon_Effects(Chosen_Card): # Play Card Supporter
	BC.Activate_Summon_Effects(Chosen_Card)

func Reparent_Nodes(Source_Node, Destination_Node):
	BF.Reparent_Nodes(Source_Node, Destination_Node)

func Reposition_Field_Cards(Side):
	BF.Reposition_Field_Cards(Side)

func Resolve_Card_Effects():
	BC.Resolve_Card_Effects()

func Sacrifice_Card(Card_Sacrificed):
	BC.Sacrifice_Card(Card_Sacrificed)

func Hero_Deck_Selected():
	BC._on_Deck_Slot_pressed()



"""--------------------------------- Setup Game Functions ---------------------------------"""
func Setup_Game():
	# Populate Duelist Data
	Player.set_duelist_data("Player", 0)
	Enemy.set_duelist_data("Enemy", 0)

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
	GameData.Current_Step = "Draw"
	Draw_Card(GameData.Current_Turn, 5)
	GameData.Current_Turn = "Enemy" if GameData.Current_Turn == "Player" else "Player"
	Draw_Card(GameData.Current_Turn, 5)
	GameData.Current_Turn = "Enemy" if GameData.Current_Turn == "Player" else "Player"
	GameData.Current_Step = "Start"
	
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
	var player = Player if GameData.Current_Turn == "Player" else Enemy
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	
	Update_Game_State("Step")
	Draw_Card(GameData.Current_Turn, 1)
	Update_Game_State("Step")
	player.set_summon_crests(BC.Dice_Roll(), "Add")
	UI.Update_HUD_Duelist(player, Side)
	Update_Game_State("Step")
	BC.Recruit_Hero()
	Update_Game_State("Phase")



"""--------------------------------- Standby Phase ---------------------------------"""
func Conduct_Standby_Phase():
	# Standby Phase (Effect -> Token)
	BC.Set_Field_Card_Effect_Status() # Sets the Can_Activate_Effect of all Periodic-style Hero cards on the turn player's field == True
	BC.Resolve_Damage("Burn") # Resolves Burn Damage from any active Burn Effects
	Update_Game_State("Step")
	BC.Add_Tokens()
	Update_Game_State("Phase")



"""--------------------------------- Main Phase ---------------------------------"""
func Conduct_Main_Phase():
	# Main Phase (Reposition -> Summon/Set -> Flip)
	# NOTE: Func skipped entirely due to all steps being handled by other funcs
	# Reposition handled by Reposition_Field_Cards(),
	# Summon/Set by _on_Card_Slot_pressed() and Play_Card(),
	# Flip by on_Focus_Sensor_pressed() in SmallCard.gd and Activate_Set_Card()
	pass

func Play_Card(Side, Summon_Mode, Destination_Node, Chosen_Card):
	var player = Player if GameData.Current_Turn == "Player" else Enemy
	var Card_Is_Valid = BC.Valid_Card(Side, Chosen_Card, Destination_Node)
	var Card_Net_Cost = BC.Calculate_Net_Cost(player, Chosen_Card)
	var Destination_Is_Valid = BC.Valid_Destination(Side, Destination_Node, Chosen_Card)
	var Card_Is_Affordable = BC.Summon_Affordable(player, Card_Net_Cost)
	
	if Card_Is_Valid and Destination_Is_Valid and Card_Is_Affordable:
		BF.Play_Card(Side, Card_Net_Cost, Summon_Mode, Destination_Node, Chosen_Card)

func Activate_Set_Card(Side, Chosen_Card):
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
	# Reload Step
	Update_Game_State("Step")
	UI.Update_HUD_GameState()	
	BC.Check_For_Deck_Reload()
	
	# Effect Step
	Update_Game_State("Step")
	
	# Victory Step
	Update_Game_State("Step")
	if BC.Check_For_Deck_Out() or BC.Exodia_Complete():
		print("VICTORY")
		print(GameData.Victor + " wins!")
		return

	# HACK: Close out any card effects/action buttons that are still awaiting their signal
	SignalBus.emit_signal("Confirm")
	get_tree().call_group("Cards", "Remove_Action_Buttons")
	
	# End Step
	Update_Game_State("Step")

func Discard_Card(Side, Chosen_Card):
	var Dueler = Player if GameData.Current_Turn == "Player" else Enemy
	var MedBay = get_node("Playmat/CardSpots/NonHands/" + Side + "MedBay")
	
	# Updates children for parents in From & To locations
	BF.Reparent_Nodes(Chosen_Card, MedBay)
	
	# Matches focuses of child to new parent.
	BF.Set_Focus_Neighbors("Field", Side, Chosen_Card)
	BF.Set_Focus_Neighbors("Hand", Side, get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand"))
	
	# Retry to End Turn
	while get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand").get_child_count() > Dueler.Hand_Size_Limit:
		return
	if GameData.Current_Step == "Discard":
		Update_Game_Turn()

func Reload_Deck(Deck_To_Reload):
	BF.Reload_Deck(Deck_To_Reload)

func Shuffle_Deck(player, deck_source):
	DC.Shuffle_Deck(player, deck_source)



#######################################
# SIGNAL FUNCTIONS
#######################################
func _on_Playmat_gui_input(event):
	IC.Scroll(event)

func _on_SwitchSides_pressed():
	UI._on_SwitchSides_pressed()

func _on_Deck_Slot_pressed():
	BC._on_Deck_Slot_pressed()

func _on_Next_Step_pressed():
	Update_Game_State("Step")

func _on_Next_Phase_pressed():
	Update_Game_State("Phase")

func _on_End_Turn_pressed():
	Update_Game_State("Turn")

func _on_Cancel_pressed():
	get_tree().call_group("Cards", "Remove_Action_Buttons")
