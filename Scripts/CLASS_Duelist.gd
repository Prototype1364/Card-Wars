class_name Duelist

# Member variables
var Name
var LP
var Summon_Crests
var Tokens
var Field_ATK_Bonus
var Field_Health_Bonus
var Summon_Crest_Roll_Bonus
var Cost_Discount_Normal
var Cost_Discount_Hero
var Cost_Discount_Magic
var Cost_Discount_Trap
var Relentless # Refers to the Duelist's ability to grant extra attacks to their Fighter(s) each turn. This var is likely only changeable with a Tech Card.
var Valid_Attackers
var Deck
var Tech_Deck
var Hand
var Frontline
var Reinforcement
var Backrow
var MedicalBay
var Graveyard
var Banished
var Tech_Zone

func _init(Duelist_Name, Duelist_LP, Duelist_Summon_Crests, Duelist_Tokens, Duelist_Field_ATK_Bonus, Duelist_Field_Health_Bonus, Duelist_Summon_Crest_Roll_Bonus, Duelist_Cost_Discount_Normal, Duelist_Cost_Discount_Hero, Duelist_Cost_Discount_Magic, Duelist_Cost_Discount_Trap, Duelist_Relentless, Duelist_Deck, Duelist_Tech_Deck, Duelist_Hand, Duelist_Frontline, Duelist_Reinforcement, Duelist_Backrow, Duelist_MedicalBay, Duelist_Graveyard, Duelist_Banished, Duelist_Tech_Zone):
	Name = Duelist_Name
	LP = Duelist_LP
	Summon_Crests = Duelist_Summon_Crests
	Tokens = Duelist_Tokens
	Field_ATK_Bonus = Duelist_Field_ATK_Bonus
	Field_Health_Bonus = Duelist_Field_Health_Bonus
	Summon_Crest_Roll_Bonus = Duelist_Summon_Crest_Roll_Bonus
	Cost_Discount_Normal = Duelist_Cost_Discount_Normal
	Cost_Discount_Hero = Duelist_Cost_Discount_Hero
	Cost_Discount_Magic = Duelist_Cost_Discount_Magic
	Cost_Discount_Trap = Duelist_Cost_Discount_Trap
	Relentless = Duelist_Relentless
	Valid_Attackers = 0
	Deck = Duelist_Deck
	Tech_Deck = Duelist_Tech_Deck
	Hand = Duelist_Hand
	Frontline = Duelist_Frontline
	Reinforcement = Duelist_Reinforcement
	Backrow = Duelist_Backrow
	MedicalBay = Duelist_MedicalBay
	Graveyard = Duelist_Graveyard
	Banished = Duelist_Banished
	Tech_Zone = Duelist_Tech_Zone
