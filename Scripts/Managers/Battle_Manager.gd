extends Control

const PHASES = ["Opening Phase", "Standby Phase", "Main Phase", "Battle Phase", "End Phase"]
const PHASE_THRESHOLDS = [2, 4, 5, 10, 15]
const STEPS = ["Start", "Draw", "Roll", "Effect", "Token", "Main", "Selection", "Target", "Damage", "Capture", "Repeat", "Discard", "Reload", "Effect", "Victory", "End"]
const EFFECT_STEPS = ["Effect", "Selection", "Damage", "Capture", "Discard"] # Discard may/may not end up being an Effect Step. You just added it, just in case (also Summon/Set should be added to check for Event-effects like Mordred's).
const FUNC_STEPS = ["Damage"]

# Import Dependencies
@onready var BC = BattleController.new()
@onready var CC = CombatantController.new() # Represents Duelist. Used Combatant due to Duelist class already being used AND DC alias already being used by DeckController.
@onready var DC = DeckController.new()
@onready var IC = InputController.new()
@onready var UI = UIController.new()
@onready var BF = FieldController.new()


"""--------------------------------- Engine Functions ---------------------------------"""
func _ready():
	# Setup Signal_Bus functionality. Note: Holder Variables (_HV) serve to eliminate Debugger warnings.
	var _HV1 = SignalBus.connect("Activate_Set_Card", Callable(self, "Activate_Set_Card"))
	var _HV2 = SignalBus.connect("Check_For_Targets", Callable(self, "Check_For_Targets"))
	var _HV3 = SignalBus.connect("Capture_Card", Callable(self, "Capture_Card"))
	var _HV4 = SignalBus.connect("Discard_Card", Callable(self, "Discard_Card"))
	var _HV5 = SignalBus.connect("Update_GameState", Callable(self, "Update_Game_State"))
	var _HV6 = SignalBus.connect("Advance_Phase", Callable(self, "_on_Next_Phase_pressed"))
	var _HV7 = SignalBus.connect("Advance_Turn", Callable(self, "_on_End_Turn_pressed"))
	var _HV8 = SignalBus.connect("Activate_Summon_Effects", Callable(self, "Activate_Summon_Effects"))
	var _HV9 = SignalBus.connect("Update_HUD_Duelist", Callable(self, "Update_HUD_Duelist"))
	var _HV10 = SignalBus.connect("Summon_Affordable", Callable(self, "Summon_Affordable"))
	var _HV11 = SignalBus.connect("Summon_Set_Pressed", Callable(self, "_on_Card_Slot_pressed"))
	var _HV12 = SignalBus.connect("Clear_MedBay", Callable(self, "Clear_MedBay"))
	var _HV13 = SignalBus.connect("Resolve_Card_Effects", Callable(self, "Resolve_Card_Effects"))
	var _HV14 = SignalBus.connect("Reposition_Field_Cards", Callable(self, "Reposition_Field_Cards"))
	var _HV15 = SignalBus.connect("Reset_Reposition_Card_Variables", Callable(self, "Reset_Reposition_Card_Variables"))
	var _HV16 = SignalBus.connect("Play_Card", Callable(self, "Play_Card"))
	var _HV17 = SignalBus.connect("Draw_Card", Callable(self, "Draw_Card"))
	var _HV18 = SignalBus.connect("Reparent_Nodes", Callable(self, "Reparent_Nodes"))
	
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
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var Side = "W" if GameData.Current_Turn == "Player" else "B"	
	
	# Call required funcs at appropriate Steps (and contain step values within bounds of current Phase)
	if GameData.Current_Step in EFFECT_STEPS: # Ensures that Card Effects are resolved when appropriate (moved to first if statement to ensure effects are resolved before step is handled [important for Damage step-related card efffects])
		BC.Resolve_Card_Effects()
	if STEPS.find(GameData.Current_Step) == 8: # Current Step is Damage Step
		Resolve_Battle_Damage()
	if STEPS.find(GameData.Current_Step) == 11 and get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand").get_child_count() > 5: # Ensures cards are discarded when appropriate
		return
	
	# Update Step value
	if STEPS.find(GameData.Current_Step) + 1 > len(STEPS): # Resets index to start of New Turn.
		GameData.Current_Step = STEPS[0]
	elif STEPS.find(GameData.Current_Step) in PHASE_THRESHOLDS: # Ensures that you can't advance to a Step that belongs to a different Phase
		return
	elif STEPS.find(GameData.Current_Step) == 3 and GameData.Current_Phase == "End Phase": # Fixes bug where Step state would reset to Standby Phases' Effect Step (instead of End Phases' Effect Step)
		GameData.Current_Step = STEPS[14]
	elif STEPS.find(GameData.Current_Step) == 9 and player.Valid_Attackers == 0:
		GameData.Current_Phase = PHASES[4]
		GameData.Current_Step = STEPS[11]
	else:
		GameData.Current_Step = STEPS[STEPS.find(GameData.Current_Step) + 1]

func Update_Game_Phase():
	var Dueler = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy

	if PHASES.find(GameData.Current_Phase) + 1 >= len(PHASES): # Ensures game doesn't crash when trying to advance to a non-existent Phase.
		return
	elif GameData.Turn_Counter == 1 and PHASES.find(GameData.Current_Phase) == 2: # Skips Battle Phase on first turn of game
		GameData.Current_Phase = PHASES[PHASES.find(GameData.Current_Phase) + 2]
		GameData.Current_Step = STEPS[11]
	else:
		GameData.Current_Phase = PHASES[PHASES.find(GameData.Current_Phase) + 1]
		print("Phase Conversion: " + str(STEPS[PHASE_THRESHOLDS[PHASES.find(GameData.Current_Phase) - 1] + 1]))
		GameData.Current_Step = STEPS[PHASE_THRESHOLDS[PHASES.find(GameData.Current_Phase) - 1] + 1]
	
	# Ensures that Attacks to Launch is set at start of each Battle Phase
	if GameData.Current_Phase == "Battle Phase":
		Set_Attacks_To_Launch()
	
	# Skips Battle Phase if no cards are in player's Fighter/Reinforcement slots
	if GameData.Current_Phase == "Battle Phase" and len(Dueler.Fighter) + len(Dueler.Reinforcement) == 0:
		Update_Game_Phase()

func Update_Game_Turn():
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	
	# Complete all incomplete Phases/Steps for remainder of Turn
	while GameData.Current_Phase != "End Phase":
		if STEPS.find(GameData.Current_Step) in PHASE_THRESHOLDS:
			Update_Game_Phase()
		else:
			Update_Game_Step()
	
	# Check if Discard Required to avoid exceeding Hand Size Limit
	if get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand").get_child_count() <= 5:
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
func Draw_Card(Turn_Player, Cards_To_Draw = 1, Deck_Type = "Main", Draw_At_Index = -1):
	var player = GameData.Player if Turn_Player == "Player" else GameData.Enemy
	var Deck_ID
	if Deck_Type == "Main":
		Deck_ID = "WMainDeck" if Turn_Player == "Player" else "BMainDeck"
	elif Deck_Type == "Tech":
		Deck_ID = "WTechDeck" if Turn_Player == "Player" else "BTechDeck"
	
	# Allows for single draws of specific cards
	if Draw_At_Index != -1:
		var InstanceCard = BC.Instantiate_Card()
		if Deck_Type == "Main":
			InstanceCard.Set_Card_Variables(Draw_At_Index, "TurnMainDeck")
			InstanceCard.Set_Card_Visuals()
			BF.Add_Card_Node_To_Hand(Deck_ID, InstanceCard)
			InstanceCard.Update_Data()
			BC.Draw_Card(player, InstanceCard)
			DC.Pop_Deck(player, "Main", Draw_At_Index)

			# Activate Advance Tech Card Effect when Drawn
			if InstanceCard.Type == "Special":
				BC.Activate_Summon_Effects(InstanceCard)

		elif Deck_Type == "Tech":
			InstanceCard.Set_Card_Variables(Draw_At_Index, "TurnTechDeck")
			InstanceCard.Set_Card_Visuals()
			BF.Add_Card_Node_To_Tech_Zone(Deck_ID, InstanceCard)
			InstanceCard.Update_Data()
			DC.Pop_Deck(player, "Tech", Draw_At_Index)

			# Activate Tech Effect
			BC.Activate_Summon_Effects(InstanceCard)
		
		return
	
	for _i in range(Cards_To_Draw):
		var InstanceCard = BC.Instantiate_Card()
		if Deck_Type == "Main":
			InstanceCard.Set_Card_Variables(Draw_At_Index, "TurnMainDeck")
			InstanceCard.Set_Card_Visuals()
			BF.Add_Card_Node_To_Hand(Deck_ID, InstanceCard)
			InstanceCard.Update_Data()
			BC.Draw_Card(player, InstanceCard)
			DC.Pop_Deck(player)

			# Activate Advance Tech Card Effect when Drawn
			if InstanceCard.Type == "Special":
				BC.Activate_Summon_Effects(InstanceCard)

		elif Deck_Type == "Tech":
			InstanceCard.Set_Card_Variables(Draw_At_Index, "TurnTechDeck")
			InstanceCard.Set_Card_Visuals()
			BF.Add_Card_Node_To_Tech_Zone(Deck_ID, InstanceCard)
			InstanceCard.Update_Data()
			DC.Pop_Deck(player, "Tech")

			# Activate Tech Effect
			BC.Activate_Summon_Effects(InstanceCard)

func Add_Tokens():
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Backrow_Slots = BF.Get_Field_Card_Data($Playmat/CardSpots/NonHands, Side, "Backrow")
	BC.Add_Tokens(Backrow_Slots)



"""--------------------------------- Major Support Functions ---------------------------------"""
# Battle Phase Supporters
func Check_For_Targets():
	var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
	var Fighter_Opp = BF.Get_Field_Card_Data($Playmat/CardSpots/NonHands, Side_Opp, "Fighter")
	
	BC.Check_For_Targets(Fighter_Opp)
	UI.Update_HUD_GameState()

func Set_Attacks_To_Launch():
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Fighter = BF.Get_Field_Card_Data($Playmat/CardSpots/NonHands, Side, "Fighter")
	var Reinforcers = BF.Get_Field_Card_Data($Playmat/CardSpots/NonHands, Side, "R")
	
	BC.Set_Attacks_To_Launch(Fighter, Reinforcers)



"""--------------------------------- Pass-Along Functions ---------------------------------"""
func _input(event):
	IC.Advance_GameState(event)
	IC.Confirm(event)

func Update_HUD_Duelist(Node_To_Update, Dueler):
	UI.Update_HUD_Duelist(Node_To_Update, Dueler)

func Activate_Summon_Effects(Chosen_Card): # Play Card Supporter
	BC.Activate_Summon_Effects(Chosen_Card)

func Reparent_Nodes(Source_Node, Destination_Node):
	BF.Reparent_Nodes(Source_Node, Destination_Node)

func Reposition_Field_Cards(Side):
	BF.Reposition_Field_Cards(Side)

func Resolve_Card_Effects():
	BC.Resolve_Card_Effects()

func Reset_Reposition_Card_Variables():
	BC.Reset_Reposition_Card_Variables()



"""--------------------------------- Setup Game Functions ---------------------------------"""
func Setup_Game():
	# Populates & Shuffles Player/Enemy Decks
	DC.Create_Deck("Arthurian", "Player")
	DC.Create_Deck("Olympians", "Enemy")
	DC.Create_Advance_Tech_Card()
	DC.Shuffle_Deck(GameData.Player)
	DC.Shuffle_Deck(GameData.Enemy)
	
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
	UI.Update_HUD_Duelist(get_node("HUD_W"), GameData.Player)
	UI.Update_HUD_Duelist(get_node("HUD_B"), GameData.Enemy)
	UI.Update_Deck_Counts()
	
	# Set Turn Player
	BC.Set_Turn_Player()
	
	# Initiate First Turn (Opening & Standby Phase require no user input)
	Conduct_Opening_Phase()
	Conduct_Standby_Phase()



"""--------------------------------- Opening Phase ---------------------------------"""
func Conduct_Opening_Phase():
	# Opening Phase (Start -> Draw -> Roll)
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Result
	
	Update_Game_State("Step")
	Draw_Card(GameData.Current_Turn, 1)
	UI.Update_Deck_Counts()
	Update_Game_State("Step")
	Result = Utils.Dice_Roll()
	player.Update_Summon_Crests(Result)
	UI.Update_HUD_Duelist(get_node("HUD_" + Side), player)
	Update_Game_State("Phase")



"""--------------------------------- Standby Phase ---------------------------------"""
func Conduct_Standby_Phase():
	# Standby Phase (Effect -> Token)
	BC.Set_Hero_Card_Effect_Status() # Sets the Effect_Active of all Periodic-style Hero cards on the turn player's field == True
	BC.Resolve_Burn_Damage() # Resolves Burn Damage from any active Burn Effects
	Update_Game_State("Step")
	Add_Tokens()
	Update_Game_State("Phase")



"""--------------------------------- Main Phase ---------------------------------"""
func Conduct_Main_Phase():
	# Main Phase (Reparenttion -> Summon/Set -> Flip)
	# NOTE: Func skipped entirely due to all steps being handled by other funcs
	# Reposition handled by Reposition_Field_Cards(),
	# Summon/Set by _on_Card_Slot_pressed() and Play_Card(),
	# Flip by on_Focus_Sensor_pressed() in SmallCard.gd and Activate_Set_Card()
	pass

func Play_Card(Base_Node, Side):
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var Card_Is_Valid = BC.Valid_Card(Base_Node.get_parent(), Side, GameData.Chosen_Card)
	var Card_Net_Cost = BC.Calculate_Net_Cost(player, GameData.Chosen_Card)
	var Destination_Is_Valid = BC.Valid_Destination(Side, GameData.CardTo, GameData.Chosen_Card)
	var Card_Is_Affordable = BC.Summon_Affordable(player, Card_Net_Cost)
	
	if Card_Is_Valid and Destination_Is_Valid and Card_Is_Affordable:
		BF.Play_Card(Base_Node, Side, Card_Net_Cost)

func Activate_Set_Card(Side, Chosen_Card):
	BC.Activate_Set_Card(Chosen_Card)
	BF.Activate_Set_Card(Side, Chosen_Card)
	Chosen_Card.Reset_Variables_After_Flip_Summon()



"""--------------------------------- Battle Phase ---------------------------------"""
func Conduct_Battle_Phase():
	# Battle Phase (Selection -> Target -> Damage -> Capture -> Repeat)
	# NOTE: Func skipped entirely due to all steps being handled by other funcs (Except Repeat step which may require some thought to implement)
	pass

func Resolve_Battle_Damage():
	var Side_Opp = "B" if GameData.Current_Turn == "Player" else "W"
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var enemy = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	var Reinforcers_Opp = BF.Get_Field_Card_Data($Playmat/CardSpots/NonHands, Side_Opp, "R")
	
	BC.Resolve_Battle_Damage(Reinforcers_Opp, player, enemy)
	UI.Update_HUD_Duelist(get_node("HUD_" + Side_Opp), enemy)
	UI.Update_HUD_GameState()

func Capture_Card(Card_Captured, Capture_Type = "Normal", Reset_Stats = true):
	var attacking_player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var defending_player = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	var Destination_MedBay = BC.Get_Destination_MedBay_on_Capture(Capture_Type)
	var Parent_Name = Card_Captured.get_parent().name
	var Fighter_Captured = true if "Fighter" in Parent_Name else false
	
	# Capture Targeted Card
	BC.Capture_Card(attacking_player, defending_player, Card_Captured, "MedBay")
	BF.Reparent_Nodes(Card_Captured, Destination_MedBay)

	# Move Equips to Graveyard when Fighter is Captured
	if Fighter_Captured:
		var Side = "W" if defending_player == GameData.Player else "B"
		var Equip_Magic_Slot = BC.Get_Field_Card_Slot(Side, "EquipMagic")
		var Equip_Trap_Slot = BC.Get_Field_Card_Slot(Side, "EquipTrap")
		var Graveyard = BC.Get_Destination_Graveyard_on_Capture(Capture_Type)

		if Equip_Magic_Slot.get_child_count() > 0:
			var Equip_Magic_Card = Equip_Magic_Slot.get_child(0)
			BC.Capture_Card(attacking_player, defending_player, Equip_Magic_Card, "Graveyard")
			BF.Reparent_Nodes(Equip_Magic_Card, Graveyard)
		if Equip_Trap_Slot.get_child_count() > 0:
			var Equip_Trap_Card = Equip_Trap_Slot.get_child(0)
			BC.Capture_Card(attacking_player, defending_player, Equip_Trap_Card, "Graveyard")
			BF.Reparent_Nodes(Equip_Trap_Card, Graveyard)
	
	# Reset Captured Card's Stats/Visuals
	if Reset_Stats:
		Card_Captured.Reset_Stats_On_Capture()
		Card_Captured.Update_Data()



"""--------------------------------- End Phase ---------------------------------"""
func Conduct_End_Phase():
	# End Phase (Discard -> Reload -> Effect -> Victory -> End)
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	
	# May/may not be needed depending on if Discard step remains an EFFECT step.
	BC.Resolve_Card_Effects()
	
	# Reload Step
	GameData.Current_Step = "Reload"
	
	# Update HUD
	UI.Update_HUD_GameState()
	
	# Check for required Reload
	DC.Reload_Deck(player.Deck, player.MedicalBay)
	DC.Shuffle_Deck(player)
	UI.Update_Deck_Counts()
	
	# Effect Step
	GameData.Current_Step = "Effect"
	BC.Resolve_Card_Effects()
	
	# Victory Step
	GameData.Current_Step = "Victory"
	if BC.Check_For_Victor_LP() or BC.Check_For_Victor_Deck_Out():
		print("VICTORY")
		print(GameData.Victor + " wins!")
		return

	# HACK: Close out any card effects that are still stuck awaiting the Confirm signal
	SignalBus.emit_signal("Confirm")
	
	# End Step
	GameData.Current_Step = "End"

func Discard_Card(Side):
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var CardMoved = get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand/" + str(GameData.CardMoved))
	var MedBay = get_node("Playmat/CardSpots/NonHands/" + Side + "MedBay")
	
	# Updates children for parents in From & To locations
	BF.Reparent_Nodes(CardMoved, MedBay)
	
	# Matches focuses of child to new parent.
	BF.Set_Focus_Neighbors("Field",Side,CardMoved)
	BF.Set_Focus_Neighbors("Hand",Side,get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand"))
	
	# Update Duelist's Hand & MedicalBay Array
	player.Hand.erase(CardMoved)
	player.MedicalBay.append(CardMoved)
	
	# Resets GameData variables for next movement.
	BC.Reset_Reposition_Card_Variables()
	
	# Retry to End Turn
	while get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand").get_child_count() > 5:
		return
	if GameData.Current_Step == "Discard":
		Update_Game_Turn()

func Clear_MedBay():
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var Side = "W" if player == GameData.Player else "B"
	var Node_MedBay = get_node("Playmat/CardSpots/NonHands/" + Side + "MedBay")
	
	BF.Clear_MedBay(Node_MedBay)



#######################################
# SIGNAL FUNCTIONS
#######################################
func _on_Playmat_gui_input(event):
	IC.Scroll(event)

func _on_SwitchSides_pressed():
	UI._on_SwitchSides_pressed()

func _on_Card_Slot_pressed(slot_name):
	BF._on_Card_Slot_pressed($Playmat/CardSpots/NonHands, slot_name)

func _on_Next_Step_pressed():
	Update_Game_State("Step")

func _on_Next_Phase_pressed():
	Update_Game_State("Phase")

func _on_End_Turn_pressed():
	Update_Game_State("Turn")
