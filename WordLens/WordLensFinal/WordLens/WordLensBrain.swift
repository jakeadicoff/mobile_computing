//
//  WordLensBrain.swift
//  WordLens
//
//  Created by Jake Adicoff on 11/14/16.
//  Copyright © 2016 Adicoff-Zhou - Mobile Computing. All rights reserved.
//

import Foundation
import UIKit

class WordLensBrain {
    
    // set in view controller
    var imageFromUser: UIImage?
    var imageSize: CGSize?
    
    // instanciate the OCR engine
    private let tesseract = G8Tesseract(language: "eng")
    
    // class variables to hold data produced by tesseract
    private var wordBlocks = [G8RecognizedBlock]()
    private var lineBlocks = [G8RecognizedBlock]()
    
    // class variable to hold modified information that was ripped from word and line blocks
    private var modifiedWordBlocks = [(rect: CGRect, word: String, confidence: Double)]()
    
    // called in view controller. calls process to get words in user's picture 
    // then modifies the bounding box rectanges for the processed words
    func getWordBlocks() -> [(rect: CGRect, word: String, confidence: Double)] {
        process()
        modifyRectSize()
        return modifiedWordBlocks
    }
    
    // Makes the rectangels on each line of text the same width by making each word box the width of its coordinate line box
    // This is purely to clean up user interface
    private func modifyRectSize() {
        modifiedWordBlocks.removeAll()
        for wordBlock in wordBlocks{
            var newRect = CGRect(x: 0, y: 0, width: 0, height: 0)
            let wordBox = wordBlock.boundingBoxAtImageOfSize(imageSize!)
            for lineBlock in lineBlocks {
                let lineBox = lineBlock.boundingBoxAtImageOfSize(imageSize!)
                if wordBox.midX <= lineBox.maxY && wordBox.midY >= lineBox.minY {
                    let newSize = CGSize(width: wordBox.width, height: lineBox.height)
                    let newOrigin = CGPoint(x: wordBox.minX, y: lineBox.minY)
                    newRect = CGRect(origin: newOrigin, size: newSize)
                }
            }
            modifiedWordBlocks.append((rect: newRect, word: wordBlock.text, confidence: Double(wordBlock.confidence)))
        }
    }
    
    // clear old data
    private func clearOldBlocks() {
        wordBlocks.removeAll()
        lineBlocks.removeAll()
    }
    
    // use tesseract OCR to process users image
    private func process() {
        tesseract.engineMode = .TesseractOnly
        tesseract.pageSegmentationMode = .Auto
        tesseract.maximumRecognitionTime = 5.0
        tesseract.image = imageFromUser
        // sets centered area in image to be processed. We do this to speed up processing time
        tesseract.rect = CGRect(x: imageFromUser!.size.width/4, y: imageFromUser!.size.height/3, width: imageFromUser!.size.width/2, height: imageFromUser!.size.height/3)
        // recognize text from user image
        tesseract.recognize()
        // redundant...
        clearOldBlocks()
        // grab data produced by teseract engine
        wordBlocks = tesseract.recognizedBlocksByIteratorLevel(G8PageIteratorLevel.Word) as! [G8RecognizedBlock]
        lineBlocks = tesseract.recognizedBlocksByIteratorLevel(G8PageIteratorLevel.Textline) as! [G8RecognizedBlock]

    }
        
}