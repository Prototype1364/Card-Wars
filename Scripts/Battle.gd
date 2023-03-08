extends Control

const PHASES = ["Opening Phase", "Standby Phase", "Main Phase", "Battle Phase", "End Phase"]
const PHASE_THRESHOLDS = [2, 4, 7, 12, 17]
const STEPS = ["Start", "Draw", "Roll", "Effect", "Token", "Reposition", "Summon/Set", "Flip", "Selection", "Target", "Damage", "Capture", "Repeat", "Discard", "Reload", "Effect", "Victory", "End"]
const EFFECT_STEPS = ["Effect", "Selection", "Capture", "Discard"] # Discard may/may not end up being an Effect Step. You just added it, just in case (also Summon/Set should be added to check for Event-effects like Mordred's).
const FUNC_STEPS = ["Damage"]

var BoardImage = preload("res://Assets/Playmat/BoardImage.png")
var BoardImageReverse = preload("res://Assets/Playmat/BoardImageReverse.png")
var Card_Drawn = preload("res://Scenes/SupportScenes/SmallCard.tscn")

func _ready():
	# Setup Signal_Bus functionality. Note: Holder Variables (_HV) serve to eliminate Debugger warnings.
	var _HV1 = SignalBus.connect("Reposition_Field_Cards", self, "Reposition_Field_Cards")
	var _HV2 = SignalBus.connect("Play_Card", self, "Play_Card")
	var _HV3 = SignalBus.connect("Activate_Set_Card", self, "Activate_Set_Card")
	var _HV4 = SignalBus.connect("Check_For_Targets", self, "Check_For_Targets")
	var _HV5 = SignalBus.connect("Discard_Card", self, "Discard_Card")
	var _HV6 = SignalBus.connect("Update_GameState", self, "Update_Game_State")
	set_focus_mode(true)
	
	Setup_Game()

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
					card["Attribute"],
					card["Description"],
					card["ShortDescription"],
					card["Attack"],
					0,
					card["Cost"],
					card["Health"],
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
					Current_Duelist)
					
				# Ensures that Tech cards go into the Tech Deck.
				if Current_Duelist == "Player":
					if Created_Card.Type == "Tech":
						GameData.Player.Tech_Deck.append(Created_Card)
					else:
						GameData.Player.Deck.append(Created_Card)
				else:
					if Created_Card.Type == "Tech":
						GameData.Enemy.Tech_Deck.append(Created_Card)
					else:
						GameData.Enemy.Deck.append(Created_Card)

func Create_Advance_Tech_Card():
	var Created_Card
	for card in GameData.CardData:
		if card["Passcode"] == 42489363:
			Created_Card = Card.new(card["CardType"], card["CardArt"], card["CardName"], card["CardType"], card["EffectType"], card["Attribute"], card["Description"], card["ShortDescription"], card["Attack"], 0, card["Cost"], card["Health"], 0, card["SpecialEditionText"], card["Rarity"], card["Passcode"], card["DeckCapacity"], 0, false, false, 1, false, false, false, false, "Game")
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var random_number = rng.randi_range(1,2)
	if random_number == 1:
		GameData.Player.Deck.append(Created_Card)
	else:
		GameData.Enemy.Deck.append(Created_Card)

func Shuffle_Decks():
	randomize()
	GameData.Player.Deck.shuffle()
	GameData.Enemy.Deck.shuffle()

func Choose_Starting_Player():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var random_number = rng.randi_range(1,2)
	GameData.Current_Turn = "Player" if random_number == 1 else "Enemy"
	
	# Flip field (if Black goes first)
	if random_number == 2:
		_on_SwitchSides_pressed()
		$HUD_GameState.Update_Data()

func Set_Turn_Player():
	if GameData.Turn_Counter == 1: # Ensures that the program doesn't switch the Turn_Player on the first Opening Phase of the Game.
		return
	else:
		GameData.Current_Turn = "Player" if GameData.Current_Turn == "Enemy" else "Enemy"

func Draw_Card(Turn_Player, Cards_To_Draw = 1):
	# Draw Step
#	GameData.Current_Step = "Draw"
	
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

func Dice_Roll():
	# Roll Step
#	GameData.Current_Step = "Roll"
	
	# Get Result of Dice Roll
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var roll_result = rng.randi_range(1,6)
	
	# Add Summon Crests to appropriate Crest Pool
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	player.Summon_Crests += roll_result
	
	# Update HUD
	if GameData.Current_Turn == "Player":
		$HUD_W.Update_Data(player)
	else:
		$HUD_B.Update_Data(player)

func Set_Hero_Card_Effect_Status():
	# Populate lists for both players (List Comprehension is apparently not a thing in Godot)
	var Heroes_On_Field_Player = []
	var Heroes_On_Field_Enemy = []
	for card in GameData.Player.Frontline:
		if card.Type == "Hero":
			Heroes_On_Field_Player.append(card)
	for card in GameData.Enemy.Frontline:
		if card.Type == "Hero":
			Heroes_On_Field_Enemy.append(card)
	
	# Set Hero card's Effect_Active status
	if GameData.Current_Turn == "Player":
		for i in range(len(Heroes_On_Field_Player)):
			Heroes_On_Field_Player[i].Effect_Active = true
	elif GameData.Current_Turn == "Enemy":
		for i in range(len(Heroes_On_Field_Enemy)):
			Heroes_On_Field_Enemy[i].Effect_Active = true

func Resolve_Card_Effects():
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Available_Zones = get_node("Playmat/CardSpots/NonHands").get_children() + get_node("Playmat/CardSpots/" + Side + "HandScroller/").get_children()
	var Zones_To_Check = []
	var Passcode
	var string_prefix = "c"
	var func_name
	
	# Populate Zones_To_Check Array
	for i in Available_Zones.size():
		if Available_Zones[i].name.left(1) == Side or Side + "Hand" in Available_Zones[i].name:
			if "Deck" in Available_Zones[i].name or "Banished" in Available_Zones[i].name:
				pass
			else:
				Zones_To_Check.append(Available_Zones[i])
	
	# Resolve Card Effects
	for zone in range(len(Zones_To_Check)): # Zone loop enables you to check all zones with just a single Item (card) loop.
		for item in range(len(Zones_To_Check[zone].get_children())):
			Passcode = Zones_To_Check[zone].get_child(item).Passcode
			if Zones_To_Check[zone].get_child(item).Type != "Normal": # Eliminates the need to have blank funcs for Normal cards in Card_Effects Singleton to avoid crashing game
				var Card_To_Check = Zones_To_Check[zone].get_child(item)
				func_name = string_prefix + str(Passcode)
				CardEffects.call(func_name, Card_To_Check)

func Add_Tokens():
	# Token Step
#	GameData.Current_Step = "Token"
	
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	
	for i in range(1,4): # Range is exclusive. I.E. it runs 3 times, from 1 to 3, excluding 4.
		var Current_Card
		if get_node("Playmat/CardSpots/NonHands/" + Side + "Backrow" + str(i)).get_child_count() > 0:
			Current_Card = get_node("Playmat/CardSpots/NonHands/" + Side + "Backrow" + str(i)).get_child(0) # Index 0 used as Backrow slots can only hold 1 card at a time
		if Current_Card != null:
			if Current_Card.Type == "Trap":
				Current_Card.Tokens += 1
				Current_Card.Update_Data()

func Reposition_Field_Cards(Side):
	var MoveFrom # Grabs the parent of the selected scene instance.
	var MoveTo # Reparents the selected scene instance only if said parent has no children (i.e. cannot multistack in Fighter slot).
	var CardMoved # From GameData singleton, indicates the specific instance of the SmallCard scene that has been selected.
	var CardSwitched # Indicates the card instance that got switched out of its spot (i.e. the one that was replaced by the CardMoved).
	var MoveWithoutSwitching = true
	
	# Ensures that cards are not switched out of the MedBay, Graveyard, or Banished piles.
	if ("Banished" in GameData.CardTo or "Graveyard" in GameData.CardTo or "MedBay" in GameData.CardTo) or ("Banished" in GameData.CardFrom or "Graveyard" in GameData.CardFrom or "MedBay" in GameData.CardFrom):
		if "Banished" in GameData.CardFrom or "Graveyard" in GameData.CardFrom or "MedBay" in GameData.CardFrom:
			Reset_Reposition_Card_Variables()
			return
		else:
			MoveWithoutSwitching = false
	# Sets MoveFrom/To variable values for repositioning.
	if GameData.CardFrom == Side + "Hand":
		MoveFrom = self.get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")
	else:
		MoveFrom = self.get_node("Playmat/CardSpots/NonHands/" + GameData.CardFrom)
	if GameData.CardTo == Side + "Hand":
		MoveTo = self.get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")
	else:
		MoveTo = self.get_node("Playmat/CardSpots/NonHands/" + GameData.CardTo)
	CardMoved = MoveFrom.get_node(GameData.CardMoved)
	
	# Ensures cards are not switched around from within the Hand.
	if GameData.CardSwitched == Side + "Hand":
		return
	# Ensures that card switching behavior only happens when switching (as opposed to merely moving) cards.
	if GameData.CardSwitched != "":
		CardSwitched = MoveTo.get_node(GameData.CardSwitched)
	
	if GameData.CardMoved != GameData.CardSwitched: # Ensures that you aren't switching a card with itself (same instance of scene). If this isn't here weird errors get thrown, particularly in CardExaminer scene/script.
		# Fixes bug regarding auto-updating of rect_pos of selected scene when moving from slot to slot.
		CardMoved.rect_position.x = 0
		CardMoved.rect_position.y = 0
		if CardSwitched != null: # Ensures that card switching behavior only happens when switching (as opposed to merely moving) cards.
			CardSwitched.rect_position.x = 0
			CardSwitched.rect_position.y = 0
		MoveFrom.remove_child(CardMoved)
		if MoveWithoutSwitching == true and CardSwitched != null: # Ensures switching only happens when performing a valid switch.
			MoveTo.remove_child(CardSwitched)
			MoveFrom.add_child(CardSwitched)
		MoveTo.add_child(CardMoved)
	
	# Set Focus Neighbour values for repositioned card(s).
	var Moved = MoveTo.get_node(GameData.CardMoved)
	Set_Focus_Neighbors("Field",Side,Moved)
	if GameData.CardSwitched != "":
		Moved = MoveFrom.get_node(GameData.CardSwitched)
		Set_Focus_Neighbors("Field",Side,Moved)
	
	# Resets variables to avoid game crashing if you try to switch multiple times in a single turn.
	Reset_Reposition_Card_Variables()

func Play_Card(Side):
	var Chosen_Card # Indicates the card object that is being played.
	var MoveFrom # Grabs the origin parent of the selected scene instance.
	var MoveTo # Grabs the destination parent of the selected scene instance.
	var CardMoved # From GameData singleton, indicates the specific instance of the SmallCard scene that has been selected.
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	
	# Ensure card played is from Turn Player's Hand.
	if (Side == "W" and GameData.Current_Turn == "Enemy") or (Side == "B" and GameData.Current_Turn == "Player"):
		return
	
	# ID Card Played
	if GameData.CardFrom == Side + "Hand":
		Chosen_Card = self.get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand/" + GameData.CardMoved)
	
	# Prep variables to reposition cards on field & scene tree
	if GameData.CardFrom == "BHand":
		MoveFrom = self.get_node("Playmat/CardSpots/BHandScroller/BHand")
	elif GameData.CardFrom == "WHand":
		MoveFrom = self.get_node("Playmat/CardSpots/WHandScroller/WHand")
	if GameData.CardTo == "BHand":
		MoveTo = self.get_node("Playmat/CardSpots/BHandScroller/BHand")
	elif GameData.CardTo == "WHand":
		MoveTo = self.get_node("Playmat/CardSpots/WHandScroller/WHand")
	else:
		MoveTo = self.get_node("Playmat/CardSpots/NonHands/" + GameData.CardTo)
	
	CardMoved = MoveFrom.get_node(GameData.CardMoved)
	
	# Ensures that card Cost is Affordable & that it's being summoned to a valid card slot
	if Valid_Destination(Side, MoveTo, Chosen_Card) and Summon_Affordable(player, Chosen_Card):
		# Fixes bug regarding auto-updating of rect_pos of selected scene when moving from slot to slot.
		CardMoved.rect_position.x = 0
		CardMoved.rect_position.y = 0
		
		# Deducts summoned card's Cost from appropriate Summon Crest pool & Updates HUD
		player.Summon_Crests -= Chosen_Card.Cost
		get_node("HUD_" + Side).Update_Data(player)
		
		# Updates children for parents in From & To locations (if destination is valid for Card Type).
		MoveFrom.remove_child(CardMoved)
		MoveTo.add_child(CardMoved)
		
		# Matches focuses of child to new parent.
		var Moved = MoveTo.get_node(GameData.CardMoved)
		Set_Focus_Neighbors("Field",Side,Moved)
		Set_Focus_Neighbors("Hand",Side,Moved)
		
		# Activate Summon Effects (Currently no way to Set cards)
		if Chosen_Card.Type == "Hero" or (Chosen_Card.Type == "Magic" and Chosen_Card.Is_Set == false):
			Chosen_Card.Effect_Active = true
			Activate_Summon_Effects(Chosen_Card)
			# Ensures that card summoned to Equip slot is not immediately sent to Graveyard.
			if Chosen_Card.Type == "Magic" and not ("Equip" in Chosen_Card.get_parent().name):
				# Sends activated Magic card to Graveyard
				MoveFrom = MoveTo
				MoveTo = self.get_node("Playmat/CardSpots/NonHands/" + Side + "Graveyard")
				MoveFrom.remove_child(CardMoved)
				MoveTo.add_child(CardMoved)
				# Resets Effect_Active status to ensure card doesn't activate from Graveyard
				Chosen_Card.Effect_Active = false
	else:
		pass
	
	# Resets GameData variables for next movement.
	Reset_Reposition_Card_Variables()

func Summon_Affordable(Dueler, Chosen_Card):
	if Chosen_Card.Cost <= Dueler.Summon_Crests:
		return true
	else:
		return false

func Valid_Destination(Side, Destination, Chosen_Card):
	if (Destination.name == Side + "Fighter") and (Chosen_Card.Type == "Normal" or Chosen_Card.Type == "Hero"):
		return true
	elif Destination.name == Side + "EquipTrap" and (Chosen_Card.Type == "Trap"):
		return true
	elif Destination.name == Side + "EquipMagic" and (Chosen_Card.Type == "Magic"):
		return true
	elif (Destination.name == Side + "R1" or Destination.name == Side + "R2" or Destination.name == Side + "R3") and (Chosen_Card.Type == "Normal" or Chosen_Card.Type == "Hero"):
		return true
	elif (Destination.name == Side + "Backrow1" or Destination.name == Side + "Backrow2" or Destination.name == Side + "Backrow3") and (Chosen_Card.Type == "Magic" or Chosen_Card.Type == "Trap"):
		return true
	elif Destination.name == Side + "TechZone" and Chosen_Card.Type == "Tech":
		return true
	else:
		return false

func Reset_Reposition_Card_Variables():
	GameData.CardMoved = ""
	GameData.CardFrom = ""
	GameData.CardTo = ""
	GameData.CardSwitched = ""

func Set_Focus_Neighbors(Focus_To_Set, Side, Node_To_Set_For):
	if Focus_To_Set == "Hand":
		var Hand_Node = get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")
		var Hand = Hand_Node.get_children()
		
		for i in len(Hand):
			if i == 0 and i < len(Hand) - 1:
				Hand_Node.get_node(Hand[i].name).focus_neighbour_left = Hand[-1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_previous = Hand[-1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_neighbour_right = Hand[i + 1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_next = Hand[i + 1].get_path()
			elif i + 1 >= len(Hand):
				Hand_Node.get_node(Hand[i].name).focus_neighbour_left = Hand[i - 1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_previous = Hand[i - 1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_neighbour_right = Hand[0].get_path()
				Hand_Node.get_node(Hand[i].name).focus_next = Hand[0].get_path()
			elif i > 0:
				Hand_Node.get_node(Hand[i].name).focus_neighbour_left = Hand[i - 1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_previous = Hand[i - 1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_neighbour_right = Hand[i + 1].get_path()
				Hand_Node.get_node(Hand[i].name).focus_next = Hand[i + 1].get_path()
			Node_To_Set_For.focus_neighbour_top = Node_To_Set_For.get_parent().focus_neighbour_top
			Node_To_Set_For.focus_neighbour_bottom = Node_To_Set_For.get_parent().focus_neighbour_bottom
		
		# Changes bottom focus of MainDeck to first card in Hand.
		if len(Hand) > 0:
			self.get_node("Playmat/CardSpots/NonHands/" + Side + "MainDeck").focus_neighbour_bottom = Hand.front().get_path()
	elif Focus_To_Set == "Field":
		Node_To_Set_For.focus_neighbour_left = Node_To_Set_For.get_parent().focus_neighbour_left
		Node_To_Set_For.focus_neighbour_right = Node_To_Set_For.get_parent().focus_neighbour_right
		Node_To_Set_For.focus_neighbour_top = Node_To_Set_For.get_parent().focus_neighbour_top
		Node_To_Set_For.focus_neighbour_bottom = Node_To_Set_For.get_parent().focus_neighbour_bottom
		Node_To_Set_For.focus_previous = Node_To_Set_For.get_parent().focus_previous
		Node_To_Set_For.focus_next = Node_To_Set_For.get_parent().focus_next

func Activate_Summon_Effects(Chosen_Card):
	var string_prefix = "c"
	var func_name
	
	func_name = string_prefix + str(Chosen_Card.Passcode)
	CardEffects.call(func_name, Chosen_Card)

func Activate_Set_Card(Side, Chosen_Card):
	# Flip Step
	GameData.Current_Step = "Flip"
	
	# Resolves card effect if card is activatable
	if Chosen_Card.Type != "Trap" or (Chosen_Card.Type == "Trap" and Chosen_Card.Tokens > 0):
		var string_prefix = "c"
		var func_name = string_prefix + str(Chosen_Card.Passcode)
		CardEffects.call(func_name, Chosen_Card)
		Chosen_Card.Is_Set = false
		# Resets Effect_Active status to ensure card effect isn't triggered from Graveyard.
		Chosen_Card.Effect_Active = false
		
		# Replaces current Equip card with activated card
		if Chosen_Card.Attribute == "Equip":
			var EquipSlot = get_node("Playmat/CardSpots/NonHands/" + Side + "Equip" + Chosen_Card.Type)
			var MoveFrom = get_node("Playmat/CardSpots/NonHands/" + GameData.CardFrom)
			var MoveTo = get_node("Playmat/CardSpots/NonHands/" + Side + "Graveyard")
			var New_Equip_Card
			New_Equip_Card = MoveFrom.get_node(GameData.CardMoved)
			
			# Updates children for parents in From & To locations (previous Equip cards sent to Graveyard)
			if EquipSlot.get_child_count() > 0:
				var Old_Equip_Card = EquipSlot.get_child(0)
				EquipSlot.remove_child(Old_Equip_Card)
				MoveTo.add_child(Old_Equip_Card)
			MoveFrom.remove_child(New_Equip_Card)
			EquipSlot.add_child(New_Equip_Card)
		else: # Moves activated card to appropriate Graveyard
			var MoveFrom = get_node("Playmat/CardSpots/NonHands/" + GameData.CardFrom)
			var MoveTo = get_node("Playmat/CardSpots/NonHands/" + Side + "Graveyard")
			MoveFrom.remove_child(Chosen_Card)
			MoveTo.add_child(Chosen_Card)

func Set_Attacks_To_Launch():
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	
	# Adds Attack for Fighter, if present
	if get_node("Playmat/CardSpots/NonHands/" + Side + "Fighter").get_child_count() > 0:
		GameData.Attacks_To_Launch += 1
	# Adds Attacks for each Reinforcer who can attack from Reinforcement Zone
	for i in range(1, 4):
		if get_node("Playmat/CardSpots/NonHands/" + Side + "R" + str(i)).get_child_count() > 0:
			if get_node("Playmat/CardSpots/NonHands/" + Side + "R" + str(i)).get_child(0).Attack_As_Reinforcement:
				GameData.Attacks_To_Launch += 1

func Check_For_Targets():
	var player = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	var Side = "B" if GameData.Current_Turn == "Player" else "W"
	
	if get_node("Playmat/CardSpots/NonHands/" + Side + "Fighter").get_child_count() + get_node("Playmat/CardSpots/NonHands/" + Side + "R1").get_child_count() + get_node("Playmat/CardSpots/NonHands/" + Side + "R2").get_child_count() + get_node("Playmat/CardSpots/NonHands/" + Side + "R3").get_child_count() > 0:
		pass
	else: # No Valid Targets. Attack will be Direct Attack
		GameData.Target = player
	GameData.Current_Step = "Target"
	
	# Update HUD
	$HUD_GameState.Update_Data()

func Resolve_Battle_Damage():
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var enemy = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	var Side = "B" if GameData.Current_Turn == "Player" else "W"
	
	if GameData.Attacker != null: # Ensures no error is thrown when func is called with empty player field.
		GameData.Attacks_To_Launch -= 1
		if GameData.Target == enemy:
			enemy.LP -= (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + player.Field_ATK_Bonus)
			# Update HUD
			get_node("HUD_" + Side).Update_Data(enemy)
			if enemy.LP <= 0:
				GameData.Victor = player.Name
		else:
			if GameData.Target.Invincible == false:
				GameData.Target.Health -= (GameData.Attacker.Attack + GameData.Attacker.ATK_Bonus + player.Field_ATK_Bonus)
				GameData.Target.Update_Data()
			
			# Capture Step
			if GameData.Target.Health <= 0:
				GameData.Current_Step = "Capture"
				Capture_Card(GameData.Target, GameData.Target.get_parent())
			
			# Update HUD
			$HUD_GameState.Update_Data()

func Capture_Card(Card_Captured, slot_name):
	var targeted_player = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	var Destination_MedBay = $Playmat/CardSpots/NonHands/WMedBay if GameData.Current_Turn == "Player" else $Playmat/CardSpots/NonHands/BMedBay
#	GameData.Current_Step = "Capture"
	GameData.Cards_Captured_This_Turn.append(Card_Captured)
	
	# Move captured card to appropriate MedBay
	slot_name.remove_child(Card_Captured)
	Destination_MedBay.add_child(Card_Captured)
	
	# Reset ATK_Bonus, Health, and Health_Bonus values to appropriate amounts & Update HUD
	Card_Captured.ATK_Bonus = 0
	Card_Captured.Health = Card_Captured.Revival_Health
	Card_Captured.Health_Bonus = 0
	Card_Captured.Update_Data()
	
	# Update Current_Fighter value (if applicable)
	if "Fighter" in slot_name:
		targeted_player.Current_Fighter = "None"

func Discard_Card(Side):
	var MoveFrom # Grabs the origin parent of the selected scene instance.
	var MoveTo # Grabs the destination parent of the selected scene instance.
	var CardMoved # From GameData singleton, indicates the specific instance of the SmallCard scene that has been selected.
	
	# Prep variables to reposition cards on field & scene tree
	MoveFrom = self.get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand")
	MoveTo = self.get_node("Playmat/CardSpots/NonHands/" + Side + "MedBay")
	CardMoved = MoveFrom.get_node(GameData.CardMoved)
	
	# Fixes bug regarding auto-updating of rect_pos of selected scene when moving from slot to slot.
	CardMoved.rect_position.x = 0
	CardMoved.rect_position.y = 0
	
	# Updates children for parents in From & To locations
	MoveFrom.remove_child(CardMoved)
	MoveTo.add_child(CardMoved)
	
	# Matches focuses of child to new parent.
	var Moved = MoveTo.get_node(GameData.CardMoved)
	Set_Focus_Neighbors("Field",Side,Moved)
	Set_Focus_Neighbors("Hand",Side,Moved)
	
	# Resets GameData variables for next movement.
	Reset_Reposition_Card_Variables()
	
	# Retry Conducting End Phase
	if GameData.Current_Step == "Discard":
		Conduct_End_Phase()

func Conduct_Opening_Phase():
	# Opening Phase (Start -> Draw -> Roll)
	Update_Game_State("Step")
	Draw_Card(GameData.Current_Turn, 1)
	Update_Game_State("Step")
	Dice_Roll()
	Update_Game_State("Phase")

func Conduct_Standby_Phase():
	# Standby Phase (Effect -> Token)
	Set_Hero_Card_Effect_Status() # Sets the Effect_Active of all Periodic-style Hero cards on the turn player's field == True
	Update_Game_State("Step")
	Add_Tokens()
	Update_Game_State("Phase")

func Conduct_Main_Phase():
	# Main Phase (Reposition -> Summon/Set -> Flip)
	# NOTE: Func skipped entirely due to all steps being handled by other funcs
	# Reposition handled by Reposition_Field_Cards(),
	# Summon/Set by _on_Card_Slot_pressed() and Play_Card(),
	# Flip by on_Focus_Sensor_pressed() in SmallCard.gd and Activate_Set_Card()
	pass

func Conduct_Battle_Phase():
	# Battle Phase (Selection -> Target -> Damage -> Capture -> Repeat)
	# NOTE: Func skipped entirely due to all steps being handled by other funcs (Except Repeat step which may require some thought to implement)
	pass

func Conduct_End_Phase():
	# End Phase (Discard -> Reload -> Effect -> Victory -> End)
	var player = GameData.Player if GameData.Current_Turn == "Player" else GameData.Enemy
	var enemy = GameData.Enemy if GameData.Current_Turn == "Player" else GameData.Player
	
	# Discard Step (Hand Limit = 5 [logic handled in Update_Game_Turn() func])
	Resolve_Card_Effects() # May/may not be needed depending on if Discard step remains an EFFECT step.
	
	# Reload Step
	GameData.Current_Step = "Reload"
	if len(player.Deck) == 0:
		if len(player.MedicalBay) > 0:
			# Move cards from player's MedBay to Deck
			for i in range(len(player.MedicalBay)):
				player.Deck.append(player.MedicalBay[i])
			player.MedicalBay.clear()
			# Reshuffle player's Deck
			randomize()
			player.Deck.shuffle()
	
	# Effect Step
	GameData.Current_Step = "Effect"
	Resolve_Card_Effects()
	
	
	# Victory Step
	GameData.Current_Step = "Victory"
	if len(player.Deck) == 0 or player.LP <= 0:
		GameData.Victor = enemy.Name
		print("VICTORY")
		return
	
	# End Step
	GameData.Current_Step = "End"

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
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	
	# Call required funcs at appropriate Steps (and contain step values within bounds of current Phase)
	if STEPS.find(GameData.Current_Step) == 10: # Current Step is Damage Step
		Resolve_Battle_Damage()
	if STEPS.find(GameData.Current_Step) == 13 and get_node("Playmat/CardSpots/" + Side + "HandScroller/" + Side + "Hand").get_child_count() > 5: # Ensures cards are discarded when appropriate
		return
	if GameData.Current_Step in EFFECT_STEPS: # Ensures that Card Effects are resolved when appropriate
		Resolve_Card_Effects()
	
	# Update Step value
	if STEPS.find(GameData.Current_Step) + 1 > len(STEPS): # Resets index to start of New Turn.
		GameData.Current_Step = STEPS[0]
	elif STEPS.find(GameData.Current_Step) in PHASE_THRESHOLDS: # Ensures that you can't advance to a Step that belongs to a different Phase
		return
	elif STEPS.find(GameData.Current_Step) == 3 and GameData.Current_Phase == "End Phase": # Fixes bug where Step state would reset to Standby Phases' Effect Step (instead of End Phases' Effect Step)
		GameData.Current_Step = STEPS[16]
	elif STEPS.find(GameData.Current_Step) == 11 and GameData.Attacks_To_Launch == 0:
		GameData.Current_Phase = PHASES[4]
		GameData.Current_Step = STEPS[13]
	else:
		GameData.Current_Step = STEPS[STEPS.find(GameData.Current_Step) + 1]

func Update_Game_Phase():
	var Side = "W" if GameData.Current_Turn == "Player" else "B"
	var Repositionable_Cards = get_node("Playmat/CardSpots/NonHands/" + Side + "Fighter").get_child_count() + get_node("Playmat/CardSpots/NonHands/" + Side + "R1").get_child_count() + get_node("Playmat/CardSpots/NonHands/" + Side + "R2").get_child_count() + get_node("Playmat/CardSpots/NonHands/" + Side + "R3").get_child_count()
	
	if PHASES.find(GameData.Current_Phase) + 1 >= len(PHASES): # Ensures game doesn't crash when trying to advance to a non-existent Phase.
		return
	elif PHASES.find(GameData.Current_Phase) == 1 and Repositionable_Cards == 0: # Skips Reposition Step when there are no cards to Reposition
		GameData.Current_Phase = PHASES[PHASES.find(GameData.Current_Phase) + 1]
		GameData.Current_Step = STEPS[6]
	elif GameData.Turn_Counter == 1 and PHASES.find(GameData.Current_Phase) == 2: # Skips Battle Phase on first turn of game
		GameData.Current_Phase = PHASES[PHASES.find(GameData.Current_Phase) + 2]
		GameData.Current_Step = STEPS[13]
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
			GameData.Cards_Captured_This_Turn.clear()
			GameData.Turn_Counter += 1
			GameData.Current_Phase = PHASES[0]
			GameData.Current_Step = STEPS[0]
			GameData.Attacks_To_Launch = 0
			print(GameData.Current_Phase + " - " + GameData.Current_Step)
			Set_Turn_Player()
			# Flip Field
			_on_SwitchSides_pressed()

			# Opening & Standby Phases called due to currently requiring no user input
			Conduct_Opening_Phase()
			Conduct_Standby_Phase()
		else: # Eventually this'll call a Show_Victory_Screen() func.
			pass

func Setup_Game():
	# Populates & Shuffles Player/Enemy Decks
	Create_Deck("Arthurian", "Player")
	Create_Deck("Olympians", "Enemy")
	Create_Advance_Tech_Card()
	Shuffle_Decks()
	
	# Set Turn Player for First Turn
	Choose_Starting_Player()
	
	# Draw Opening Hands
	Draw_Card(GameData.Current_Turn, 5)
	GameData.Current_Turn = "Enemy" if GameData.Current_Turn == "Player" else "Player"
	Draw_Card(GameData.Current_Turn, 5)
	GameData.Current_Turn = "Enemy" if GameData.Current_Turn == "Player" else "Player"
	
	# Set Turn Player
	Set_Turn_Player()
	
	# Initiate First Turn (Opening & Standby Phase require no user input)
	Conduct_Opening_Phase()
	Conduct_Standby_Phase()


func _on_Playmat_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			$BoardScroller.value -= 30
		elif event.button_index == BUTTON_WHEEL_DOWN:
			$BoardScroller.value += 30
		$Playmat.rect_position.y = 0 - $BoardScroller.value

func _on_SwitchSides_pressed():
	if $Playmat.flip_v == true:
		$Playmat.flip_v = false
		$Playmat.texture = BoardImage
	else: 
		$Playmat.flip_v = true
		$Playmat.texture = BoardImageReverse
	
	$Playmat.get_node("CardSpots").rect_rotation += 180

func _on_Card_Slot_pressed(slot_name):
	if "MainDeck" in slot_name:
		Reset_Reposition_Card_Variables()
		var Hand = self.get_node("Playmat/CardSpots/" + slot_name.left(1) + "HandScroller/" + slot_name.left(1) + "Hand")
		var InstanceCard = Card_Drawn.instance()
		InstanceCard.name = "Card" + str(GameData.CardCounter)
		GameData.CardCounter += 1
		Hand.add_child(InstanceCard)
		Set_Focus_Neighbors("Hand", slot_name.left(1), InstanceCard)
	elif "TechDeck" in slot_name:
		Reset_Reposition_Card_Variables()
		var TechZone = self.get_node("Playmat/CardSpots/NonHands/" + slot_name.left(5) + "Zone")
		var InstanceCard = Card_Drawn.instance()
		InstanceCard.name = "Card" + str(GameData.CardCounter)
		GameData.CardCounter += 1
		TechZone.add_child(InstanceCard)
	else:
		if "Hand" in GameData.CardFrom and GameData.Current_Step == "Summon/Set" and GameData.Summon_Mode != "":
			GameData.Summon_Mode = ""
			GameData.CardTo = slot_name
			SignalBus.emit_signal("Play_Card", GameData.CardFrom.left(1))
		elif GameData.Current_Step == "Reposition":
			if GameData.CardFrom != "":
				GameData.CardTo = slot_name
				SignalBus.emit_signal("Reposition_Field_Cards", GameData.CardTo.left(1))

func _on_Next_Step_pressed():
	Update_Game_State("Step")

func _on_Next_Phase_pressed():
	Update_Game_State("Phase")

func _on_End_Turn_pressed():
	Update_Game_State("Turn")
