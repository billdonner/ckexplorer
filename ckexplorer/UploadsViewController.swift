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

final class UploadsViewController: UIViewController,VisualProt {
  var samplesConduit = Conduit<SampleRecord>()
  
  var grandTotalWrites = 0
  
func uploadRecordSampleRecord(
  _ imURL: URL,
  placeName: String,
  latitude:  CLLocationDegrees,
  longitude: CLLocationDegrees,
  //  changingTable: ChangingTableLocation,
  //  seatType:  SeatingType,
  healthy: Bool,
  kidsMenu: Bool,
  ratings: [UInt]) {
  
  grandTotalWrites += 1
  
  let rec = CKRecord(recordType: samplesConduit.typeName)
  let coverPhoto = CKAsset(fileURL: imURL)
  let location = CLLocation(latitude: latitude, longitude: longitude)
  rec.setObject(coverPhoto, forKey: "CoverPhoto")
  rec.setObject(placeName as CKRecordValue?, forKey: "Name")
  rec.setObject(location, forKey: "Location")
  
  rec.setObject(grandTotalWrites as CKRecordValue?, forKey: "id")
  rec.setObject(healthy as CKRecordValue?, forKey: "HealthyOption")
  rec.setObject(kidsMenu as CKRecordValue?, forKey: "KidsMenu")
  
  samplesConduit.uploadCKRecord(rec)
}
    @IBOutlet weak var sliderVal: UISlider!

    @IBOutlet weak var elapedTime: UILabel!
    @IBAction func sliderValChanged(_ sender: Any) {
        uploadbutton.setTitle ( "upload \(Int(sliderVal.value))",for:UIControlState.normal)
    }
    
    
    @IBOutlet weak var upnumber: UILabel!
    @IBOutlet weak var timeper: UILabel!
    @IBAction func uploadagain(_ sender: Any) {
        redo()
    }

    @IBOutlet weak var uploadbutton: UIButton!

    
    private var countUp:Int = 0
    
    var myTimer: Timer? = nil
    
    func countUpTick() {
        countUp += 1
        
        if (countUp == 0) {
            myTimer!.invalidate()
            myTimer=nil
        }
        
        elapedTime.text = "\(countUp)"
    }
   
 
  
  func redo() {
      grandTotalWrites = 0
    
    myTimer?.invalidate()
    myTimer=nil
    
    // set repeating timer for UI updates
    countUp = 0
    
    myTimer = Timer(timeInterval: 1.0, target: self, selector:#selector(UploadsViewController.countUpTick), userInfo: nil, repeats: true)
    elapedTime.text = "\(countUp)"
    
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            self.allUploadsTest(delegate: self)
          
              // come here any umber of times to post results
              DispatchQueue.main.async {
                
                self.upnumber.text = "done"
              }

        }
    }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    redo()
   }

    
    override func viewDidLoad() {
        super.viewDidLoad()
      print("UploadsViewController \(self)")
    
    
    }
  // must be on main thread
  
  func didAddRogue(r:Rogue){
    }
  func didFinishDownload (){
  
  }
  func didPublish(opcode:PulseOpCode, x up:Int, t per:TimeInterval) {
    if opcode == .uploadCountAndMs {
      self.timeper.text = "\(Gfuncs.prettyFloat(per,digits:3)) sec/item"
      self.upnumber.text = "\(up) items uploaded"
      self.view.setNeedsDisplay()
    
    }
  }
  


  // Apple Campus location = 37.33182, -122.03118

/// a bit unusual, but lets pass a delegate into this global func
func allUploadsTest(delegate: VisualProt?) {
  let startTime = Date()
    grandTotalWrites = 0
    
    for _ in 0..<Int(sliderVal.value) {
    switch Int(arc4random_uniform(3)) {
    case 0: uploadRecordSampleRecord(
    Bundle.main.url(forResource: "pizza", withExtension: "jpeg")!,
    placeName: "Ceasar's Pizza Palace",
    latitude: 37.332,
    longitude: -122.03,
    healthy: false,
    kidsMenu: true,
    ratings: [0, 1, 2])
  
  
  case 1: uploadRecordSampleRecord(
    Bundle.main.url(forResource: "chinese", withExtension: "jpeg")!,
    placeName: "King Wok",
    latitude: 37.1,
    longitude: -122.1,
    healthy: true,
    kidsMenu: false,
    ratings: [])
  
 case 2:  uploadRecordSampleRecord(
    Bundle.main.url(forResource: "steak", withExtension: "jpeg")!,
    placeName: "The Back Deck",
    latitude: 37.4,
    longitude: -122.03,
    healthy: true,
    kidsMenu: true,
    ratings: [5, 5, 4])
        
    default: fatalError()
        
    }
    }
  let timeper : TimeInterval = Date().timeIntervalSince(startTime) / //*1000.0 / 
    Double(grandTotalWrites)
  
  
  DispatchQueue.main.async {
  delegate?.didPublish(opcode: PulseOpCode.uploadCountAndMs,
                       x: self.grandTotalWrites,t: timeper)
  }
}
}
