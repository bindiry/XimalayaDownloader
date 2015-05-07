//
//  ViewController.swift
//  XimalayaDownloader
//
//  Created by bindiry on 5/2/15.
//  Copyright (c) 2015 bindiry. All rights reserved.
//

import Cocoa
import Alamofire
import WebKit

extension String {
    func replace(target: String, withString: String) -> String {
        return self.stringByReplacingOccurrencesOfString(target, withString: withString, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
}

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var albumURL: NSTextField!
    @IBOutlet weak var btnParse: NSButton!
    @IBOutlet weak var labAlbumName: NSTextField!
    @IBOutlet weak var labSoundCount: NSTextField!
    @IBOutlet weak var tabSoundList: NSTableView!
    @IBOutlet weak var btnRemoveSelected: NSButton!
    @IBOutlet weak var btnClear: NSButton!
    @IBOutlet weak var btnStartDownload: NSButton!
    @IBOutlet weak var wvWebView: WebView!
    
    var parser:HTMLParser?
    var parserBodyNode:HTMLNode?
    var soundList:[XDSound] = []
    var soundDic = Dictionary<String, XDSound>()
    var albumDirectoryName:String?
    var currentDownloadIndex:Int = 0;
    var downloadedCount:Int = 0
    var didParseFinish:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.labAlbumName.stringValue = ""
        self.labSoundCount.stringValue = ""
        
        self.wvWebView.hidden = true
        self.wvWebView.frameLoadDelegate = self
        
        self.tabSoundList.setDelegate(self)
        self.tabSoundList.setDataSource(self)
    }
    
    func reset() {
        self.soundList = []
        self.soundDic = [:]
        self.tabSoundList.reloadData()
        self.labAlbumName.stringValue = ""
        self.labSoundCount.stringValue = ""
        self.currentDownloadIndex = 0
        self.downloadedCount = 0
        self.didParseFinish = false
    }
    
    @IBAction func parseUrl(sender: NSButton) {
        var albumUrlValue = self.albumURL.stringValue + ".ajax"
        if var url = NSURL(string: albumUrlValue) {
            self.reset()
            
            var request = NSURLRequest(URL: url)
            self.wvWebView.mainFrame.loadRequest(request)
        }
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.soundList.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        var result = ""
        var xdSound = self.soundList[row]
        var columnIdentifier = tableColumn?.identifier
        if columnIdentifier == "title" {
            result = xdSound.title
        }
        if columnIdentifier == "duration" {
            result = xdSound.duration
        }
        if columnIdentifier == "size" {
            result = xdSound.size
        }
        if columnIdentifier == "downloadPer" {
            result = xdSound.downloadPer == 0 ? "" : "\(xdSound.downloadPer)%"
        }
        return result
    }
    
    func tableView(tableView: NSTableView, shouldEditTableColumn tableColumn: NSTableColumn?, row: Int) -> Bool {
        return false
    }
    
    override func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        if self.didParseFinish {
            return
        }
        self.didParseFinish = true
        
        var htmlSource:String = self.wvWebView.stringByEvaluatingJavaScriptFromString("document.documentElement.outerHTML")
        htmlSource = htmlSource.replace("<article>", withString: "<div>")
        htmlSource = htmlSource.replace("</article>", withString: "</div>")
        htmlSource = htmlSource.replace("<canvas ", withString: "<div ")
        htmlSource = htmlSource.replace("</canvas>", withString: "</div>")
        // parse html
        var err:NSError?
        self.parser = HTMLParser(html: htmlSource, encoding: NSUTF8StringEncoding, error: &err)
        if err != nil {
            println(err)
            exit(1)
        }
        self.parserBodyNode = self.parser?.body
        // set album title
        if let xpath:[HTMLNode] = self.parserBodyNode?.xpath("//div[@class='detailContent_title']/h1") {
            for node in xpath {
                self.labAlbumName.stringValue = node.contents
            }
            self.albumDirectoryName = self.labAlbumName.stringValue
            // create album directory
            if let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DesktopDirectory, inDomains: .UserDomainMask)[0] as? NSURL {
                var folder = directoryURL.URLByAppendingPathComponent(self.albumDirectoryName!, isDirectory: true)
                let exist = NSFileManager.defaultManager().fileExistsAtPath(folder.path!)
                var error:NSErrorPointer = nil
                if !exist {
                    let createSuccess = NSFileManager.defaultManager().createDirectoryAtURL(folder, withIntermediateDirectories: true, attributes: nil, error: error)
                }
            }
            
        }
        // get sound list
        if let soundPath:[HTMLNode] = self.parserBodyNode?.xpath("//div[@class='album_soundlist ']//li") {
            var soundCounter = 0
            for node in soundPath {
                var soundTitle:HTMLNode = node.findChildTagAttr("a", attrName: "class", attrValue: "title")!
                var xdSound = XDSound()
                xdSound.id = node.getAttributeNamed("sound_id")
                xdSound.title = soundTitle.contents
                xdSound.index = soundCounter
                soundList.append(xdSound)
                soundDic[xdSound.id] = xdSound
                soundCounter++
            }
            self.updateSoundCount()
        }
        self.reloadDataInBackgroundThreads()
    }
    
    func updateSoundCount() {
        self.labSoundCount.stringValue = "\(self.downloadedCount)/\(self.soundList.count)"
    }
    
    @IBAction func removeSelected(sender: NSButton) {
        var xdSound = self.soundList.removeAtIndex(self.tabSoundList.selectedRow)
        self.soundDic.removeValueForKey(xdSound.id)
        self.updateSoundCount()
        self.reloadDataInBackgroundThreads()
    }
    
    @IBAction func removeAll(sender: NSButton) {
        self.reset()
        self.reloadDataInBackgroundThreads()
    }
    
    @IBAction func startDownload(sender: NSButton) {
        download()
        
        self.albumURL.enabled = false
        self.btnParse.enabled = false
        self.btnRemoveSelected.enabled = false
        self.btnClear.enabled = false
        self.btnStartDownload.enabled = false
    }
    
    func download() {
        if self.currentDownloadIndex < self.soundList.count {
            downloading(self.soundList[self.currentDownloadIndex].id)
        }
        else {
            // download complete
            self.albumURL.enabled = true
            self.btnParse.enabled = true
            self.btnRemoveSelected.enabled = true
            self.btnClear.enabled = true
            self.btnStartDownload.enabled = true
            
            var storyboard = NSStoryboard(name: "Main", bundle: nil)
            var completeView: NSViewController? = storyboard?.instantiateControllerWithIdentifier("completeView") as? NSViewController
            self.presentViewControllerAsSheet(completeView!)
        }
    }
    
    func downloading(soundId:String) {
        var jsonUrl = Utils.getJsonUrl(soundId)
        Alamofire.request(.GET, jsonUrl)
            .responseJSON { (_, _, jsonString, _) in
                let json = JSON(jsonString!)
                var soundId = json["id"].stringValue
                var xdSound = self.soundDic[soundId]
                xdSound!.url = Utils.urlPrefix + json["play_path"].stringValue
                var duration = (json["duration"].stringValue as NSString).doubleValue
                xdSound!.duration = NSString(format: "%.2f分", (duration / 60)) as String
                // start download mp3
                Alamofire.download(.GET, xdSound!.url, {(temporaryURL, response) in
                    if let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DesktopDirectory, inDomains: .UserDomainMask)[0] as? NSURL {
                        var albumPath:NSURL = directoryURL.URLByAppendingPathComponent(self.albumDirectoryName!, isDirectory: true)
                        return albumPath.URLByAppendingPathComponent("\(xdSound!.title).mp3")
                    }
                    return temporaryURL
                })
                    .progress { (bytesRead, totalBytesRead, totalBytesExpectedToRead) in
                        xdSound!.size = self.getSizeString(totalBytesExpectedToRead)
                        xdSound!.downloadPer = self.getDownloadPer(totalBytesRead, total: totalBytesExpectedToRead)
                        self.reloadDataInBackgroundThreads()
                    }
                    .response { (request, response, _, error) in
                        self.downloadedCount++
                        self.updateSoundCount()
                        self.currentDownloadIndex++
                        self.download()
                }
        }
    }
    
    func reloadDataInBackgroundThreads() {
        // reload data in background threads
        // https://thatthinginswift.com/background-threads/
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                self.tabSoundList.reloadData()
            }
        }
    }
    
    func getDownloadPer(current:Int64, total:Int64) -> Int {
        return Int(ceil(Double(current) / Double(total) * 100))
    }
    
    func getSizeString(total:Int64) -> String {
        var result = ""
        var totalSize = Double(total)
        if total > 1024 * 1024 {
            result = String(Int(round(totalSize / 1024 / 1024))) + "MB"
        }
        else {
            result = String(Int(round(totalSize / 1024))) + "KB"
        }
        return result
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
}
