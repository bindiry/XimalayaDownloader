//
//  Utils.swift
//  XimalayaDownloader
//
//  Created by bindiry on 5/6/15.
//  Copyright (c) 2015 bindiry. All rights reserved.
//

import Foundation

class Utils {
    
    static let urlPrefix = "http://fdfs.xmcdn.com/"
    
    /** 获得声音的json地址 */
    static func getJsonUrl(soundId:String) -> String {
        return "http://www.ximalaya.com/tracks/\(soundId).json"
    }
    
}
