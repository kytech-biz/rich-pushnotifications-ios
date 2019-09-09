//
//  NotificationViewController.swift
//  NotificationServiceCustom
//
//  Created by Ryuji Kawaida on 2019/09/07.
//  Copyright © 2019 KYTECH. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    let RICH_CONTENT_KEY = "rich"
    let user = "xxx"
    let password = "xxx"
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
        webView.delegate = self
    }
    
    func didReceive(_ notification: UNNotification) {
        guard let rich = notification.request.content.userInfo[RICH_CONTENT_KEY] as? [String: Any],
            let richString = rich["url"] as? String else {
                self.preferredContentSize = CGSize(width: UIScreen.main.bounds.size.width, height: 0)
                self.view.setNeedsUpdateConstraints()
                self.view.setNeedsLayout()
                self.activityIndicatorView.isHidden = true
                return
        }
        
        url = URL(string: richString)
        if let url = url {
            let request = URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalCacheData,
                timeoutInterval: 12
            )
            self.webView.loadRequest(request)
        }
        
        self.preferredContentSize = CGSize(width: self.view.frame.size.width, height: 47)
        self.view.setNeedsUpdateConstraints()
        self.view.setNeedsLayout()
        self.activityIndicatorView.isHidden = false
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.preferredContentSize = CGSize(width: self.view.frame.size.width, height: self.view.frame.size.width)
        self.view.setNeedsUpdateConstraints()
        self.view.setNeedsLayout()
        self.activityIndicatorView.isHidden = true
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        self.preferredContentSize = CGSize(width: self.view.frame.size.width, height: 0)
        self.view.setNeedsUpdateConstraints()
        self.view.setNeedsLayout()
        self.activityIndicatorView.isHidden = true
    }
}
