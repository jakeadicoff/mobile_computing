//
//  CalculatorBrain.swift
//  Adicoff.Jake.Calculator
//
//  Created by Jake Adicoff on 9/11/16.
//  Copyright © 2016 Adicoff - Mobile Computing. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
    var result: Double {
        get {
            return accumulator
        }
    }
    var operationDescription: String {
        get{
            if description == "" {
                return " "
            } else {
                if isPartialOperationPending {
                    return description  + "..."
                } else {
                    return description + "="
                }
            }
        }
    }
    private var accumulator = 0.0
    private var pending = pendingBinaryOperation?()
    private var description = ""
    private var endDescription = ""
    var isPartialOperationPending = false // public so it can be accessed by calcviewController. allows prepareForSegue to execute properly
    private var userHasUsedOperand = false
    var internalProgram = [AnyObject]()
    
    //enumeration of possible calculator operations
    private enum Operation {
        case Constant(Double)
        case UnaryOperation((Double)-> Double)
        case BinaryOperation((Double,Double)-> Double)
        case Equals
        case Clear
    }
    
    //store info of the pending operation
    private struct pendingBinaryOperation {
        var binaryFunction: ((Double,Double)-> Double)
        var firstOperand: Double
    }
    
    //Dictionary of all operations on calculator
    private var operations: Dictionary<String,Operation> = [
        "Clear": Operation.Clear,
        "∏": Operation.Constant(M_PI),
        "e": Operation.Constant(M_E),
        "√": Operation.UnaryOperation(sqrt),
        "ln": Operation.UnaryOperation(log),
        "abs": Operation.UnaryOperation(abs),
        "cos": Operation.UnaryOperation(cos),
        "sin": Operation.UnaryOperation(sin),
        "tan": Operation.UnaryOperation(tan),
        "+": Operation.BinaryOperation({$0+$1}),
        "-": Operation.BinaryOperation({$0-$1}),
        "x": Operation.BinaryOperation({$0*$1}),
        "÷": Operation.BinaryOperation({$0/$1}),
        "=": Operation.Equals
    ]
    
    // Dictionary of variables and associated values. Kept private. There are get and set functions below for controller to access the info from dict
    private var variablesValues: Dictionary<String,Double> = [
        :
    ]
    //sets a variable in dict with specified value
    func setValueInValuesDictionary(variableName: String, variableValue: Double) {
        variablesValues[variableName] = variableValue
        //print(variablesValues.count)
    }
    //gets a value from variables dict. If the value is not 
    //in dict, sets a new variable =0 in the dictionary and
    //returns it
    func getValueFromValuesDictionary(variableName: String) -> Double {
        if let varValue = variablesValues[variableName] {
            return varValue
        } else {
            variablesValues[variableName] = 0.0
            return 0.0
        }
    }
    //sets operand to variables value and adds variable name to description string
    func setVariableOperand(variableName: String) {
        accumulator = getValueFromValuesDictionary(variableName)
        if !isPartialOperationPending {clearDescriptionString()}
        internalProgram.append(variableName)
        endDescription = variableName
        userHasUsedOperand = true
    }
    
    //set current operand based on calculator display
    func setOperand(operand: Double) {
        accumulator = operand
        if !isPartialOperationPending { clearDescriptionString() }
        internalProgram.append(operand)
        endDescription = String(operand)
        userHasUsedOperand = true
    }
    //get will give the list of operands and operators in the current program
    //set will clear necessary information and run essentially run a program givven to it (in a property list)
    typealias PropertyList = AnyObject
    private var program: PropertyList {
        get{
            return internalProgram
        } set {
            clearAccumulatorAndPending()
            clearDescriptionString()
            if let arrayOfOps = newValue as? [AnyObject] {
                for op in arrayOfOps {
                    if let operand = op as? Double {
                        setOperand(operand)
                    } else if let operationOrVariable = op as? String {
                        if let _ = operations[operationOrVariable] {
                            preformOperation(operationOrVariable)
                        } else {
                            setVariableOperand(operationOrVariable)
                        }
                    }
                }
            }
        }
    }
    //deletes the last thing in the property list and 
    //reruns program
    func backspace() {
        var fullProgram = internalProgram
        if fullProgram.count > 0 {
            fullProgram.removeLast()
        }
        program = fullProgram
        
    }
    //reruns the program. called when user saves a value
    func rerunProgram() {
        if !isPartialOperationPending {
            program = internalProgram
        }
        //print(result)
        //print(program.count)
    }
    //performs operation when user hits an oparator button.
    //also sets the description string. Used code from 
    //example on piazza, only because its a lot cleaner than
    //what i had before
    func preformOperation(symbol: String) {
        if let operation = operations[symbol] {
            internalProgram.append(symbol)
            switch  operation {
            case.Clear:
                clearAccumulatorAndPending()
                clearDescriptionString()
                deleteAllVariablesInDictionary()
                userHasUsedOperand = false
            case.Constant(let value):
                accumulator = value
                if !isPartialOperationPending {
                    description = ""
                }
                endDescription = symbol
                userHasUsedOperand = false
            case.UnaryOperation(let function):
                accumulator = function(accumulator)
                
                if isPartialOperationPending {
                    endDescription = symbol + "(" + endDescription + ")"
                } else {
                    if userHasUsedOperand {
                        description = symbol + "(" + endDescription + ")"
                        endDescription = ""
                    } else {
                        description = symbol + "(" + description + ")"
                    }
                }
                userHasUsedOperand = false
            case.BinaryOperation(let function):
                executePendingBinaryOperation()
                pending = pendingBinaryOperation(binaryFunction: function, firstOperand: accumulator)
                isPartialOperationPending = true
                description = description + endDescription + symbol
                endDescription = ""
                userHasUsedOperand = false
            case.Equals:
                if endDescription == "" { endDescription = String(accumulator)}
                executePendingBinaryOperation()
                isPartialOperationPending = false
                description = description + endDescription
                endDescription = ""
                userHasUsedOperand = false
            }
        }
    }
    
    //self described
    private func executePendingBinaryOperation() {
        if pending != nil {
            accumulator = pending!.binaryFunction(pending!.firstOperand,accumulator)
            pending = nil
        }
    }
    
    // clears pending operation, accumulator, and the internal program property list
    private func clearAccumulatorAndPending() {
        accumulator = 0.0
        pending = nil
        internalProgram.removeAll()
    }
    
    //clears the dictionary of variables and values
    private func deleteAllVariablesInDictionary() {
        variablesValues.removeAll()
    }
    
    //clears the description string
    private func clearDescriptionString() {
        description = ""
        isPartialOperationPending = false
    }

}

