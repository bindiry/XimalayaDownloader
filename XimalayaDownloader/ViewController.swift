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
    @IBOutlet weak var labAlbumName: NSTextField!
    @IBOutlet weak var labSoundCount: NSTextField!
    @IBOutlet weak var tabSoundList: NSTableView!
    @IBOutlet weak var wvWebView: WebView!
    
    var parser:HTMLParser?
    var parserBodyNode:HTMLNode?
    var didFinish:Bool = false
    var soundList:[XDSound] = []
    var soundDic = Dictionary<String, XDSound>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.labAlbumName.stringValue = ""
        self.labSoundCount.stringValue = ""
        
        self.wvWebView.hidden = true
        self.wvWebView.frameLoadDelegate = self
        
        self.tabSoundList.setDelegate(self)
        self.tabSoundList.setDataSource(self)
    }

    @IBAction func textDidChange(sender: NSTextField) {
        var albumUrlValue = sender.stringValue + ".ajax"
        if var url = NSURL(string: albumUrlValue) {
            self.didFinish = false
            self.soundList = []
            self.soundDic = [:]
            self.tabSoundList.reloadData()
            self.labAlbumName.stringValue = ""
            self.labSoundCount.stringValue = ""
            self.currentDownloadIndex = 0
            
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
        if columnIdentifier == "timesize" {
            result = xdSound.duration
        }
        return result
    }
    
    override func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        if self.didFinish == false {
            self.didFinish = true
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
            }
            // get sound list
            if let soundPath:[HTMLNode] = self.parserBodyNode?.xpath("//div[@class='album_soundlist ']//li") {
                for node in soundPath {
                    var soundTitle:HTMLNode = node.findChildTagAttr("a", attrName: "class", attrValue: "title")!
                    var xdSound = XDSound()
                    xdSound.id = node.getAttributeNamed("sound_id")
                    xdSound.title = soundTitle.contents
                    soundList.append(xdSound)
                    soundDic[xdSound.id] = xdSound
                }
                self.labSoundCount.stringValue = String(self.soundList.count)
            }
            tabSoundList.reloadData()
        }
        
    }

    var currentDownloadIndex:Int = 0;
    
    @IBAction func startDownload(sender: NSButton) {
        if self.currentDownloadIndex < self.soundList.count {
            downloading(self.soundList[self.currentDownloadIndex].id)
        }
        else {
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
                xdSound!.duration = String(Int(round(duration / 60)))
                println(xdSound?.url)
                println(xdSound?.duration)
                self.tabSoundList.reloadData()
                self.currentDownloadIndex++
        }
        
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
}
