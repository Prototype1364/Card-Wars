extends Control

@onready var trigger_card = get_parent()

func _ready():
	pass

func Select_Transfer_Amount():
	return $PanelContainer/TextEdit.text

func Remove_Scene():
	trigger_card.remove_child(self)
	queue_free()

func _on_text_edit_text_changed():
	var text_edit_node = $PanelContainer/TextEdit
	var current_text = $PanelContainer/TextEdit.text
	var valid_int_attributes = ["Support", "Warrior"]
	
	if trigger_card.Attribute in valid_int_attributes:
		if not current_text.is_valid_int():
			$PanelContainer/TextEdit.text = str(current_text.to_int())
		text_edit_node.set_caret_column(current_text.length()) # Set the cursor to the end of the line
