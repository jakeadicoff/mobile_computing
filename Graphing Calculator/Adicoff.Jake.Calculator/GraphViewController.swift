//
//  GraphViewController.swift
//  Adicoff.Jake.Calculator
//
//  Created by Jake Adicoff on 10/12/16.
//  Copyright © 2016 Adicoff - Mobile Computing. All rights reserved.
//

import Foundation
import UIKit


class GraphViewController: UIViewController, GraphViewDataSource {
    var graphBrain = GraphBrain(scale: 0, origin: CGPoint(x: 0, y:0), xBounds: CGFloat(0))
    var calcBrainProgram = [AnyObject]() {
        didSet {
            updateUI()
        }
    }
    // for showing the function description in the graph
    @IBOutlet weak var curveDescription: UILabel!
    var curveDescriptionText = " "
    // initialize gestures in the view
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            // gesture for zoom
            graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: #selector(GraphView.changeScale(_:))))
            // gesture for double tap origin move
            let newOriginTapRecognizer = UITapGestureRecognizer(target: graphView, action: #selector(GraphView.moveOrigin(_:)))
            newOriginTapRecognizer.numberOfTapsRequired = 2
            graphView.addGestureRecognizer(newOriginTapRecognizer)
            // gesture for panning
            let panGestureRecognizer = UIPanGestureRecognizer(target: graphView, action: #selector(GraphView.panGraph(_:)))
            graphView.addGestureRecognizer(panGestureRecognizer)
            graphBrain = GraphBrain(scale: graphView.pointsPerUnit, origin: graphView.origin, xBounds: graphView.bounds.size.width)
            
            graphView.dataSource = self // set delegate
            // set description of graph
            if curveDescriptionText == " " || curveDescriptionText == "" {
                curveDescription!.text = "No function to graph"
            } else {
                curveDescription!.text = curveDescriptionText
            }
            updateUI()
            
        }
    }
    
    // make sure view has all info before loading
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        graphBrain = GraphBrain(scale: graphView.pointsPerUnit, origin: graphView.origin, xBounds: graphView.bounds.size.width)
    }
    

    
    // just transfers points computed in model to the view (via delegation)
    func pointsForGraphView(sender: GraphView) -> [Double]? {
        graphBrain = GraphBrain(scale: graphView.pointsPerUnit, origin: graphView.origin, xBounds: graphView.bounds.size.width)
        graphBrain.calcBrainProgram = calcBrainProgram
        graphBrain.calculatePointsOnLine()
        return graphBrain.listOfOrderedPairs
    }
    // calls set need display
    private func updateUI() {
        if graphView != nil {
            graphBrain = GraphBrain(scale: graphView.pointsPerUnit, origin: graphView.origin, xBounds: graphView.bounds.size.width)
            pointsForGraphView(graphView)
            graphView.setNeedsDisplay()
        }
    }
}
