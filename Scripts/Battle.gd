extends Control

const PHASES = ["Opening Phase", "Standby Phase", "Main Phase", "Battle Phase", "End Phase"]
const PHASE_THRESHOLDS = [2, 4, 5, 10, 15]
const STEPS = ["Start", "Draw", "Roll", "Effect", "Token", "Main", "Selection", "Target", "Damage", "Capture", "Repeat", "Discard", "Reload", "Effect", "Victory", "End"]
const EFFECT_STEPS = ["Effect", "Selection", "Damage", "Capture", "Discard"] # Discard may/may not end up being an Effect Step. You just added it, just in case (also Summon/Set should be added to check for Event-effects like Mordred's).
const FUNC_STEPS = ["Damage"]

var BoardImage = preload("res://Assets/Playmat/BoardImage.png")
var BoardImageReverse = preload("res://Assets/Playmat/BoardImageReverse.png")
var Card_Drawn = preload("res://Scenes/SupportScenes/SmallCard.tscn")


"""--------------------------------- Engine Functions ---------------------------------"""
func _ready():
	print("READY")
	# Setup Signal_Bus functionality. Note: Holder Variables (_HV) serve to eliminate Debugger warnings.
	var _HV1 = SignalBus.connect("Reposition_Field_Cards", Callable(self, "Reposition_Field_Cards"))
	var _HV2 = SignalBus.connect("Play_Card", Callable(self, "Play_Card"))
	var _HV3 = SignalBus.connect("Activate_Set_Card", Callable(self, "Activate_Set_Card"))
	var _HV4 = SignalBus.connect("Check_For_Targets", Callable(self, "Check_For_Targets"))
	var _HV5 = SignalBus.connect("Capture_Card", Callable(self, "Capture_Card"))
	var _HV6 = SignalBus.connect("Discard_Card", Callable(self, "Discard_Card"))
	var _HV7 = SignalBus.connect("Update_GameState", Callable(self, "Update_Game_State"))
	
	Setup_Game()

func _input(event):
	if event.is_action_pressed("next_phase"):
		_on_Next_Phase_pressed()
		Fake_Click()
	if event.is_action_pressed("end_turn"):
		_on_End_Turn_pressed()
		Fake_Click()



"""--------------------------------- GameState Functions ---------------------------------"""
func Update_Game_State(State_To_Change):
	if State_To_Change == "Step":
		Update_Game_Step()
	elif State_To_Change == "Phase":
		Update_Game_Phase()
	elif State_To_Change == "Turn":
		Update_Game_Turn()

	# Update HUD
	$HUD_GameState.Update_Data()
	
	# Print DEBUG
	print(GameData.Current_Phase + " - " + GameData.Current_Step)

func Update_Game_Step():
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	
	# Call required funcs at appropriate Steps (and contain step values within bounds of current Phase)
	if STEPS.find(GameData.Current_Step) == 8: # Current Step is Damage Step
		Resolve_Battle_Damage()
	if STEPS.find(GameData.Current_Step) == 11 and get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand").get_child_count() > 5: # Ensures cards are discarded when appropriate
		return
	if GameData.Current_Step in EFFECT_STEPS: # Ensures that Card Effects are resolved when appropriate
		Resolve_Card_Effects()
	
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
			Reset_Turn_Variables()
			Set_Turn_Player()
			# Flip Field & HUDs
			_on_SwitchSides_pressed()
			Flip_HUDs()

			# Opening & Standby Phases called due to currently requiring no user input
			Conduct_Opening_Phase()
			Conduct_Standby_Phase()
		else: # Eventually this'll call a Show_Victory_Screen() func.
			pass



"""--------------------------------- Utility Functions ---------------------------------"""
func Resolve_Card_Effects():
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Available_Zones = get_node("Playmat/CardSpots/NonHands").get_children() + get_node("Playmat/CardSpots/" + Side + "HandScroller/").get_children()
	var Zones_To_Check = []
	var AnchorText
	
	# Populate Zones_To_Check Array
	for i in Available_Zones.size():
		if Available_Zones[i].name.left(1) == Side or Side + "Hand" in Available_Zones[i].name or "Backrow" in Available_Zones[i].name:
			if "Deck" in Available_Zones[i].name or "Banished" in Available_Zones[i].name:
				pass
			else:
				Zones_To_Check.append(Available_Zones[i])
	
	# Resolve Card Effects
	for zone in range(len(Zones_To_Check)): # Zone loop enables you to check all zones with just a single Item (card) loop.
		for item in range(len(Zones_To_Check[zone].get_children())):
			AnchorText = Zones_To_Check[zone].get_child(item).Anchor_Text
			if AnchorText != null:
				if Zones_To_Check[zone].get_child(item).Type != "Normal": # Eliminates the need to have blank funcs for Normal cards in Card_Effects Singleton to avoid crashing game
					var Chosen_Card = Zones_To_Check[zone].get_child(item)
					CardEffects.call(AnchorText, Chosen_Card)

func Get_Field_Card_Data(Zone):
	var Side_Opponent = "B" if GameData.Current_Turn == "Player" else "W"
	var Fighter
	var Reinforcers = []
	
	if Zone == "Fighter Opponent":
		var Fighter_Path = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Opponent + "Fighter")
		if Fighter_Path.get_child_count() > 0:
			Fighter = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Opponent + "Fighter").get_child(0)
			return Fighter
	elif Zone == "Reinforcers Opponent":
		for i in range(0, 3):
			var Reinforcer_Path_Opponent = get_node("/root/SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Opponent + "R" + str(i + 1))
			if Reinforcer_Path_Opponent.get_child_count() > 0:
				Reinforcers.append(Reinforcer_Path_Opponent.get_child(0))
		return Reinforcers

func Draw_Card(Turn_Player, Cards_To_Draw = 1):
	# Draw card to appropriate Hand.
	for _i in range(Cards_To_Draw):
		var player = GameData.Player if Turn_Player == "Player" else GameData.Enemy
		player.Hand.append(player.Deck[-1])
		# Create card nodes in appropriate hand.
		if player == GameData.Player:
			$Playmat/CardSpots/NonHands/WMainDeck.emit_signal("pressed")
		else:
			$Playmat/CardSpots/NonHands/BMainDeck.emit_signal("pressed")
		# Removes drawn card from Deck
		player.Deck.pop_back()
	
	# Update Deck Count GUI
	Update_Deck_Counts()

func Update_Deck_Counts():
	get_node("Playmat/CardSpots/WMainDeckCardCount").text = str(GameData.Player.Deck.size())
	get_node("Playmat/CardSpots/WTechDeckCardCount").text = str(GameData.Player.Tech_Deck.size())
	get_node("Playmat/CardSpots/BMainDeckCardCount").text = str(GameData.Enemy.Deck.size())
	get_node("Playmat/CardSpots/BTechDeckCardCount").text = str(GameData.Enemy.Tech_Deck.size())

func Dice_Roll():
	# Get Result of Dice Roll
	var roll_result = RNGesus(1, 6)
	
	# Add Summon Crests to appropriate Crest Pool
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	player.Summon_Crests += roll_result
	
	# Update HUD
	if GameData.Current_Turn == "Player":
		$HUD_W.Update_Data(player)
	else:
		$HUD_B.Update_Data(player)

func Add_Tokens():
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var BR_Path = "Playmat/CardSpots/NonHands/" + Side + "Backrow"
	var Backrow_Slots = [get_node(BR_Path + "1"), get_node(BR_Path + "2"), get_node(BR_Path + "3")]
	
	for i in Backrow_Slots:
		if i.get_child_count() > 0:
			var Card_To_Check = i.get_child(0)
			if Card_To_Check != null:
				Card_To_Check.Add_Token()
				Card_To_Check.Update_Data()

func Flip_HUDs():
	var HUD_W = $HUD_W.position
	var HUD_B = $HUD_B.position
	
	$HUD_W.position = HUD_B
	$HUD_B.position = HUD_W



"""--------------------------------- Major Support Functions ---------------------------------"""
# Reposition Card Supporters
func Reparent_Nodes(Source_Node, Destination_Node):
	Source_Node.get_parent().remove_child(Source_Node)
	Destination_Node.add_child(Source_Node)

func Reset_Reposition_Card_Variables():
	GameData.CardMoved = ""
	GameData.CardFrom = ""
	GameData.CardTo = ""
	GameData.CardSwitched = ""

func Set_Focus_Neighbors(Focus_To_Set, Side, Node_To_Set_For):
	if Focus_To_Set == "Hand":
		var Hand_Node = get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")
		var Hand = Hand_Node.get_children()
		for i in range(len(Hand)):
			var Current_Node = Hand_Node.get_node(str(Hand[i].name))
			var Left_Neighbor = Hand[(i - 1 + len(Hand)) % len(Hand)]
			var Right_Neighbor = Hand[(i + 1) % len(Hand)]
			Current_Node.focus_neighbor_left = Left_Neighbor.get_path()
			Current_Node.focus_previous = Left_Neighbor.get_path()
			Current_Node.focus_neighbor_right = Right_Neighbor.get_path()
			Current_Node.focus_next = Right_Neighbor.get_path()
		
		# Changes bottom focus of MainDeck to first card in Hand.
		if len(Hand) > 0:
			self.get_node("Playmat/CardSpots/NonHands/" + Side + "MainDeck").focus_neighbor_bottom = Hand.front().get_path()
		
	elif Focus_To_Set == "Field":
		var Parent = Node_To_Set_For.get_parent()
		Node_To_Set_For.focus_neighbor_left = Parent.focus_neighbor_left
		Node_To_Set_For.focus_neighbor_right = Parent.focus_neighbor_right
		Node_To_Set_For.focus_neighbor_top = Parent.focus_neighbor_top
		Node_To_Set_For.focus_neighbor_bottom = Parent.focus_neighbor_bottom
		Node_To_Set_For.focus_previous = Parent.focus_previous
		Node_To_Set_For.focus_next = Parent.focus_next

func Fix_GUI_Position_Bug(Node_To_Fix):
	Node_To_Fix.set_position(Vector2(0, 0))


# Play Card Supporters
func Valid_Card(Side, Chosen_Card):
	var Valid_Reinforcer_Zones = ["R1", "R2", "R3"]
	# ID Card Played
	if GameData.CardFrom == Side + "Hand":
		Chosen_Card = self.get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand/" + str(GameData.CardMoved))
	
	# Checks for the following: Card played is from Turn Player's Hand, Card is not being played in Equip slot (unless it IS an Equip card), Card is not a reinforcer being played while "For Honor And Glory" is in effect.
	if (((Side == "W" and GameData.Current_Turn == "Enemy") or (Side == "B" and GameData.Current_Turn == "Player")) or (Chosen_Card.Attribute != "Equip" and "Equip" in GameData.CardTo.name) or ((GameData.CardTo.name in Valid_Reinforcer_Zones) and GameData.For_Honor_And_Glory)):
		Reset_Reposition_Card_Variables()
		return false
	else:
		return true

func Valid_Destination(Side, Destination, Chosen_Card):
	var Valid_Combat_Zones = [Side + "Fighter", Side + "R1", Side + "R2", Side + "R3"]
	var Valid_Backrow_Zones = [Side + "Backrow1", Side + "Backrow2", Side + "Backrow3"]
	
	if (Destination.name in Valid_Combat_Zones) and (Chosen_Card.Type in ["Normal", "Hero"]):
		return true
	elif Destination.name == Side + "EquipTrap" and (Chosen_Card.Type == "Trap"):
		return true
	elif Destination.name == Side + "EquipMagic" and (Chosen_Card.Type == "Magic"):
		return true
	elif (Destination.name in Valid_Backrow_Zones) and (Chosen_Card.Type in ["Magic", "Trap"]):
		return true
	elif Destination.name == Side + "TechZone" and Chosen_Card.Type == "Tech":
		return true
	else:
		return false

func Calculate_Net_Cost(player, Chosen_Card):
	const DISCOUNT_TYPES = {"Normal": "Cost_Discount_Normal", "Hero": "Cost_Discount_Hero", "Magic": "Cost_Discount_Magic", "Trap": "Cost_Discount_Trap"}
	var Discount_Used = DISCOUNT_TYPES.get(Chosen_Card.Type, 0)
	
	if Discount_Used:
		return Chosen_Card.Cost + player.get(Discount_Used)
	else:
		return 0

func Summon_Affordable(Dueler, Net_Cost):
	if Net_Cost <= Dueler.Summon_Crests:
		return true
	else:
		return false

func Activate_Summon_Effects(Chosen_Card):
	var AnchorText = Chosen_Card.Anchor_Text
	
	if Chosen_Card.Type == "Hero" or (Chosen_Card.Type == "Magic" and Chosen_Card.Is_Set == false and GameData.Muggle_Mode == false) or (Chosen_Card.Type == "Trap" and Chosen_Card.Attribute == "Equip" and Chosen_Card.Is_Set == false):
		Chosen_Card.Effect_Active = true
		GameData.Current_Card_Effect_Step = "Activation"
		CardEffects.call(AnchorText, Chosen_Card)
		# Resets Effect_Active status to ensure card doesn't activate from Graveyard
		Chosen_Card.Effect_Active = false


# Battle Phase Supporters
func Check_For_Targets():
	var player = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	var Side = "B" if GameData.Current_Turn == "Player" else "W"
	
	# Currently only checks for card in Fighter slot as Reinforcers are untargetable in current code base
	if get_node("Playmat/CardSpots/NonHands/" + Side + "Fighter").get_child_count() > 0:
		pass
	else: # No Valid Targets. Attack will be Direct Attack
		GameData.Target = player
	GameData.Current_Step = "Target"
	
	if GameData.Target == player:
		Direct_Attack_Automation()
	
	# Update HUD
	$HUD_GameState.Update_Data()

func Set_Attacks_To_Launch():
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	
	# Adds Attack for Fighter, if present
	if get_node("Playmat/CardSpots/NonHands/" + Side + "Fighter").get_child_count() > 0:
		player.Valid_Attackers += 1
	# Adds Attacks for each Reinforcer who can attack from Reinforcement Zone
	for i in range(1, 4):
		if get_node("Playmat/CardSpots/NonHands/" + Side + "R" + str(i)).get_child_count() > 0:
			if get_node("Playmat/CardSpots/NonHands/" + Side + "R" + str(i)).get_child(0).Attack_As_Reinforcement:
				player.Valid_Attackers += 1


# End Phase Supporters
func Reset_Turn_Variables():
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	
	player.Valid_Attackers = 0
	GameData.Cards_Summoned_This_Turn.clear()
	GameData.Cards_Captured_This_Turn.clear()
	GameData.Turn_Counter += 1
	GameData.Current_Phase = PHASES[0]
	GameData.Current_Step = STEPS[0]
	GameData.Attacker = null
	GameData.Target = null


# Miscellaneous Supporters
func RNGesus(lower_bound, upper_bound):
	var rng = RandomNumberGenerator.new()
	var rnd_value = rng.randi_range(lower_bound, upper_bound)
	return rnd_value

func Instantiate_Card():
	var InstanceCard = Card_Drawn.instantiate()
	InstanceCard.name = "Card" + str(GameData.CardCounter)
	GameData.CardCounter += 1
	return InstanceCard

func Fake_Click():
	# Fakes a click input to remove green focus-boarder from card when Next Phase/Turn Control Buttons are triggered via InputMap key/button.
	var fake_click = InputEventMouseButton.new()
	fake_click.button_index = MOUSE_BUTTON_LEFT
	fake_click.doubleclick = false
	fake_click.button_pressed = true
	get_tree().input_event(fake_click)



"""--------------------------------- Automation Functions ---------------------------------"""
func Direct_Attack_Automation():
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	# Signal emitted twice to ensure that Damage Step is conducted following successful Target selection
	SignalBus.emit_signal("Update_GameState", "Step")
	SignalBus.emit_signal("Update_GameState", "Step")
	if player.Valid_Attackers == 0:
		# Move to End Phase (no captures will happen following direct attack)
		SignalBus.emit_signal("Update_GameState", "Phase")
		# Attempt to End Turn (works if no discards are necessary)
		SignalBus.emit_signal("Update_GameState", "Turn")
	else:
		# Move to Repeat Step to prep for next attack
		SignalBus.emit_signal("Update_GameState", "Step")



"""--------------------------------- Setup Game Functions ---------------------------------"""
func Setup_Game():
	# Populates & Shuffles Player/Enemy Decks
	Create_Deck("Arthurian", "Player")
	Create_Deck("Olympians", "Enemy")
	Create_Advance_Tech_Card()
	Shuffle_Decks()
	
	# Set Turn Player for First Turn
	Choose_Starting_Player()
	
	# Draw Opening Hands
	GameData.Current_Step = "Draw"
	Draw_Card(GameData.Current_Turn, 40)
	GameData.Current_Turn = "Enemy" if GameData.Current_Turn == "Player" else "Player"
	Draw_Card(GameData.Current_Turn, 5)
	GameData.Current_Turn = "Enemy" if GameData.Current_Turn == "Player" else "Player"
	GameData.Current_Step = "Start"
	
	# Update Deck Count GUI
	Update_Deck_Counts()
	
	# Set Turn Player
	Set_Turn_Player()
	
	# Initiate First Turn (Opening & Standby Phase require no user input)
	Conduct_Opening_Phase()
	Conduct_Standby_Phase()

func Create_Deck(Deck_List, Current_Duelist):
	for card in GameData.CardData:
		if card["Passcode"] in GameData.Master_Deck_List["Decks"][Deck_List]:
			var Passcode = card["Passcode"]
			for _copies in range(0,GameData.Master_Deck_List["Decks"][Deck_List].count(Passcode)):
				var Created_Card = Card.new(
					card["CardType"],
					card["CardArt"],
					card["CardName"],
					card["CardType"],
					card["EffectType"],
					card["AnchorText"],
					card["Attribute"],
					card["Description"],
					card["ShortDescription"],
					card["Attack"],
					0,
					0,
					card["Cost"],
					card["Health"],
					0,
					0,
					card["SpecialEditionText"],
					card["Rarity"],
					card["Passcode"],
					card["DeckCapacity"],
					0,
					false,
					false,
					1,
					false,
					false,
					false,
					false,
					false,
					false,
					false,
					false,
					Current_Duelist)
					
				# Ensures that Tech cards go into the Tech Deck.
				var player = GameData.Player if Current_Duelist == "Player" else GameData.Enemy
				if Created_Card.Type == "Tech":
					player.Tech_Deck.append(Created_Card)
				else:
					player.Deck.append(Created_Card)

func Create_Advance_Tech_Card():
	var Created_Card
	for card in GameData.CardData:
		if card["Passcode"] == 42489363:
			Created_Card = Card.new(card["CardType"], card["CardArt"], card["CardName"], card["CardType"], card["EffectType"], card["AnchorText"], card["Attribute"], card["Description"], card["ShortDescription"], card["Attack"], 0, 0, card["Cost"], card["Health"], 0, 0, card["SpecialEditionText"], card["Rarity"], card["Passcode"], card["DeckCapacity"], 0, false, false, 1, false, false, false, false, false, false, false, false, "Game")
	
	var random_number = RNGesus(1, 2)
	if random_number == 1:
		GameData.Player.Deck.append(Created_Card)
	else:
		GameData.Enemy.Deck.append(Created_Card)

func Shuffle_Decks():
	randomize()
	GameData.Player.Deck.shuffle()
	GameData.Enemy.Deck.shuffle()

func Choose_Starting_Player():
#	var random_number = RNGesus(1, 2)
	var random_number = 1
	GameData.Current_Turn = "Player" if random_number == 1 else "Enemy"
	
	# Flip field (if Black goes first)
	if random_number == 2:
		_on_SwitchSides_pressed()
		Flip_HUDs()
		$HUD_GameState.Update_Data()



"""--------------------------------- Opening Phase ---------------------------------"""
func Conduct_Opening_Phase():
	# Opening Phase (Start -> Draw -> Roll)
	Update_Game_State("Step")
	Draw_Card(GameData.Current_Turn, 1)
	Update_Game_State("Step")
	Dice_Roll()
	Update_Game_State("Phase")



"""--------------------------------- Standby Phase ---------------------------------"""
func Conduct_Standby_Phase():
	# Standby Phase (Effect -> Token)
	Set_Hero_Card_Effect_Status() # Sets the Effect_Active of all Periodic-style Hero cards on the turn player's field == True
	Update_Game_State("Step")
	Add_Tokens()
	Update_Game_State("Phase")

func Set_Hero_Card_Effect_Status():
	if GameData.Current_Turn == "Player":
		for card in GameData.Player.Frontline:
			if card.Type == "Hero":
				card.Effect_Active = true
	else:
		for card in GameData.Enemy.Frontline:
			if card.Type == "Hero":
				card.Effect_Active = true



"""--------------------------------- Main Phase ---------------------------------"""
func Conduct_Main_Phase():
	# Main Phase (Reposition -> Summon/Set -> Flip)
	# NOTE: Func skipped entirely due to all steps being handled by other funcs
	# Reposition handled by Reposition_Field_Cards(),
	# Summon/Set by _on_Card_Slot_pressed() and Play_Card(),
	# Flip by on_Focus_Sensor_pressed() in SmallCard.gd and Activate_Set_Card()
	pass

func Reposition_Field_Cards(Side):
	var CardSwitched # Indicates the card instance that got switched out of its spot (i.e. the one that was replaced by the CardMoved).
	var Slots_To_Avoid = ["Banished", "Graveyard", "MedBay", "Hand", "TechZone"]
	
	# Ensures Cards aren't moved into/out of ineligible hand/field slots (or sides of the field)
	if (("Hand" in GameData.Chosen_Card.get_parent().name) or
		(GameData.Chosen_Card.get_parent().name in Slots_To_Avoid or GameData.CardTo.name in Slots_To_Avoid) or
		(GameData.Current_Turn == "Player" and GameData.CardTo.name.left(1) == "B") or (GameData.Current_Turn == "Enemy" and GameData.CardTo.name.left(1) == "W") or 
		(GameData.CardSwitched == Side + "Hand")):
		Reset_Reposition_Card_Variables()
		return
	
	# Ensures Cards are only repositioned into valid slots based on Card Type/Attribute, Game-related variables
	match GameData.CardTo.name:
		"Fighter":
			if GameData.Chosen_Card.Type not in ["Normal", "Hero"]:
				Reset_Reposition_Card_Variables()
				return
		"WR1", "WR2", "WR3", "BR1", "BR2", "BR3":
			if GameData.For_Honor_And_Glory:
				Reset_Reposition_Card_Variables()
				return
		"Equip":
			if ("Magic" in GameData.CardTo.name and (GameData.Chosen_Card.Attribute != "Equip" or GameData.Chosen_Card.Type != "Magic")) or ("Trap" in GameData.CardTo.name and (GameData.Chosen_Card.Attribute != "Equip" or GameData.Chosen_Card.Type != "Trap")):
				Reset_Reposition_Card_Variables()
				return
		"Backrow":
			if GameData.Chosen_Card.Type not in ["Magic", "Trap"]:
				Reset_Reposition_Card_Variables()
				return
	
	# Ensures that card switching behavior only happens when switching (as opposed to merely moving) cards.
	if GameData.CardSwitched != "":
		CardSwitched = GameData.CardTo.get_node(str(GameData.CardSwitched))
	
	if GameData.Chosen_Card.name != GameData.CardSwitched: # Ensures that you aren't switching a card with itself (same instance of scene). If this isn't here weird errors get thrown, particularly in CardExaminer scene/script.
		Fix_GUI_Position_Bug(GameData.Chosen_Card)
		if CardSwitched != null: # Ensures that card switching behavior only happens when switching (as opposed to merely moving) cards.
			Fix_GUI_Position_Bug(CardSwitched)

		if CardSwitched != null: # Ensures switching only happens when performing a valid switch.
			Reparent_Nodes(CardSwitched, GameData.Chosen_Card.get_parent())
		Reparent_Nodes(GameData.Chosen_Card, GameData.CardTo)
	
	# Set Focus Neighbour values for repositioned card(s).
	if GameData.CardSwitched != "":
		Set_Focus_Neighbors("Field",Side,CardSwitched)
	Set_Focus_Neighbors("Field",Side,GameData.Chosen_Card)
	
	# Resets variables to avoid game crashing if you try to switch multiple times in a single turn.
	Reset_Reposition_Card_Variables()

func Play_Card(Side):
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	
	if Valid_Card(Side, GameData.Chosen_Card):
		var Reparent_Variables = [GameData.Chosen_Card.get_parent(), GameData.CardTo, GameData.Chosen_Card]
		
		# Ensures that card Cost is Affordable & that it's being summoned to a valid card slot
		var Net_Cost = Calculate_Net_Cost(player, GameData.Chosen_Card)
		
		if Valid_Destination(Side, Reparent_Variables[1], GameData.Chosen_Card) and Summon_Affordable(player, Net_Cost):
			Fix_GUI_Position_Bug(Reparent_Variables[2])
			
			# Deducts summoned card's Net_Cost from appropriate Summon Crest pool
			player.Summon_Crests -= Net_Cost
			
			# Reparents Previous Equip Card Node (if applicable)
			var Equip_Slot = get_node("Playmat/CardSpots/NonHands/" + Side + "EquipMagic") if Reparent_Variables[2].Type == "Magic" else get_node("Playmat/CardSpots/NonHands/" + Side + "EquipTrap")
			var Graveyard = get_node("Playmat/CardSpots/NonHands/" + Side + "Graveyard")
			if Equip_Slot.get_child_count() > 0 and Reparent_Variables[2].Attribute == "Equip":
				Reparent_Nodes(Equip_Slot.get_child(0), Graveyard)
			
			# Reparents Card Played Node
			Reparent_Nodes(Reparent_Variables[2], Reparent_Variables[1])
			
			# Matches focuses of child to new parent.
			Set_Focus_Neighbors("Field",Side,Reparent_Variables[1].get_child(0))
			Set_Focus_Neighbors("Hand",Side,Reparent_Variables[1].get_child(0))
			
			# Activate Summon Effects
			Activate_Summon_Effects(GameData.Chosen_Card)
			# Ensures that card summoned to Equip slot is not immediately sent to Graveyard.
			if GameData.Chosen_Card.Type == "Magic" and not ("Equip" in GameData.Chosen_Card.get_parent().name) and GameData.Chosen_Card.Is_Set == false:
				Reparent_Nodes(Reparent_Variables[2], Graveyard)
			
			# Updates Card Summoned This Turn Array
			GameData.Cards_Summoned_This_Turn.append(GameData.Chosen_Card)
			SignalBus.emit_signal("Card_Summoned", GameData.Chosen_Card)
			
			# Allows card effects that resolve during Summon/Set to occur (i.e. Deep Pit)
			GameData.Current_Card_Effect_Step = "Resolving"
			Resolve_Card_Effects()
			GameData.Current_Card_Effect_Step = null
	
	# Resets GameData variables for next movement.
	Reset_Reposition_Card_Variables()
	
	# Updates Duelist HUD (Places at end of func so that summon effects resolve before update)
	get_node("HUD_" + Side).Update_Data(player)

func Activate_Set_Card(Side, Chosen_Card):
	# Resolves card effect if card is activatable
	if (Chosen_Card.Type == "Magic" and GameData.Muggle_Mode == false) or ((Chosen_Card.Type == "Trap" and (Chosen_Card.Tokens > 0 or GameData.Auto_Spring_Traps))):
		var AnchorText = Chosen_Card.Anchor_Text
		CardEffects.call(AnchorText, Chosen_Card)
		Chosen_Card.Is_Set = false
		# Resets Effect_Active status to ensure card effect isn't triggered from Graveyard.
		Chosen_Card.Effect_Active = false
		
		# Reset Tokens & Visuals
		Chosen_Card.Tokens = 0
		Chosen_Card.Update_Token_Info()
		
		# Replaces current Equip card with activated card
		if Chosen_Card.Attribute == "Equip":
			var EquipSlot = get_node("Playmat/CardSpots/NonHands/" + Side + "Equip" + Chosen_Card.Type)
			var New_Equip_Card = get_node("Playmat/CardSpots/NonHands/" + str(GameData.CardFrom) + "/" + str(GameData.CardMoved))
			
			# Updates children for parents in From & To locations (previous Equip cards sent to Graveyard)
			if EquipSlot.get_child_count() > 0:
				var Graveyard = get_node("Playmat/CardSpots/NonHands/" + Side + "Graveyard")
				Reparent_Nodes(EquipSlot.get_child(0), Graveyard)
			Reparent_Nodes(New_Equip_Card, EquipSlot)
		else: # Moves activated card to appropriate Graveyard
			var Graveyard = get_node("Playmat/CardSpots/NonHands/" + Side + "Graveyard")
			Reparent_Nodes(Chosen_Card, Graveyard)



"""--------------------------------- Battle Phase ---------------------------------"""
func Conduct_Battle_Phase():
	# Battle Phase (Selection -> Target -> Damage -> Capture -> Repeat)
	# NOTE: Func skipped entirely due to all steps being handled by other funcs (Except Repeat step which may require some thought to implement)
	pass

func Resolve_Battle_Damage():
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var enemy = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	var Side = "B" if GameData.Current_Turn == "Player" else "W"
	
	if GameData.Attacker != null and GameData.Target != null: # Ensures no error is thrown when func is called with empty player field.
		player.Valid_Attackers -= 1
		if GameData.Target == enemy:
			for _i in range(GameData.Attacker.Attacks_Remaining):
				GameData.Attacker.Update_Attacks_Remaining("Attack")
				enemy.LP -= (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + player.Field_ATK_Bonus)
				# Update HUD
				get_node("HUD_" + Side).Update_Data(enemy)
			if enemy.LP <= 0:
				GameData.Victor = player.Name
		else:
			if GameData.Target.Invincible == false:
				for _i in range(GameData.Attacker.Attacks_Remaining):
					GameData.Attacker.Update_Attacks_Remaining("Attack")
					GameData.Target.Health -= (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + player.Field_ATK_Bonus)
					GameData.Target.Update_Data()
					if GameData.Attacker.Multi_Strike:
						var Reinforcers_Opp = Get_Field_Card_Data("Reinforcers Opponent")
						for i in range(len(Reinforcers_Opp)):
							Reinforcers_Opp[i].Health -= (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + player.Field_ATK_Bonus)
							Reinforcers_Opp[i].Update_Data()
							if Reinforcers_Opp[i].Health <= 0 and Reinforcers_Opp[i].Immortal == false:
								GameData.Current_Step = "Capture"
								Capture_Card(Reinforcers_Opp[i])
								GameData.Current_Step = "Damage"
			
			# Capture Step
			if GameData.Target.Health <= 0 and GameData.Target.Immortal == false:
				GameData.Current_Step = "Capture"
				Capture_Card(GameData.Target)
			
			# Update HUD
			$HUD_GameState.Update_Data()

func Capture_Card(Card_Captured, Capture_Type = "Normal"):
	var attacking_player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var Destination_MedBay
	
	if Capture_Type == "Normal":
		Destination_MedBay = $Playmat/CardSpots/NonHands/WMedBay if GameData.Current_Turn == "Player" else $Playmat/CardSpots/NonHands/BMedBay
	else:
		Destination_MedBay = $Playmat/CardSpots/NonHands/BMedBay if GameData.Current_Turn == "Player" else $Playmat/CardSpots/NonHands/WMedBay
	GameData.Cards_Captured_This_Turn.append(Card_Captured)
	
	Fix_GUI_Position_Bug(Card_Captured)
	
	# Move captured card to appropriate MedBay
	Reparent_Nodes(Card_Captured, Destination_MedBay)
	
	# Update Duelist's MedicalBay Array
	attacking_player.MedicalBay.append(Card_Captured)
	
	# Reset ATK_Bonus, Health, and Health_Bonus values to appropriate amounts & Update HUD
	Card_Captured.Reset_Stats_On_Capture()
	Card_Captured.Update_Data()



"""--------------------------------- End Phase ---------------------------------"""
func Conduct_End_Phase():
	# End Phase (Discard -> Reload -> Effect -> Victory -> End)
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var enemy = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	var Side = "W" if player == GameData.Player else "B"
	# Discard Step (Hand Limit = 5 [logic handled in Update_Game_Turn() func])
	Resolve_Card_Effects() # May/may not be needed depending on if Discard step remains an EFFECT step.
	
	# Reload Step
	GameData.Current_Step = "Reload"
	# Update HUD
	$HUD_GameState.Update_Data()
	
	# Check for required Reload
	if len(player.Deck) == 0 and len(player.MedicalBay) > 0:
		for i in range(len(player.MedicalBay)):
			player.Deck.append(player.MedicalBay[i])
		player.MedicalBay.clear()
		
		# Update Node Tree
		var MedBay = get_node("Playmat/CardSpots/NonHands/" + Side + "MedBay")
		for i in MedBay.get_children():
			MedBay.remove_child(i)
		
		# Reshuffle player's Deck
		randomize()
		player.Deck.shuffle()
		
		# Update Deck Count GUI
		Update_Deck_Counts()
	
	# Effect Step
	GameData.Current_Step = "Effect"
	Resolve_Card_Effects()
	
	
	# Victory Step
	GameData.Current_Step = "Victory"
	if len(player.Deck) == 0 or player.LP <= 0:
		GameData.Victor = enemy.Name
		print("VICTORY")
		print(enemy.Name + " wins!")
		return
	
	# End Step
	GameData.Current_Step = "End"

func Discard_Card(Side):
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var CardMoved = get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand/" + str(GameData.CardMoved))
	var MedBay = get_node("Playmat/CardSpots/NonHands/" + Side + "MedBay")
	
	# Fixes bug regarding auto-updating of rect_pos of selected scene when moving from slot to slot.
	Fix_GUI_Position_Bug(CardMoved)
	
	# Updates children for parents in From & To locations
	Reparent_Nodes(CardMoved, MedBay)
	
	# Matches focuses of child to new parent.
	Set_Focus_Neighbors("Field",Side,CardMoved)
	Set_Focus_Neighbors("Hand",Side,CardMoved)
	
	# Update Duelist's MedicalBay Array
	player.MedicalBay.append(CardMoved)
	
	# Resets GameData variables for next movement.
	Reset_Reposition_Card_Variables()
	
	# Retry to End Turn
	while get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand").get_child_count() > 5:
		return
	if GameData.Current_Step == "Discard":
		Update_Game_Turn()

func Set_Turn_Player():
	if GameData.Turn_Counter == 1: # Ensures that the program doesn't switch the Turn_Player on the first Opening Phase of the Game.
		return
	else:
		GameData.Current_Turn = "Player" if GameData.Current_Turn == "Enemy" else "Enemy"



#######################################
# SIGNAL FUNCTIONS
#######################################
func _on_Playmat_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			$BoardScroller.value -= 30
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			$BoardScroller.value += 30
		$Playmat.position.y = 0 - $BoardScroller.value

func _on_SwitchSides_pressed():
	if $Playmat.flip_v == true:
		$Playmat.flip_v = false
		$Playmat.texture = BoardImage
	else: 
		$Playmat.flip_v = true
		$Playmat.texture = BoardImageReverse
	
	$Playmat.get_node("CardSpots").rotation += deg_to_rad(180)

func _on_Card_Slot_pressed(slot_name):
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var Hand = get_node("Playmat/CardSpots/" + slot_name.left(1) + "HandScroller/" + slot_name.left(1) + "Hand")
	
	if "MainDeck" in slot_name and GameData.Current_Step == "Draw":
		if player.Deck[-1].get_class() == "Control":
			Hand.add_child(player.Deck[-1])
		else:
			Reset_Reposition_Card_Variables()
			var InstanceCard = Instantiate_Card()
			Hand.add_child(InstanceCard)
			Set_Focus_Neighbors("Hand", slot_name.left(1), InstanceCard)
	elif "TechDeck" in slot_name:
		Reset_Reposition_Card_Variables()
		var TechZone = get_node("Playmat/CardSpots/NonHands/" + slot_name.left(5) + "Zone")
		var InstanceCard = Instantiate_Card()
		TechZone.add_child(InstanceCard)
	else:
		if "Hand" in GameData.Chosen_Card.get_parent().name and GameData.Current_Step == "Main" and GameData.Summon_Mode != "":
			GameData.Summon_Mode = ""
			GameData.CardTo = get_node("Playmat/CardSpots/NonHands/" + slot_name)
			SignalBus.emit_signal("Play_Card", GameData.Chosen_Card.get_parent().name.left(1))
		elif GameData.Current_Step == "Main":
			if GameData.Chosen_Card.get_parent().name != "":
				GameData.CardTo = get_node("Playmat/CardSpots/NonHands/" + slot_name)
				SignalBus.emit_signal("Reposition_Field_Cards", GameData.CardTo.name.left(1))

func _on_Next_Step_pressed():
	Update_Game_State("Step")

func _on_Next_Phase_pressed():
	Update_Game_State("Phase")

func _on_End_Turn_pressed():
	Update_Game_State("Turn")
