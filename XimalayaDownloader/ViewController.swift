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

class ViewController: NSViewController {

    @IBOutlet weak var albumURL: NSTextField!
    @IBOutlet weak var labAlbumName: NSTextField!
    @IBOutlet weak var labCurrentSoundName: NSTextField!
    @IBOutlet var wvWebView: WebView!
    
    var parser:HTMLParser?
    var parserBodyNode:HTMLNode?
    var albumName:String = ""
    var currentSoundName:String = ""
    var didFinish:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.labAlbumName.stringValue = albumName
        self.labCurrentSoundName.stringValue = currentSoundName
        
        self.wvWebView.hidden = true
        self.wvWebView.frameLoadDelegate = self
    }

    @IBAction func textDidChange(sender: NSTextField) {
        var albumUrlValue = sender.stringValue + ".ajax"
        if var url = NSURL(string: albumUrlValue) {
            var request = NSURLRequest(URL: url)
            self.wvWebView.mainFrame.loadRequest(request)
        
        }
    }
    
    override func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        if self.didFinish == false {
            self.didFinish = true
            var htmlSource:String = self.wvWebView.stringByEvaluatingJavaScriptFromString("document.documentElement.outerHTML")
            
            println(htmlSource)
            // parse html
            var err:NSError?
            self.parser = HTMLParser(html: htmlSource, encoding: NSUTF8StringEncoding, error: &err)
            if err != nil {
                println(err)
                exit(1)
            }
            self.parserBodyNode = self.parser?.body
            // set album title
            println(self.parserBodyNode?.findChildTagAttr("div", attrName: "class", attrValue: "detailContent_title")?.contents)

        }
        
    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    extension String {
        func replace(target: String, withString: String) -> String {
            return self.stringByReplacingOccurrencesOfString(target, withString: withString, options: NSStringCompareOptions.LiteralSearch, range: nil)
        }
    }
}
