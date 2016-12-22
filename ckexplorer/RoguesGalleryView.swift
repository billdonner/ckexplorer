/*
 
 RoguesGalleryView.swift
 Created by bill donner on 11/23/16
 
 Copyright 2016 Bill Donner/aka MidnightRambler
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 
 */

import UIKit

/// used in both the TVOS and IOS versions

// a self maintaining collection view

let originalCellSize = CGSize(width:225, height:354)
let focusCellSize = CGSize(width:240, height:380)

/// used in both the TVOS and IOS versions
/// push into here
fileprivate class ShowDetailsViewController : UIViewController{
    var text: String!
    var urlForImage: URL!
    
    func userdidcancel() {
       // let _ = self.navigationController?.popViewController(animated: true)
        self.presentingViewController?.dismiss(animated: true,
                                               completion: {
        })
    }
    
    fileprivate override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        self.view.setNeedsLayout()
    }
    fileprivate override func viewDidLoad() {
        super.viewDidLoad()
        //        guard let nav = self.navigationItem else {
        //            fatalError("must be in nav controller")
        //        }
        self.navigationItem.leftBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(ShowDetailsViewController.userdidcancel))
        let iv = UIImageView(frame:(self.view?.frame)!)
        do {
            let data = try Data(contentsOf: urlForImage)
            iv.image = UIImage(data:data)
            let tgr = UITapGestureRecognizer(target: self, action:#selector(ShowDetailsViewController.userdidcancel))
            iv.addGestureRecognizer(tgr)
            iv.isUserInteractionEnabled   = true
            self.view.addSubview(iv)
            
            let label = UILabel(frame:(self.view?.frame)!)
            label.text = self.text
            label.textColor = .blue
            self.view.addSubview(label)
        }
        catch {
        }
    }
}
struct Rogue {
    
    let idx: Int
    var id:String
    let fileURL:URL
    var fileData:Data?
    
    init(idx:Int,id:String,fileURL:URL,fileData:Data? = nil) {
        self.idx = idx
        self.id = id
        self.fileURL = fileURL
        self.fileData = fileData
    }
}
protocol RoguePro {
    func resetRogue()
    func addRogue(r:Rogue)
    func removeRogue(id:String)
}
extension UIViewController {  // where self is Modal...
    //dismissButtonAltImageName
    public func addDismissButtonToViewController(_ v:UIViewController,named:String, _ sel:Selector){
        let img = UIImage(named:named)
        let iv = UIImageView(image:img)
        iv.frame = CGRect(x:0,y:0,width:60,height:60)//// test
        iv.isUserInteractionEnabled = true
        iv.contentMode = .scaleAspectFit
        let tgr = UITapGestureRecognizer(target: v, action: sel)
        iv.addGestureRecognizer(tgr)
        v.view.addSubview(iv)
    }
}
extension UIImageView {
    func loadimageFromRogue(_ rogue: Rogue, onerror:   ((Error?)->())? ) {
        
        self.image = UIImage (named:"placeholderrogue")
        URLSession.shared.dataTask(with: rogue.fileURL, completionHandler: { (data, response, error) -> Void in
            
            if let error = error {
                onerror?(error)
                return
            }
            DispatchQueue.main.async(execute: { () -> Void in
                //rogue.fileData = data
                let image = UIImage(data: data!)
                self.image = image
            })
            
        }).resume()
    }
    public func loadimageFromURL(_ url: URL, onerror:   ((Error?)->())? ) {
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            
            if let error = error {
                onerror?(error)
                return
            }
            DispatchQueue.main.async(execute: { () -> Void in
                let image = UIImage(data: data!)
                self.image = image
            })
            
        }).resume()
    }
}
class RoguesGalleryViewCell:UICollectionViewCell {
    

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var idstring: UILabel!
    
    func configure(r:Rogue) {
        self.idstring.text = r.id
        self.imageView.loadimageFromRogue( r )
        { err in
            print("\(err)")
        }
        
    }
    override func prepareForReuse() {
        self.imageView.image = nil
        self.idstring.text = ""
        self.layer.borderWidth = 0.0
        self.layer.borderColor = UIColor.yellow.cgColor
    }
}
class RoguesGalleryView:UICollectionView {
    
    private var _currentpvc: UIViewController? = nil
    var parentvc:UIViewController? { // used from rogues gallery
        get { return _currentpvc }
        set { _currentpvc = newValue }
    }
    
    var downloadDelegate: DownloadProt!
    func roguesCount() -> Int {
        return rogues.count
    }
    fileprivate var rogues = [Rogue]()
    func setup(vc:UIViewController, pvc:DownloadProt) {
        self.parentvc = vc
        self.downloadDelegate = pvc
        self.dataSource = self
        self.delegate = self
        rogues = []
    }
}
extension RoguesGalleryView : UICollectionViewDelegate {
    override var preferredFocusEnvironments : [UIFocusEnvironment] {
        
        //condition
        return [self]
    }
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        return true
    }
    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return true //
    }
     func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        if let previousItem = context.previouslyFocusedView as? RoguesGalleryViewCell {
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                previousItem.imageView.frame.size =  originalCellSize
            })
        }
        if let nextItem = context.nextFocusedView as? RoguesGalleryViewCell {
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                nextItem.imageView.frame.size = focusCellSize
            })
        }
        
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        downloadDelegate?.selectedCellIndexPath = nil
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderWidth = 0.0
        cell?.layer.borderColor = UIColor.clear.cgColor
        }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let rogue = rogues[indexPath.item]
        
        // clear out the old cell
        let oldPath = downloadDelegate?.selectedCellIndexPath
        if let oldPath = oldPath {
            let oldCell = collectionView.cellForItem(at: oldPath)
            if let oldCell = oldCell {
                oldCell.layer.borderWidth = 0.0
                oldCell.layer.borderColor = UIColor.clear.cgColor
            }
        }
        // setup the new selected cell
        downloadDelegate?.selectedCellIndexPath = indexPath
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderWidth = 5.0
        cell?.layer.borderColor = UIColor.red.cgColor
        
        // 
        
        let vc = ShowDetailsViewController()
        vc.text = rogue.id
        vc.urlForImage = rogue.fileURL
        
        parentvc?.present(vc, animated: true, completion: nil)
        
    }
}
extension RoguesGalleryView:UICollectionViewDataSource{
    //MARK: UICollectionViewDataSource
    
    override var numberOfSections: Int {
        return 1
    }
    
//    @objc(numberOfSectionsInCollectionView:)
//    func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
    
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
        
        if indexPath == downloadDelegate?.selectedCellIndexPath {
            cell.layer.borderWidth = 5.0
            cell.layer.borderColor = UIColor.red.cgColor
        }
        
        return cell
    }
}
extension RoguesGalleryView : RoguePro {
    internal func resetRogue() {
        
    }
    
    func addRogue(r rogue:Rogue) {
        
        rogues.append(rogue)
        // put at front
        
        //rogues.insert(rogue, at: 0)
        
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
