extends Control

@onready var Active_Effects = []
@onready var Selected_Button = null
@onready var BF = get_tree().get_root().get_node("SceneHandler/Battle/Playmat/CardSpots")

func _ready():
	var _HV1 = SignalBus.connect("Button_Selected", Callable(self, "On_Button_Selection"))

	position = get_parent().get_parent().global_position

func Get_Active_Card_Effects(desired_types = ["Any"], desired_attributes = ["Any"]):
	var active_effects_dict = {}
	for card in get_tree().get_nodes_in_group("Cards"):
		if card.Anchor_Text not in GameData.Disabled_Effects and card.Anchor_Text != "Juggernaut" and (card.Type in desired_types or desired_types == ["Any"]) and (card.Attribute in desired_attributes or desired_attributes == ["Any"]):
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
	get_parent().remove_child(self)
	queue_free()

func On_Button_Selection(button):
	Selected_Button = button

	# Creating a timer ensures that the Selected_Button variable is set before the signal is emitted
	await get_tree().create_timer(0.05).timeout

	if Selected_Button != null:
		SignalBus.emit_signal("Confirm")
