//
//  DictionaryViewController.swift
//  WordLens
//
//  Created by Jake Adicoff on 11/20/16.
//  Copyright © 2016 Adicoff-Zhou - Mobile Computing. All rights reserved.
//

import UIKit


class DictionaryViewController: UIViewController {
    // instantiate the dictionary we use. We only have the trial version, so it will only define a words. It also will not  s
    // define short propasitions like an or and
    private let lexicon = Lexicontext.sharedDictionary()
    // set in prepare for segue in PageViewController
    var word = ""
    // outlets to lay out definition in popover
    @IBOutlet weak var wordLabel: UILabel!
    // was a label, now a textView. Naming convention is terrible, but...
    @IBOutlet weak var definitionLabel: UITextView!
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set attributes of textView and then get text to display
        definitionLabel.editable = false
        definitionLabel.selectable = false
        definitionLabel.scrollEnabled = true
        displayDefinition()
    }
    
    // function to get definition from dict, parse and display
    private func displayDefinition() {
        
        // get definition from dictionary with user selected word as a key value
        var definition = lexicon.definitionFor(word)
        
        // definition contains word, so this is just parsing to remove the word, since the word is already in our label
        if let parensRange = definition.rangeOfString("(") {
            definition.removeRange(definition.startIndex..<parensRange.startIndex)
        }
        
        // set text in label and textView
        wordLabel.text = word
        definitionLabel.text = definition//+definition+definition+definition+definition
    }
}
