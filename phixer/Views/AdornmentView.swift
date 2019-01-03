//
//  AdornmentView.swift
//  phixer
//
//  Created by Philip Price on 01/01/19
//  Copyright © 2016 Nateemma. All rights reserved.
//


import UIKit
import Neon



// Generic view that can display a list of 'adornments (icon, text, action etc.)


class AdornmentView: UIView {
    
    var theme = ThemeManager.currentTheme()
    

    
   //MARK: - Class variables:
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 32.0

    var layoutDone: Bool = false

    var adornmentList:[Adornment] = []
    var adornmentViewList:[UIView] = []
    var highlightSelection:Bool = false


    //MARK: Accessors
    
    // specify the list of adornments to use
    public func addAdornments(_ list:[Adornment]){
        adornmentList = list
        update()
    }

    // secifies whether the selected item should be highlighted or not (i.e. stay highlighted after it is touched)
    public func setHighlightSelection(_ highlight:Bool){
        if (!highlight){
            clearHighlights()
        }
        self.highlightSelection = highlight
    }

    // clear any highlighting that might have been done
    public func clearHighlights(){
        DispatchQueue.main.async(execute: { () -> Void in
            if self.adornmentViewList.count > 0 {
                for v in self.adornmentViewList {
                    v.backgroundColor = self.theme.backgroundColor
                    v.tintColor = self.theme.textColor
                    v.layer.cornerRadius = 4.0
                    v.layer.borderWidth = 1.0
                    v.layer.borderColor = self.theme.backgroundColor.cgColor
                }
            }
        })
    }
    
    
    //MARK: - Initialisation:
    
    convenience init(){
        self.init(frame: CGRect.zero)
        adornmentList = []
        adornmentViewList = []
        layoutDone = false
    }

    
    
    
    //MARK: - View functions
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        theme = ThemeManager.currentTheme()
        self.backgroundColor = theme.backgroundColor

        if adornmentList.count > 0 {
            buildAdornmentViews()
        }
        
        self.layoutDone = true
    }
    

    private func buildAdornmentViews(){
        
        // buld the list of adornment views
        if adornmentList.count > 0 {
            adornmentViewList = []
            for i in 0...(adornmentList.count-1) {
                if adornmentList[i].isHidden == false {
                    adornmentViewList.append(makeAdornmentView(index: i, adornment: adornmentList[i])!)
                }
            }
            
            // distribute the adornments evenly
            let pad = self.frame.size.width / CGFloat (adornmentList.count + 1)
            self.groupInCenter(group: .horizontal, views: adornmentViewList, padding: pad, width: buttonSize, height: bannerHeight)
        }

    }
    
    // called to request an update of the view
    public func update(){
        log.debug("update requested")
        if self.layoutDone {
            DispatchQueue.main.async(execute: { () -> Void in
                self.buildAdornmentViews()
            })
        }
    }
    
    
    private func makeAdornmentView(index: Int, adornment:Adornment) -> UIView? {
        let view:UIView? = UIView()
        view?.frame.size.width = buttonSize
        view?.frame.size.height = bannerHeight
        
        let btn = SquareButton(bsize: buttonSize)
        if !(adornment.icon.isEmpty) {
            btn.setImageAsset(adornment.icon)
        } else if (adornment.view != nil) {
            btn.setImage(adornment.view!)
        }
        btn.setTintable(true)
        btn.tag = index
        btn.addTarget(self, action: #selector(self.btnDidPress), for: .touchUpInside)
        
        let label = UILabel()
        label.text = adornment.text
        label.font = UIFont.systemFont(ofSize: 10.0)
        label.textColor = theme.textColor
        label.textAlignment = .center


        view?.addSubview(btn)
        view?.addSubview(label)
        
        btn.anchorToEdge(.top, padding: 0, width: buttonSize, height: buttonSize)
        label.align(.underCentered, relativeTo: btn, padding: 0, width: buttonSize, height: bannerHeight-buttonSize)
        
        return view
    }
    
    func highlightItem(index:Int){
        if self.highlightSelection {
            if (self.adornmentViewList.count > 0) {
                if (index < self.adornmentViewList.count) && (index > 0) {
                    let v = self.adornmentViewList[index]
                    v.backgroundColor = self.theme.backgroundColor
                    v.tintColor = self.theme.textColor
                    v.layer.cornerRadius = 4.0
                    v.layer.borderWidth = 1.0
                    v.layer.borderColor = self.theme.backgroundColor.cgColor
                } else {
                    log.error("Invalid index: \(index)")
                }
            }
        }
    }
    
    /////////////////////////////////
    //MARK: - touch handlers
    /////////////////////////////////

    @objc func btnDidPress() {
        let index = self.tag
        highlightItem(index: index)
        let f = adornmentList[index].callback
        if f != nil {
            DispatchQueue.main.async(execute: { () -> Void in
                f!()
            })
        } else {
            log.warning("No handler supplied for item \(adornmentList[index].text)")
        }
    }

}
