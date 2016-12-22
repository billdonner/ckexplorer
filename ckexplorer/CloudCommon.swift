/*
 
 CloudCommon.swift
 Created by bill donner on 11/23/16
 
 Copyright 2016 Bill Donner/aka MidnightRambler
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 
 */


/// used in both the TVOS and IOS versions

import Foundation
import UIKit
import CloudKit
import CoreLocation

/// the PulseOpCode is used to send back signals


/// the viewcontrollers have associated callback class protocols which can be weak

// global funcs

struct Gfuncs {
    static func intWithLeadingZeros (_ thing:Int64,digits:Int) -> String {
        return String(format:"%0\(digits)lu", (thing) )
    }
    
    static func prettyFloat (_ t:TimeInterval,digits:Int=2) -> String  {
        return String(format:"%0.\(digits)f", (t) )
    }
}
//MARK: - PhotoAsset docs

//final class PhotoAsset: NSObject  {
//    // MARK: - Properties
//    var record: CKRecord!
//    var name: String!
//    weak var database: CKDatabase!
//    var assetCount = 0
//    
//    // MARK: - Initializers
//    init(record: CKRecord, database: CKDatabase) {
//        self.record = record
//        self.database = database
//        self.name = record["Name"] as! String
//    }
//    var title: String? {
//        return name
//    }
//}

//MARK: - Conduit gathers all operations against one particular set of Record Types T

/// generic parameter is only used for the type of record passed to CKRecord

/// "CONTAINER-ID" depending on the actual app instance theres a differen shared data area
//    it looks something like group.xxx.yyy.zzz
public var containerID: String  { get {
    if let iDict = Bundle.main.infoDictionary,
        let w =  iDict["CONTAINER-ID"] as? String {
        return w
    }
    return "PLEASE_SET_CONTAINER-ID" }
}
/// "CLOUD-TABLE-NAME" depending on the actual app instance theres a differen shared data area
//    it looks something like group.xxx.yyy.zzz
public var containerTableName: String  { get {
    if let iDict = Bundle.main.infoDictionary,
        let w =  iDict["CLOUD-TABLE-NAME"] as? String {
        return w
    }
    return "PLEASE_SET_CLOUD-TABLE-NAME" }
}
/// combo name can be used for icloud.com
public var titleName: String  { get {
    let tail  = containerID.components(separatedBy: ".").last!
    return tail + ":" + containerTableName }
}

public struct IOSSpecialOps { // only compiles in main app - ios bug?
    
    public static func blurt (_ vc:UIViewController, title:String, mess:String, f:@escaping ()->()) {
        
        let action : UIAlertController = UIAlertController(title:title, message: mess, preferredStyle: .alert)
        
        action.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {alertAction in
            f()
        }))
        
//        action.modalPresentationStyle = .popover
//        let popPresenter = action.popoverPresentationController
//        popPresenter?.sourceView = vc.view
        vc.present(action, animated: true , completion:nil)
    }
    public static func blurt (_ vc:UIViewController, title:String, mess:String) {
        blurt(vc,title:title,mess:mess,f:{})
    }
    public static func ask (_ vc:UIViewController, title:String, mess:String, f:@escaping ()->()) {
        
        let action : UIAlertController = UIAlertController(title:title, message: mess, preferredStyle: .alert)
        
        action.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {alertAction in
            
        }))
        action.addAction(UIAlertAction(title: "Delete", style: .default, handler: {alertAction in
            f()
        }))
        
        //action.modalPresentationStyle = .popover
//        let popPresenter = action.popoverPresentationController
//        popPresenter?.sourceView = vc.view
        vc.present(action, animated: true , completion:nil)
    }
    public  static func ask (_ vc:UIViewController, title:String, mess:String) {
        ask(vc,title:title,mess:mess,f:{})
    }
}



