extends Control

var Current_Scene = Engine.get_main_loop().get_current_scene()
var BF = Current_Scene.get_node("Battle/Playmat/CardSpots")
@onready var BM = get_tree().get_root().get_node("SceneHandler/Battle")
var Card_Selected = null
var Card_ID = null
var Effect_Card = null
var Card_Slot = null

func _ready():
	var _HV1 = SignalBus.connect("EffectTargetSelected", Callable(self, "On_Card_Selection"))

func Get_Field_Card_Parent_Data(side, slot):
	var card_data: Array = BF.Get_Field_Card_Data(side, slot)
	return card_data[0].get_parent() if len(card_data) > 0 else null

func Determine_Card_List(selection_type, slot = null, Desired_Attributes: Array = [], Desired_Types: Array = [], Previous_Cards_Selected: Array = [], Repositioned_Card = null) -> Array:
	var converted_selection_type = selection_type.replace("Opponent ", "")
	var Selection_Side = ("W" if BM.Current_Turn == "Player" else "B") if "Opponent" not in selection_type else ("B" if BM.Current_Turn == "Player" else "W")
	var Selection_Source = []
	var Source_Map = {
		"Deck": "MainDeck",
		"Tech Deck": "TechDeck",
		"Field": slot,
		"Field (All)": ["Fighter", "R"],
		"Reinforcers": "R",
		"MedBay": "MedBay",
		"Graveyard": "Graveyard",
		"Hand": "Hand",
		"Both MedBays": "MedBay",
		"Cards In Play (Universal)": ["Fighter", "R", "Backrow", "EquipMagic", "EquipTrap", "MedBay", "Graveyard", "TechZone", "Hand", "MainDeck", "HeroDeck", "TechDeck"],
		"Global Cards": "Global_Card_Holder"
	}

	# Determine the source (field card slot) of the cards to choose from
	if Source_Map.has(converted_selection_type):
		if "Universal" in selection_type:
			for side in ["W", "B"]:
				for current_slot in Source_Map[converted_selection_type]:
					Selection_Source.append(Get_Field_Card_Parent_Data(side, current_slot))
		elif "Both" in selection_type:
			for side in ["W", "B"]:
				Selection_Source.append(Get_Field_Card_Parent_Data(side, Source_Map[converted_selection_type]))
		elif "All" in selection_type:
			for current_slot in Source_Map[converted_selection_type]:
				Selection_Source.append(Get_Field_Card_Parent_Data(Selection_Side, current_slot))
		elif selection_type == "Field":
			Selection_Source.append(Get_Field_Card_Parent_Data(Selection_Side, slot))
		elif selection_type == "Global Cards":
			Selection_Source.append(Current_Scene.get_node("Battle/Global_Card_Holder"))
		else:
			Selection_Source.append(Get_Field_Card_Parent_Data(Selection_Side, Source_Map[converted_selection_type]))
	
	# Populate the list of cards to choose from
	var Card_List = []
	for source in Selection_Source:
		if source != null:
			Selection_Side = source.name.left(1) if "Both" in selection_type or "Universal" in selection_type else Selection_Side
			var cards = BF.Get_Field_Card_Data(Selection_Side, BF.Get_Clean_Slot_Name(source.name))
			for card in cards:
				var card_is_not_self = card != Repositioned_Card
				var card_not_previously_selected = card not in Previous_Cards_Selected
				var card_is_acceptable_type = card.Type in Desired_Types or Desired_Types == [] or "Any" in Desired_Types
				var card_is_acceptable_attribute = card.Attribute in Desired_Attributes or Desired_Attributes == [] or "Any" in Desired_Attributes
				var card_is_not_in_list = card not in Card_List
				var card_is_valid = card_is_not_self and card_not_previously_selected and card_is_acceptable_type and card_is_acceptable_attribute and card_is_not_in_list
				if card_is_valid:
					Card_List.append(card)
	
	# Ensures an empty list is not used
	if len(Card_List) > 0:
		Populate_Card_Options_List(Card_List)

	return Card_List

func Populate_Card_Options_List(Card_List):
	var DC = get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands")
	for i in len(Card_List):
		var original = Card_List[i]
		var copy = DC.Create_Card(original.Passcode)
		copy.name = original.name
		$ScrollContainer/Effect_Target_List.add_child(copy)
		for n in original.get_property_list():
			var PropertyName = n["name"]
			var value = original.get_indexed(PropertyName)
			copy.set_indexed(PropertyName,value)
		copy.Update_Data()
		
		# Hides Advance Tech Card from list (but still spawns it to ensure correct card is chosen from Card_Selector scene)
		if original.Type == "Special":
			copy.visible = false
		
		# Hide Button Selector Scene if present
		if copy.has_node("ButtonSelector"):
			copy.get_node("ButtonSelector").visible = false
		
		# Fix Positioning Bug
		copy.get_node("SmallCard").set_position(Vector2.ZERO)

func On_Card_Selection(card):
	Card_Selected = card
	Card_ID = card.name

func Get_Card():
	return Card_Selected

func Set_Effect_Card(card):
	Effect_Card = card

func Remove_Scene():
	# Queue free the Card Selector scene from the scene tree
	var Card_Selector_Scene = Current_Scene.get_node("Battle/CardSelector")
	Card_Selector_Scene.queue_free()

func _on_confirm_button_pressed():
	SignalBus.emit_signal("Confirm")
