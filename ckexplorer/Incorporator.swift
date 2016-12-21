/*
 
 Incorporator.swift
 
 
 Copyright 2016 Bill Donner/aka MidnightRambler
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 
 */

import UIKit

/**
 Executes the lefthand closure on a background thread and,
 upon completion, the righthand closure on the main thread.
 */
func doThis(
    _ dothis: @escaping () -> (),
    thenThat:@escaping () -> ())
{
    let _queue = DispatchQueue(label: "serial-worker")
    
    _queue.async {
        dothis()
        DispatchQueue.main.async(execute: {
            thenThat()
        })
    }
}


func timedClosure(_:String, closure:()->())->TimeInterval {
    let startTime = Date()
    closure()
    let elapsedTime : TimeInterval = Date().timeIntervalSince(startTime)
    return elapsedTime * 1000.0
}

public typealias FilePath = String
public typealias FilePaths = [FilePath]
public typealias selectorFunc = (String)->(Bool)

typealias compleet = (String,Int,Int,Int) -> ()

//MARK:- StorageModel is all that the Incorporator Sees
//
// can (and is) reworked for different apps
protocol StorageModel {
    /// where to expand zip files
    func tempDirectoryForZip()->String
    /// do the expansions
    func unzipFileAtPath(_ zipPath:String, toDestination: String)
    /// cleanup titles into legacy normalized form
    func normalizeTitle(_ title:String)->String
    ///  add a bunch of bits as a document
    func addDocumentWithBits(_ bits:AnyObject,title:String,type:String) -> (Bool,String,String)
    /// save the Corpus and other global structures
    func saveGorpus()
    /// save the Addeds
    func saveAddedsAndRecents()
}

extension StorageModel {
    func tempDirectoryForZip()->String {
        return NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0] as String + "/" + "tmp"
    }
    func normalizeTitle(_ title2:String)->String {
        //let title2  = Corpus.normalizeTitle(title)
        if title2.characters.count == 0 { //println ("path \(path) has no tag")
            return  ""}
        return title2
        
    }
    func unzipFileAtPath(_ zipPath:String, toDestination: String) {
        
        // ZipMain.unzipFile(atPath: zipPath, toDestination: FS.shared.TemporaryDirectory)
    }
    func addDocumentWithBits(_ bits:AnyObject,title:String,type:String) -> (Bool,String,String) {
        //return Corpus.addDocumentWithBits(bits as! Data,title:title,type:type)
        if bits is Data {
            
        }
        
        return (false,"","")
    }
    func saveGorpus() {
        
        //       Corpus.shared.save() // make it safe by writing (ugh) the entire hashtable thing
        //     Corpus.shared.buildSortedTable()
    }
    func saveAddedsAndRecents() {
        
        // Addeds.shared.save()
        //  Recents.shared.save()
    }
}


final class Incorporator:StorageModel {
    
    var dupes = 0
    var filesread = 0
    
    var gson = 0
    var csv = 0
    var zip = 0
    var deft = 0
    var read = 0
    
    var elaps: Double = 0.0
    var opages = 0
    var odupes = 0
    var ofilesread = 0
    
    class func pathsForPrefix(_ dirPath:String) -> FilePaths {
        var error:NSError?
        var paths:NSArray?
        do {
            paths = try FileManager.default.contentsOfDirectory(atPath: dirPath) as NSArray?
        } catch let error1 as NSError {
            error = error1
            paths = nil
        }
        var toProcess:FilePaths = []
        if (error != nil) { return toProcess }
        for path:Any in paths! {
            let spath = path as! String
            if !spath.hasPrefix("."){
                let fullpath:FilePath = dirPath + "/" + spath
                //do {
                toProcess.append(fullpath)
                
            }
        } // all paths
        return toProcess
    }
    /// each file in iTunes is duplicated N times based on slider val
    private func makeTempFileFrom(url:URL)  -> URL? {
        // copy into a safe random file
        let uuid = UUID().uuidString
        let last = url.pathExtension
        let newf =  "\(NSTemporaryDirectory())\(uuid).\(last)"
        let nurl = URL(fileURLWithPath: newf, isDirectory: false)
       // print ("copy from \(url) to \(nurl)")
        do {
            try  FileManager.default.copyItem(at: url, to: nurl)
        }
        catch {
            print("copy failed \(error)")
            return nil
        }
        return nurl
    }
    private func processIncomingFromPath(_ inboxPath:String,each:   @escaping ((URL,String)->())) {
        
        func iassimilate(_ path:String,todo:selectorFunc,  x: inout Int) {
            // delete the incoming if told to do so
            //var error:NSError?
            let toDelete = todo (path)
            if toDelete {
                x += 1
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch  _ as NSError {
                    //error = error1
                }
            }
        }
        
        func doFile(_ path:String) -> Bool {
            let nspath = path as NSString
            let r  = true
            autoreleasepool {
                var _:NSError?
                let part = (nspath.lastPathComponent as NSString).deletingPathExtension.components(separatedBy: "-")[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let normalTitle  = self.normalizeTitle(part)
                    // call per file completion
                
                
                let nurl =  makeTempFileFrom(url:URL(fileURLWithPath: path))
                if let nurl = nurl {
            DispatchQueue.main.async(execute: {
                        each(nurl,normalTitle)
                    })
                }
                
            } // autoreleasepool
            return r
        }
        
        
        gson = 0
        csv = 0
        zip = 0
        deft = 0
        
        let toProcess = Incorporator.pathsForPrefix(inboxPath)
        
        print("--------------------assimilating \(toProcess.count) documents from (\(inboxPath)) ---------")
        
        for fp in toProcess {
            let filepath = fp as NSString
            let filetitle:String = filepath.lastPathComponent
            if (!filetitle.hasPrefix(".")) { // skip any system files that dribble in
                let filetype:NSString = filepath.pathExtension as NSString // swift bug - must be NSString
                let lower:String = filetype.lowercased
                
                switch lower {
                default:
                    iassimilate(fp,todo: doFile,x: &deft)
                }
            }
        }
    }
    
    func assimilateInBackground(_ documentsPath:String, each: @escaping ((URL,String)->()), completion:@escaping compleet) -> Bool {
        
        doThis( {
            self.processIncomingFromPath(documentsPath, each: each)
        }
            , thenThat: {
                self.saveAddedsAndRecents()
                self.saveGorpus()
                
                completion ("Import Done",self.ofilesread,self.odupes,self.csv)
        })
        print ("--------------------grand total read: \(self.ofilesread) dupes: \(self.odupes) ")
        return true
    }
}

//////



func loadfromitunes(each:@escaping(URL,String)->(),finally:@escaping ()->()) {
    /// kick off background assimilation
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    let	assim = Incorporator()
    let _ = assim.assimilateInBackground(documentsPath,
            each: { url,label  in
                    each(url,label)
    }, completion: { label,read,dupes,csv in
                                            let fresh = read - dupes
                                            let blh = "added \(fresh) shared iTunes documents and \(csv) Configurations"
                                            print (blh)
                                            finally()
    })
}
