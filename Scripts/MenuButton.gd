tool
extends TextureButton

export(String) var text = "Text Button"
export(int) var arrow_margin_from_center = 100

func _ready():
	setup_text()
	hide_arrows()
	set_focus_mode(true)

func _process(_delta):
	if Engine.editor_hint:
		setup_text()
		show_arrows()

func setup_text():
	$RichTextLabel.bbcode_text = "[center] %s [/center]" % [text]

func show_arrows():
	for arrow in [$LeftArrow, $RightArrow]:
		arrow.visible = true
		arrow.global_position.y = rect_global_position.y + (rect_size.y / 3.0)
	
	var center_x = rect_global_position.x + (rect_size.x / 2.0)
	$LeftArrow.global_position.x = center_x - arrow_margin_from_center
	$RightArrow.global_position.x = center_x + arrow_margin_from_center

func hide_arrows():
	for arrow in [$LeftArrow, $RightArrow]:
		arrow.visible = false


func _On_TextureButton_Focus_Entered():
	show_arrows()


func _On_TextureButton_Focus_Exited():
	hide_arrows()


func _On_TextureButton_Mouse_Entered():
	grab_focus()
