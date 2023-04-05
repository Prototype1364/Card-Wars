extends Control

var Cards
var CardParent

func _ready():
	pass

func Graveyard_Called(Dueler):
	Clear_Scroller()
	Cards = Dueler.Graveyard
	Add_Cards()

func Medical_Bay_Called(Dueler=GameData.Player):
	Clear_Scroller()
	Cards = Dueler.MedicalBay
	Add_Cards()

func Banished_Called(Dueler):
	Clear_Scroller()
	Cards = Dueler.Banished
	Add_Cards()


func Clear_Scroller():
	#Clears all cards.
	for i in $Deck_Scroller/Deck_Container.get_children():
		#Fixes change in position from being placed in an HBoxContainer.
		i.position = Vector2(0,0)
		$Deck_Scroller/Deck_Container.remove_child(i)
		CardParent.add_child(i)

func Add_Cards():
	#Adds cards based on which function was called.
	for i in Cards:
		#Saves the cards' parent for later.
		CardParent = i.get_parent()
		CardParent.remove_child(i)
		$Deck_Scroller/Deck_Container.add_child(i)
		
func Remove_Blocker():
	$Focus_Blocker.visible = false

#If I create a duplicate card, the ready() function in the SmallCard scene causes problems.
#As such, I merely move all the cards from whichever deck to the appropriate node and back.
#If we change this, we'll be able to duplicate the cards whenever we'd like.

#BigCard scene does not work and crashes the game if you focus on cards in the Pile_Scroller.
#Probably because we didn't set anything up for it. "Focus_Blocker" node prevents this crash.
#"Focus_Blocker" node won't be needed later if we fix the crash, thankfully.

#Each function needs a "Side" when called. Lets us choose from whichever side's piles on case-by-case basis. 

#I think I forgot something while typing this all out. This is a reminder: You forgot something, future Eric.


#For future reference, I tried:
#1. Making a viewport to turn a card into an image that I could then place into a TextureRect. Everything worked
# except for the actual turning the viewport's data into an image. Not sure what the issue actually was; there was
# too many possible explanations for its failure to function.
#2. i.duplicate(). This worked, but ran afoul of the whole "ready()" function not knowing what to do.

#Possible fixes(?)
#1. Make a second SmallCard scene that copies data, displays, and does nothing else. It exists solely for this 
# scene.
#2. Transform whichever pile is being gone through into a scroller when needed.
#3. Reconfigure the SmallCard scene so that duplicate() functions.
