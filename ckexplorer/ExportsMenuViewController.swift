//
//  ExportsMenuViewController.swift
//  ckexplorer
//
//  Created by bill donner on 12/22/16.
//  Copyright © 2016 midnightrambler. All rights reserved.
//

import UIKit

var ExportDirectory:String {
    return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String + "/" + "export"
}
final class ExportsMenuViewController: UIViewController {
    
    fileprivate var uploadConduit = UploadConduit(containerID,tableName:containerTableName)
    private func createDir(_ dir:String) {  // Private
        var error:NSError?
        if FileManager.default.fileExists(atPath: dir) == false {
            do {
                try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
            } catch let error1 as NSError {
                error = error1
            }
            if (error != nil) {
                //errln("Cant create dir \(dir) \(error)")
            }
            if FileManager.default.fileExists(atPath: dir) == false {
                print ("Cant create dir \(dir) failed on re-read")
            }
        } else {
            //print  ("cant create because Directory exists -> \(dir)")
        }
    }
    func exportOne(_ sourceURL:URL, docID:String,md5:String,title:String,type:String) {
        print("Exporting \(docID),\(md5) as \(title).\(type)")
        
        let fm = FileManager.default
      
            //let spath = Corpus.corpusFileName(x, type: type)
            let dpath = ExportDirectory + "/" + title + "." + type
            do{
                /// transform here
                
                try    fm.copyItem(atPath: sourceURL.absoluteString, toPath: dpath)
            }
            catch let error as NSError  {
                print ("Could Not Export error \(error)")
       
        }
    }
    
    
    @IBAction func exportSS(_ sender: Any) {
        print("exportPileOfScreenShots")
        var j = 0
        loadfromitunes(each : { url, name in
            j += 1
            self.exportOne(url, docID: "\(j)", md5: "\(j)", title: name, type: url.pathExtension)
           
        })
        {
            print("did exportPileOfScreenShots from itunes to cloudkit")
        }
    }
    
    @IBAction func expCloudKit(_ sender: Any) {

        print("exportPileToCloudKit")
        var j = 0
        loadfromitunes(each : { url, name in
                j += 1
                self.uploadConduit.uploadRecordPhotoAsset(
                    self.uploadConduit, url:url, idval:j,      placeName: name,
                    latitude: 37.4,
                    longitude: -122.03,
                    ratings: [])
            })
        {
            print("did exportPileToCloudKit from itunes to cloudkit")
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createDir(ExportDirectory)
    }
}
