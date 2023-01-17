extends Sprite

func _ready():
	pass 



func _on_VScrollBar_value_changed(value):
	self.position.y = 0 - value


func _on_SwitchSides_pressed():
	if self.flip_h == true:
		self.flip_h = false
	else:
		self.flip_h = true
	if self.flip_v == true:
		self.flip_v = false
	else: 
		self.flip_v = true
	self.get_node("CardSpots").rect_rotation += 180
