//
//  GraphView.swift
//  Adicoff.Jake.Calculator
//
//  Created by Jake Adicoff on 10/12/16.
//  Copyright © 2016 Adicoff - Mobile Computing. All rights reserved.
//

import UIKit

protocol GraphViewDataSource{
    func pointsForGraphView(sender: GraphView) -> [Double]?
}
@IBDesignable
class GraphView: UIView {
    
    var dataSource: GraphViewDataSource?
    
    private var axesDrawer = AxesDrawer() {didSet {setNeedsDisplay()}}
    private var lineWidth: CGFloat = 1.0
    private var counter = 0
    @IBInspectable var pointsPerUnit: CGFloat = 25 {didSet {setNeedsDisplay()}}
    private var centerOfView: CGPoint {return CGPoint(x: bounds.midX, y: bounds.midY)}//only for initial drawing of axes
    private var originShift: CGPoint = CGPoint(x: 0, y: 0) { didSet {setNeedsDisplay()}}//for translating origin when panning/ tapping
    private var originHolder: CGPoint = CGPoint(x:0, y: 0) { didSet {setNeedsDisplay()}}//
    private var path = UIBezierPath() //{didSet {setNeedsDisplay()}}
    private var radius = CGFloat(0.5)

    //computes origin which is held in originHolder. I had some confusion with this: bounds aren't initialized
    //unitl entire object is initialized, so there needs to be a computed value here
    var origin: CGPoint {
        get {
            if counter == 0 {
                counter += 1
                return CGPoint(x: centerOfView.x - originShift.x, y: centerOfView.y - originShift.y)
            } else {
                return originHolder
            }
        }
        set {
            originHolder = newValue
            }
    }
    
    
    // handle panning
    func panGraph(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .Changed{
            let slowingConstant = CGFloat(3)
            originShift.x = originHolder.x + (recognizer.translationInView(self).x / slowingConstant)
            originShift.y = originHolder.y + (recognizer.translationInView(self).y / slowingConstant)
            origin = originShift
        }
    }
    
    // handle tapping
    func moveOrigin(recognizer: UITapGestureRecognizer) {
        recognizer.numberOfTapsRequired = 2
        if recognizer.state == .Ended {
            originShift.x = recognizer.locationInView(self).x
            originShift.y = recognizer.locationInView(self).y
            origin = originShift
            //setNeedsDisplay()
        }
    }
    
    // handle zooming
    func changeScale(recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .Changed, .Ended:
            self.pointsPerUnit *= recognizer.scale
            recognizer.scale = 1.0
            //setNeedsDisplay()
        default: break
        }
    }
    
    // use protocol to get data, and graph using lots of tiny bezier path circles
    func makePath() {
        path.removeAllPoints()
        var points = dataSource?.pointsForGraphView(self)
        var needNewPath = true
        if points != nil && points! != []{
            let count = points?.count
            var i = 0
            var firstPointInPath = CGPoint(x: CGFloat(points![0]), y:CGFloat(points![1]))
            firstPointInPath.x = firstPointInPath.x + origin.x
            firstPointInPath.y = firstPointInPath.y + origin.y
            //path.moveToPoint(firstPointInPath)
            while i < count {
                if points![i+1] == Double.infinity || points![i+1] == -Double.infinity || points![i+1].isNaN {
                    path.lineWidth = lineWidth
                    path.stroke()
                    path.removeAllPoints()
                    needNewPath = true
                } else {
                    let x = CGFloat(points![i]) + origin.x
                    let y = CGFloat(points![i+1]) + origin.y
                    let point = CGPoint(x: x, y: y)
                    if needNewPath {
                        path.moveToPoint(point)
                        needNewPath = false
                    } else {
                        path.addLineToPoint(point)
                    }
                }
                i = i + 2
            }
        }
        path.lineWidth = lineWidth
        path.stroke()
        setNeedsDisplay()
    }
    
    
    // redraw all necessary things
    override func drawRect(rect: CGRect) {
        axesDrawer.drawAxesInRect(bounds, origin: origin, pointsPerUnit: pointsPerUnit)
        makePath()
    }
}

//
//  AxesDrawer.swift
//  Calculator
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class AxesDrawer
{
    private struct Constants {
        static let HashmarkSize: CGFloat = 6
    }
    
    var color = UIColor.blueColor()
    var minimumPointsPerHashmark: CGFloat = 40
    var contentScaleFactor: CGFloat = 1 // set this from UIView's contentScaleFactor to position axes with maximum accuracy
    
    convenience init(color: UIColor, contentScaleFactor: CGFloat) {
        self.init()
        self.color = color
        self.contentScaleFactor = contentScaleFactor
    }
    
    convenience init(color: UIColor) {
        self.init()
        self.color = color
    }
    
    convenience init(contentScaleFactor: CGFloat) {
        self.init()
        self.contentScaleFactor = contentScaleFactor
    }
    
    // this method is the heart of the AxesDrawer
    // it draws in the current graphic context's coordinate system
    // therefore origin and bounds must be in the current graphics context's coordinate system
    // pointsPerUnit is essentially the "scale" of the axes
    // e.g. if you wanted there to be 100 points along an axis between -1 and 1,
    //    you'd set pointsPerUnit to 50
    
    func drawAxesInRect(bounds: CGRect, origin: CGPoint, pointsPerUnit: CGFloat)
    {
        CGContextSaveGState(UIGraphicsGetCurrentContext())
        color.set()
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: bounds.minX, y: align(origin.y)))
        path.addLineToPoint(CGPoint(x: bounds.maxX, y: align(origin.y)))
        path.moveToPoint(CGPoint(x: align(origin.x), y: bounds.minY))
        path.addLineToPoint(CGPoint(x: align(origin.x), y: bounds.maxY))
        path.stroke()
        drawHashmarksInRect(bounds, origin: origin, pointsPerUnit: abs(pointsPerUnit))
        CGContextRestoreGState(UIGraphicsGetCurrentContext())
    }
    
    // the rest of this class is private
    
    private func drawHashmarksInRect(bounds: CGRect, origin: CGPoint, pointsPerUnit: CGFloat)
    {
        if ((origin.x >= bounds.minX) && (origin.x <= bounds.maxX)) || ((origin.y >= bounds.minY) && (origin.y <= bounds.maxY))
        {
            // figure out how many units each hashmark must represent
            // to respect both pointsPerUnit and minimumPointsPerHashmark
            var unitsPerHashmark = minimumPointsPerHashmark / pointsPerUnit
            if unitsPerHashmark < 1 {
                unitsPerHashmark = pow(10, ceil(log10(unitsPerHashmark)))
            } else {
                unitsPerHashmark = floor(unitsPerHashmark)
            }
            
            let pointsPerHashmark = pointsPerUnit * unitsPerHashmark
            
            // figure out which is the closest set of hashmarks (radiating out from the origin) that are in bounds
            var startingHashmarkRadius: CGFloat = 1
            if !CGRectContainsPoint(bounds, origin) {
                if origin.x > bounds.maxX {
                    startingHashmarkRadius = (origin.x - bounds.maxX) / pointsPerHashmark + 1
                } else if origin.x < bounds.minX {
                    startingHashmarkRadius = (bounds.minX - origin.x) / pointsPerHashmark + 1
                } else if origin.y > bounds.maxY {
                    startingHashmarkRadius = (origin.y - bounds.maxY) / pointsPerHashmark + 1
                } else {
                    startingHashmarkRadius = (bounds.minY - origin.y) / pointsPerHashmark + 1
                }
                startingHashmarkRadius = floor(startingHashmarkRadius)
            }
            
            // now create a bounding box inside whose edges those four hashmarks lie
            let bboxSize = pointsPerHashmark * startingHashmarkRadius * 2
            var bbox = CGRect(center: origin, size: CGSize(width: bboxSize, height: bboxSize))
            
            // formatter for the hashmark labels
            let formatter = NSNumberFormatter()
            formatter.maximumFractionDigits = Int(-log10(Double(unitsPerHashmark)))
            formatter.minimumIntegerDigits = 1
            
            // radiate the bbox out until the hashmarks are further out than the bounds
            while !CGRectContainsRect(bbox, bounds)
            {
                let label = formatter.stringFromNumber((origin.x-bbox.minX)/pointsPerUnit)!
                if let leftHashmarkPoint = alignedPoint(x: bbox.minX, y: origin.y, insideBounds:bounds) {
                    drawHashmarkAtLocation(leftHashmarkPoint, .Top("-\(label)"))
                }
                if let rightHashmarkPoint = alignedPoint(x: bbox.maxX, y: origin.y, insideBounds:bounds) {
                    drawHashmarkAtLocation(rightHashmarkPoint, .Top(label))
                }
                if let topHashmarkPoint = alignedPoint(x: origin.x, y: bbox.minY, insideBounds:bounds) {
                    drawHashmarkAtLocation(topHashmarkPoint, .Left(label))
                }
                if let bottomHashmarkPoint = alignedPoint(x: origin.x, y: bbox.maxY, insideBounds:bounds) {
                    drawHashmarkAtLocation(bottomHashmarkPoint, .Left("-\(label)"))
                }
                bbox.insetInPlace(dx: -pointsPerHashmark, dy: -pointsPerHashmark)
            }
        }
    }
    
    private func drawHashmarkAtLocation(location: CGPoint, _ text: AnchoredText)
    {
        var dx: CGFloat = 0, dy: CGFloat = 0
        switch text {
        case .Left: dx = Constants.HashmarkSize / 2
        case .Right: dx = Constants.HashmarkSize / 2
        case .Top: dy = Constants.HashmarkSize / 2
        case .Bottom: dy = Constants.HashmarkSize / 2
        }
        
        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: location.x-dx, y: location.y-dy))
        path.addLineToPoint(CGPoint(x: location.x+dx, y: location.y+dy))
        path.stroke()
        
        text.drawAnchoredToPoint(location, color: color)
    }
    
    private enum AnchoredText
    {
        case Left(String)
        case Right(String)
        case Top(String)
        case Bottom(String)
        
        static let VerticalOffset: CGFloat = 3
        static let HorizontalOffset: CGFloat = 6
        
        func drawAnchoredToPoint(location: CGPoint, color: UIColor) {
            let attributes = [
                NSFontAttributeName : UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote),
                NSForegroundColorAttributeName : color
            ]
            var textRect = CGRect(center: location, size: text.sizeWithAttributes(attributes))
            switch self {
            case Top: textRect.origin.y += textRect.size.height / 2 + AnchoredText.VerticalOffset
            case Left: textRect.origin.x += textRect.size.width / 2 + AnchoredText.HorizontalOffset
            case Bottom: textRect.origin.y -= textRect.size.height / 2 + AnchoredText.VerticalOffset
            case Right: textRect.origin.x -= textRect.size.width / 2 + AnchoredText.HorizontalOffset
            }
            text.drawInRect(textRect, withAttributes: attributes)
        }
        
        var text: String {
            switch self {
            case Left(let text): return text
            case Right(let text): return text
            case Top(let text): return text
            case Bottom(let text): return text
            }
        }
    }
    
    // we want the axes and hashmarks to be exactly on pixel boundaries so they look sharp
    // setting contentScaleFactor properly will enable us to put things on the closest pixel boundary
    // if contentScaleFactor is left to its default (1), then things will be on the nearest "point" boundary instead
    // the lines will still be sharp in that case, but might be a pixel (or more theoretically) off of where they should be
    
    private func alignedPoint(x x: CGFloat, y: CGFloat, insideBounds: CGRect? = nil) -> CGPoint?
    {
        let point = CGPoint(x: align(x), y: align(y))
        if let permissibleBounds = insideBounds {
            if (!CGRectContainsPoint(permissibleBounds, point)) {
                return nil
            }
        }
        return point
    }
    
    private func align(coordinate: CGFloat) -> CGFloat {
        return round(coordinate * contentScaleFactor) / contentScaleFactor
    }
}

extension CGRect
{
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x-size.width/2, y: center.y-size.height/2, width: size.width, height: size.height)
    }
}
