extends Control

@onready var Active_Effects = []
@onready var trigger_card = get_parent()
@onready var Selected_Button = null

func _ready():
	var _HV1 = SignalBus.connect("Button_Selected", Callable(self, "On_Button_Selection"))

func Get_Active_Card_Effects():
	var active_effects_dict = {}
	var active_decks = GameData.Player.Deck + GameData.Enemy.Deck

	for card in active_decks:
		if card.Anchor_Text not in GameData.Disabled_Effects:
			active_effects_dict[card.Anchor_Text] = true

	Active_Effects = active_effects_dict.keys()

func Get_Custom_Options(options):
	var active_effects_dict = {}
	
	for option in options:
		active_effects_dict[option] = true

	Active_Effects = active_effects_dict.keys()

func Add_Buttons():
	for effect_text in Active_Effects:
		var button_scene = load("res://Scenes/SupportScenes/Button_Option.tscn").instantiate()
		button_scene.text = effect_text
		$ScrollContainer/Options_List.add_child(button_scene)

func Get_Text():
	return Selected_Button.text

func Remove_Scene():
	trigger_card.remove_child(self)
	queue_free()

func On_Button_Selection(button):
	Selected_Button = button

	# Creating a timer ensures that the Selected_Button variable is set before the signal is emitted
	await get_tree().create_timer(0.05).timeout

	if Selected_Button != null:
		SignalBus.emit_signal("Confirm")
