/*
 
 CloudCommon.swift
 Created by bill donner on 11/23/16
 
 Copyright 2016 Bill Donner/aka MidnightRambler
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 
 */
import Foundation
import CloudKit
import CoreLocation
public enum PulseOpCode:Int  {
  
  case uploadCountAndMs
  case eventCountAndMs
  case initialCountAndTime
  case moreData
}
protocol VisualProt:class {
  func didPublish(opcode:PulseOpCode, x:Int,t:TimeInterval)
  func didAddRogue(r:Rogue)
  func didFinishDownload ()
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
//MARK: - establishment docs

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
    self.name = record["Name"] as? String
  }
  var title: String? {
    return name
  }
}


//var inpulse : ((PulseOpCode,Int,TimeInterval)->())? // copy to global


class Conduit<T> {
  
  let container:CKContainer
  let db:CKDatabase
  let typeName = "\(T.self)s" // hacked s in for now
  
  weak var delegate: VisualProt?
  var allrecids :[CKRecordID] = []
  init() {
    container = CKContainer(identifier: "iCloud.com.midnightrambler.babifud")
    db = container.privateCloudDatabase
  }
  func getRecIds (comp:@escaping ([CKRecordID])->()) {
    queryRecords(forEachRecord:absorbRecordID) {[unowned self] _ in
      comp(self.allrecids) }
  }
  func getTheRecords  (comp:@escaping ([CKRecordID])->()) {
    queryRecords(forEachRecord:absorbWholeRecord) {[unowned self]  _ in
      comp(self.allrecids) }
  }
  private func queryRecords(forEachRecord: @escaping (CKRecord) -> (),finally:@escaping ([CKRecordID])->()) {
    let predicate = NSPredicate(value: true)
    let query = CKQuery(recordType: typeName, predicate: predicate)
    let queryOperation = CKQueryOperation(query: query)
    queryOperation.qualityOfService = .userInitiated
    queryOperation.recordFetchedBlock = forEachRecord
    queryOperation.queryCompletionBlock = { cursor, error in
      if cursor != nil {
        DispatchQueue.main.async {
          self.delegate?.didPublish(opcode: PulseOpCode.moreData,  x: 1,t: 0)
          print("There is more data to fetch -- ")
        }
        self.fetchRecords(cursor: cursor!,forEachRecord: forEachRecord)
      }
    }
    db.add(queryOperation)
  }
  
  fileprivate  func fetchRecords(cursor: CKQueryCursor?,
                                 forEachRecord: @escaping (CKRecord) -> ()) {
    
    let queryOperation = CKQueryOperation(cursor: cursor!)
    queryOperation.qualityOfService = .userInitiated
    queryOperation.recordFetchedBlock = forEachRecord
    queryOperation.queryCompletionBlock = { cursor, error in
      if cursor != nil {
        
        DispatchQueue.main.async {
          self.delegate?.didPublish(opcode: PulseOpCode.moreData,x: 1,t: 0)
          print("more data again --")
        }
        self.fetchRecords(cursor: cursor!,forEachRecord: forEachRecord)
      } else {
        DispatchQueue.main.async {
          self.delegate?.didPublish(opcode: PulseOpCode.moreData,x: 0,t: 0)
          print("no more data")
          self.delegate?.didFinishDownload()
        }
      }
    }
    db.add(queryOperation)
  }
  
  func deleteAllRecords(comp:@escaping ()->())
  {
    // fetch records from iCloud, get their recordID and then delete them
    self.getRecIds( ) { recordIDsArray in
      
      let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsArray)
      operation.modifyRecordsCompletionBlock = {
        (savedRecords: [CKRecord]?, deletedRecordIDs: [CKRecordID]?, error: Error?) in
        print("deleted all records \(deletedRecordIDs?.count)")
        comp()
      }
      
      self.db.add(operation)
    }
  }
  // here when we hve a spce
  // here when we hve a spce
  func absorbRecordID (record: CKRecord) {
    allrecids.append(record.recordID)
  }
  func absorbWholeRecord (record: CKRecord) {
    //  let name = record ["Name"]
    guard let imageAsset = record["CoverPhoto"] as? CKAsset
      else { return }
    var recordid : String
    if let rid = record["id"] as? String {
      recordid = rid
    }else {
      recordid = "\(Date())"
    }
    
    allrecids.append(record.recordID)
    let startTime = Date()
    do {
      let data = try Data(contentsOf:imageAsset.fileURL)
      let rogue = Rogue(id:recordid , fileURL: imageAsset.fileURL, fileData:data)
  DispatchQueue.main.async {
        self.delegate?.didAddRogue(r: rogue)
  }
    }
    catch {
      print ("Couldnt read imageasset from \(imageAsset.fileURL)")
    }
    
    let netelapsedTime    = Date().timeIntervalSince(startTime)*1000.0
    
    DispatchQueue.main.async {
      // print ("Did read imageasset from \(imageAsset.fileURL)")
      self.delegate?.didPublish(opcode: PulseOpCode.eventCountAndMs,x: 1,t: netelapsedTime)
    }
  }
  
  func uploadCKRecord (_ rec:CKRecord) {
    db.save(rec, completionHandler: { record, error in
      guard error == nil else {
        print("error setting up record \(error)")
        return
      }
    })
  }
}

