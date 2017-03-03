//
//  ViewController.swift
//  WordLens
//
//  Created by Jake Adicoff on 11/14/16.
//  Copyright © 2016 Adicoff-Zhou - Mobile Computing. All rights reserved.
//

import UIKit

class PageViewController: UIViewController, pageViewDataSource, UIPopoverPresentationControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    // image grabbed from image view and givven to ocr brain for processing
    private var imageTakenByUser: UIImage?
    //instanciate brain
    private var ocrBrain = WordLensBrain()
    private var activityIndicator: UIActivityIndicatorView!
    //tap location from user
    private var pointFromUser: CGPoint?
    // single word selected by user
    private var blockSelectedByUser: (rect: CGRect, word: String, confidence: Double)?
    private var userHasAlreadyTakenPicture = false
    private var dummyBlock = (CGRect(x:0,y:0,width:0,height:0), "", 0.0)
    // to overlay on camera
    private var overlayView: UIView!
    // image view to show user's taken image
    @IBOutlet weak var imageView: UIImageView!
    private var wordsAndRectsBlocks = [(rect: CGRect, word: String, confidence: Double)]() {
        didSet {
            // update ui when new data is collected from tesseract
            updateUI()
        }
    }
    // button to anchor segue
    @IBOutlet weak var performSegueButton: UIButton!
    @IBOutlet weak var pageView: PageView! {
        didSet {
            // set delegate
            pageView.dataSource = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //create overlay view for showCamera
        initializeOverlayView()
    }
    
    
    override func viewWillLayoutSubviews() {

        super.viewWillLayoutSubviews()
        // show camera if user has not yet taken a picture
        if !userHasAlreadyTakenPicture {
            userHasAlreadyTakenPicture = true
            showCamera()
        }
    }
    
    // makes overlay so user knows how to properly use camera within framework of app
    private func initializeOverlayView() {
        //FUTURE NOTE: do this frameWidth frameHieght in PageView so that its more readable
        let frameWidth = super.view.bounds.width
        let frameHeight = super.view.bounds.height
        let cornerLength = frameWidth/16
        let thickness: CGFloat = 2
        //I dont think it matters what the frame is?? subviews can be bigger than this overlay view
        overlayView = UIView(frame: CGRect(x: 0, y: 0, width: frameWidth, height: frameHeight/2))
        
        let topLeftA = UIView(frame: CGRect(x: frameWidth/4, y: frameHeight/3, width: cornerLength, height: thickness))
        let topLeftB = UIView(frame: CGRect(x: frameWidth/4, y: frameHeight/3, width: thickness, height: cornerLength))
        let topRightA = UIView(frame: CGRect(x: frameWidth/4*3-cornerLength, y: frameHeight/3, width: cornerLength, height: thickness))
        let topRightB = UIView(frame: CGRect(x: frameWidth/4*3, y: frameHeight/3, width: thickness, height: cornerLength))
        
        let bottomLeftA = UIView(frame: CGRect(x: frameWidth/4, y: frameHeight/3*2, width: cornerLength, height: thickness))
        let bottomLeftB = UIView(frame: CGRect(x: frameWidth/4, y: frameHeight/3*2-cornerLength, width: thickness, height: cornerLength))
        
        let bottomRightA = UIView(frame: CGRect(x: frameWidth/4*3-cornerLength, y: frameHeight/3*2, width: cornerLength, height: thickness))
        let bottomRightB = UIView(frame: CGRect(x: frameWidth/4*3, y: frameHeight/3*2-cornerLength+thickness, width: thickness, height: cornerLength))
        
        
        func changeColorAndAddView(view: UIView) {
            view.backgroundColor = UIColor.blueColor()
            view.alpha = 0.75
            overlayView.addSubview(view)
        }
        // make transparent blue guidelines for user to capture word within
        changeColorAndAddView(topLeftA)
        changeColorAndAddView(topLeftB)
        changeColorAndAddView(topRightA)
        changeColorAndAddView(topRightB)
        changeColorAndAddView(bottomLeftA)
        changeColorAndAddView(bottomLeftB)
        changeColorAndAddView(bottomRightA)
        changeColorAndAddView(bottomRightB)
        
        // add instructive label to camera label
        let labelBounds = CGRect(x: frameWidth/8, y: frameHeight/8, width: frameWidth * 6 / 8, height: frameHeight/16)
        let label = UILabel(frame: labelBounds)
        label.text = "  Position word in between blue marks   "
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0
        label.textAlignment = NSTextAlignment.Center
        label.textColor = UIColor.blackColor()
        label.backgroundColor = UIColor(white: 1, alpha: 0.25)
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 6
        overlayView.addSubview(label)
    }
    
    // Brings up camera for user to take photo
    private func showCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera;
            imagePicker.allowsEditing = false
            imagePicker.showsCameraControls = true
            imagePicker.cameraOverlayView = overlayView
            self.presentViewController(imagePicker, animated: false, completion: nil)
        }
    }
    
    // Allows us to set imageView.image to the imageTaken by the user in UIIMagePicker
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.contentMode = .ScaleAspectFit
            imageView.image = nil
            imageView.image = pickedImage
        }
        // dismiss camera
        dismissViewControllerAnimated(true, completion: nil)
        addActivityIndicator()
        //begins processing user's image after it is set
        processImage()
    }
    
    // redundant check
    private func clearOldData() {
        blockSelectedByUser = dummyBlock
        wordsAndRectsBlocks.removeAll()
    }
    
    // segue to ditionaryViewController. forces popover and sets word-to-be-defined in dictionaryViewController
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "popoverSegue" {
            let dictionaryViewController = segue.destinationViewController
            dictionaryViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.Down
            dictionaryViewController.popoverPresentationController?.delegate = self
            let dictVC = dictionaryViewController as? DictionaryViewController
            dictVC?.word = blockSelectedByUser!.word
        }
    }
    
    // forces dictionaryViewController to appear in popover. Default for iphone is to make whole-page viewController - we needed to change that
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    // allows redraw of all highlight boxes immediately after user has dismissed popover
    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        pageView.userHasSelectedWord = false
    }
    
    // to allow shake gesture to be sensed when in definitionViewController
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    // shake it lika a poleroid picture (to bring camera back)
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if motion == .MotionShake {
            showCamera()
        }
    }
    
    // gets the word selected by the user and checks if the tap location is valid.
    // also programaticly moves a button to the tap location, so we can anchor a segue to a popover
    // in the specified location
    @IBAction func getTapLocationFromUser(sender: UITapGestureRecognizer) {
        if sender.state == .Ended {
            pointFromUser = sender.locationInView(pageView)
            getSelectedBlock()
            // is word == "", user has not tapped on a valid location
            if blockSelectedByUser!.word != "" {
                //print(blockSelectedByUser!.word)
                pageView.userHasSelectedWord = true
            } else {
                pageView.userHasSelectedWord = false
            }
        }
        // moves button that anchors segue and executes segue
        if blockSelectedByUser!.rect != CGRect(x: 0, y: 0, width: 0, height: 0) {
            performSegueButton.center = CGPoint(x:blockSelectedByUser!.rect.midX, y: blockSelectedByUser!.rect.origin.y)
            performSegueWithIdentifier("popoverSegue", sender: self)
        }
    }
    
    // removes activity inicator after processing and passes word bounding boxes to view by protocols
    func rectsToDrawInPageView(sender: PageView) -> [(rect: CGRect, word: String, confidence: Double)]? {
        deleteActivityIndicator()
        return wordsAndRectsBlocks
    }
    
    // takes tap location from user and identifies the word that was selected by the user
    private func getSelectedBlock() {
        blockSelectedByUser = dummyBlock
        if wordsAndRectsBlocks.count > 0 {
            for block in wordsAndRectsBlocks {
                if block.rect.contains(pointFromUser!) {
                    blockSelectedByUser = block
                }
            }
        }
    }
    
    //deprecated
    //@IBOutlet weak var TakeAnotherPic: UIBarButtonItem!
    
    // give selected bounding box of word to page view by protocol
    func getSelectedRect(sender: PageView) -> CGRect? {
        let dummyRect = CGRect(x: 0, y: 0, width: 0, height: 0)
        if blockSelectedByUser != nil {
            return blockSelectedByUser!.rect
        }
        return dummyRect
    }
    
    // on navigation bar to trigger action
    @IBAction func TakeAnotherPic(sender: AnyObject) {
        showCamera()
    }

    // clear any old picture data, give image to brain to process, get processed words
    private func processImage() {
        clearOldData()
        if imageView.image != nil {
            // set class variable to image taken by the user
            imageTakenByUser = imageView?.image
            // class variable depricated. kept for debuging
            pageView.imageSize = CGSize(width: imageView.bounds.width , height: imageView.bounds.height)
            ocrBrain.imageSize = CGSize(width: imageView.bounds.width , height: imageView.bounds.height)
            // give brain image to process
            ocrBrain.imageFromUser = imageTakenByUser
            // get data from processed image
            wordsAndRectsBlocks = ocrBrain.getWordBlocks()
        }
    }
    
    // adds activity indicator during processing time
    private func addActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(frame: pageView.bounds)
        activityIndicator.activityIndicatorViewStyle = .White
        activityIndicator.backgroundColor = UIColor(white:  0, alpha: 0.25)
        activityIndicator.startAnimating()
        pageView.addSubview(activityIndicator)
    }
    // remove activity indicator if one exists
    private func deleteActivityIndicator() {
        if activityIndicator != nil {
            activityIndicator.removeFromSuperview()
            activityIndicator = nil
        }
    }
    // called when new data is collected from tesseract. When this happens, view must be redrawn
    private func updateUI() {
        if pageView != nil && wordsAndRectsBlocks.count != 0 {
            pageView.setNeedsDisplay()
        }
    }
}

