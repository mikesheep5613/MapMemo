//
//  UploadToStorage.swift
//  MapMemo
//
//  Created by MIKETSAI on 2021/7/31.
//

import Foundation
import Firebase

class UploadToStorage : NSObject {
    /// Singleton instance
    static let shared: UploadToStorage = UploadToStorage()
    
    /// Path
    let kFirFileStorageRef = Storage.storage().reference().child("images/")
    
    /// Current uploading task
    var currentUploadTask: StorageUploadTask?
    
    func upload(data: Data,
                withName fileName: String,
                block: @escaping (_ url: String?) -> Void) {
        
        // Create a reference to the file you want to upload
        let fileRef = kFirFileStorageRef.child(fileName)
        
        /// Start uploading
        upload(data: data, withName: fileName, atPath: fileRef) { (url) in
            block(url)
        }
    }
    
    func upload(data: Data,
                withName fileName: String,
                atPath path:StorageReference,
                block: @escaping (_ url: String?) -> Void) {
        
        // Upload the file to the path
        self.currentUploadTask = path.putData(data, metadata: nil) { (metaData, error) in
            guard let _ = metaData else {
                // Uh-oh, an error occurred!
                block(nil)
                return
            }
            // Metadata contains file metadata such as size, content-type.
            // let size = metadata.size
            // You can also access to download URL after upload.
            path.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    block(nil)
                    return
                }
                block(downloadURL.absoluteString)
            }
        }
    }
    
    func cancel() {
        self.currentUploadTask?.cancel()
    }
    
    
    
    
    
}
