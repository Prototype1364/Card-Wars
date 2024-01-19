class_name Card

# Member variables
var Frame
var Art
var Name
var Type
var Effect_Type
var Anchor_Text
var Resolve_Side
var Resolve_Phase
var Resolve_Step
var Attribute
var Description
var Short_Description
var Attacks_Remaining
var Attack
var ATK_Bonus # Used to keep track of Equip card bonuses specifically.
var Toxicity # The amount of Burn_Damage per turn you add to the Target card's Burn_Damage variable.
var Cost
var Health
var Health_Bonus # Used to keep track of Equip card bonuses specifically.
var Burn_Damage # Damage taken by card each turn due to Poison (and other) burn-damage style ailments.
var Revival_Health # HP that a card resets to upon Capture.
var Special_Edition_Text
var Rarity
var Passcode
var Deck_Capacity
var Tokens
var Is_Set
var Effect_Active # Primarily used to determine if cards with Summon Effects have been activitated to ensure they don't trigger each turn.
var Fusion_Level # Refers to the number of cards it is Fused with (defaults to 1 as it'll allow for easier multiplication of Attack/Health stats). Knights of the Round Table is the first card to have this ability.
var Attack_As_Reinforcement # Refers to a card's ability to launch an attack from a Reinforcement slot. Mongols (when led by Ghenghis Khan) is the first card to have this ability.
var Immortal # Refers to whether a card can be captured with 0 HP. Demeter (in SAP version) is the first card to have this effect.
var Invincible # Refers to a card that cannot be captured in Battle. It must be defeated by a Hero/Magic/Trap/Tech card's effects. "The Level Beyond" is the first card to have this ability.
var Relentless # Refers to a card that may attack more than once per turn. King Leonidas was the first card to have this ability.
var Multi_Strike # Refers to a card's ability to deal damage to cards in the opponent's Reinforcement zone (Zeus is the first card to have this ability).
var Target_Reinforcer # Refers to a card's ability to choose to target an opponent in a reinforcement slot instead of the opposing Fighter (Poseidon is the first card to have this ability).
var Paralysis # Refers to a card's ability to launch an attack. Lancelot is the first card to utilize this Attribute (there's a 1/3 chance that his effect will result in him being unable to attack during that turn's Battle Phase).
var Direct_Attack
var Owner # Refers to the card's original Owner (Player or Enemy). Used as part of Mordred's Hero card effect.

func _init(Card_Frame, Card_Art, Card_Name, Card_Type, Card_EffectType, Card_Anchor_Text, Card_Resolve_Side, Card_Resolve_Phase, Card_Resolve_Step, Card_Attribute, Card_Description, Card_Short_Description, Card_Attack, Card_ATK_Bonus, Card_Toxicity, Card_Cost, Card_Health, Card_Health_Bonus, Card_Burn_Damage, Card_Special_Edition_Text, Card_Rarity, Card_Passcode, Card_Deck_Capacity, Card_Tokens, Card_Is_Set, Card_Effect_Active, Card_Fusion_Level, Card_Attack_As_Reinforcement, Card_Immortal, Card_Invincible, Card_Relentless, Card_Multi_Strike, Card_Target_Reinforcer, Card_Paralysis, Card_Direct_Attack, Card_Owner):
	Frame = Card_Frame
	Art = Card_Art
	Name = Card_Name
	Type = Card_Type
	Effect_Type = Card_EffectType
	Anchor_Text = Card_Anchor_Text
	Resolve_Side = Card_Resolve_Side
	Resolve_Phase = Card_Resolve_Phase
	Resolve_Step = Card_Resolve_Step
	Attribute = Card_Attribute
	Description = Card_Description
	Short_Description = Card_Short_Description
	Attack = Card_Attack
	ATK_Bonus = Card_ATK_Bonus
	Cost = Card_Cost
	Health = Card_Health
	Health_Bonus = Card_Health_Bonus
	Revival_Health = Card_Health
	Special_Edition_Text = Card_Special_Edition_Text
	Rarity = Card_Rarity
	Passcode = Card_Passcode
	Deck_Capacity = Card_Deck_Capacity
	Tokens = Card_Tokens
	Is_Set = Card_Is_Set
	Effect_Active = Card_Effect_Active 
	Fusion_Level = Card_Fusion_Level
	Attack_As_Reinforcement = Card_Attack_As_Reinforcement
	Immortal = Card_Immortal
	Invincible = Card_Invincible
	Relentless = Card_Relentless
	Attacks_Remaining = 1 if Relentless == false else 2
	Multi_Strike = Card_Multi_Strike
	Target_Reinforcer = Card_Target_Reinforcer
	Paralysis = Card_Paralysis
	Direct_Attack = Card_Direct_Attack
	Toxicity = Card_Toxicity
	Burn_Damage = Card_Burn_Damage
	Owner = Card_Owner
