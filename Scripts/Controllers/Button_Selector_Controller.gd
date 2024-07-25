extends Control

@onready var Active_Effects = []
@onready var trigger_card = get_parent()
@onready var Selected_Button = null

func _ready():
	var _HV1 = SignalBus.connect("Button_Selected", Callable(self, "On_Button_Selection"))

func Get_Active_Card_Effects():
	var active_effects_dict = {}
	var card_sources = {
		"W_Deck": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/WMainDeck"),
		"W_Hand": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/WHandScroller/WHand"),
		"W_Graveyard": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/WGraveyard"),
		"W_MedicalBay": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/WMedBay"),
		"W_Fighter": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/WFighter"),
		"WR1": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/WR1"),
		"WR2": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/WR2"),
		"WR3": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/WR3"),
		"W_Backrow_1": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/WBackrow1"),
		"W_Backrow_2": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/WBackrow2"),
		"W_Backrow_3": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/WBackrow3"),
		"W_Equip_Magic": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/WEquipMagic"),
		"W_Equip_Trap": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/WEquipTrap"),
		"B_Deck": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/BMainDeck"),
		"B_Hand": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/BHandScroller/BHand"),
		"B_Graveyard": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/BGraveyard"),
		"B_MedicalBay": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/BMedBay"),
		"B_Fighter": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/BFighter"),
		"BR1": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/BR1"),
		"BR2": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/BR2"),
		"BR3": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/BR3"),
		"B_Backrow_1": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/BBackrow1"),
		"B_Backrow_2": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/BBackrow2"),
		"B_Backrow_3": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/BBackrow3"),
		"B_Equip_Magic": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/BEquipMagic"),
		"B_Equip_Trap": get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots/NonHands/BEquipTrap"),
	}

	for source in card_sources:
		for card in card_sources[source].get_children():
			if card.Anchor_Text not in GameData.Disabled_Effects:
				active_effects_dict[card.Anchor_Text] = true

	Active_Effects = active_effects_dict.keys()

func Get_Custom_Options(options):
	var active_effects_dict = {}
	
	for option in options:
		active_effects_dict[option] = true

	Active_Effects = active_effects_dict.keys()

func Add_Buttons():
	# Alphabetize Effects List
	Active_Effects.sort()

	for effect_text in Active_Effects:
		var button_scene = load("res://Scenes/SupportScenes/Button_Option.tscn").instantiate()
		button_scene.text = effect_text.replace("_"," ")
		$ScrollContainer/Options_List.add_child(button_scene)

func Get_Text():
	return Selected_Button.text.replace(" ","_")

func Remove_Scene():
	trigger_card.remove_child(self)
	queue_free()

func On_Button_Selection(button):
	Selected_Button = button

	# Creating a timer ensures that the Selected_Button variable is set before the signal is emitted
	await get_tree().create_timer(0.05).timeout

	if Selected_Button != null:
		SignalBus.emit_signal("Confirm")
