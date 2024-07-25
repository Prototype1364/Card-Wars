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
var Relentless = false # Refers to the Duelist's ability to grant extra attacks to their Fighter(s) each turn. This var is likely only changeable with a Tech Card.
var Valid_Attackers = 0
var Tech_Zone = []
var Deck_Reloaded = false

# func _init(Duelist_Name, Duelist_LP, Duelist_Summon_Crests, Duelist_Tokens, Duelist_Field_ATK_Bonus, Duelist_Field_Health_Bonus, Duelist_Summon_Crest_Roll_Bonus, Duelist_Cost_Discount_Normal, Duelist_Cost_Discount_Hero, Duelist_Cost_Discount_Magic, Duelist_Cost_Discount_Trap, Duelist_Relentless, Duelist_Tech_Zone):
# 	Name = Duelist_Name
# 	LP = Duelist_LP
# 	Summon_Crests = Duelist_Summon_Crests
# 	Tokens = Duelist_Tokens
# 	Field_ATK_Bonus = Duelist_Field_ATK_Bonus
# 	Field_Health_Bonus = Duelist_Field_Health_Bonus
# 	Summon_Crest_Roll_Bonus = Duelist_Summon_Crest_Roll_Bonus
# 	Cost_Discount_Normal = Duelist_Cost_Discount_Normal
# 	Cost_Discount_Hero = Duelist_Cost_Discount_Hero
# 	Cost_Discount_Magic = Duelist_Cost_Discount_Magic
# 	Cost_Discount_Trap = Duelist_Cost_Discount_Trap
# 	Relentless = Duelist_Relentless
# 	Valid_Attackers = 0
# 	Tech_Zone = Duelist_Tech_Zone
# 	Deck_Reloaded = false

func Update_Summon_Crests(roll_result):
	Summon_Crests += roll_result

func Update_Cost_Discount_Normal(change_amount):
	Cost_Discount_Normal += change_amount

func Update_Cost_Discount_Hero(change_amount):
	Cost_Discount_Hero += change_amount

func Update_Cost_Discount_Magic(change_amount):
	Cost_Discount_Magic += change_amount

func Update_Cost_Discount_Trap(change_amount):
	Cost_Discount_Trap += change_amount

func Update_Field_ATK_Bonus(change_amount):
	Field_ATK_Bonus += change_amount

func Update_Field_Health_Bonus(change_amount):
	Field_Health_Bonus += change_amount
