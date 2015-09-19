//
//  main.swift
//  BingBackground
//
//  Created by Josue Espinosa on 8/19/15.
//  Copyright (c) 2015 Josue Espinosa. All rights reserved.
//

import Foundation
import AppKit

func downloadJSON() -> NSDictionary {
    print("Downloading JSON...")
    let data = NSData(contentsOfURL: NSURL(string: "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US")!)!
    var json : NSDictionary? = nil
    
    do {
        json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? NSDictionary
    } catch let error as NSError {
        NSLog("\(error.localizedDescription)")
    }
    
    return json!
}

func getBackgroundURLBase() -> String {
    let jsonObject = downloadJSON()
    return "https://www.bing.com/" + ((jsonObject["images"] as! NSArray)[0]["urlbase"] as! String)
}

func websiteExists(url: String) -> Bool {
    let request = NSURLRequest(URL: NSURL(string: url)!)
    var response: NSURLResponse? = nil
    
    do {
        try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response) as NSData?
    } catch let error as NSError {
        NSLog("\(error.localizedDescription)")
    }
    
    let httpResponse = response as! NSHTTPURLResponse
    return httpResponse.statusCode == 200
}

func getResolutionExtension(url: String) -> String {
    let screen = NSScreen.mainScreen()!
    let resolution = screen.visibleFrame
    var width = Int(resolution.width)
    var height = Int(resolution.height)
    
    if screen.backingScaleFactor > 1 {
        width *= 2
        height *= 2
    }
    
    let widthByHeight = "\(width)" + "x" + "\(height)"
    let potentialExtension = "_" + widthByHeight + ".jpg"
    
    if websiteExists(url + potentialExtension) {
        print("Background for \(widthByHeight) found.")
        return potentialExtension
    } else {
        print("No background for \(widthByHeight) was found.")
        print("Using 1920x1080 instead.")
        return "_1920x1080.jpg"
    }
}

func downloadBackground(url : String) -> NSData {
    print("Downloading background...")
    return NSData(contentsOfURL: NSURL(string: url)!)!
}

func getBackgroundImagePath() -> String {
    let picturesDirectory = NSSearchPathForDirectoriesInDomains(.PicturesDirectory, .UserDomainMask, true)[0]
    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
    let year = calendar?.component(.Year, fromDate: NSDate())
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "M-d-yyyy"
    let saveDirectory = picturesDirectory + "/Bing Backgrounds" + "/\(year!)"
    
    do {
        try NSFileManager.defaultManager().createDirectoryAtPath(saveDirectory, withIntermediateDirectories: true, attributes: nil)
    } catch let error as NSError {
        NSLog("\(error.localizedDescription)")
    }

    return saveDirectory + "/\(dateFormatter.stringFromDate(NSDate())).jpg"
}

func saveBackground(background : NSData) {
    print("Saving background...")
    background.writeToFile(getBackgroundImagePath(), atomically: true)
}

func setBackground() {
    print("Setting background...")
    let workspace = NSWorkspace.sharedWorkspace()
    let screen = NSScreen.mainScreen()!
    
    do {
        try workspace.setDesktopImageURL(NSURL(fileURLWithPath: getBackgroundImagePath()), forScreen: screen, options: [:])
    } catch let error as NSError {
        NSLog("\(error.localizedDescription)")
    }
    
}

let urlBase = getBackgroundURLBase()
let background = downloadBackground(urlBase + getResolutionExtension(urlBase))
saveBackground(background)
setBackground()