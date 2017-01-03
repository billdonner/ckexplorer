/*
 
 UploadsViewController.swift
 
 Copyright 2016 Bill Donner/aka MidnightRambler
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 
 */


import UIKit
import CoreLocation
import CloudKit

//MARK: - Test Uploads in Self-Sufficient View Controller

public enum UploadOpCode:Int  {
    case uploadCountAndMs
}
protocol UpProt {
    
    func uploadRecordPhotoAsset(_ conduit:UploadConduit,
                                
                                url imURL: URL,
                                idval: Int ,
                                placeName: String,
                                latitude:  CLLocationDegrees,
                                longitude: CLLocationDegrees,
                                ratings: [UInt])

}
protocol UploadProt : UpProt {
    func didFinishUpload()
    func publishEventUpload(opcode:UploadOpCode, x count:Int, t per:TimeInterval)
  
}
extension UpProt {
    //MARK: - uploadRecordSampleRecord adds one to Cloudkit
    
    func uploadRecordPhotoAsset(_ conduit:UploadConduit,
                                
                                url imURL: URL,
                                idval: Int ,
                                placeName: String,
                                latitude:  CLLocationDegrees,
                                longitude: CLLocationDegrees,
                                ratings: [UInt]) {
        let rec = CKRecord(recordType: containerTableName)
        let coverPhoto = CKAsset(fileURL: imURL)
        let location = CLLocation(latitude: latitude, longitude: longitude)
        rec.setObject(coverPhoto, forKey: "CoverPhoto")
        rec.setObject(placeName as CKRecordValue?, forKey: "Name")
        rec.setObject(location, forKey: "Location")
        rec.setObject(idval as CKRecordValue?, forKey: "id")
        
        print("uploading #\(rec["id"]) \(rec["Name"])) to \(containerTableName) from \(imURL)")
        conduit.uploadCKRecord(rec)
    }
}
final class UploadConduit : Conduit, UpProt {
    
     var upload_delegate: UploadProt?
    fileprivate var  allrecids :[CKRecordID] = []
    fileprivate var querystarttime : Date?
    
    /// callback - get the whole record integrated into Rogue structure
    
    /// save record to cloudkit
    func uploadCKRecord (_ rec:CKRecord) {
        db.save(rec, completionHandler: { record, error in
            guard error == nil else {
                print("!!!error saving to cloudkit \(error)")
                if let basevc = self.upload_delegate as? UIViewController {
                    IOSSpecialOps.blurt(basevc, title: "!!!error saving to cloudkit", mess: "cloudkit \(error)")
                }
                return
            }
        })
    }//end upload
}

final class UploadsViewController: UIViewController,UploadProt {
    
    fileprivate var grandTotalWrites = 0
    
    /// samplesConduit connects to Cloudkit Sample Record Type, providing instance
    fileprivate var uploadConduit = UploadConduit(containerID,tableName:containerTableName)
    
    
    
    /// quick and dirty ui in IB
    @IBOutlet weak var sliderVal: UISlider!
    
    @IBOutlet weak var elapedTime: UILabel!
    
    @IBAction func sliderValChanged(_ sender: Any) {
        upnumber.text = "will upload \(Int(sliderVal.value)) assets"
    }
    @IBAction func cancelTheTest(_ sender: Any) {
        countUp = -1 // set the flag
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var upnumber: UILabel!
    
    @IBOutlet weak var timeper: UILabel!
    
    @IBAction func icloudAction(_ sender: Any) {
        redoUploadFromICloud()
    }
    @IBAction func itunesAction(_ sender: Any) {
        redoUploadFromITunes()
    }
    @IBAction func localAction(_ sender: Any) {
        redoUploadFromLocals()
    }
    
    @IBOutlet weak var icloudButton: UIButton!
    
    @IBOutlet weak var itunesButton: UIButton!
    
    @IBOutlet weak var localButton: UIButton!
    
    fileprivate var countUp:Int = 0
    fileprivate var startTime = Date()
    fileprivate var myTimer: Timer? = nil
    
    //MARK: - maintain a periodic timer for onscreen display
    
    /// setting countUp to -1 stops the timer
    func countUpTick() {
        countUp += 1
        if (countUp == 0) {
            myTimer!.invalidate()
            myTimer=nil
        }
        let netelapsedTime : TimeInterval = Date().timeIntervalSince(startTime)
        elapedTime.text = "\(Gfuncs.prettyFloat(netelapsedTime,digits:1)) secs elapsed"
    }
    
    //MARK: - viewcontroller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "upload to " + titleName
        sliderValChanged(self) //fills in ui first time up
        uploadConduit.upload_delegate = self
    }
}


internal extension UploadsViewController {
    
    /// at the beginning of a cycle, reset everthing
    func redocommon () {
        myTimer?.invalidate()
        myTimer=nil
        // set repeating timer for UI updates
        countUp = 0
        startTime = Date()
        spinner.startAnimating()
        myTimer = Timer.scheduledTimer (timeInterval: 1.0, target: self, selector:#selector(UploadsViewController.countUpTick), userInfo: nil, repeats: true)
        elapedTime.text = "\(countUp)"
        self.upnumber.text = "0 items uploaded"
        
    }
    /// at the end of  cycle update the UI
    func redofinally() {
        print("end of upload cycle")
        DispatchQueue.main.async {
            self.upnumber.text = "done"
            self.myTimer?.invalidate()
            self.spinner.stopAnimating()
        }
    }
    
    //MARK: - pull images from iCloud import
    
    /// continues in DocumentPickerDelegate
    func redoUploadFromICloud () {
        redocommon()
        let supportedCloudUTIs =
            ["com.compuserve.gif",
             "public.png",
             "public.jpeg"]
        let importMenu = UIDocumentPickerViewController(documentTypes:  supportedCloudUTIs, in: .import)
        importMenu.delegate = self
        present (importMenu, animated: true, completion: nil)
    }
    //MARK: - pull images from iTunes
    func redoUploadFromITunes () {
        let percycle = Int(sliderVal.value)
        redocommon()
        loadfromitunes(each : { url, name in
            for _ in 0..<percycle {
                //  do {
                self.uploadRecordPhotoAsset(self.uploadConduit,url:url,
                                            idval:self.grandTotalWrites,
                                            placeName: name,
                                            latitude: 37.4,
                                            longitude: -122.03,
                                            ratings: [])
                //}
                //                catch {
                //                    print("couldnt make temp file\(url)  error \(error)")
                //                }
                
                
                
            }})
        {
            self.redofinally()
        }
    }
    
    //MARK: - pull images from Local Resources
    
    /// operation is finished in allUploadsTest
    func redoUploadFromLocals() {
        redocommon()
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            self.allUploadsTest(delegate: self)
        }
    }
    
    //MARK: - delegate must be on main thread
    
    internal func didFinishUpload() {
        myTimer?.invalidate()
        
    }
    
    internal func publishEventUpload(opcode:UploadOpCode, x up:Int, t per:TimeInterval) {
        if opcode == .uploadCountAndMs {
            self.timeper.text = "\(Gfuncs.prettyFloat(per,digits:3)) sec/item"
            self.upnumber.text = "\(up) items uploaded"
            self.view.setNeedsDisplay()
        }
    }
    
    //MARK: - LOCAL TEST CASES
    
    
    // Apple Campus location = 37.33182, -122.03118
    
    /// a bit unusual, but lets pass a delegate into this global func
    func allUploadsTest(delegate: UploadProt?) {
        let startTime = Date()
        for _ in 0..<Int(sliderVal.value) {
            if countUp == -1 { break }
            
            switch Int(arc4random_uniform(3)) {
                
            case 0: uploadRecordPhotoAsset(self.uploadConduit,url:
                Bundle.main.url(forResource: "pizza", withExtension: "jpeg")!,
                                           idval:grandTotalWrites,
                                           placeName: "Ceasar's Pizza Palace",
                                           latitude: 37.332,
                                           longitude: -122.03,
                                           ratings: [0, 1, 2])
                
                
            case 1: uploadRecordPhotoAsset(self.uploadConduit,url:
                Bundle.main.url(forResource: "chinese", withExtension: "jpeg")!,
                                           idval:grandTotalWrites,
                                           placeName: "King Wok",
                                           latitude: 37.1,
                                           longitude: -122.1,
                                           ratings: [])
                
            case 2:  uploadRecordPhotoAsset(self.uploadConduit,url:
                Bundle.main.url(forResource: "steak", withExtension: "jpeg")!,
                                            idval:grandTotalWrites,
                                            placeName: "The Back Deck",
                                            latitude: 37.4,
                                            longitude: -122.03,
                                            ratings: [5, 5, 4])
                
            default: fatalError()
                
            }
            
            grandTotalWrites += 1
            
        }
        
        self.redofinally()
        let timeper : TimeInterval = Date().timeIntervalSince(startTime) / //*1000.0 /
            Double(grandTotalWrites)
        
        DispatchQueue.main.async {
            delegate?.publishEventUpload(opcode: UploadOpCode.uploadCountAndMs,
                                         x: self.grandTotalWrites,t: timeper)
        }
    }
}
//MARK: - UIDocumentPickerDelegate finishes upload from icloud files into cloudkit
extension UploadsViewController : UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("cancelled from doc picker")
    }
    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentAt url: URL) {
        print("picked new document at \(url)")
        let percycle = Int(sliderVal.value)
        for _ in 0..<percycle {
            if countUp == -1 { break }
            uploadRecordPhotoAsset(self.uploadConduit,url:url,
                                   idval:grandTotalWrites,
                                   placeName: "PickedFromCloud",
                                   latitude: 37.4,
                                   longitude: -122.03,
                                   ratings: [])
            grandTotalWrites += 1
        }
        self.redofinally()
    }
}
