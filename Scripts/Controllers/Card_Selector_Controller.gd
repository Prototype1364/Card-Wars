extends Control

# Determine the type of card selection list being used (medbay, grave, opponent hand, etc)

# Populate the HBoxContainer with appropriate cards

# Ability to confirm selection of desired card (likely a confirm button on bottom of popup window)

var Current_Scene = Engine.get_main_loop().get_current_scene()

func _ready():
	pass

func Determine_Card_List(selection_type):
	var Selection_Source = Current_Scene.get_node("Battle/Playmat/CardSpots/BHandScroller/BHand")
	var Card_List = []
	
	for i in Selection_Source.get_children():
		Card_List.append(i)
	
	Populate_Card_Options_List(Card_List)

func Populate_Card_Options_List(Card_List):
	for i in len(Card_List):
		var original = Card_List[i]
		var copy = original.duplicate()
		$ScrollContainer/HBoxContainer.add_child(copy)
		for n in original.get_property_list():
			var PropertyName = n["name"]
			var value = original.get_indexed(PropertyName)
			copy.set_indexed(PropertyName,value)
		copy.Set_Card_Variables(i, "NonTurnHand")
		copy.Set_Card_Visuals()
		copy.Update_Data()

func On_Card_Selection():
	pass
