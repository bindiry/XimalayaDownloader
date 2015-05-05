//
//  Regex.swift
//  XimalayaDownloader
//
//  Created by bindiry on 5/5/15.
//  Copyright (c) 2015 bindiry. All rights reserved.
//

import Foundation

struct RegexHelper {
    let regex: NSRegularExpression?
    
    init(_ pattern: String) {
        var error: NSError?
        regex = NSRegularExpression(pattern: pattern,
            options: .CaseInsensitive,
            error: &error)
    }
    
    func match(input: String) -> Bool {
        if let matches = regex?.matchesInString(input,
            options: nil,
            range: NSMakeRange(0, count(input))) {
                return matches.count > 0
        } else {
            return false
        }
    }
}

infix operator =~ {
    associativity none
    precedence 130
}

func =~(lhs: String, rhs: String) -> Bool {
    return RegexHelper(rhs).match(lhs)
}