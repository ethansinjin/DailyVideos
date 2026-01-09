//
//  PlatformImage.swift
//  DailyVideos
//
//  Created by Ethan Gill on 1/8/26.
//

#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformImage = UIImage
#endif
