class_name Card

# Member variables
var Frame
var Art
var Name
var Type
var Effect_Type
var Attribute
var Description
var Short_Description
var Attack
var ATK_Bonus # Used to keep track of Equip card bonuses specifically.
var Cost
var Health
var Health_Bonus # Used to keep track of Equip card bonuses specifically.
var Special_Edition_Text
var Rarity
var Passcode
var Deck_Capacity
var Tokens
var Is_Set
var Effect_Active # Primarily used to determine if Equip card effects have been activitated to ensure stat boosts don't accumulate each turn.
var Fusion_Level # Refers to the number of cards it is Fused with (defaults to 1 as it'll allow for easier multiplication of Attack/Health stats). Knights of the Round Table is the first card to have this ability.
var Attack_As_Reinforcement # Refers to a card's ability to launch an attack from a Reinforcement slot. Mongols (when led by Ghenghis Khan) is the first card to have this ability.
var Invincible # Refers to a card that cannot be captured in Battle. It must be defeated by a Hero/Magic/Trap/Tech card's effects. "The Level Beyond" is the first card to have this ability.
var Multi_Strike # Refers to a card's ability to deal damage to cards in the opponent's Reinforcement zone (Zeus is the first card to have this ability).
var Paralysis # Refers to a card's ability to launch an attack. Lancelot is the first card to utilize this Attribute (there's a 1/3 chance that his effect will result in him being unable to attack during that turn's Battle Phase).
var Owner # Refers to the card's original Owner (Player or Enemy). Used as part of Mordred's Hero card effect.

func _init(Card_Frame, Card_Art, Card_Name, Card_Type, Card_EffectType, Card_Attribute, Card_Description, Card_Short_Description, Card_Attack, Card_ATK_Bonus, Card_Cost, Card_Health, Card_Health_Bonus, Card_Special_Edition_Text, Card_Rarity, Card_Passcode, Card_Deck_Capacity, Card_Tokens, Card_Is_Set, Card_Effect_Active, Card_Fusion_Level, Card_Attack_As_Reinforcement, Card_Invincible, Card_Multi_Strike, Card_Paralysis, Card_Owner):
	Frame = Card_Frame
	Art = Card_Art
	Name = Card_Name
	Type = Card_Type
	Effect_Type = Card_EffectType
	Attribute = Card_Attribute
	Description = Card_Description
	Short_Description = Card_Short_Description
	Attack = Card_Attack
	ATK_Bonus = Card_ATK_Bonus
	Cost = Card_Cost
	Health = Card_Health
	Health_Bonus = Card_Health_Bonus
	Special_Edition_Text = Card_Special_Edition_Text
	Rarity = Card_Rarity
	Passcode = Card_Passcode
	Deck_Capacity = Card_Deck_Capacity
	Tokens = Card_Tokens
	Is_Set = Card_Is_Set
	Effect_Active = Card_Effect_Active 
	Fusion_Level = Card_Fusion_Level
	Attack_As_Reinforcement = Card_Attack_As_Reinforcement
	Invincible = Card_Invincible
	Multi_Strike = Card_Multi_Strike
	Paralysis = Card_Paralysis
	Owner = Card_Owner
