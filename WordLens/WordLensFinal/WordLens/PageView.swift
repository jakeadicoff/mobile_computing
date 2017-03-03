//
//  PageView.swift
//  WordLens
//
//  Created by Jake Adicoff on 11/14/16.
//  Copyright © 2016 Adicoff-Zhou - Mobile Computing. All rights reserved.
//

import UIKit
//protocols to get all word rects for drawing and a single rect to draw when the user has selected a word
protocol pageViewDataSource {
    func rectsToDrawInPageView(sender: PageView) -> [(rect: CGRect, word: String, confidence: Double)]?
    func getSelectedRect(sender: PageView) -> CGRect?
}
class PageView: UIView {
    
    
    var dataSource: pageViewDataSource?
    var dummyRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    //make color constants
    private var redHighlight = UIColor(red: 1, green: 0, blue: 0, alpha: 0.25)
    private var blueHighlight = UIColor(red: 0, green: 0.4, blue: 1, alpha: 0.25)
    private var clearBackground = UIColor(white: 0, alpha: 0.0)
    private var seeThroughGreyBackground = UIColor(white: 0, alpha: 0.25)
    private var boxesHaveBeenDrawn = false
    //set to true in viewConroller - redraws to only show one highlighted word
    //if set to false, redraws to highlight all selectable words
    var imageSize: CGSize?
    var userHasSelectedWord = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    
    // heilights all slelectable words. Highlights words that may be cut off by bounding rectangle in red
    private func drawAllWordBoxes() {
        let blocks = dataSource!.rectsToDrawInPageView(self)
        if let blockList = blocks {
            if blockList.count > 0 {
                boxesHaveBeenDrawn = true
            }
            else {
                boxesHaveBeenDrawn = false
            }
            for block in blockList {
                let rectToDraw = block.rect
                let bpath:UIBezierPath = UIBezierPath(roundedRect: rectToDraw, cornerRadius: 6.0)
                if (rectToDraw.minX == imageSize!.width/4 || rectToDraw.maxX == imageSize!.width*3/4 || rectToDraw.minY == imageSize!.height/3 || rectToDraw.maxY == ((imageSize!.height)*2)/3) {
                    redHighlight.setFill()
                }
                else {
                    blueHighlight.setFill()
                }
                bpath.fill()
            }
        }
    }
    
    // overlays seethrough grey on area of non-selectable words
    private func overlayGrey() {
        let upperBox = CGRect(x: 0, y: 0, width: imageSize!.width, height: imageSize!.height/3)
        let lowerBox = CGRect(x: 0, y: imageSize!.height * 2 / 3, width: imageSize!.width, height: imageSize!.height/3)
        let midLeftBox = CGRect(x:0, y: imageSize!.height/3, width: imageSize!.width/4, height: imageSize!.height/3)
        let midRightBox = CGRect(x: imageSize!.width * 3 / 4, y: imageSize!.height/3, width: imageSize!.width/4, height:imageSize!.height/3)
        seeThroughGreyBackground.setFill()
        var path = UIBezierPath(rect: upperBox)
        path.fill()
        path = UIBezierPath(rect: lowerBox)
        path.fill()
        path = UIBezierPath(rect: midLeftBox)
        path.fill()
        path = UIBezierPath(rect: midRightBox)
        path.fill()
        
    }
    
    // draws highlightd blue box around user selected word
    private func drawOnlySelectedWordBox() {
        let rect = dataSource!.getSelectedRect(self)
        if  rect != nil {
            if rect != dummyRect {
                let path = UIBezierPath(roundedRect: rect!, cornerRadius: 6.0)
                blueHighlight.setFill()
                path.fill()
            } else {
                userHasSelectedWord = false
                //print("this worked")
            }
        }
    }
    
    //chooses how to draw based on what the user has done
    override func drawRect(rect: CGRect) {
        if !userHasSelectedWord {
            drawAllWordBoxes()
            if boxesHaveBeenDrawn {
                overlayGrey()
            }
        }
        else {
            drawOnlySelectedWordBox()
        }
    }
}
