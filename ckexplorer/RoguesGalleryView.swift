/*

   RoguesGalleryView.swift
   Created by bill donner on 11/23/16
 
 Copyright 2016 Bill Donner/aka MidnightRambler
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 
 */

import UIKit

// a self maintaining collection view
struct Rogue {
  var id:String
  let fileURL:URL
  let fileData:Data
}
protocol RoguePro {
  func resetRogue()
  func addRogue(r:Rogue)
}

class RoguesGalleryViewCell:UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var idstring: UILabel!
    
  func configure(r:Rogue) {
   // print("configure cell id \(r.id)")
    self.imageView.image = UIImage(data: r.fileData)
  }
}
class RoguesGalleryView:UICollectionView {
 fileprivate var rogues = [Rogue]()
  func setup() {
    self.dataSource = self
    rogues = []
  }
}
extension RoguesGalleryView:UICollectionViewDataSource{
  //MARK: UICollectionViewDataSource
  
  @objc(numberOfSectionsInCollectionView:)
  func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return rogues.count
  }
  
  @objc(collectionView:cellForItemAtIndexPath:)
  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell  = self.dequeueReusableCell(withReuseIdentifier: "RoguesGalleryViewCell", for: indexPath  )
      as! RoguesGalleryViewCell // Create the cell from the storyboard cell
    let rogue = rogues[indexPath.item]
    cell.configure(r:rogue)
    return cell
   }
}
extension RoguesGalleryView : RoguePro {
  internal func resetRogue() {
    
  }

  func addRogue(r rogue:Rogue) {
    // put at front
    
    rogues.insert(rogue, at: 0)
    self.reloadData()
  }
  func removeRogue(id:String) {
    var idx = 0
    for rogue in rogues {
      if rogue.id == id {
        rogues.remove(at:idx)
        return
      }
      idx += 1
    }
  }
}
