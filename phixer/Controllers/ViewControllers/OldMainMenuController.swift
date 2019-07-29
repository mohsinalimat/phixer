//
//  OldMainMenuController.swift
//  phixer
//
//  Created by Phil Price on 4/10/17.
//  Copyright © 2017 Nateemma. All rights reserved.
//

import Foundation
import UIKit

import Neon
import GoogleMobileAds

// This is the Main View Controller for phixer, and basically just presents a menu of available options

class OldMainMenuController: CoordinatedController, UINavigationControllerDelegate {
    
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
    // Menu items
    var choosePhotoMenuItem: UILabel = UILabel()
    var simpleEditMenuItem: UILabel = UILabel()
    var styleTransferMenuItem: UILabel = UILabel()
    var browseFiltersMenuItem: UILabel = UILabel()
    var browsePresetsMenuItem: UILabel = UILabel()
    var settingsMenuItem: UILabel = UILabel()
 
    let numItems = 6
    
    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////
    
    // return the display title for this Controller
    override public func getTitle() -> String {
        return "Main Menu"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "About"
    }
    
    /////////////////////////////
    // INIT
    /////////////////////////////
    

    convenience init(){
        self.init(nibName:nil, bundle:nil)
        //log.debug("=== OldMainMenuController() ===")
        //doInit()
    }
    
    var initDone:Bool = false
    
    func doInit(){
        
        if (!initDone){
            log.verbose("init")
            initDone = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // common setup
        self.prepController()

        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        UISettings.showAds = (UISettings.isLandscape == true) ? false : true // don't show in landscape mode, too cluttered
        
        doInit()
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(adView)
        view.addSubview(choosePhotoMenuItem)
        view.addSubview(simpleEditMenuItem)
        view.addSubview(styleTransferMenuItem)
        view.addSubview(browseFiltersMenuItem)
        view.addSubview(browsePresetsMenuItem)
        view.addSubview(settingsMenuItem)
        
        
        
        
        // set up Ads
        if (UISettings.showAds){
            adView.isHidden = false
            adView.frame.size.height = UISettings.panelHeight
            adView.frame.size.width = displayWidth
            adView.layer.borderColor = theme.borderColor.cgColor
            adView.layer.borderWidth = 1.0
            view.addSubview(adView)
            adView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: adView.frame.size.height)
            Admob.startAds(view:adView, viewController:self)
        } else {
            adView.frame.size.height = 0
            adView.isHidden = true
        }

        let h = ((view.frame.size.height - adView.frame.size.height - UISettings.topBarHeight) / CGFloat(numItems)) - 8
        let w = displayWidth - 4
        

        // setup text, colours etc.
        
        setupMenuItem(label:choosePhotoMenuItem, height:h, width:w,
                      title:"Change Photo", color:UIColor.flatOrange, handler: UITapGestureRecognizer(target: self, action: #selector(presentPhotoChooser)))
        
        setupMenuItem(label:simpleEditMenuItem, height:h, width:w,
                      title:"Simple Picture Editor", color:UIColor.flatMint, handler: UITapGestureRecognizer(target: self, action: #selector(presentSimpleImageEditor)))

        setupMenuItem(label:styleTransferMenuItem, height:h, width:w,
                      title:"Style Transfer", color:UIColor.flatMintDark, handler: UITapGestureRecognizer(target: self, action: #selector(presentStyleTransfer)))
        
        setupMenuItem(label:browseFiltersMenuItem, height:h, width:w,
                      title:"Browse Filters", color:UIColor.flatWatermelonDark, handler: UITapGestureRecognizer(target: self, action: #selector(presentFilterGallery)))
        
        setupMenuItem(label:browsePresetsMenuItem, height:h, width:w,
                      title:"Browse Presets", color:UIColor.flatPlumDark, handler: UITapGestureRecognizer(target: self, action: #selector(presentPresetGallery)))

        
        setupMenuItem(label:settingsMenuItem, height:h, width:w,
                      title:"Settings", color:UIColor.flatPurple, handler: UITapGestureRecognizer(target: self, action: #selector(presentSettings)))


        // set layout constraints
        view.groupAgainstEdge(group: .vertical,
                              views: [choosePhotoMenuItem, simpleEditMenuItem, styleTransferMenuItem, browseFiltersMenuItem, browsePresetsMenuItem, settingsMenuItem],
                              againstEdge: .bottom, padding: 8, width: w-8, height: h)
      
        

    }
    
   
 
    // utility function to setup a menu item
    func setupMenuItem(label:UILabel, height:CGFloat, width:CGFloat, title:String, color:UIColor, handler:UITapGestureRecognizer){
        
        // set size
        label.frame.size.height = height
        label.frame.size.width = width
        
        // change font to bold (and slightly bigger size)
        let size = max(label.font.pointSize + 3.0, 24.0)
        label.font = UIFont.systemFont(ofSize: size, weight: UIFont.Weight.thin)
 
        // set text
        label.text = title

        // set Colours
        label.backgroundColor = color
        //label.textColor = UIColor.flatWhite()
        label.textColor = UIColor(contrastingBlackOrWhiteColorOn:color, isFlat:false)
        label.textAlignment = .center

        // assign gesture handler
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(handler)
    }
    
    /////////////////////////////////
    // Handlers for menu items
    /////////////////////////////////
    
    
    @objc func presentPhotoChooser(){
        InputSource.setCurrent(source: .edit)
        self.coordinator?.activateRequest(id: .choosePhoto)
    }
    
    @objc func presentSimpleImageEditor(){
        InputSource.setCurrent(source: .edit)
        self.coordinator?.activateRequest(id: .edit)
    }

    @objc func presentStyleTransfer(){
        InputSource.setCurrent(source: .edit)
        self.coordinator?.activateRequest(id: .browseStyleTransfer)
    }

    
    @objc func presentFilterGallery(){
        InputSource.setCurrent(source: .edit)
        self.coordinator?.activateRequest(id: .browseFilters)
    }
    
    @objc func presentPresetGallery(){
        InputSource.setCurrent(source: .edit)
        filterManager.setCurrentCollection("presets") //TODO: make a constant
        self.coordinator?.activateRequest(id: .categoryGallery)
    }


    @objc func presentSettings(){
        self.coordinator?.activateRequest(id: .settings)

    }
    
    
    /////////////////////////////////
    // Handling for functions not yet implemented
    /////////////////////////////////
    
    fileprivate var notImplementedAlert:UIAlertController? = nil
    
    fileprivate func notImplemented(){
        
        if (notImplementedAlert == nil){
            notImplementedAlert = UIAlertController(title: "Not Implemented  ☹️", message: "Sorry, this function has not (yet) been implemented", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel) { (action:UIAlertAction) in
                log.debug("OK")
            }
            notImplementedAlert?.addAction(okAction)
        }
        DispatchQueue.main.async(execute: { () -> Void in
            self.present(self.notImplementedAlert!, animated: true, completion:nil)
        })
    }

} // OldMainMenuController


/////////////////////////////////
// Extensions
/////////////////////////////////

