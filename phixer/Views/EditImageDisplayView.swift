//
//  EditImageDisplayView.swift
//  phixer
//
//  Created by Philip Price on 9/16/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation


// Class responsible for displaying the edited image, with the full stack of filters applied
// Note that filters are not saved to the edit stack, that is the responsibility of the ViewController
class EditImageDisplayView: UIView {
    
    var theme = ThemeManager.currentTheme()
    

    // enum that controls the display mode
    public enum displayMode {
        case full
        case split
    }
    
    // enum that controls the filtered mode
    public enum filterMode {
        case preview
        case saved
        case original
    }
    
    fileprivate var currDisplayMode: displayMode = .full
    fileprivate var currFilterMode: filterMode = .preview
    
    fileprivate var currSplitOffset:CGFloat = 0.0
    fileprivate var currSplitPoint:CGPoint = CGPoint.zero

    fileprivate var renderView: MetalImageView? = MetalImageView()
    fileprivate var imageView: UIImageView! = UIImageView()
    
    fileprivate var initDone: Bool = false
    fileprivate var layoutDone: Bool = false
    fileprivate var filterManager = FilterManager.sharedInstance
    
    
    fileprivate var currInput:CIImage? = nil
    fileprivate var currBlendInput:CIImage? = nil
    
    fileprivate var currFilterKey:String = ""
    //fileprivate var currFilterDescriptor: FilterDescriptor? = nil

    
    
    ///////////////////////////////////
    // MARK: - Setup/teardown
    ///////////////////////////////////
    convenience init(){
        self.init(frame: CGRect.zero)
        doInit()
    }
    
    
    deinit {
        //suspend()
    }

   
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //log.debug("layout")
       doInit()

        //log.debug("layout")
        self.currInput = InputSource.getCurrentImage() // this can change
        renderView?.frame = self.frame
        renderView?.image = self.currInput
        let imgSize = InputSource.getSize()
        renderView?.setImageSize(imgSize)
        renderView?.frame = self.frame
        renderView?.backgroundColor = theme.backgroundColor
        
        self.currSplitPoint = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2) // middle of view
        self.setSplitPosition(self.currSplitPoint)
        
        self.addSubview(renderView!)
        renderView?.fillSuperview()
        // self.bringSubview(toFront: renderView!)
        
        layoutDone = true
        
        // check to see if filter has already been set. If so update
        
        if !(currFilterKey.isEmpty) {
            update()
        }

        

    }
    
    fileprivate func doInit(){
        

        if (!initDone){
            //log.debug("init")
            self.backgroundColor = theme.backgroundColor
            
            //EditManager.reset()
            //self.currInput = ImageManager.getCurrentEditImage()
            self.currInput = InputSource.getCurrentImage()
            EditManager.setInputImage(self.currInput)

            self.layoutDone = false
            initDone = true
            
        }
    }
    


    
    
    
    ///////////////////////////////////
    // MARK: - Accessors
    ///////////////////////////////////
    
    public func setDisplayMode(_ mode:displayMode){
        self.currDisplayMode = mode
        log.verbose("Display Mode: \(mode)")
    }
    
    public func setFilterMode(_ mode:filterMode){
        self.currFilterMode = mode
        log.verbose("Filter Mode: \(mode)")
    }

    
    public func setSplitPosition(_ position:CGPoint){
        self.currSplitOffset = self.offsetFromPosition(position)
        //log.verbose("position: \(position) offset:\(self.currSplitOffset)")
    }

    public func setFilter(key:String){
        //currFilterKey = filterManager.getSelectedFilter()
        if (!key.isEmpty){
            currFilterKey = key

            EditManager.addPreviewFilter(filterManager.getFilterDescriptor(key: key))
            update()
        } else {
            log.error("Empty key specified")
        }
    }
    
    // saves the filtered image to the camera roll
    public func saveImage(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let ciimage = self.renderView?.image
            if (ciimage != nil){
                let cgimage = ciimage?.generateCGImage(size:(self.renderView?.image?.extent.size)!)
                let image = UIImage(cgImage: cgimage!)
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            } else {
                log.error("Error saving photo")
            }
        }
    }
    
    open func update(){
        if (layoutDone) {
            //log.verbose("update requested")
            DispatchQueue.main.async(execute: { () -> Void in
                self.runFilter()
            })
        }
    }
    
    public func getImagePosition(viewPos:CGPoint) -> CIVector?{
        if renderView != nil {
            return renderView?.getImagePosition(viewPos: viewPos)
        } else {
            return CIVector(cgPoint: CGPoint.zero)
        }
    }
    
    open func updateImage(){
        DispatchQueue.main.async(execute: { () -> Void in
            //log.verbose("Updating edit image")
            EditManager.setInputImage(InputSource.getCurrentImage())
            self.currInput = EditManager.previewImage
            if self.currInput == nil {
                log.warning("Edit image not set, using Sample")
                self.currInput = ImageManager.getCurrentSampleInput() // no edit image set, so make sure there is something
            }
            self.update()
        })
    }
    
    
   
    ///////////////////////////////////
    // MARK: filter execution
    ///////////////////////////////////
    
    // Sets up the filter pipeline. Call when filter, orientation or camera changes
    open func runFilter(){
        
        if !self.currFilterKey.isEmpty && layoutDone {
            DispatchQueue.main.async(execute: { () -> Void in
                if self.currDisplayMode == .full {
                    log.verbose("Running filter: \(self.currFilterKey)")
                   switch self.currFilterMode {
                     case .preview:
                        self.renderView?.image = EditManager.getPreviewImage()
                    case .saved:
                        self.renderView?.image = EditManager.getFilteredImage()
                    case .original:
                        self.renderView?.image = EditManager.getOriginalImage()
                    default:
                        log.error("Uknown mode")
                    }
                } else {
                    self.renderView?.image = EditManager.getSplitPreviewImage(offset: self.currSplitOffset)
                }
            })
        } else {
            if self.currFilterKey.isEmpty { log.warning("Filter not set") }
            if !layoutDone { log.warning("Layout not yet done") }
        }
    }
    
    
    func suspend(){

    }
    
    
    ///////////////////////////////////
    // MARK: - Utilities
    ///////////////////////////////////
    
    // convert the view-based position into an offset in image space, adjusted for rotation
    public func offsetFromPosition(_ position:CGPoint) -> CGFloat {
        var offset:CGFloat
        
        // get the position in image coordinates
        let imgOffset = renderView?.getImagePosition(viewPos: position).cgPointValue
        
        // adjust based on the image orientation. This assumes landscape images are rotated
        let imgSize = InputSource.getSize()
        
        if imgOffset != nil {
            if imgSize.height > imgSize.width { // portrait
                offset = (imgOffset?.x)!
            } else { // landscape
                offset = (imgOffset?.y)!
            }
        } else {
            // error, put offset in the middle of the image
            offset = min (imgSize.width, imgSize.height) / 2
        }

        return offset
    }
    
}
