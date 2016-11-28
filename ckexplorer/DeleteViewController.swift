/*
 
DeletesViewController.swift
 
Copyright 2016 Bill Donner/aka MidnightRambler

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 
 */


import UIKit 
import CloudKit

final class DeletesViewController: UIViewController,VisualProt {
  var samplesConduit = Conduit<SampleRecord>()
  
    @IBAction func deleteEm(_ sender: Any) {
        spinner.startAnimating()
        samplesConduit.delegate = self
        samplesConduit.deleteAllRecords(){
            print("Deleted all em records")
            self.spinner.stopAnimating()
            
    }

    }
    // must be on main thread
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    func didAddRogue(r:Rogue){}
    func didFinishDownload (){
        
        print("Deleted all records")
    }
    func didPublish(opcode:PulseOpCode, x up:Int, t per:TimeInterval) {
//        if opcode == .uploadCountAndMs {
//            self.timeper.text = "\(Gfuncs.prettyFloat(per,digits:3)) sec/item"
//            self.upnumber.text = "\(up) items"
//            self.view.setNeedsDisplay()
//            
       // }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
      print("DeletesViewController \(self)")
    }
}
