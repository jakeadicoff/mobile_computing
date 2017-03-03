//
//  GraphBrain.swift
//  Adicoff.Jake.Calculator
//
//  Created by Jake Adicoff on 10/13/16.
//  Copyright © 2016 Adicoff - Mobile Computing. All rights reserved.
//

import Foundation
import UIKit

class GraphBrain {
    
    private var calcBrain: CalculatorBrain
    var listOfOrderedPairs: [Double]
    private var minX = 0.0
    var calcBrainProgram = [AnyObject]()
    private var graphOrigin: CGPoint
    private var graphScale: CGFloat
    private var bounds: Double
    private var morePointsMultiplier = 10
    
    
    // initialize all variables
    init(scale: CGFloat, origin: CGPoint, xBounds: CGFloat) {
        calcBrain = CalculatorBrain()
        listOfOrderedPairs = []
        graphScale = scale
        graphOrigin = origin
        bounds = Double(xBounds)
    }
    
    // calculate all points given c
    func calculatePointsOnLine() {
        var prevY = 0.0
        var count = 0
        if calcBrainProgram.count != 0 {
            calcBrain.internalProgram = calcBrainProgram
            minX = 0 - Double(graphOrigin.x)
            for i in 0...Int(bounds) * 10 {
                let xInCGUnits = (Double(i)/10 + minX)
                let x = xInCGUnits / (Double(graphScale))
                calcBrain.setValueInValuesDictionary("M", variableValue: x)
                calcBrain.rerunProgram()
                let y = calcBrain.result
                var yInCGUnits = (y) * Double(graphScale)
                // takes care of discontinuities where point is inf, but precision does not allow point to be inf
                if count > 0 {
                    if abs(prevY - y) > 25{ // Its a hard threshold, but this was a hard problem to solve......
                        yInCGUnits = Double.infinity
                    }
                }
                listOfOrderedPairs.append(xInCGUnits)
                listOfOrderedPairs.append(-yInCGUnits)// switch to coordinates of a view
                prevY = y
                count += 1
            }
        }
    }
}
