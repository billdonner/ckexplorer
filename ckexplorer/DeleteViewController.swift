/*
 
 DeletesViewController.swift
 
 Copyright 2016 Bill Donner/aka MidnightRambler
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 
 */


import UIKit
import CloudKit


final class DeletesViewController: UIViewController  {
    
    var samplesConduit = Conduit<PhotoAsset>()
    
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
    
    // runs a full 10 fps
    func redo() {
        self.myTimer?.invalidate()
        self.myTimer = nil
        
        // set repeating timer for UI updates of elapsed time
        self.countUp = 0
        self.startTime = Date() // reset for this redo
        self.myTimer = Timer.scheduledTimer (timeInterval: 0.1, target: self, selector:#selector(DeletesViewController.countUpTick), userInfo: nil, repeats: true)
    }
    @IBAction func deleteEm(_ sender: Any) {
        redo() // gets timer going
        downcounter.text = "...gathering..."
        spinner.startAnimating()
        samplesConduit.delete_delegate = self
        samplesConduit.deleteAllRecords(){ deletecount  in
            print("Deleted\(deletecount) records")
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                self.myTimer?.invalidate()
            }
        }
    }
    // must be on main thread
    @IBOutlet weak var downcounter: UILabel!
    @IBOutlet weak var elapsedWallTime: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    @IBAction func cancelTheTest(_ sender: Any) {
        countUp = -1 // set the flag
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "delete from " + containerID
        self.downcounter.text = "...press to start deleting ..."
        print("DeletesViewController \(self)")
    }
}
extension DeletesViewController : DeleteProt {
    func didFinishDelete (){
        DispatchQueue.main.async {
            print("Deleted all records")
            self.spinner.stopAnimating()
            self.myTimer?.invalidate()
        }
    }
    func publishEventDelete(opcode:PulseOpCode, x count:Int, t per:TimeInterval) {
        switch opcode {
        case .moreData :
            self.downcounter.text = count == 0 ? "no more to delete" : "more data to delete anticipated"
        default:
            self.downcounter.text = "unknown opcode \(opcode)"
        }
    }
}
