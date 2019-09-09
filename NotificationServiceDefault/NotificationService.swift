//
//  NotificationService.swift
//  NotificationServiceDefault
//
//  Created by Ryuji Kawaida on 2019/09/07.
//  Copyright © 2019 KYTECH. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    enum Category: String {
        case image = "image"
        case video = "video"
        case normal = "normal"
        
        init(value: String) {
            switch value {
            case "image":
                self = .image
            case "video":
                self = .video
            default:
                self = .normal
            }
        }
    }
    
    let RICH_CONTENT_KEY = "rich"
    
    func exitNormal(_ reason: String = "", request: UNNotificationRequest, contentHandler: @escaping (UNNotificationContent) -> Void) {
        
        let bca = request.content.mutableCopy() as? UNMutableNotificationContent
        
        contentHandler(bca!)
    }
    
    func verifyUrlAttachment(url: URL, category: Category) -> URL? {
        switch category {
        case .image:
            let ext = url.pathExtension.lowercased()
            if (ext == "jpg" || ext == "jpeg" || ext == "gif" || ext == "png") { return url }
        case .video:
            let ext = url.pathExtension.lowercased()
            if (ext == "mpg" || ext == "mpeg" || ext == "mpeg2" || ext == "mp4" || ext == "avi") { return url }
        default:
            return nil
        }
        
        return nil
    }
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        guard let bestAttemptContent = bestAttemptContent else { return }
        
        // Get rich url
        guard let rich = request.content.userInfo[RICH_CONTENT_KEY] as? [String: Any], let richString = rich["url"] as? String else {
            // Show notification
            return exitNormal(request: request, contentHandler: contentHandler)
        }
        
        // Get category
        let category = Category(value: request.content.categoryIdentifier)
        
        // Instance URL
        guard let richUrl = URL(string: richString) else {
            // Show notification
            return exitNormal(request: request, contentHandler: contentHandler)
        }
        
        // Check attachment type and url
        guard let urlAttachment = verifyUrlAttachment(url: richUrl, category: category) else {
            // Show notification
            return exitNormal(request: request, contentHandler: contentHandler)
        }
        
        // Download attachment
        let task = URLSession.shared.downloadTask(with: urlAttachment) {
            downloadUrl, response, error in
            
            // Check download success
            guard let downloadUrl = downloadUrl else {
                // Show notification
                self.exitNormal(request: request, contentHandler: contentHandler)
                return
            }
            
            // Stored attachment
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            var url = URL(fileURLWithPath: path)
            url = url.appendingPathComponent("\(category.rawValue).\(richUrl.pathExtension)")
            
            try? FileManager.default.moveItem(at: downloadUrl, to: url)
            
            do {
                // Prepare notification attachment
                let attachment = try UNNotificationAttachment(identifier: category.rawValue,url: url, options: nil)
                bestAttemptContent.attachments = [attachment]
                
                // Show notification
                contentHandler(bestAttemptContent)
            } catch {
                // Show notification
                self.exitNormal(request: request, contentHandler: contentHandler)
            }
        }
        
        task.resume()
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
