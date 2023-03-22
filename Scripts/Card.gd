extends Control

var Frame
var Art
var Name
var Type
var Attribute
var Description
var Short_Description
var Attack
var Cost
var Health
var Special_Edition_Text
var Rarity
var Passcode
var Deck_Capacity

func _ready():
	pass

func set_variable_values(Card_ID):
	Name = GameData.CardData[Card_ID]["CardName"]
	Attack = str(GameData.CardData[Card_ID]["Attack"])
	Health = str(GameData.CardData[Card_ID]["Health"])
	Short_Description = GameData.CardData[Card_ID]["ShortDescription"]
	Attribute = GameData.CardData[Card_ID]["Attribute"]
	Type = GameData.CardData[Card_ID]["CardType"]

func set_card_text():
	$Name.append_bbcode("[color=#000000][center]" + Name + "[/center][/color]")
	$Attack.append_bbcode("[color=#000000]" + Attack + "[/color]")
	$Health.append_bbcode("[color=#000000]" + Health + "[/color]")
	$Description.append_bbcode("[color=#000000]" + "[" + Attribute + " / " + Type + "]\n" + Short_Description + "[/color]")
