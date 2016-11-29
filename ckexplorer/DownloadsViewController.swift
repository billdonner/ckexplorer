/*
 
DownloadsViewController.swift
Created by bill donner on 11/23/16
 
 Copyright 2016 Bill Donner/aka MidnightRambler
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 
 */
import UIKit

class DownloadsViewController: UIViewController {
  @IBOutlet weak var downTime: UILabel!
  @IBOutlet weak var downCount: UILabel!
  @IBOutlet weak var moreDataIndicator: UILabel!
  @IBOutlet weak var elapsedWallTime: UILabel!
  @IBOutlet weak var startupDelay: UILabel!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  @IBOutlet weak var roguesGalleryView: RoguesGalleryView!
  @IBOutlet weak var refreshButton: UIButton!

    @IBAction func tapped(_ sender: Any) { 
    redo()
  }
  
  //MARK: connection to Cloudkit for sample records
    var samplesConduit = Conduit<SampleRecord>()
  
 fileprivate var totalincoming = 0
  
    fileprivate var  redoStartTime = Date()
  
    //MARK: repaint interface and start Download (again)
    private var countUp:Int = 0
    private var startTime = Date()
    
    var myTimer: Timer? = nil
    
    func countUpTick() {
        countUp += 1
        
        if (countUp == 0) {
            myTimer!.invalidate()
            myTimer=nil
        }
         let netelapsedTime : TimeInterval = Date().timeIntervalSince(startTime)
        elapsedWallTime.text = "\(Gfuncs.prettyFloat(netelapsedTime,digits:1)) secs elapsed"
    }
   
    
  func redo() {
        self.myTimer?.invalidate()
        self.myTimer=nil
        
        // set repeating timer for UI updates
        self.countUp = 0
        
        self.myTimer = Timer.scheduledTimer (timeInterval: 0.1, target: self, selector:#selector(DownloadsViewController.countUpTick), userInfo: nil, repeats: true)
        
    
    DispatchQueue.main.async {
      self.redoStartTime = Date()
      self.spinner.startAnimating() // starts on mainq
      self.refreshButton.isEnabled = false
        self.refreshButton.setTitle("...downloading...", for: .normal)
      self.downTime.text = "...restarting..."
      self.downCount.text = "no items"
      self.moreDataIndicator.text = "...thinking..."
    }
    
    DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
      self.downloadAllTest()//still working in back, will finish with delegate call on mainq
    }
  }
  

  override func viewDidLoad() {
    super.viewDidLoad()
    // pain the screen, including the image assets
    roguesGalleryView.setup()
  }
    /// get all the records
  func downloadAllTest( ) {
    let startTime = Date()
    totalincoming = 0
    samplesConduit.delegate = self
    samplesConduit.getTheRecords(){ recs in
      print ("downloadalltest finished with \(recs.count) items")
        self.spinner.stopAnimating() // starts on mainq
        self.refreshButton.isEnabled = true
        self.refreshButton.setTitle("Download Again", for: .normal)
        self.downTime.text = "...done..."
        self.moreDataIndicator.text = "done"
    }
    let netelapsedTime : TimeInterval = Date().timeIntervalSince(startTime)
    print ("downloadAllTest records started \(netelapsedTime)ms, still fetching")
    DispatchQueue.main.async {
      self.didPublish(opcode: PulseOpCode.initialCountAndTime,x: 0,t: netelapsedTime)
    }
  }
}
extension DownloadsViewController: VisualProt {
  // must be on main thread
  func didAddRogue(r:Rogue) {
    roguesGalleryView.addRogue(r: r)
  }
  func didFinishDownload () {
    self.moreDataIndicator.text = "done"
    self.refreshButton.isEnabled = true
        self.refreshButton.setTitle("Done Downloading", for: .normal)
    self.spinner.stopAnimating()
    self.myTimer?.invalidate()
  }
  func didPublish(opcode: PulseOpCode, x count:Int, t mstime: TimeInterval) {
    switch opcode {
        
    case  .eventCountAndMs :
      totalincoming += count
      self.downTime.text = "\(Gfuncs.prettyFloat(mstime,digits:3))sec/item"
      self.downCount.text = "\(totalincoming) items"
      
    case  .initialCountAndTime :
      self.startupDelay.text = "\(Gfuncs.prettyFloat(mstime,digits:3))  warmup"
      self.downCount.text = "initially \(count) items"
      
    case .moreData :
      self.moreDataIndicator.text = count == 0 ? "no more" : "more data anticipated"
//      if count == 0 {
//        self.spinner.stopAnimating()
//      }
    default: fatalError("upload enum in download controller")
    }
    
//    let elapsed = Date().timeIntervalSince(redoStartTime)
//    self.elapsedWallTime.text = "0:0:\(Gfuncs.prettyFloat(elapsed,digits:1)) elapsed"
    
    self.view.setNeedsDisplay()
  }
}
