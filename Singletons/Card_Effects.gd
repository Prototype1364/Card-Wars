extends Node

var BM
var BC
var BF
var DC
@onready var root = get_tree().get_root()

func _ready():
	var _HV1 = SignalBus.connect("READY", Callable(self, "Set_Battle_Scripts"))

func Set_Battle_Scripts(): # A temporary function to fix the issue of the BM variable not being available/ready when this script is loaded due to Card_Effects being a singleton. If this script is changed to a non-singleton, this function (and the accompanying signal in the BM & SignalBus can be removed)
	BM = root.get_node("SceneHandler/Battle")
	BC = root.get_node("SceneHandler/Battle/Playmat")
	BF = root.get_node("SceneHandler/Battle/Playmat/CardSpots")
	DC = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands")



"""--------------------------------- General Functions ---------------------------------"""
func On_Field(card) -> bool: 
	var Clean_Parent_Name = BF.Get_Clean_Slot_Name(card.get_parent().name)
	var Valid_Slots = ["Fighter", "R", "Backrow", "EquipTrap", "EquipMagic", "TechZone"]
	
	return true if Clean_Parent_Name in Valid_Slots else false

func Resolvable_Card(card) -> bool:
	var Card_Side = card.get_parent().name.left(1)
	var Card_On_Valid_Side = true if Card_Side == BM.Side and card.Resolve_Side == "Self" or Card_Side != BM.Side and card.Resolve_Side == "Opponent" else false
	
	if card.Resolve_Side == "Both" or Card_On_Valid_Side:
		return true
	else:
		return false

func Valid_GameState(card) -> bool:
	return true if (BM.Current_Phase == card.Resolve_Phase) or card.Resolve_Phase == "Any" else false

func Valid_Effect_Type(card) -> bool:
	var Dueler = BM.Player if card.get_parent().name.left(1) == "W" else BM.Enemy

	return false if card.Anchor_Text in BM.Disabled_Effects or (card.Type == "Magic" and Dueler.Muggle_Mode) else true

func Get_Card_Selected(card, card_list, Side, Side_Opp, slot = null, desired_attributes: Array = [], desired_types: Array = [], previous_cards_selected: Array = [], repositioned_card = null) -> Card:
	var Card_Selector = load("res://Scenes/SupportScenes/Card_Selector.tscn").instantiate()
	var Battle_Scene = root.get_node("SceneHandler/Battle")
	var Chosen_Card_Node
	Battle_Scene.add_child(Card_Selector)
	var Card_Options = Card_Selector.Determine_Card_List(card_list, slot, desired_attributes, desired_types, previous_cards_selected, repositioned_card)
	Card_Selector.Set_Effect_Card(card)

	# Automatically select card if only 1 option exists
	if len(Card_Options) == 1:
		Chosen_Card_Node = Card_Options[0]
	else:
		# Find Chosen Card's Node (if any)
		if Battle_Scene.get_node("CardSelector/ScrollContainer/Effect_Target_List").get_child_count() > 0:
			await SignalBus.Confirm
			
			var Chosen_Card = Card_Selector.Get_Card()
			for i in range(len(Card_Options)):
				if Card_Options[i].name == Chosen_Card.name:
					Chosen_Card_Node = Card_Options[i]
					break
	Card_Selector.Remove_Scene()
	
	return Chosen_Card_Node

func Get_Text_Entry_Transfer_Amount(card, total_stat_value) -> int:
	var Text_Entry = load("res://Scenes/SupportScenes/Text_Entry.tscn").instantiate()
	card.add_child(Text_Entry)

	# Wait for the Confirm signal to be emitted using await
	await SignalBus.Confirm

	# Get Attack Transfer Value & Remove Scene
	var Attack_Transfer_Value = int(Text_Entry.Select_Transfer_Amount())
	if Attack_Transfer_Value < 0:
		Attack_Transfer_Value = 0
	if Attack_Transfer_Value > total_stat_value:
		Attack_Transfer_Value = total_stat_value
	Text_Entry.Remove_Scene()

	return Attack_Transfer_Value

func Get_Button_Selected(card: Card, selection_type: String = "Normal", custom_options: Array = [], desired_types: Array = ["Any"], desired_attributes: Array = ["Any"]) -> String:
	# Add Button_Selector scene as child of card to allow for selection
	var Button_Selector_Scene = load("res://Scenes/SupportScenes/Button_Selector.tscn").instantiate()
	card.add_child(Button_Selector_Scene)
	
	# Populate Button_Selector Scene with appropriate options
	if selection_type == "Custom":
		Button_Selector_Scene.Get_Custom_Options(custom_options)
	else:
		Button_Selector_Scene.Get_Active_Card_Effects(desired_types, desired_attributes)
	Button_Selector_Scene.Add_Buttons()

	# Wait for the Confirm signal to be emitted using await
	await SignalBus.Confirm

	# Get Chosen Effect text & Remove Scene
	var chosen_effect_text = Button_Selector_Scene.Get_Text()
	Button_Selector_Scene.Remove_Scene()

	return chosen_effect_text



"""--------------------------------- Attribute Effects ---------------------------------"""
func Breakthrough(card): # Activate Tech (Special)
	var Card_In_Hand = card in BF.Get_Field_Card_Data(BM.Side, "Hand")
	var Dueler_Tech_Deck = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side + "TechDeck")
	var Destination_Node = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side_Opp + "MedBay")

	if len(Dueler_Tech_Deck.get_children()) > 0 and Card_In_Hand:
		SignalBus.emit_signal("Draw_Card", BM.Current_Turn, 1, "Tech")
		SignalBus.emit_signal("Reparent_Nodes", card, Destination_Node)

func Actor(card):
	pass

func Assassin(card):
	pass

func Creature(card):
	card.Can_Activate_Effect = false
	var Cards_On_Field = BF.Get_Field_Card_Data(BM.Side, "Fighter") + BF.Get_Field_Card_Data(BM.Side, "R")
	var Cards_In_Main_Deck = BF.Get_Field_Card_Data(BM.Side, "MainDeck")
	var Destination_Node = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side + "Banished")

	# Perform Fusion Summon if a copy of the card exists on the field
	for field_card in Cards_On_Field:
		if field_card.Name == card.Name and field_card != card:
			field_card.set_fusion_level(1, "Add")
			SignalBus.emit_signal("Reparent_Nodes", card, Destination_Node)
			return # Exit function if Fusion Summon is successful (without checking MainDeck until next turn)
	
	# Perform Fusion Summon(s) if a copy of the card exists in the MainDeck
	for deck_card in Cards_In_Main_Deck:
		if deck_card.Name == card.Name:
			card.set_fusion_level(1, "Add")
			SignalBus.emit_signal("Reparent_Nodes", deck_card, Destination_Node)
			deck_card.Update_Data()

func Cryptid(card):
	pass

func Engineer(card):
	pass

func Explorer(card):
	pass

func Master(card):
	var Chosen_Card_Node = await Get_Card_Selected(card, "Reinforcers", BM.Side, BM.Side_Opp)
	Chosen_Card_Node.Attack_As_Reinforcement = true

func Mythological(card):
	pass

func Olympian(card):
	pass

func Outlaw(card):
	card.Can_Activate_Effect = false
	var Chosen_Card_Node = await Get_Card_Selected(card, "Opponent Hand", BM.Side, BM.Side_Opp)

	if Chosen_Card_Node != null:
		var Destination_Node = root.get_node("SceneHandler/Battle/Playmat/CardSpots/" + BM.Side + "HandScroller/" + BM.Side + "Hand")
		SignalBus.emit_signal("Reparent_Nodes", Chosen_Card_Node, Destination_Node)

func Philosopher(card):
	pass

func Politician(card):
	pass

func Protector(card):
	var Guardianship = await Get_Card_Selected(card, "Reinforcers", BM.Side, BM.Side_Opp, null, [], [], [], card)
	card.set_guardianship(Guardianship)

	if BM.Target == card.Guardianship and card.Guardianship != null:
		var damage_dealt = BM.Attacker.get_net_damage()
		card.set_health(damage_dealt, "Remove")
		BM.Target.set_health(damage_dealt, "Add")

func Ranged(card):
	card.Can_Activate_Effect = false
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side, "Fighter") != [] else null
	var Reinforcers = BF.Get_Field_Card_Data(BM.Side, "R")
	var Ranged_On_Field = false
	
	for i in Reinforcers:
		if Reinforcers[i].Attribute == "Ranged":
			Ranged_On_Field = true
			break
	
	if Ranged_On_Field:
		Fighter.Attacks_Remaining = Fighter.Attacks_Remaining + 2 if Fighter.Relentless else Fighter.Attacks_Remaining + 1

func Rogue(card):
	pass

func Scientist(card):
	card.Can_Activate_Effect = false
	var roll_result = BC.Dice_Roll(6)
	var roll_result2 = BC.Dice_Roll(6)
	var sum_of_rolls = roll_result + roll_result2

	if sum_of_rolls == 7:
	
		var Dueler_Tech_Deck = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side + "TechDeck")
		if len(Dueler_Tech_Deck.get_children()) > 0:
			SignalBus.emit_signal("Draw_Card", BM.Current_Turn, 1, "Tech")

func Spy(card):
	pass

func Support(card):
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side, "Fighter") != [] else null

	if (card.Health + card.Health_Bonus) > 0: # Allows for partial transfers on Summon without locking player out of ability to transfer down the road.
		card.Can_Activate_Effect = true

	if Fighter != null and card != Fighter and (card.Health + card.Health_Bonus) > 0 and card.Can_Activate_Effect:
		card.Can_Activate_Effect = false
		var Health_Transfer_Value = await Get_Text_Entry_Transfer_Amount(card, card.Health + card.Health_Bonus)		
		var Health_Bonus_Reduction = max(0, Health_Transfer_Value - card.Health)
		Fighter.set_health(Health_Transfer_Value, "Add")
		card.set_health(min(card.Health, Health_Transfer_Value), "Remove")
		card.set_health_bonus(Health_Bonus_Reduction, "Remove")

		# Move card to MedBay for healing if it dies
		if card.Total_Health <= 0:
			var Destination_Node = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side + "MedBay")
			SignalBus.emit_signal("Reparent_Nodes", card, Destination_Node)
			card.Reset_Stats_On_Capture()

	if BM.Current_Phase == BM.Phases.OPENING:
		card.set_health(ceil(float(card.Revival_Health) / 10), "Add")

func Titan(card):
	pass

func Treasure_Hunter(card):
	pass

func Trickster(card):
	pass

func Warrior(card):
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side, "Fighter") != [] else null

	if (card.Attack + card.ATK_Bonus) > 0: # Allows for partial transfers on Summon without locking player out of ability to transfer down the road.
		card.Can_Activate_Effect = true

	if Fighter != null and card != Fighter and (card.Attack + card.ATK_Bonus) > 0 and card.Can_Activate_Effect:
		card.Can_Activate_Effect = false
		var Attack_Transfer_Value = await Get_Text_Entry_Transfer_Amount(card, card.Attack + card.ATK_Bonus)
		var ATK_Bonus_Reduction = max(0, Attack_Transfer_Value - card.Attack)
		Fighter.set_attack(Attack_Transfer_Value, "Add")
		card.set_attack(min(card.Attack, Attack_Transfer_Value), "Remove")
		card.set_attack_bonus(ATK_Bonus_Reduction, "Remove")

	if BM.Current_Phase == BM.Phases.OPENING:
		card.set_attack(ceil(float(card.Base_Attack) / 10), "Add")

func Wizard(card):
	card.Can_Activate_Effect = false
	var chosen_effect_text = await Get_Button_Selected(card, "Normal", [], ["Normal"], ["Any"])

	# Add Disabled Effect to Disabled_Effects list & this card's Disabled_Effects list
	card.set_effects_disabled(chosen_effect_text, "Add")



"""--------------------------------- Hero Effects ---------------------------------"""
func Absorption(card):
	pass

func Atrocity(card):
	"""
	Effect (PROTOTYPE UPDATE):
		- If the card is on the field, the player can select a card from the opponent's MedBay to attack.
		- The card will then deal damage to the selected card equal to 20% of its total ATK.
		- If the targeted card has its total health reduced to 0, it will be moved to the Banished slot.
		- ACE SETUP: Maximized by high ATK values, ATK boosting support effects, drain/DoT effects, and any other effect that lowers the amount of damage you need to deal to banish targets.
		- COUNTERPLAY: Versatile deck-building strategies that don't rely on one "ace" card to win, health recovery effects, and effects that allow for card pile movement (i.e. move cards out of medbay).
	"""

	
	var MedBay_Opp = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side_Opp + "MedBay")
	
	if MedBay_Opp.get_child_count() > 0 and card.Can_Activate_Effect:
		card.Can_Activate_Effect = false
		var Chosen_Card_Node = await Get_Card_Selected(card, "Opponent MedBay", BM.Side, BM.Side_Opp, null, [], ["Normal", "Hero"], [])

		if Chosen_Card_Node != null:
			if not Chosen_Card_Node.is_immune("Card Effect", card):
				var Damage_Modifier = 0.2
				var damage_dealt = int(floor(card.Total_Attack * Damage_Modifier))
				Chosen_Card_Node.set_health(damage_dealt, "Remove")

				# Send card to Banished slot if it dies
				if Chosen_Card_Node.Total_Health <= 0:
					var Destination_Node = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side_Opp + "Banished")
					SignalBus.emit_signal("Reparent_Nodes", Chosen_Card_Node, Destination_Node)

func Barrage(card):
	card.set_multi_strike(true)

func Behind_Enemy_Lines(card):
	"""
	Effect (PROTOTYPE UPDATE):
		- If this card is placed in the reinforcer zones, target a random card in the opponent's hero deck.
		- Drain (but don't steal) a percentage of the target's health (max 50% per activation).
		ACE SETUP: Maximized by drawing out Battles through use of board control & stall cards, Fighter's with the ability to capture from the Hero Deck (i.e. Atrocity) or attack multiple times per turn (i.e. Relentless).
		COUNTERPLAY: Gaining health & field-related bonuses are crucial to counteract this effect as it only steals up to 50% of Health (not Total Health). Alternatively, red-barring (i.e. deliberately building your deck to work when your Heroes are at 1 HP [Invincible, etc]) can neutralize this effect.
	"""

	var Clean_Parent_Name = BF.Get_Clean_Slot_Name(card.get_parent().name)
	
	if Clean_Parent_Name == "R":
		var Hero_Deck = BF.Get_Field_Card_Data(BM.Side_Opp, "HeroDeck")
		if Hero_Deck != [] and card.Can_Activate_Effect:
			card.Can_Activate_Effect = false
			var Targeted_Hero = Hero_Deck[BC.Dice_Roll(len(Hero_Deck)) - 1]
			var damage_dealt = int(floor(float(BC.Dice_Roll(5)) / 10 * Targeted_Hero.Health))
			if not Targeted_Hero.is_immune("Card Effect", card):
				Targeted_Hero.set_health(damage_dealt, "Remove")

func Bestow(card):
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side, "Fighter") != [] else null
	var Zones_To_Search = ["MainDeck", "Fighter", "R", "Backrow", "EquipMagic", "EquipTrap", "TechZone", "Graveyard", "MedBay", "Hand"]
	
	if Fighter != null:
		if Fighter.Name == "King Arthur":
			for zone in Zones_To_Search:
				for side in ["W", "B"]:
					var Cards_In_Zone = BF.Get_Field_Card_Data(side, zone)
					for card_in_zone in Cards_In_Zone:
						if card_in_zone.Name == "Excalibur" and zone != "EquipMagic":
							# Add Excalibur to the field in EquipMagic slot (replacing previous card if necessary)
							var Fighter_Side = "W" if Fighter.get_parent().name.left(1) == "W" else "B"
							var Graveyard = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Fighter_Side + "Graveyard")
							var EquipSlot = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Fighter_Side + "EquipMagic")
							if EquipSlot.get_child_count() > 0:
								BM.Last_Equip_Card_Replaced.append(EquipSlot.get_child(0))
								SignalBus.emit_signal("Reparent_Nodes", EquipSlot.get_child(0), Graveyard)
								BC.Activate_Set_Card(EquipSlot.get_child(0)) # Ensures that any effects that trigger upon being sent to the Graveyard are resolved (i.e. Last Stand).
							card_in_zone.Can_Activate_Effect = true
							SignalBus.emit_signal("Reparent_Nodes", card_in_zone, EquipSlot)
							Excalibur(card_in_zone) # Manually activate Excalibur's effect after it is equipped
							card_in_zone.Update_Data()
							break

func Conqueror(card):
	pass

func Counter(card):
	pass

func Defiance(card):
	if card.Total_Health <= 0:
		var Coin_Flip = BC.Dice_Roll(2)
		if Coin_Flip == 1: # Defiance succeeds
			card.set_health(card.Revival_Health, "Set")
			card.set_health_bonus(0, "Set")

func Detonate(card, is_automated):
	"""
	Effect (PROTOTYPE UPDATE):
		- Upon activation, spawn a new "Bomb" card into the opponent's MainDeck.
		- This card does x damage to the card holder's current Fighter when drawn (Standby Phase).
		- The damage dealt is equal to the number of tokens on the hero card when the activation occured.
		- This card cannot be played or banished by the opponent in any way (basically like negative status cards in Slay the Spire).
		- During any standby phase where this card exists in the hand, damage is dealt.
		- Card is automatically discarded to medbay after resolution and reloaded into the maindeck when appropriate.
		- ACE SETUP: This effect is maximized by token-transfer and token-stacking effects (more tokens at once, more tokens per turn).
		- COUNTERPLAY: This card is minimized by damage reflecting effects or damage transferrence effects (armor, mirror force).
	"""


	#Effect1
	card.Can_Activate_Effect = false
	card.set_tokens(1, "Add")
	
	#Effect2
	if is_automated == false and card.Tokens > 0:
		# Create Bomb Card and add to Opponent's MainDeck
		var Bomb_Card = DC.Create_Card(38035971)
		var Deck_Opp = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side_Opp + "MainDeck")
		Deck_Opp.add_child(Bomb_Card)
		Bomb_Card.set_attack(card.Tokens, "Set")
		card.set_tokens(card.Tokens, "Remove")

		# Fix Positioning Bug
		Bomb_Card.get_node("SmallCard").set_position(Vector2.ZERO)

		# Shuffle Opponent's MainDeck
		SignalBus.emit_signal("Shuffle_Deck", BM.Dueler_Opp, "MainDeck")

func Disorient(card):
	"""
	Effect (PROTOTYPE UPDATE):
		- Upon summon switches the positions of any two cards on the field of play (including decks, hands, medbays, field card slots, opponent cards, etc.)
		- The only real restrictions are the once per summon rule and the fact that the two switched cards must be of the same general type
		- (not necesarily normal for normal, but form the same source [i.e. maindeck for maindeck. So normal for magic, cool {as long as it doesn't violate card slot placement}. Normal for Hero, bad])
		- ACE SETUP: This effect is maximized by having a deck that can enable multiple summons very quickly (For_Honor_And_Glory + a "Call to Arms" sort of effect, etc.), or has negative cards that can be switched onto the opponent's field (think Parasite Paracide from YGO [but obviously we can have more options]).
		- COUNTERPLAY: Minimized by decks built to work with a lot of cards that are "cogs in the machine" instead of one or two "ace" cards, by making hero summons more costly, or a Time Seal-like effect that delays the activation of hero effects for x turns.
	"""


	card.Can_Activate_Effect = false
	var card_given = await Get_Card_Selected(card, "Cards In Play (Universal)", BM.Side, BM.Side_Opp) # Technically could be either given or taken, but this will determine the card selection pool for the next card.
	var card_list_conditionals_map = {
		"Fighter": {"Type": ["Hero"], "Attribute": ["Any"]},
		"R": {"Type": ["Normal", "Hero"], "Attribute": ["Any"]},
		"Backrow": {"Type": ["Magic", "Trap"], "Attribute": ["Any"]},
		"EquipMagic": {"Type": ["Magic"], "Attribute": ["Equip"]},
		"EquipTrap": {"Type": ["Trap"], "Attribute": ["Equip"]},
		"MedBay": {"Type": ["Normal", "Magic", "Trap"], "Attribute": ["Any"]},
		"Graveyard": {"Type": ["Hero", "Magic", "Trap"], "Attribute": ["Any"]},
		"TechZone": {"Type": ["Tech"], "Attribute": ["Any"]},
		"Hand": {"Type": ["Normal", "Magic", "Trap"], "Attribute": ["Any"]},
		"MainDeck": {"Type": ["Normal", "Magic", "Trap"], "Attribute": ["Any"]},
		"HeroDeck": {"Type": ["Hero"], "Attribute": ["Any"]},
		"TechDeck": {"Type": ["Tech"], "Attribute": ["Any"]}}
	var Card_Given_Clean_Parent_Name = BF.Get_Clean_Slot_Name(card_given.get_parent().name)
	var desired_types = card_list_conditionals_map[Card_Given_Clean_Parent_Name]["Type"]
	var desired_attributes = card_list_conditionals_map[Card_Given_Clean_Parent_Name]["Attribute"]
	await get_tree().create_timer(0.05).timeout # Ensures previous Card_Selector is fully queue_freed before the next one is created (otherwise the node names [and as a result paths] don't match and game crashes on clicking Confirm button)
	var card_taken = await Get_Card_Selected(card, "Cards In Play (Universal)", BM.Side, BM.Side_Opp, null, desired_attributes, desired_types, [card_given]) # Represents the card switched with the card_given. Must be of the same general type as card_given.
	var Card_Taken_Clean_Parent_Name = BF.Get_Clean_Slot_Name(card_taken.get_parent().name)

	if card_given != null and card_taken != null:
		# Resolve Effect and Reparent Nodes (accounting for possibility of Deck node rules being violated)
		var trading_uses_both_sides_of_field = true if card_given.get_parent().name.left(1) != card_taken.get_parent().name.left(1) else false
		var Side_Used = "B" if (trading_uses_both_sides_of_field and BM.Current_Turn == "Player") else ("W" if BM.Current_Turn == "Player" else "B")
		var destination_nodes_conditionals_map = {
			"Normal": {"Acceptable Zones": ["R", "MedBay", "Hand", "MainDeck"], "Default_Destination": "MainDeck"},
			"Hero": {"Acceptable Zones": ["Fighter", "R", "Graveyard", "HeroDeck"], "Default_Destination": "HeroDeck"},
			"Magic": {"Acceptable Zones": ["Backrow", "EquipMagic", "MedBay", "Graveyard", "Hand", "MainDeck"], "Default_Destination": "MainDeck"},
			"Trap": {"Acceptable Zones": ["Backrow", "EquipTrap", "MedBay", "Graveyard", "Hand", "MainDeck"], "Default_Destination": "MainDeck"},
			"Tech": {"Acceptable Zones": ["TechZone", "TechDeck"], "Default_Destination": "TechDeck"}}
		var Card_Taken_Parent = card_taken.get_parent()
		var Card_Given_Parent = card_given.get_parent()
		var Card_Taken_Default_Destination = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Used + destination_nodes_conditionals_map[card_taken.Type]["Default_Destination"])
		var Card_Given_Default_Destination = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + Side_Used + destination_nodes_conditionals_map[card_given.Type]["Default_Destination"])
		var Destination_Node_Card_Taken = Card_Taken_Default_Destination if Card_Given_Clean_Parent_Name not in destination_nodes_conditionals_map[card_taken.Type]["Acceptable Zones"] else Card_Given_Parent
		var Destination_Node_Card_Given = Card_Given_Default_Destination if Card_Taken_Clean_Parent_Name not in destination_nodes_conditionals_map[card_given.Type]["Acceptable Zones"] else Card_Taken_Parent
		SignalBus.emit_signal("Reparent_Nodes", card_taken, Destination_Node_Card_Taken)
		SignalBus.emit_signal("Reparent_Nodes", card_given, Destination_Node_Card_Given)
		card_given.Update_Data()
		card_taken.Update_Data()

func Earthbound(card):
	"""
	Effect (PROTOTYPE UPDATE):
		- When this card is considered valid, the opponent's magic cards no longer have any effect.
		- ACE SETUP: Maximized by having a deck focused on providing survivability-related support to this card and neutralizing auto-capture effects. Basically anything you can do to keep this card on the field maintains your magical monopoly, limiting the options your opponent has with the cards they possess.
		- COUNTERPLAY: Board wipe/removal effects, multi-strike effects, and highly synergistic hero/support deck builds (i.e. decks that focus on the benefits normal cards provide heroes instead of magic cards)
	"""
	
	var Dueler = BM.Enemy if card.get_parent().name.left(1) == "W" else BM.Player
	Dueler.Muggle_Mode = true

func Expansion(card):
	pass

func Faithful(card):
	var Card_On_Correct_Side = true if card.get_parent().name.left(1) == BM.Side else false
	var Reinforcers = BF.Get_Field_Card_Data(BM.Side, "R")
	
	if (Reinforcers.size() >= 3) and Card_On_Correct_Side:
		card.set_immortal(true)
	elif (Reinforcers.size() < 3 or On_Field(card) == false) and Card_On_Correct_Side:
		card.set_immortal(false)

func For_Honor_And_Glory(card):
	var HeroDeck = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side + "HeroDeck")
	var HeroDeckOpp = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side_Opp + "HeroDeck")
	var MedBay = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side + "MedBay")
	var MedBay_Opp = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side_Opp + "MedBay")
	var Reinforcers = BF.Get_Field_Card_Data(BM.Side, "R")
	var Reinforcers_Opp = BF.Get_Field_Card_Data(BM.Side_Opp, "R")
	
	BM.For_Honor_And_Glory = true
	for reinforcer in Reinforcers + Reinforcers_Opp:
		var Destination_Node
		if reinforcer.Type != "Hero":
			Destination_Node = MedBay if reinforcer in Reinforcers else MedBay_Opp
		else:
			Destination_Node = HeroDeck if reinforcer in Reinforcers else HeroDeckOpp

		SignalBus.emit_signal("Reparent_Nodes", reinforcer, Destination_Node)

func Fury(card):
	"""
	Effect (PROTOTYPE UPDATE):
		- Increase the ATK of the card for each card in the player's MedBay once per turn.
		- ACE SETUP: Maximized by decks with a lot of draw/discard power that can time when this card hits the field, cheap support cards to spam that guard this card against taking damage or pair it with defensive Fighter and a card that allows for Reinforcers to attack (basically create the RPG holy trinity).
		- COUNTERPLAY: Minimized by paralysis effects, damage transferrence/rebound effects, effects that reduce total attack power, and cards that can remove cards from the MedBay (forced reload effect).
	"""

	card.Can_Activate_Effect = false
	var MedBay_Count = len(BF.Get_Field_Card_Data(BM.Side, "MedBay"))
	card.set_attack_bonus(MedBay_Count, "Add")

func Guardian(card):
	"""
	Effect (PROTOTYPE UPDATE):
		- Reflects damage done to ally reinforcers back to the opponent's Fighter.
		- ACE SETUP: Maximized when used in a supporting role with a high-attack Reinforcers and a support card allowing for the reinforcer to attack from the reinforcement zone (would be perfect paired with Fury card and Ranged Normal card).
		- COUNTERPLAY: Minimized by attacking this Fighter directly, or when paired with the proper support cards using status cards or other non-direct attack approaches to capture those support cards.
	"""


	
	var Reinforcers = BF.Get_Field_Card_Data(BM.Side_Opp, "R")
	var Is_Fighter = true if card in BF.Get_Field_Card_Data(BM.Side, "Fighter") else false
	
	if BM.Target in Reinforcers and Is_Fighter:
		BM.Target.set_health(BM.Attacker.get_net_damage(), "Add")
		if not BM.Attacker.is_immune("Card Effect", card):
			BM.Attacker.set_health(BM.Attacker.get_net_damage(), "Remove")

func Humiliator(card):
	pass		

func Inspiration(card):
	var Dueler_Tech_Deck = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side + "TechDeck")
	var Card_Index = BC.Dice_Roll(Dueler_Tech_Deck.get_child_count())

	# Add selected Tech card to Tech Zone
	if len(Dueler_Tech_Deck.get_children()) > 0:
		SignalBus.emit_signal("Draw_Card", BM.Current_Turn, 1, "Tech", Card_Index)

func Invincibility(card):
	"""
	Effect (PROTOTYPE UPDATE):
		- This card takes no damage from battle. Still takes damage from effects.
		- ACE SETUP: Maximized by forcing the opponent to attempt to win via battle damage against this card (target changing effects, magic/trap/status card nullification effects [muggle mode]).
		- COUNTERPLAY: Decks that do not need to defeat your Fighter to win (Exodia) or using non-direct damage dealing strategies to win (poison, status cards, etc.).
	"""

	if On_Field(card) == false or Valid_Effect_Type(card) == false:
		card.set_invincible(false)
	else:
		card.set_invincible(true)

func Juggernaut(card):
	"""
	Effect (PROTOTYPE UPDATE):
		- This card can only be damaged by direct battle damage while on the field. This effect cannot be disabled and this card can't suffer from burn damage or inhibiting effects (i.e. paralysis) while on the field. Magic/Trap/Status cards have no effect on it while on the field.
		- ACE SETUP: Maximized by being the sole hero in the deck, or by having a deck that can consistently keep this card on the field.
		- COUNTERPLAY: Disorient-style effects that can move this card off the field without needing to defeat it, capturing it before it hits the field through a targeted-damage effect (Atrocity), or using your own beatstick to do enough damage through battle to capture it quickly.
	"""

	if On_Field(card) == false:
		card.set_immunity("Type", "N/A", "Reset") # Remove all type-related immunities (including those granted by other cards) when off the field
		card.set_unstoppable(false) # Remove Paralysis immunity when off the field
		card.set_rejuvenation(false) # Remove Burn Damage immunity when off the field
		card.set_warded(false) # Remove Overflow Damage immunity when off the field
	else:
		card.set_immunity("Type", "Magic", "Add") # Immune to all Magic cards
		card.set_immunity("Type", "Trap", "Add") # Immune to all Trap cards
		card.set_immunity("Type", "Status", "Add") # Immune to all Status cards
		card.set_unstoppable(true) # Immune to Paralysis
		card.set_rejuvenation(true) # Immune to Burn Damage
		card.set_warded(true) # Immune to Overflow Damage

func Kinship(card):
	card.Can_Activate_Effect = false
	if card == BM.Target:
		var Card_Side = "W" if card.get_parent().name.left(1) == "W" else "B"
		var Cards_On_Field = BF.Get_Field_Card_Data(Card_Side, "Fighter") + BF.Get_Field_Card_Data(Card_Side, "R")
		var net_damage = BM.Attacker.get_net_damage()
					
		# Find Excess Fusion Level of Reinforcers
		var total_fusion_level = 1
		for current_card in Cards_On_Field:
			total_fusion_level += current_card.Fusion_Level - 1 if current_card != card and current_card.Fusion_Level > 1 else 0

		# Heal back the difference between net damage and true damage taken
		var true_damage_taken = int(floor(net_damage / total_fusion_level))
		card.set_health(net_damage - true_damage_taken, "Add")

func Mimic(card):
	pass

func Paralysis(card):
	var Fighter_Opp = BF.Get_Field_Card_Data(BM.Side_Opp, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side_Opp, "Fighter") != [] else null
	
	if Fighter_Opp != null:
		card.Can_Activate_Effect = false
		Fighter_Opp.set_paralysis(true, "Add")

func Perfect_Copy(card):
	pass

func Poison(card):
	card.Can_Activate_Effect = false
	var chosen_effect_text = await Get_Button_Selected(card, "Custom", ["Heal", "Poison"])
	var Side_Used = BM.Side if chosen_effect_text == "Heal" else BM.Side_Opp
	var Cards_On_Field = BF.Get_Field_Card_Data(Side_Used, "Fighter") + BF.Get_Field_Card_Data(Side_Used, "R")

	if chosen_effect_text == "Heal" and Cards_On_Field.size() > 0:
		var chosen_target = await Get_Card_Selected(card, "Field (All)", BM.Side, BM.Side_Opp)
		chosen_target.set_health(card.Toxicity, "Add")
	elif chosen_effect_text == "Poison" and Cards_On_Field.size() > 0:
		var chosen_target = await Get_Card_Selected(card, "Opponent Field (All)", BM.Side, BM.Side_Opp)
		if not chosen_target.is_immune("Card Effect", card):
			chosen_target.set_burn_damage(card.Toxicity, "Add") # Doesn't update health because that happens automatically during the Standby Phase

func Reformation(card):
	pass

func Reincarnation(card):
	pass

func Relentless(card):
	"""
	Effect (PROTOTYPE UPDATE):
		- This card can attack multiple times per turn.
		- ACE SETUP: Maximized when paired with cards that force low-health Heroes to spawn (i.e. Atrocity), or cards that can increase the number of attacks this card can make per turn.
		- COUNTERPLAY: Minimized when facing cards that can reduce its attacks remaining (since all alterations to this stat are doubled), target-lock abilities (forcing this card to always target a specific card when attacking [ability not yet created]), or cards with a combination of target transferrence (force attack of reinforcer) and damage reflector effects (Guardian).
	"""

	if On_Field(card) == false or Valid_Effect_Type(card) == false:
		card.set_relentless(false)
	else:
		card.set_relentless(true)

func Retribution(card):
	var Fighter_Opp = BF.Get_Field_Card_Data(BM.Side, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side, "Fighter") != [] else null # Not "Side_Opponent" since this effect will occur during opponent's turn!

	# If 1+ Normal/Hero cards were captured this turn, resolve effect
	for current_card in BM.Cards_Captured_This_Turn:
		if current_card.Type in ["Normal", "Hero"]:
			if Fighter_Opp != null and card.Can_Activate_Effect:
				card.Can_Activate_Effect = false
				if not Fighter_Opp.is_immune("Card Effect", card):
					Fighter_Opp.set_health(card.Total_Attack, "Remove")

				# Capture card if it dies
				if Fighter_Opp.Total_Health <= 0:
					SignalBus.emit_signal("Capture_Card", Fighter_Opp, "Inverted")

func Spawn(card):
	card.set_tokens(1, "Add")

	# Reduce Fighter_Opp's Health by 1 for every Token on card and capture if applicable
	var Fighter_Opp = BF.Get_Field_Card_Data(BM.Side_Opp, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side_Opp, "Fighter") != [] else null
	if Fighter_Opp != null and not Fighter_Opp.is_immune("Card Effect", card):
		Fighter_Opp.set_health(card.Tokens, "Remove")
	
	# Neutralize damage taken using spawned tokens as shields. Barrage attacks will destroy all tokens simultaneously (and damage card).
	if card.Tokens > 0:
		if BM.Attacker.Multi_Strike == false or card.is_immune("Card Effect", BM.Attacker):
			card.set_health(BM.Attacker.Total_Attack, "Add")
			card.set_tokens(1, "Remove")
		else:
			card.set_tokens(card.Tokens, "Remove")

func Tailor_Made(card):
	card.Can_Activate_Effect = false
	var options = []
	var Global_Card_Holder = root.get_node("SceneHandler/Battle/Global_Card_Holder")

	# Find all Equip cards
	for current_card in BM.CardData:
		if current_card["CardType"] in ["Magic", "Trap"] and current_card["Attribute"] == "Equip":
			options.append(current_card)

	# Choose 3 random cards from options array & instantiate them
	for i in range(3):
		var random_index = randi() % len(options)
		var Equip_Card = DC.Create_Card(options[random_index]["Passcode"])
		Global_Card_Holder.add_child(Equip_Card)
		options.pop_at(random_index)

	# Move Chosen_Card to proper hand
	var Chosen_Card_Node = await Get_Card_Selected(card, "Global Cards", BM.Side, BM.Side_Opp)
	var Destination_Node = root.get_node("SceneHandler/Battle/Playmat/CardSpots/" + BM.Side + "HandScroller/" + BM.Side + "Hand")
	if Chosen_Card_Node != null:		
		SignalBus.emit_signal("Reparent_Nodes", Chosen_Card_Node, Destination_Node)

	# Remove all children from Global_Card_Holder
	for child in Global_Card_Holder.get_children():
		child.queue_free()

func Taunt(card):
	pass



"""--------------------------------- Magic/Trap Effects ---------------------------------"""
func Blade_Song(card):
	var Chosen_Card_Node = await Get_Card_Selected(card, "Graveyard", BM.Side, BM.Side_Opp, "Graveyard", ["Equip"])

	# Reparent Nodes
	var Destination_Hand = root.get_node("SceneHandler/Battle/Playmat/CardSpots/" + BM.Side + "HandScroller/" + BM.Side + "Hand")
	var Destination_Graveyard = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side + "Graveyard")
	if Chosen_Card_Node != null:		
		SignalBus.emit_signal("Reparent_Nodes", Chosen_Card_Node, Destination_Hand)
	SignalBus.emit_signal("Reparent_Nodes", card, Destination_Graveyard)

func Crook(card):
	card.Can_Activate_Effect = false
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side, "Fighter") != [] else null
	var Reinforcers = BF.Get_Field_Card_Data(BM.Side, "R")

	if Fighter != null:
		for reinforcer in Reinforcers:
			if reinforcer.Attribute == "Creature":
				Fighter.set_health(int(ceil(float(reinforcer.Total_Health) / 4)), "Add")

func Cursed_Mirror(card): # NOTE: Should tokens be spawning on start of enemy turn instead of start of next player turn? Trap cards like this feel slow under current implementation.
	if card.Tokens > 0:
		card.set_tokens(0, "Reset")
		BM.Target.set_health(BM.Attacker.get_net_damage(), "Add")
		if not BM.Attacker.is_immune("Card Effect", card):
			BM.Attacker.set_health(BM.Attacker.get_net_damage(), "Remove")
			if BM.Attacker.Total_Health <= 0:
				SignalBus.emit_signal("Capture_Card", BM.Attacker, "Inverted")
		
		# Reparent Nodes
		var Destination_Node = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side_Opp + "Graveyard")
		SignalBus.emit_signal("Reparent_Nodes", card, Destination_Node)

func Deep_Pit(card):
	"""
	Effect (PROTOTYPE UPDATE):
		- Reduces combat effectiveness of all Warrior cards on opposing field by 3 ATK_Bonus due to forcing them to maneuver around the terrain.
		- ACE SETUP: ???
		- COUNTERPLAY: ???
	"""

	if card.Tokens > 0:
		var Cards_On_Field_Opp = BF.Get_Field_Card_Data(BM.Side, "R") + BF.Get_Field_Card_Data(BM.Side, "Fighter")
		var Destination_Node = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side_Opp + "Graveyard")
		for current_card in Cards_On_Field_Opp:
			if current_card.Attribute == "Warrior":
				current_card.set_attack_bonus(3, "Remove")
		card.set_tokens(card.Tokens, "Remove")
		SignalBus.emit_signal("Reparent_Nodes", card, Destination_Node)

func Disarm(card):
	"""
	Effect (PROTOTYPE UPDATE):
		- Remove all currently equipped cards from the opponent's Fighter.
		- ACE SETUP: ???
		- COUNTERPLAY: ???
	"""

	card.Can_Activate_Effect = false
	var Equip_Cards_Opp = BF.Get_Field_Card_Data(BM.Side_Opp, "EquipMagic") + BF.Get_Field_Card_Data(BM.Side_Opp, "EquipTrap")
	var Destination_Node = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side_Opp + "Graveyard")

	for current_card in Equip_Cards_Opp:
		SignalBus.emit_signal("Reparent_Nodes", current_card, Destination_Node)

func Excalibur(card):
	var Dueler = BM.Player if card.get_parent().name.left(1) == "W" else BM.Enemy
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side, "Fighter") != [] else null
	var Reinforcers = BF.Get_Field_Card_Data(BM.Side, "R")
	var Fighter_Opp = BF.Get_Field_Card_Data(BM.Side_Opp, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side_Opp, "Fighter") != [] else null
	var Reinforcers_Opp = BF.Get_Field_Card_Data(BM.Side_Opp, "R")
	var Cards_On_Field = [Fighter] + Reinforcers if Fighter != null else Reinforcers
	var Cards_On_Field_Opp = [Fighter_Opp] + Reinforcers_Opp if Fighter_Opp != null else Reinforcers_Opp

	# Resolve Effect(s) if equipped to King Arthur
	if Fighter.Name == "King Arthur":
		# Effect 1-3:
			# 1) Add Attack Bonus to King Arthur and all allied Warriors, Remove Attack Bonus from all enemy cards
			# 2) Make King Arthur and all allies immune to Burn Damage (Rejuvenation)
			# 3) Inspire King Arthur and all allies to attack again
		if BM.Current_Phase == BM.Phases.STANDBY and card.Can_Activate_Effect:
			card.Can_Activate_Effect = false
			for current_card in Cards_On_Field:
				current_card.set_rejuvenation(true)
				current_card.set_attacks_remaining(1, "Add")
				if current_card.Attribute == "Warrior":
					current_card.set_attack_bonus(3, "Add")
			for current_card in Cards_On_Field_Opp:
				if current_card.is_immune("Card Effect", card):
					current_card.set_attack_bonus(2, "Remove")

		# Effect 4: Deal a percentage of King Arthur's Total Attack as damage to all opposing Reinforcers (if any)
		if BM.Current_Phase == BM.Phases.BATTLE and BM.Attacker == Fighter:
			var Damage_Percent = 0.33
			for current_card in Reinforcers_Opp:
				if not current_card.is_immune("Card Effect", card) and BM.Attacker == Fighter:
					current_card.set_health(int(floor(Fighter.Total_Attack * Damage_Percent)), "Remove")

	# Reset Can_Activate_Effect to allow for resolving standby effects once per turn (periodic equip effects [NOTE: This should probably be a func in BC, not here, but since this is currently the only Periodic magic card, it's here for now])
	if BM.Current_Phase == BM.Phases.OPENING and Dueler.Name == BM.Current_Turn:
		card.Can_Activate_Effect = true

func Grenade(card):
	# An Equip Magic card that allows the Fighter to deal damage to one of the opponent's Reinforcers when attacking the Opposing Fighter.
	# When combined with Tidal_Wave, overflow damage will hit the Reinforcer(s) first, and if any remains will then hit the Hero Deck.	
	get_tree().call_group("Cards", "set_can_deal_overflow_damage", true)

func Heart_of_the_Underdog(card):
	var Defending_Fighter = BF.Get_Field_Card_Data(BM.Side_Opp, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side_Opp, "Fighter") != [] else null # Not "BM.Side" since this effect will occur during opponent's turn!

	if BM.Target == Defending_Fighter and card.Tokens > 0:
		if BM.Attacker.Total_Attack >= BM.Target.Total_Health and BM.Attacker.Total_Attack < BM.Target.Total_Health + 7: # Ensures trap only activates when it would save the Target from Capture
			BM.Target.set_health(7, "Add")
			var Destination_Node = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side_Opp + "Graveyard")
			SignalBus.emit_signal("Reparent_Nodes", card, Destination_Node)
			SignalBus.emit_signal("Activate_Set_Card", BM.Side_Opp, card)

func Last_Stand(card):
	var Parent_Name = card.get_parent().name
	var Cards_On_Field = BF.Get_Field_Card_Data(BM.Side, "Fighter") + BF.Get_Field_Card_Data(BM.Side, "R")
	var Cards_On_Field_Opp = BF.Get_Field_Card_Data(BM.Side_Opp, "Fighter") + BF.Get_Field_Card_Data(BM.Side_Opp, "R")
	var Cards_On_Field_Used = Cards_On_Field if card in BM.Last_Equip_Card_Replaced else Cards_On_Field_Opp

	# Reset card's Can_Activate_Effect value to allow for resolving the effect from Graveyard (once per turn)
	if card in BM.Cards_Captured_This_Turn or card in BM.Last_Equip_Card_Replaced:
		card.Can_Activate_Effect = true
		BM.Last_Equip_Card_Replaced.erase(card)

	# Resolve Effect
	if "Graveyard" in Parent_Name and card.Can_Activate_Effect and BM.Current_Phase == BM.Phases.END:
		card.Can_Activate_Effect = false
		for current_card in Cards_On_Field_Used:
			current_card.set_attack_bonus(8, "Remove")
	else:
		for current_card in Cards_On_Field:
			current_card.set_attack_bonus(5, "Add")

func Miraculous_Recovery(card):
	# Check if there are any cards in the MedBay
	var MedBay_Cards = BF.Get_Field_Card_Data(BM.Side, "MedBay") + BF.Get_Field_Card_Data(BM.Side_Opp, "MedBay")

	# Remove Advance Tech card from MedBay Array (if applicable)
	for current_card in MedBay_Cards:
		if current_card.Name == "Activate Technology":
			MedBay_Cards.erase(current_card)
			break

	# Resolve Effect
	if card.Can_Activate_Effect and len(MedBay_Cards) > 0:
		card.Can_Activate_Effect = false
		var Chosen_Card_Node = await Get_Card_Selected(card, "Both MedBays", BM.Side, BM.Side_Opp)

		# Restore Stats to Base (if Normal/Hero)
		if Chosen_Card_Node != null:
			if Chosen_Card_Node.Type in ["Normal", "Hero"]:
				Chosen_Card_Node.set_health(Chosen_Card_Node.Revival_Health, "Set")
				Chosen_Card_Node.set_health_bonus(0, "Set")
				Chosen_Card_Node.set_attack(Chosen_Card_Node.Base_Attack, "Set")
				Chosen_Card_Node.set_attack_bonus(0, "Set")

			# Reparent Nodes
			var Destination_Hand = root.get_node("SceneHandler/Battle/Playmat/CardSpots/" + BM.Side + "HandScroller/" + BM.Side + "Hand")
			var Destination_Graveyard = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side + "Graveyard")
			SignalBus.emit_signal("Reparent_Nodes", Chosen_Card_Node, Destination_Hand)
			SignalBus.emit_signal("Reparent_Nodes", card, Destination_Graveyard)

func Morale_Boost(card):
	"""
	Effect (PROTOTYPE UPDATE):
		- Adds an additional attack this turn to a Normal/Hero card of your choice.
		- ACE SETUP: Utilize with Relentless-enabled cards for maximum impact.
		- COUNTERPLAY: Earthbound, Relentless-disabling effects, reduce attacks_remaining effects, attack-reflecting effects.
	"""

	var Chosen_Card_Node = await Get_Card_Selected(card, "Field (All)", BM.Side, BM.Side_Opp)

	# Resolve Effect
	if Chosen_Card_Node != null:
		if Chosen_Card_Node.Type in ["Normal", "Hero"]:
			Chosen_Card_Node.set_attacks_remaining(1, "Add")

		# Reparent Nodes
		var Destination_Node = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side + "Graveyard")
		SignalBus.emit_signal("Reparent_Nodes", card, Destination_Node)

func Pans_Pipes(card):
	card.Can_Activate_Effect = false
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side, "Fighter") != [] else null
	var Reinforcers = BF.Get_Field_Card_Data(BM.Side, "R")

	if Fighter != null:
		var highest_fusion_level = 1
		for reinforcer in Reinforcers:
			if reinforcer.Fusion_Level > highest_fusion_level:
				highest_fusion_level = reinforcer.Fusion_Level

		# Multiply Fighter's Attack and Health by highest Fusion Level
		Fighter.set_attack(Fighter.Attack * highest_fusion_level, "Set")
		Fighter.set_health(Fighter.Health * highest_fusion_level, "Set")

func Prayer(card):
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side, "Fighter") != [] else null
	var Fighter_Opp = BF.Get_Field_Card_Data(BM.Side_Opp, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side_Opp, "Fighter") != [] else null
	var roll_result = BC.Dice_Roll(6)
	var Effect_Target = Fighter if roll_result in [2, 4, 5, 6] else Fighter_Opp

	if Effect_Target != null:
		if Effect_Target == Fighter or (Effect_Target == Fighter_Opp and not Fighter_Opp.is_immune("Card Effect", card)):
			if roll_result in [1, 2]:
				Effect_Target.set_attack(3, "Add")
			elif roll_result in [3, 4]:
				if Effect_Target == Fighter:
					Effect_Target.set_health(max(Effect_Target.Revival_Health, Fighter.Health), "Set")
				else:
					Effect_Target.set_health(Effect_Target.Revival_Health, "Set")
			elif roll_result == 5:
				Effect_Target.set_paralysis(true, "Add")
			elif roll_result == 6:
				Effect_Target.set_invincible(true)

func Resurrection(card):
	var Chosen_Card_Node = await Get_Card_Selected(card, "MedBay", BM.Side, BM.Side_Opp, "MedBay", [], ["Normal"])

	# Find Open Slot to Summon Chosen Card into
	if Chosen_Card_Node != null:
		var Fighter_Open = BF.Find_Open_Slot("Fighter", BM.Side)
		var Reinforcer_Open = BF.Find_Open_Slot("R", BM.Side)
		var Destination_Node
		if Fighter_Open != null:
			Destination_Node = root.get_node(Fighter_Open)
		elif Reinforcer_Open != null:
			Destination_Node = root.get_node(Reinforcer_Open)
		else:
			Destination_Node = root.get_node("SceneHandler/Battle/Playmat/CardSpots/" + BM.Side + "HandScroller/" + BM.Side + "Hand")

		# Update MedBay/Hand
		SignalBus.emit_signal("Reparent_Nodes", Chosen_Card_Node, Destination_Node)

func Runetouched(card):
	var Node_To_Update = root.get_node("SceneHandler/Battle/UI/Duelists/HUD_" + BM.Side)
	
	BM.Dueler.set_cost_discount_magic(1, "Remove")
	SignalBus.emit_signal("Update_HUD_Duelist", Node_To_Update, BM.Dueler)

func Stampede(card):
	var Reinforcers = BF.Get_Field_Card_Data(BM.Side, "R")

	for reinforcer in Reinforcers:
		if reinforcer.Attribute == "Creature":
			reinforcer.Attack_As_Reinforcement = true

func Summon_Monster(card):
	var Chosen_Card_Node = await Get_Card_Selected(card, "Reinforcers", BM.Side, BM.Side_Opp, null, ["Creature"])

	Chosen_Card_Node.set_fusion_level(1, "Add")

func Sword(card):
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side, "Fighter") != [] else null

	if Fighter != null and card.Can_Activate_Effect:
		Fighter.set_attack_bonus(3, "Add")

func Whip(card):
	card.Can_Activate_Effect = false
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side, "Fighter") != [] else null
	var Fighter_Opp = BF.Get_Field_Card_Data(BM.Side_Opp, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side_Opp, "Fighter") != [] else null
	var Reinforcers = BF.Get_Field_Card_Data(BM.Side, "R")

	if Fighter != null and Fighter_Opp != null:
		var Reinforcer_Power = 0
		for reinforcer in Reinforcers:
			if reinforcer.Attribute == "Creature":
				Reinforcer_Power += reinforcer.Total_Attack

		# Inflict damage to Fighter_Opp equal to half the combined attack power of all Reinforcers
		Fighter_Opp.set_health(int(ceil(float(Reinforcer_Power) / 2)), "Remove")



"""--------------------------------- Tech Effects ---------------------------------"""
func Concrete(card):
	if card.Can_Activate_Effect:
		card.Can_Activate_Effect = false
		BM.Dueler.set_hand_size_limit(1, "Add")

func Fire(card):
	if card.Can_Activate_Effect:
		card.Can_Activate_Effect = false
		var Node_To_Update = root.get_node("SceneHandler/Battle/UI/Duelists/HUD_" + BM.Side)
		
		BM.Dueler.set_field_health_bonus(10, "Add")
		SignalBus.emit_signal("Update_HUD_Duelist", Node_To_Update, BM.Dueler)
	get_tree().call_group("Cards", "set_total_health")

func Medicine(card):
	var Card_On_Correct_Side = true if card.get_parent().name.left(1) == BM.Side else false

	if On_Field(card) and BM.Current_Phase == BM.Phases.OPENING and Card_On_Correct_Side and BM.Turn_Counter > 1:
		card.Can_Activate_Effect = true

	if On_Field(card) and Card_On_Correct_Side and card.Can_Activate_Effect:
		card.Can_Activate_Effect = false
		var Node_To_Update = root.get_node("SceneHandler/Battle/UI/Duelists/HUD_" + BM.Side)
		
		BM.Dueler.set_field_health_bonus(3, "Add")
		SignalBus.emit_signal("Update_HUD_Duelist", Node_To_Update, BM.Dueler)
		await get_tree().create_timer(0.05).timeout # Creating a timer ensures that the HUD variable is updated before the signal is emitted
		get_tree().call_group("Cards", "set_total_health")

func Shield_Wall(card):
	if card.Can_Activate_Effect:
		card.Can_Activate_Effect = false
		BM.Dueler.Shield_Wall_Active = true

func The_Wheel(card):
	if card.Can_Activate_Effect:
		card.Can_Activate_Effect = false
		var Node_To_Update = root.get_node("SceneHandler/Battle/UI/Duelists/HUD_" + BM.Side)
		
		BM.Dueler.set_cost_discount_normal(1, "Remove")
		BM.Dueler.set_cost_discount_hero(1, "Remove")
		BM.Dueler.set_cost_discount_magic(1, "Remove")
		BM.Dueler.set_cost_discount_trap(1, "Remove")
		SignalBus.emit_signal("Update_HUD_Duelist", Node_To_Update, BM.Dueler)

func Tidal_Wave(card):
	# An effect that allows for all overflow damage to be dealt to the opponent's Reinforcers and (if applicable) cards in Hero Deck.
	# Overflow damage will hit reinforcers first, and if any remains will then hit the Hero Deck.
	# This should help to solve the issue of Attack Power (and thus Warrior effects) becoming irrelevant after a certain point because you 1-shot everything.
	if On_Field(card):
		get_tree().call_group("Cards", "set_perfected_overflow", card.get_parent().name.left(1)) 



"""--------------------------------- Status Effects ---------------------------------"""
func Bomb(card):
	# Resolve Effect
	var Fighter = BF.Get_Field_Card_Data(BM.Side, "Fighter")[0] if BF.Get_Field_Card_Data(BM.Side, "Fighter") != [] else null
	if not Fighter.is_immune("Card Effect", card):
		Fighter.set_health(card.Attack, "Remove")

	# Reparent Nodes
	var Destination_Node = root.get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/" + BM.Side + "MedBay")
	SignalBus.emit_signal("Reparent_Nodes", card, Destination_Node)



"""--------------------------------- Unused Effects ---------------------------------"""
func Cannon(card):
	pass

func Death_Ray(card):
	pass

func Fists(card):
	pass

func Gun(card):
	pass

func Missile_Launcher(card):
	pass

func Power_Up(card):
	pass

func Rock(card):
	pass

func Rocket_Launcher(card):
	pass
