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
import CloudKit
import CoreLocation

/// the PulseOpCode is used to send back signals
public enum PulseOpCode:Int  {
    case uploadCountAndMs
    case eventCountAndMs
    case initialCountAndTime
    case moreData
}

/// the viewcontrollers have associated callback class protocols which can be weak

protocol DownloadProt:class {
    func publishEventDownload(opcode:PulseOpCode, x:Int,t:TimeInterval)
    func didAddRogue(r:Rogue)
    func reloadRouges()
    func didFinishDownload ()
}

protocol DeleteProt : class {
    func didFinishDelete ()
    func publishEventDelete(opcode:PulseOpCode, x count:Int, t per:TimeInterval)
}
protocol UploadProt : class {
    func didFinishUpload()
    func publishEventUpload(opcode:PulseOpCode, x count:Int, t per:TimeInterval)
}
// global funcs

struct Gfuncs {
    static func intWithLeadingZeros (_ thing:Int64,digits:Int) -> String {
        return String(format:"%0\(digits)lu", (thing) )
    }
    
    static func prettyFloat (_ t:TimeInterval,digits:Int=2) -> String  {
        return String(format:"%0.\(digits)f", (t) )
    }
}
//MARK: - SampleRecord docs

final class SampleRecord: NSObject  {
    // MARK: - Properties
    var record: CKRecord!
    var name: String!
    weak var database: CKDatabase!
    var assetCount = 0
    
    // MARK: - Initializers
    init(record: CKRecord, database: CKDatabase) {
        self.record = record
        self.database = database
        self.name = record["Name"] as! String
    }
    var title: String? {
        return name
    }
}


//MARK: - Conduit gathers all operations against one particular set of Record Types T

/// generic parameter is only used for the type of record passed to CKRecord

var upcount = 0

final class Conduit<T> {    let container:CKContainer
    let db:CKDatabase
    let typeName = "\(T.self)s" // hacked s in for now
    
    
    weak var delete_delegate: DeleteProt?
    
    weak var upload_delegate: UploadProt?
    
    weak var download_delegate: DownloadProt?
    
    fileprivate var  allrecids :[CKRecordID] = []
    
    fileprivate var querystarttime : Date?
    
    init() {
        container = CKContainer(identifier: "iCloud.com.midnightrambler.ckexplorer")
        db = container.privateCloudDatabase
    }
    /// load whole records
    func getTheRecordsForDownload  (comp:@escaping ([CKRecordID])->()) {
        queryRecordsForDownload(forEachRecord:absorbWholeRecord) {[unowned self]  _ in
            comp(self.allrecids) }
    }
    
    /// gather the records IDs only
    func getRecIdsForDelete (comp:@escaping ([CKRecordID])->()) {
        queryRecordsForDelete(forEachRecord:absorbRecordID) {[unowned self] _ in
            comp(self.allrecids) }
    }
    
    
    /// aquire cloudkit records , in full form
    private func queryRecordsForDownload(forEachRecord: @escaping (CKRecord) -> (),finally:@escaping ([CKRecordID])->()) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: typeName, predicate: predicate)
        querystarttime = Date()
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.qualityOfService = .userInitiated
        queryOperation.recordFetchedBlock = forEachRecord
        queryOperation.queryCompletionBlock = { cursor, error in
            if cursor != nil {
                DispatchQueue.main.async {
                    self.delete_delegate?.publishEventDelete (opcode: PulseOpCode.moreData,  x: 1,t: 0)
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
    fileprivate  func fetchRecordsForDownload(cursor: CKQueryCursor?,
                                            forEachRecord: @escaping (CKRecord) -> ()) {
        
        let queryOperation = CKQueryOperation(cursor: cursor!)
        queryOperation.qualityOfService = .userInitiated
        queryOperation.recordFetchedBlock = forEachRecord
        queryOperation.queryCompletionBlock = { cursor, error in
            if cursor != nil {
                DispatchQueue.main.async {
                    self.download_delegate?.publishEventDownload(opcode: PulseOpCode.moreData,x: self.allrecids.count,t: 0)
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
  
    
    /// aquire cloudkit record ids , in format for deleting
    private func queryRecordsForDelete(forEachRecord: @escaping (CKRecord) -> (),finally:@escaping ([CKRecordID])->()) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: typeName, predicate: predicate)
        querystarttime = Date()
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.qualityOfService = .userInitiated
        queryOperation.recordFetchedBlock = forEachRecord
        queryOperation.queryCompletionBlock = { cursor, error in
            if cursor != nil {
                DispatchQueue.main.async {
                    self.delete_delegate?.publishEventDelete (opcode: PulseOpCode.moreData,  x: 1,t: 0)
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
            if cursor != nil {
                
                DispatchQueue.main.async {
                    self.delete_delegate?.publishEventDelete(opcode: PulseOpCode.moreData,x:self.allrecids.count,t: 0)
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
            let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsArray)
            
            operation.modifyRecordsCompletionBlock = {
                (savedRecords: [CKRecord]?, deletedRecordIDs: [CKRecordID]?, error: Error?) in
                print("deleted all \(recordIDsArray.count) records \(deletedRecordIDs?.count)")
                comp(recordIDsArray.count)
            }
            
            self.db.add(operation)
        }
    }
    
    /// callback - just accumulate recordids for delete
    func absorbRecordID (record: CKRecord) {
        allrecids.append(record.recordID)
    }
    /// callback - get the whole record integrated into Rogue structure
    
    func absorbWholeRecord (record: CKRecord) {
       
        allrecids.append(record.recordID)
        //  let name = record ["Name"]
        guard let imageAsset = record["CoverPhoto"] as? CKAsset
            else { return }
        var recordid : String
        if let rid = record["id"] as? String {
            recordid = rid
        } else {
            let crk = Gfuncs.intWithLeadingZeros(Int64(upcount), digits: 4)
            recordid = "\(crk)"
        }
        upcount += 1
            let rogue = Rogue(id:recordid , fileURL: imageAsset.fileURL) //, fileData:data)
            DispatchQueue.main.async {
                self.download_delegate?.didAddRogue(r: rogue)
            }
        var netelapsedTime = TimeInterval()
        
        if let qs = self.querystarttime {
         netelapsedTime    = Date().timeIntervalSince(qs)
        }
        
        DispatchQueue.main.async {
            self.download_delegate?.reloadRouges()
            self.download_delegate?.publishEventDownload (opcode: PulseOpCode.eventCountAndMs,x: 1,t: netelapsedTime)
        }
    }
    
    /// save record to cloudkit
    func uploadCKRecord (_ rec:CKRecord) {
        db.save(rec, completionHandler: { record, error in
            guard error == nil else {
                print("error setting up record \(error)")
                return
            }
        })
    }
}

