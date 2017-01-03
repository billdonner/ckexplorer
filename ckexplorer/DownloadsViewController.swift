/*
 
 DownloadsViewController.swift
 Created by bill donner on 11/23/16
 
 Copyright 2016 Bill Donner/aka MidnightRambler
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 
 */
import UIKit
import CloudKit

enum DownloadOpCode:Int  {
    case eventCountAndMs
    case initialCountAndTime
    case moreData
}

protocol DownloadProt:class {
    func didAddRogue(r:Rogue)
    func insertIntoCollection(_ indices:[Int])
    func publishEventDownload(opcode:DownloadOpCode,
                              x:Int,t:TimeInterval)
    func didSelectAsset(indexPath:IndexPath)
    func didFinishDownload ()
    var selectedCellIndexPath:IndexPath? {
        get set
    }
}


final class DownloadConduit: Conduit {
    
    weak var download_delegate: DownloadProt?
    
    fileprivate var upcount = 0
    fileprivate var allrecids :[CKRecordID] = []
    fileprivate var querystarttime : Date?
    fileprivate var allind :[Int] = []
    
    /// load whole records
    func getTheRecordsForDownload  (limit:Int,comp:@escaping ([CKRecordID])->()) {
        queryRecordsForDownload(limit:limit,forEachRecord:absorbWholeRecord) {[unowned self]  _ in
            comp(self.allrecids) }
    }
    
    
    func absorbWholeRecord (record: CKRecord) {
        
        allrecids.append(record.recordID)
        //  let name = record ["Name"]
        guard let imageAsset = record["CoverPhoto"] as? CKAsset
            else { return }
        var recordid : String
        if let rid = record["id"] as? String {
            recordid = rid
        } else {
            let crk = Gfuncs.intWithLeadingZeros(Int64(upcount+1), digits: 4)
            recordid = "\(crk)"
        }
        let rogue = Rogue(idx:upcount,
                          id:recordid , fileURL: imageAsset.fileURL)
        DispatchQueue.main.async {
            
            self.download_delegate?.didAddRogue(r: rogue)
        }
        allind.append(upcount) // keep track
        
        upcount += 1
        var netelapsedTime = TimeInterval()
        
        if let qs = querystarttime {
            netelapsedTime    = Date().timeIntervalSince(qs)
        }
        
        DispatchQueue.main.async {
            // might keep trak of what is updating and only reload those
            self.download_delegate?.insertIntoCollection(self.allind)
            self.download_delegate?.publishEventDownload (opcode: DownloadOpCode.eventCountAndMs,x: 1,t: Double(self.upcount)/netelapsedTime)
        }
    }
    
    /// aquire cloudkit records , in full form
    private func queryRecordsForDownload(limit:Int, forEachRecord: @escaping (CKRecord) -> (),finally:@escaping ([CKRecordID])->()) {
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: super.tableName, predicate: predicate)
        
        querystarttime = Date()
        let reclim = limit > 0 ? limit : CKQueryOperationMaximumResults
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.qualityOfService = .userInitiated
        queryOperation.resultsLimit = reclim // aha
        queryOperation.recordFetchedBlock = forEachRecord
        queryOperation.queryCompletionBlock = { cursor, error in
            guard error == nil else {
                print("!!!error CKQueryOperation queryRecordsForDownload \(error)")
                
                if let basevc = self.download_delegate as? UIViewController {
                    DispatchQueue.main.async {
                        IOSSpecialOps.blurt(basevc, title: "!!!CKQueryOperation cloudkit error", mess: "cloudkit \(error)")
                    }
                }
                return
            }
            if cursor != nil {
                DispatchQueue.main.async {
                    self.download_delegate?.publishEventDownload (opcode: DownloadOpCode.moreData,  x: 1,t: 0)
                    print("There is more data to fetch -- ")
                }
                self.fetchRecordsForDownload(cursor: cursor!,forEachRecord: forEachRecord)
            } else {
                // nothing more, signal the finally
                DispatchQueue.main.async {
                    finally(self.allrecids)
                }
            }
        }
        db.add(queryOperation)
    }
    
    /// recursive record fetcher
    fileprivate  func fetchRecordsForDownload(cursor: CKQueryCursor?, forEachRecord: @escaping (CKRecord) -> ()) {
        
        let queryOperation = CKQueryOperation(cursor: cursor!)
        queryOperation.qualityOfService = .userInitiated
        queryOperation.recordFetchedBlock = forEachRecord
        queryOperation.queryCompletionBlock = { cursor, error in
            guard error == nil else {
                print("!!!error CKQueryOperation fetchRecordsForDownload \(error)")
                
                if let basevc = self.download_delegate as? UIViewController {
                    DispatchQueue.main.async {
                        IOSSpecialOps.blurt(basevc, title: "!!!CKQueryOperation fetchRecordsForDownload error", mess: "cloudkit \(error)")
                    }
                }
                return
            }
            if cursor != nil {
                DispatchQueue.main.async {
                    self.download_delegate?.publishEventDownload(opcode: DownloadOpCode.moreData,x: self.allrecids.count,t: 0)
                    print("more data again for download \(self.allrecids.count) --")
                }
                self.fetchRecordsForDownload(cursor: cursor!,forEachRecord: forEachRecord)
            } else {
                DispatchQueue.main.async {
                    print("no more data \(self.allrecids.count)")
                    self.download_delegate?.didFinishDownload()
                }
            }
        }
        db.add(queryOperation)
    }
}

enum AssetType{
    case red
    case yellow
    case blue
    case green
    
    var description: String {
        switch self {
        case .red: return "Red Assets"
        case .yellow: return "Yellow Assets"
        case .blue: return "Blue Assets"
        case .green: return "Green Assets"
        }
    }
    
        var name: String {
            switch self {
            case .red: return "RedAssets"
            case .yellow: return "YellowAssets"
            case .blue: return "BlueAssets"
            case .green: return "GreenAssets"
            }
    }
}
//MARK :- ViewViewController Starts Here DownloadsViewController
final class DownloadsViewController: UIViewController {
    var showingAssetType: AssetType = .blue
    var assetsName : String = "????"
    var toggle:Bool = true
   
    @IBOutlet weak var outerSV: UIStackView! 
    @IBOutlet var inandoutSV: UIView!
    
    @IBAction func red(_ sender: Any) {
        redpushed(sender)
    }
    @IBAction func redpushed(_ sender: Any) {
        roguesGalleryView.backgroundColor = .red
        showingAssetType = .red
        tableName.text = showingAssetType.description
        assetsName = showingAssetType.name
        downloadConduit = DownloadConduit(containerID,tableName:assetsName)
         redo()
    }
    
    @IBAction func blue(_ sender: Any) {
        bluepushed(sender)
    }
    @IBAction func bluepushed(_ sender: Any) {
        roguesGalleryView.backgroundColor = .blue
        showingAssetType = .blue
        tableName.text = showingAssetType.description
        assetsName = showingAssetType.name
        downloadConduit = DownloadConduit(containerID,tableName:assetsName)
        redo()
    }
   
    @IBAction func green(_ sender: Any) {
        greenpushed(sender)
    }
    @IBAction func greenpushed(_ sender: Any) {
        roguesGalleryView.backgroundColor = .green
        showingAssetType = .green
        tableName.text = showingAssetType.description
        assetsName = showingAssetType.name
        downloadConduit = DownloadConduit(containerID,tableName:assetsName)
         redo()
    }
    @IBAction func yellow(_ sender: Any) {
        yellowpushed(sender)
    }
    
    @IBAction func yellowpushed(_ sender: Any) {
        roguesGalleryView.backgroundColor = .yellow
        showingAssetType =  .yellow
        tableName.text = showingAssetType.description
        assetsName = showingAssetType.name
        downloadConduit = DownloadConduit(containerID,tableName:assetsName)
         redo()
    }
    
    @IBAction func more(_ sender: Any) {
        morepushed(sender)
    }
    
    @IBAction func morepushed(_ sender: Any) {
        if toggle {
        
        roguesGalleryView.addSubview(inandoutSV)
            inandoutSV.center = roguesGalleryView.center
        } else {
            inandoutSV.removeFromSuperview()
        }
        toggle = !toggle
    }
    
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

    @IBOutlet weak var tableName: UILabel!
    @IBOutlet weak var clearButton: UIButton!
    @IBAction func cancel(_ sender: Any) {
        countUp = -1 // set the flag
        
        roguesGalleryView.setup(vc:self,pvc: self)
        roguesGalleryView.reloadData()
    }
    @IBAction func cancelTheTest(_ sender: Any) {
        
        countUp = -1 // set the flag
        
        roguesGalleryView.setup(vc:self,pvc: self)
        roguesGalleryView.reloadData()
  
    }
    
    
    //MARK: connection to Cloudkit for records
    fileprivate var downloadConduit = DownloadConduit(containerID,tableName:containerTableName)
    
    private var _currentValue: IndexPath? = nil
    internal var selectedCellIndexPath:IndexPath? { // used from rogues gallery
        get { return _currentValue }
        set { _currentValue = newValue }
        
    }
    
    fileprivate var firstload = true
    fileprivate var totalincoming = 0
    fileprivate var redoStartTime = Date()
    
    //MARK: repaint interface and start Download (again)
    private var countUp:Int = 0
    private var startTime = Date()
    
    fileprivate var myTimer: Timer? = nil
    
    func countUpTick() {
        countUp += 1
        
        if (countUp == 0) {
            myTimer!.invalidate()
            myTimer = nil
        }
        let netelapsedTime : TimeInterval = Date().timeIntervalSince(startTime)
        elapsedWallTime.text = "\(Gfuncs.prettyFloat(netelapsedTime,digits:1)) secs"
    }
    
    
    func redo() {
        myTimer?.invalidate()
        myTimer=nil
        
        // set repeating timer for UI updates
        countUp = 0
        startTime = Date()
        myTimer = Timer.scheduledTimer (timeInterval: 0.1, target: self, selector:#selector(DownloadsViewController.countUpTick), userInfo: nil, repeats: true)
        
        
        DispatchQueue.main.async {
            self.roguesGalleryView.resetRogue()
            self.firstload = true
            self.redoStartTime = Date()
            self.spinner.startAnimating() // starts on mainq
            self.refreshButton.isEnabled = false
            self.clearButton.isEnabled = false
            self.refreshButton.setTitle("...loading...", for: .normal)
            self.downTime.text = "...restarting..."
            self.downCount.text = "no items"
            self.moreDataIndicator.text = "......"
        }
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            self.downloadAllTest()//still working in back, will finish with delegate call on mainq
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = splashColor
        //self.navigationItem.title = "download from " + downloadConduit.tableName
        // pain the screen, including the image assets
    
        selectedCellIndexPath = IndexPath(row:0,section:0)
        roguesGalleryView.setup(vc:self,pvc: self)
        roguesGalleryView.backgroundColor = splashColor
        showingAssetType = .blue
        assetsName = showingAssetType.name
        tableName.text = downloadConduit.tableName//showingAssetType.description
        // on very first load auto-press
        redo()
    }
    /// get all the records
    func downloadAllTest( ) {
        let startTime = Date()
        totalincoming = 0
        downloadConduit.download_delegate = self
        let limit :Int = 0
//        switch segment.selectedSegmentIndex {
//        case 1: limit = 10
//        case 2: limit = 100
//        case 3: limit = 1000
//        default: limit = 0
//        }
        
        // kick off a bulky downlownload
        downloadConduit.getTheRecordsForDownload(limit: limit ){ recs in
            print ("downloadalltest finished with \(recs.count) items")
            self.spinner.stopAnimating() // starts on mainq
                self.clearButton.isEnabled = true
            self.refreshButton.isEnabled = true
            self.refreshButton.setTitle("add", for: .normal)
            self.downTime.text = "...done..."
            self.moreDataIndicator.text = "idle"
            self.myTimer?.invalidate()
            self.roguesGalleryView.reloadData()
        
        }
        
        let netelapsedTime : TimeInterval = Date().timeIntervalSince(startTime)
       // print ("downloadAllTest records started \(netelapsedTime)ms, still fetching")
        DispatchQueue.main.async {
            self.publishEventDownload(opcode: DownloadOpCode.initialCountAndTime,x: 0,t: netelapsedTime)
        }
    }
}


extension DownloadsViewController: DownloadProt {
    
    // must be on main thread
    
    
    func didSelectAsset(indexPath:IndexPath){
        selectedCellIndexPath = indexPath
        downTime.text = "(\(selectedCellIndexPath!.section),\(selectedCellIndexPath!.row)) "
        downTime.setNeedsDisplay() //
    }
    func didAddRogue(r:Rogue) {
        
        roguesGalleryView.addRogue(r: r)
        let indexPath = IndexPath(row: roguesGalleryView.roguesCount()-1, section: 0)
        DispatchQueue.main.async {
            self.didSelectAsset(indexPath: indexPath)
        }
    }
    func insertIntoCollection(_ indices:[Int]){
        if indices.count < 20 {
              self.roguesGalleryView.reloadData()
        }
    }
    func didFinishDownload () {
        moreDataIndicator.text = "idle"
        clearButton.isEnabled = true
        refreshButton.isEnabled = true
        refreshButton.setTitle("add more",for: .normal)
        spinner.stopAnimating()
        myTimer?.invalidate()
        roguesGalleryView.reloadData()
    }
    func publishEventDownload(opcode: DownloadOpCode, x count:Int, t mstime: TimeInterval) {
        switch opcode {
            
        case  .eventCountAndMs :
            totalincoming += count
            if let sel = selectedCellIndexPath {
            downTime.text = "(\(sel.section),\(sel.row)) "
            }//\(Gfuncs.prettyFloat(mstime,digits:3)) items/sec"
            downCount.text = "\(totalincoming):\(self.roguesGalleryView.roguesCount()) items"
            
        case  .initialCountAndTime :
            startupDelay.text = "\(Gfuncs.prettyFloat(mstime,digits:3))  warmup"
            downCount.text = "initially \(count) items"
            
        case .moreData :
            moreDataIndicator.text = count == 0 ? "no more" : "more data anticipated"
            //      if count == 0 {
            //        spinner.stopAnimating()
        //      }
       // default: fatalError("bad enum in download controller")
        }
        view.setNeedsDisplay()
    }
}
//        if roguesGalleryView.roguesCount() == 1 {
//            // if first, then select it
//            let cell = roguesGalleryView.cellForItem(at: indexPath)
//            cell?.layer.borderWidth = 5.0
//            cell?.layer.borderColor = UIColor.red.cgColor
//            roguesGalleryView.reloadData() // only one item
//        }
