extends Control

# Member variables
var Name = ""
var LP = 100
var Summon_Crests = 0
var Tokens = 0
var Field_ATK_Bonus = 0
var Field_Health_Bonus = 0
var Summon_Crest_Roll_Bonus = 0
var Cost_Discount_Normal = 0
var Cost_Discount_Hero = 0
var Cost_Discount_Magic = 0
var Cost_Discount_Trap = 0
var Valid_Attackers = 0
var Tech_Zone = []
var Capture_Destination = "Graveyard"
var Muggle_Mode = false

func set_summon_crests(value, context="Initialize"):
	if context == "Add":
		Summon_Crests += value
	elif context == "Remove":
		Summon_Crests -= value
	else:
		Summon_Crests = value

func set_cost_discount_normal(value, context="Initialize"):
	if context == "Add":
		Cost_Discount_Normal += value
	elif context == "Remove":
		Cost_Discount_Normal -= value
	else:
		Cost_Discount_Normal = value

func set_cost_discount_hero(value, context="Initialize"):
	if context == "Add":
		Cost_Discount_Hero += value
	elif context == "Remove":
		Cost_Discount_Hero -= value
	else:
		Cost_Discount_Hero = value

func set_cost_discount_magic(value, context="Initialize"):
	if context == "Add":
		Cost_Discount_Magic += value
	elif context == "Remove":
		Cost_Discount_Magic -= value
	else:
		Cost_Discount_Magic = value

func set_cost_discount_trap(value, context="Initialize"):
	if context == "Add":
		Cost_Discount_Trap += value
	elif context == "Remove":
		Cost_Discount_Trap -= value
	else:
		Cost_Discount_Trap = value

func set_field_attack_bonus(value, context="Initialize"):
	if context == "Add":
		Field_ATK_Bonus += value
	elif context == "Remove":
		Field_ATK_Bonus -= value
	else:
		Field_ATK_Bonus = value

func set_field_health_bonus(value, context="Initialize"):
	if context == "Add":
		Field_Health_Bonus += value
	elif context == "Remove":
		Field_Health_Bonus -= value
	else:
		Field_Health_Bonus = value

func set_duelist_data(Duelist_Name, Duelist_Summon_Crests = 0):
	Name = Duelist_Name
	set_summon_crests(Duelist_Summon_Crests)

func _on_capture_selector_pressed(new_destination: String):
	Capture_Destination = new_destination
