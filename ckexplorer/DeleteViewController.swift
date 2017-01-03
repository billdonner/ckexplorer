/*
 
 DeletesViewController.swift
 
 Copyright 2016 Bill Donner/aka MidnightRambler
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 
 */


import UIKit
import CloudKit


protocol DeleteProt : class {
    func didFinishDelete ()
    func publishEventDelete(opcode:DeleteOpCode, x count:Int, t per:TimeInterval)
}
public enum DeleteOpCode:Int  {
    case moreData
}
final class DeleteConduit:Conduit {
  
    
    weak var delete_delegate: DeleteProt?
    
    
    fileprivate var  allrecids :[CKRecordID] = []
    
    fileprivate var querystarttime : Date?
 
    /// gather the records IDs only
    func getRecIdsForDelete (comp:@escaping ([CKRecordID])->()) {
        allrecids = []
        queryRecordsForDelete(forEachRecord:absorbRecordID) {[unowned self] _ in
            comp(self.allrecids) }
    }
    
    /// aquire cloudkit record ids , in format for deleting
    private func queryRecordsForDelete(forEachRecord: @escaping (CKRecord) -> (),finally:@escaping ([CKRecordID])->()) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: containerTableName, predicate: predicate)
        querystarttime = Date()
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.qualityOfService = .userInitiated
        queryOperation.recordFetchedBlock = forEachRecord
        queryOperation.queryCompletionBlock = { cursor, error in
            guard error == nil else {
                print("!!!error CKQueryOperation queryRecordsForDelete \(error)")
                
                if let basevc = self.delete_delegate as? UIViewController {
                    DispatchQueue.main.async {
                        
                        IOSSpecialOps.blurt(basevc, title: "!!!CKQueryOperation queryRecordsForDelete error", mess: "cloudkit \(error)")
                    }
                }
                return
            }
            if cursor != nil {
                DispatchQueue.main.async {
                    self.delete_delegate?.publishEventDelete (opcode: DeleteOpCode.moreData,  x: 1,t: 0)
                    print("There is more data to fetch -- ")
                }
                self.fetchRecordsForDelete(cursor: cursor!,forEachRecord: forEachRecord,finally:finally)
            } else {
                // nothing more, signal the finally
                DispatchQueue.main.async {
                    finally(self.allrecids)
                }
            }
        }
        db.add(queryOperation)
    }
    
    /// internal, recursive records fetcher
    fileprivate  func fetchRecordsForDelete(cursor: CKQueryCursor?,
                                            forEachRecord: @escaping (CKRecord) -> (),
                                            finally:@escaping ([CKRecordID])->()) {
        
        let queryOperation = CKQueryOperation(cursor: cursor!)
        queryOperation.qualityOfService = .userInitiated
        queryOperation.recordFetchedBlock = forEachRecord
        queryOperation.queryCompletionBlock = { cursor, error in
            guard error == nil else {
                print("!!!error CKQueryOperation fetchRecordsForDelete \(error)")
                
                if let basevc = self.delete_delegate as? UIViewController {
                    DispatchQueue.main.async {
                        
                        IOSSpecialOps.blurt(basevc, title: "!!!CKQueryOperation fetchRecordsForDelete error", mess: "cloudkit \(error)")
                    }
                }
                return
            }
            if cursor != nil {
                
                DispatchQueue.main.async {
                    self.delete_delegate?.publishEventDelete(opcode: DeleteOpCode.moreData,x:self.allrecids.count,t: 0)
                    print("more data again for deleting \(self.allrecids.count)--")
                }
                self.fetchRecordsForDelete(cursor: cursor!,forEachRecord: forEachRecord,finally:finally)
            } else {
                DispatchQueue.main.async {
                    finally(self.allrecids)
                    
                    print("no more data \(self.allrecids.count)")
                    self.delete_delegate?.didFinishDelete()
                }
            }
        }
        db.add(queryOperation)
    }
    
    
    /// fetch records from iCloud, get their recordID and then delete them
    func deleteAllRecords(comp:@escaping (Int)->())
    {
        self.getRecIdsForDelete( ) { recordIDsArray in
            
            print("will delete all \(recordIDsArray.count) records  ")
            
            if let basevc = self.delete_delegate as? UIViewController {
                IOSSpecialOps.ask(basevc, title: "Do you really want to delete  \(recordIDsArray.count) records", mess: "this can never be undone ") {
                    
                    let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsArray)
                    
                    operation.modifyRecordsCompletionBlock = {
                        (savedRecords: [CKRecord]?, deletedRecordIDs: [CKRecordID]?, error: Error?) in
                        guard error == nil else {
                            print("!!!error CKModifyRecordsOperation deleteAllRecords \(error)")
                            
                            DispatchQueue.main.async {                             IOSSpecialOps.blurt(basevc, title: "!!!CKModifyRecordsOperation deleteAllRecords error", mess: "cloudkit \(error)")
                            }
                            return
                        } // end guard fail
                        
                        print("deleted all \(recordIDsArray.count) records \(deletedRecordIDs?.count)")
                        comp(recordIDsArray.count)
                    }// set modifyRecordsCompletionBlock
                    self.db.add(operation)
                }  //ask is true
            }// basevc
        }// getRecIdsForDelete
    }// end of deleteallrecords
    
    
    
    /// callback - just accumulate recordids for delete
    func absorbRecordID (record: CKRecord) {
        allrecids.append(record.recordID)
    }
}

final class DeletesViewController: UIViewController  {
    
    var deleteConduit = DeleteConduit(containerID,tableName:containerTableName)
    
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
        deleteConduit.delete_delegate = self
        deleteConduit.deleteAllRecords(){ deletecount  in
            print("Deleted \(deletecount) records")
            DispatchQueue.main.async {
                self.downcounter.text = "Deleted \(deletecount) records"
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
        
        self.navigationItem.title = "delete from " + titleName
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
    func publishEventDelete(opcode:DeleteOpCode, x count:Int, t per:TimeInterval) {
        switch opcode {
        case .moreData :
            self.downcounter.text = count == 0 ? "no more to delete" : "more data to delete anticipated"
            //default:
            //  self.downcounter.text = "unknown opcode \(opcode)"
        }
    }
}
