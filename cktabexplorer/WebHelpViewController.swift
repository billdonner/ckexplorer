//
//  WebHelpViewController.swift
//  Re-Kaptionator
//
//  Created by bill donner on 8/17/16.
//  Copyright © 2016 Bill Donner/midnightrambler. All rights reserved.
//

import UIKit
 
 
final class LoadDocHelpViewController:UIViewController, UIWebViewDelegate,ModalOverCurrentContext  {
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    func rqst() -> URLRequest {
        let rpath = Bundle.main.path(
            forResource:"LoadDocFilesIntoSheetCheats",
            ofType: "html",
            inDirectory: "sshelp")!
        
        return URLRequest(url:URL(string: rpath )!)
    }
    
    @IBOutlet weak var webView: UIWebView!
    
    func dismisstapped (_ s:AnyObject) {dismiss(animated: true)}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.webView.delegate = self
        self.webView.loadRequest(rqst())
        self.webView.isOpaque = false
        self.webView.backgroundColor = .white
        addDismissButtonToViewController(self ,
                                         named:"DismissXBlack", #selector(self.dismisstapped))
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        let x = error as NSError
        IOSSpecialOps.blurt(self,title: "Network error code = \(x.code)",mess: error.localizedDescription)
    }
}


