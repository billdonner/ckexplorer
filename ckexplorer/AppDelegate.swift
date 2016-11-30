//
//  AppDelegate.swift
//  ckexplorer
//
//  Created by bill donner on 11/25/16.
//  Copyright © 2016 midnightrambler. All rights reserved.
//

import UIKit

public struct IOSSpecialOps { // only compiles in main app - ios bug?
    
    public static func blurt (_ vc:UIViewController, title:String, mess:String, f:@escaping ()->()) {
        
        let action : UIAlertController = UIAlertController(title:title, message: mess, preferredStyle: .alert)
        
        action.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {alertAction in
            f()
        }))
        
        action.modalPresentationStyle = .popover
        let popPresenter = action.popoverPresentationController
        popPresenter?.sourceView = vc.view
        vc.present(action, animated: true , completion:nil)
    }
    public static func blurt (_ vc:UIViewController, title:String, mess:String) {
        blurt(vc,title:title,mess:mess,f:{})
    }
    public static func ask (_ vc:UIViewController, title:String, mess:String, f:@escaping ()->()) {
        
        let action : UIAlertController = UIAlertController(title:title, message: mess, preferredStyle: .alert)
        
        action.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {alertAction in
            
        }))
        action.addAction(UIAlertAction(title: "Delete", style: .default, handler: {alertAction in
            f()
        }))
        
        action.modalPresentationStyle = .popover
        let popPresenter = action.popoverPresentationController
        popPresenter?.sourceView = vc.view
        vc.present(action, animated: true , completion:nil)
    }
    public  static func ask (_ vc:UIViewController, title:String, mess:String) {
        ask(vc,title:title,mess:mess,f:{})
    }
}

extension UIViewController {
    
    public func animatedViewOf(frame:CGRect, size:CGSize, imageurl:String) -> UIWebView {
        let inset:CGFloat = 10
        let actualsize = min(size.width,size.height)
        let screensize = min( frame.width,frame.height)
        let imagesize = min(actualsize , screensize)
        let offs = (screensize - imagesize) / 2
        let frem = CGRect(x:offs+inset,
                          y:offs+inset,
                          width:imagesize-2*inset,
                          height:imagesize-2*inset)
        
        let html = "<html5> <meta name='viewport' content='width=device-width, maximum-scale=1.0' /><body  style='padding:0px;margin:0px'><img  src='\(imageurl)' height='\(frem.height)' width='\(frem.width)'  alt='\(imageurl)' /</body></html5>"
        let webViewOverlay = UIWebView(frame:frem)
        webViewOverlay.scalesPageToFit = true
        webViewOverlay.contentMode = .scaleToFill
        webViewOverlay.loadHTMLString(html, baseURL: nil)
        return webViewOverlay
    }
}

enum BackTheme {
    case white
    case black
}

/// choose white theme

let appTheme = Theme(.white)
struct Theme {
    
    var theme:BackTheme = .black  /// new
    
    let redColor = #colorLiteral(red: 0.7586702704, green: 0.2098190188, blue: 0.1745614707, alpha: 1)   // #b22222
    let blueColor = #colorLiteral(red: 0.2389388382, green: 0.5892125368, blue: 0.8818323016, alpha: 1)
    let catalogColor = UIColor.orange
    let stickerzColor = #colorLiteral(red: 0.7586702704, green: 0.2098190188, blue: 0.1745614707, alpha: 1)
    let iMessageColor = #colorLiteral(red: 0.2389388382, green: 0.5892125368, blue: 0.8818323016, alpha: 1)
    
    var backgroundColor:UIColor {
        switch theme {
        case .black : return .black
        case .white : return .white
        }
    }
    var textColor:UIColor {
        switch theme {
        case .black : return .white
        case .white : return .darkGray
        }
    }
    var textFieldColor:UIColor {
        switch theme {
        case .black : return .white
        case .white : return .darkGray
        }
    }
    var textFieldBackgroundColor:UIColor {
        switch theme {
        case .black : return .clear
        case .white : return .white
        }
    }
    var buttonTextColor:UIColor {
        switch theme {
        case .black : return .white
        case .white : return .white
        }
    }
    
    var statusBarStyle:UIStatusBarStyle {
        switch theme {
        case .black : return .lightContent
        case .white : return .default
        }
    }
    var altstatusBarStyle:UIStatusBarStyle {
        switch theme {
        case .black : return .default
        case .white : return .lightContent
        }
    }
    var dismissButtonImageName:String {
        switch theme {
        case .black : return "DismissXTransparent"
        case .white : return "DismissXBlack"
        }
    }
    var dismissButtonAltImageName:String {
        switch theme {
        case .white : return "DismissXTransparent"
        case .black : return "DismissXBlack"
        }
    }
    init(_ theme:BackTheme){
        self.theme = theme
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

