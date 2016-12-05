//
//  GaussianBlurDescriptor.swift
//  FilterCam
//
//  Created by Philip Price on 10/4/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import GPUImage


class GaussianBlurDescriptor: FilterDescriptorInterface {
    
    
    let key = "GaussianBlur"
    let title = "Gaussian Blur"
    
    var filter: BasicOperation?  = nil
    let filterGroup: OperationGroup? = nil
    
    let numParameters = 1
    let parameterConfiguration = [ParameterSettings(title:"radius", minimumValue:0.0, maximumValue:24.0, initialValue:8.0, isRGB:false)]
    
    
    let filterOperationType = FilterOperationType.singleInput
    
    fileprivate var lclFilter:GaussianBlur = GaussianBlur() // the actual filter
    fileprivate var stash_blurRadiusInPixels: Float
    
    
    required init(){
        filter = lclFilter // assign the filter defined in the interface to the instantiated filter of the desired sub-type
        lclFilter.blurRadiusInPixels = parameterConfiguration[0].initialValue
        stash_blurRadiusInPixels = lclFilter.blurRadiusInPixels
        log.verbose("config: \(parameterConfiguration)")
    }
    
    
    //MARK: - Required funcs
    
    func reset(){
        lclFilter.removeAllTargets()
        lclFilter = GaussianBlur()
        restoreParameters()
    }
    
    
    func configureCustomFilter(_ input:(filter:BasicOperation, secondInput:BasicOperation?)){
        // nothing to do
    }
    
    
    
    func getParameter(_ index: Int)->Float {
        switch (index){
        case 1:
            return lclFilter.blurRadiusInPixels
        default:
            return parameterNotSet
        }
    }
    
    
    func setParameter(_ index: Int, value: Float) {
        switch (index){
        case 1:
            lclFilter.blurRadiusInPixels = value
            log.debug("\(parameterConfiguration[0].title):\(value)")
            break
        default:
            log.error("Invalid parameter index (\(index)) for filter: \(key)")
        }
    }
    
    
    
    func getColorParameter(_ index: Int)->UIColor { return UIColor.blue }
    func setColorParameter(_ index:Int, color:UIColor) {}
    
    
    func stashParameters(){
        stash_blurRadiusInPixels = lclFilter.blurRadiusInPixels
    }
    
    func restoreParameters(){
        lclFilter.blurRadiusInPixels = stash_blurRadiusInPixels
    }
}
