Jake Adicoff, Ethan Zhou
Mobile Computing, Fall 2016
Final Project: WordLens

We've created an app to allow a user take a photo of an unknown word, and be able to see a definition for that word. The user interfacing is simple and clean. The app opens to a camera view, where the user can take a photo. After the photo is taken, the text in the image is processed (more on that later) and the possible words to be defined are highlighted. The user can then choose one of the highlighted words and a popover view will appear with the view and definition. The popover allows the user to be able to read the definition of the word and see the word in the context of the sentence they are reading. The user can then tap anywhere to dismiss the popover, and take another photo with a button tap or a shake.

PageViewController is the main controller in the design. When this controller is in setup, it initiates a UIImagePickerController, which handles displaying the camera and returning an image to be used in an image view. We have done some custom overlay on the camera to show the user where to position the word so that our processor can recognize it. This was hard. When the UIIMagePickerConroller is dismissed, functions are called to immediately process the image.

For processing, we used the open source framework Tesseract (see link) implemented with coca pods. This takes an image as input and gives G8recognizedBlocks as output. We constrain the area of the processed image to a small box in the center of the screen to allow Tesseract to work quickly. Blocks contain a word and a bounding box and there are sets of blocks for characters, words and lines. We primarily use the word blocks, but we do a bit of extra processing to make all of the boxes in one line of text the same height - this is purely for aesthetic purposes. We then make a list of tuples of the word and the modified block and pass that into back to the view controller when these methods are called in PageViewController. 

Initially, PageView highlights each word with it corresponding bounding box. The area we constrain the user to pick a word from is also shown. After the user selects a word, setNeedsDisplay is called and the view draws only one highlighted box with the word the user selected.

When a user taps a word, we get the tap location and programaticly move a button to that tap location. This button serves no purpose other than to act as an anchor point for a segue to a new view controller. The tap also triggers the segue to DictionaryViewController. This view controller is displayed in a popover, there is only a label for the word and a text view for the definition. Forcing a popover on all devices is also hard. We added delegates to the PageViewController to be able to do this, because the default on iPhones is to display any 'popover' as full screen view controller.

To define words we used the framework Lexicon (see link). This is imperfect. This dictionary is only a trial version (full version costs $$$). In the trial version, the framework will only define words that start with an 'a'. It also will not define short propositions like 'an' or 'and'. Other than that, use of the framework is self explained in the code - very simple. Finding the right dictionary was very difficult as well. Apples dictionary will not be displayed in a popover, and our original dictionary, WordNik has horrible documentation and had a lot of functionality missing.

Links:
	LexiconText: http://www.lexicontext.com/
	Tesseract: https://github.com/tesseract-ocr/tesseract/wiki

Bugs:
	There are no bugs

Other Notes:
	If you want to simulate, because there is camera functionality, you must 	simulate on a device with a camera. You also MUST open the project form 'WordLens.xcworkspace' and NOT 'WordLens.xcodeproj'.
	This was hard.