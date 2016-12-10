/*
 
 LoadDocHelpViewController
 ckexplorer
 //
 Created by bill donner on 11/25/16.
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 
 */
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


