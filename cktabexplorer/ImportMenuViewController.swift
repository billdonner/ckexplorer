/*
 
 ImportMenuViewController.swift
 ckexplorer
 //
 Created by bill donner on 11/25/16.
 
 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 
 */
import UIKit
protocol ModalOverCurrentContext {
    
}
protocol HelpDropdownDelegate : class {
    func refreshLayout()
}
final class ImportMenuViewController: UIViewController, ModalOverCurrentContext  , UINavigationControllerDelegate  {
    let supportedCloudUTIs =
        ["com.compuserve.gif",
         "public.png",
         "public.jpeg"]
    
    private var imagePicker = UIImagePickerController()
    
    weak var delegate: HelpDropdownDelegate?  // mig
 
    
    
    func dismisstapped(_ s: AnyObject) {
        delegate?.refreshLayout()
        dismiss(animated: true, completion: nil)
    }
    @IBAction func imageWasTapped(_ sender: Any) {
        // here we can do secret shit
        
        print("secret")
        
    }
        
    @IBAction func hitITunesAction(_ sender: AnyObject) {
        loadfromitunes(each:{
            url,title in
            print("Loaded \(title) via iTunes from \(url)")
        }) {
            //finally
            print("Done loading")
        }

    }
    
    
    @IBAction func hitICloud(_ sender: AnyObject) {
        let importMenu = UIDocumentPickerViewController(documentTypes:  supportedCloudUTIs, in: .import)
        importMenu.delegate = self
        present (importMenu, animated: true, completion: nil)
    }
    
    @IBAction func hitPhotoImport(_ sender: AnyObject) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        imagePicker.modalPresentationStyle = .formSheet
        imagePicker.modalTransitionStyle = .crossDissolve
        present (imagePicker, animated: true, completion: nil)
    }
    
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var hitITunes: UIButton!
    @IBOutlet weak var hitICloudButton: UIButton!
    @IBOutlet weak var hitWebHelpButton: UIButton!
    @IBOutlet weak var hitArtistsSiteButton: UIButton!
    @IBOutlet weak var hitPhotoImportButton: UIButton!

    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var subLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    
    
    //MARK: - Lifecycle
    
    override func didMove(toParentViewController parent: UIViewController?) {
        delegate?.refreshLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
         subLabel.text = // "Currently you have \(count) sticker" + s + 
        " in the Messages App"
        bodyLabel.text = //remcount != 1 ? "You have \(remcount) catalog entries as sources to make stickers" :
        
        "You have one catalog entry as a sticker source"
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
       
        
        
        addDismissButtonToViewController(self , named:appTheme.dismissButtonAltImageName,#selector(dismisstapped))
        
    }
}
//MARK: - UIDocumentPickerDelegate
extension ImportMenuViewController : UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("cancelled from doc picker")
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        print("picked new document at \(url)")
         //StickerAsset.quietlyAddNewURL(url,options:StickerOptions.generatemedium)
        self.dismisstapped(self)
    }
}
private extension ImportMenuViewController {
    //http://stackoverflow.com/questions/31314412/how-to-resize-image-in-swiftfunc
 func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
}
//MARK: - UIImagePickerControllerDelegate
extension ImportMenuViewController :UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let _ =  resizeImage(image: image,targetSize:(CGSize(width:618.0,height:618.0)))
            
       // turn this into a file wit a url
          // let url = StickerAssetSpace.writeImageToURL(newimage)
           // StickerAsset.quietlyAddNewURL(url,options:StickerOptions.generatelarge)
        }
        self.dismisstapped(self)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated:true, completion: nil)
    }

}
