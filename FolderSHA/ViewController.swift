//
//  ViewController.swift
//  FolderSHA
//
//  Created by CHENWANFEI on 26/03/2018.
//  Copyright © 2018 swordfish. All rights reserved.
//

import Cocoa

extension NSTextView {
    func append(string: String) {
        self.textStorage?.append(NSAttributedString(string: string))
        self.scrollToEndOfDocument(nil)
    }
}

class ViewController: NSViewController {
    
    
    @IBOutlet weak var fileSelectionBtn: NSButton!
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var nodesTF: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func sha256(data : Data) -> Data {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(data.count), &hash)
        }
        return Data(bytes: hash)
    }
    
   
    
    
    private func isFolder(url:URL) -> Bool{
        var isDir : ObjCBool = false
       
        let fm = FileManager.default
        if fm.fileExists(atPath: url.path, isDirectory:&isDir) {
            return isDir.boolValue;
           
        } else {
            return false;
        }
    }
    
    
    private func handleSingleFile(url:URL){
        if let data = try? Data(contentsOf: url){
           
            
            var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
            data.withUnsafeBytes {
                _ = CC_SHA1($0, CC_LONG(data.count), &digest)
            }
            let hexBytes = digest.map { String(format: "%02hhx", $0) }
            let hexString = hexBytes.joined()
            
            let s = url.path + " => " + hexString + "\n";
            DispatchQueue.main.async { [weak self] in
                self?.textView.append(string: s);
              
            }
            
            
        }
    }
    
    private func handleFolder(url:URL){
        
        if isFolder(url: url) {
            if let urls = try?  FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles){
                for u in urls{
                    handleFolder(url:u);
                }
            }
            
        }else{
            handleSingleFile(url: url);
        }
        
    }

    @IBAction func onOpenFile(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a file/folder";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
    
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            if let result = dialog.url {
                self.nodesTF.stringValue = result.path;
                self.textView.string = "";
                self.view.window?.title = "Proccessing";
                self.fileSelectionBtn.isEnabled = false;
                
                DispatchQueue.global(qos: .background).async {[weak self] in
                    // Background Thread
                    self?.handleFolder(url: result);
                    DispatchQueue.main.async {
                        self?.view.window?.title = "Done";
                        self?.fileSelectionBtn.isEnabled = true;
                        // Run UI Updates or call completion block
                    }
                }
               
                
            }
           
           
           
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
}

