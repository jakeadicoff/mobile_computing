//
//  ViewController.swift
//  Adicoff.Jake.Calculator
//
//  Created by Jake Adicoff on 9/11/16.
//  Copyright © 2016 Adicoff - Mobile Computing. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {

    
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var descriptionText: UILabel!
    private var userInTheMiddleOfTypingNumber = false
    private var userInTheMiddleOfTypingDoubble = false
    private var operateWithVariableInput = false
    private var brain = CalculatorBrain()
    private var variableName: String?
    private var variableHasBeenSet = false
    var displayValue: Double {
        get {
            return Double(display.text!)!
        }
        set {
            display.text = "\(newValue)"
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if !brain.isPartialOperationPending {
            //print(brain.internalProgram.count)
            var destinationVC = segue.destinationViewController
            if let navcon = destinationVC as? UINavigationController {
                destinationVC = navcon.visibleViewController ?? destinationVC
            }
            if let graphVC = destinationVC as? GraphViewController {
                for item in brain.internalProgram {
                    graphVC.calcBrainProgram.append(item)
                    
                }
                graphVC.curveDescriptionText = brain.operationDescription
                
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated);
        super.viewWillDisappear(animated)
        }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    //sets a variable. Sends a variable and a value to a setter method in calculatorbrain which sets the variable in the dictionary
    @IBAction func SetVariable(sender: AnyObject) {
        variableName =  String(sender.currentTitle!!.characters.dropFirst())
        brain.setValueInValuesDictionary(variableName!, variableValue: displayValue)
        display.text = String(displayValue)
        userInTheMiddleOfTypingNumber = false
        brain.rerunProgram()
        displayValue = brain.result
        display.text = String(displayValue)
        descriptionText.text = brain.operationDescription
    }
    
    //uses value from the variables dictionary in calcBrain
    @IBAction func UseSavedVariable(sender: AnyObject) {
        operateWithVariableInput = true
        variableName = sender.currentTitle!
        if !userInTheMiddleOfTypingNumber && !userInTheMiddleOfTypingDoubble {
            let variableValue = brain.getValueFromValuesDictionary(variableName!)
            display.text = String(variableValue)
            displayValue = variableValue
            brain.setVariableOperand(variableName!)
        }
    }
    //executes code in calculatorbrain to backspace
    @IBAction func BackSpace() {
        brain.backspace()
        displayValue = brain.result
        descriptionText.text = brain.operationDescription
    }
    //sets display with whenever user hits a digit button
    @IBAction func TouchDigit(sender: AnyObject) {
        let digit = sender.currentTitle!
        let textCurrentlyInDisplay = display!.text!
        if digit == "." {
            if !userInTheMiddleOfTypingDoubble {
                userInTheMiddleOfTypingDoubble = true
                if userInTheMiddleOfTypingNumber{
                    display.text = textCurrentlyInDisplay + digit!
                } else {
                    display.text = digit
                    userInTheMiddleOfTypingNumber = true
                }
                
            }
        } else {
            if userInTheMiddleOfTypingNumber{
                display.text = textCurrentlyInDisplay + digit!
            } else {
                display.text = digit!
                
                userInTheMiddleOfTypingNumber = true
            }
        }
    }
    //performs operation when user hits an operator button
    @IBAction private func performOperation(sender: UIButton) {
        if userInTheMiddleOfTypingNumber && !operateWithVariableInput {
            userInTheMiddleOfTypingNumber = false
            userInTheMiddleOfTypingDoubble = false
            if !operateWithVariableInput {brain.setOperand(displayValue)}
        }
        if let mathematicalSymbol = sender.currentTitle {
            brain.preformOperation(mathematicalSymbol)
        }
        displayValue = brain.result
        descriptionText.text = brain.operationDescription
        operateWithVariableInput = false
        variableName = nil
    }
}

