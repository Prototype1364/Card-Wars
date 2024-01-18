extends Button

func _ready():
    pass

func _on_pressed():
    SignalBus.emit_signal("Button_Selected", self)