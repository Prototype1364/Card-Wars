extends Button

@onready var BM = get_tree().get_root().get_node("SceneHandler/Battle")

func _ready():
    pass

func _on_pressed():
    SignalBus.emit_signal("Button_Selected", self)