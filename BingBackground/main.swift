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
    println("Downloading JSON...")
    let data = NSData(contentsOfURL: NSURL(string: "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US")!)!
    return NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers, error: nil) as! NSDictionary
}

func getBackgroundURLBase() -> String {
    let jsonObject = downloadJSON()
    return "https://www.bing.com/" + ((jsonObject["images"] as! NSArray)[0]["urlbase"] as! String)
}

func websiteExists(url: String) -> Bool {
    let request = NSURLRequest(URL: NSURL(string: url)!)
    var response: NSURLResponse? = nil
    let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: nil) as NSData?
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
        println("Background for \(widthByHeight) found.")
        return potentialExtension
    }
    else {
        println("No background for \(widthByHeight) was found.")
        println("Using 1920x1080 instead.")
        return "_1920x1080.jpg"
    }
}

func downloadBackground(url : String) -> NSData {
    println("Downloading background...")
    return NSData(contentsOfURL: NSURL(string: url)!)!
}

func getBackgroundImagePath() -> String {
    let picturesDirectory = (NSSearchPathForDirectoriesInDomains(.PicturesDirectory, .UserDomainMask, true)[0] as! String)
    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
    let year = calendar?.component(.CalendarUnitYear, fromDate: NSDate())
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "M-d-yyyy"
    let saveDirectory = picturesDirectory + "/Bing Backgrounds" + "/\(year!)"
    
    let fileManager = NSFileManager.defaultManager()
    fileManager.createDirectoryAtPath(saveDirectory, withIntermediateDirectories: true, attributes: nil, error: nil)

    return saveDirectory + "/\(dateFormatter.stringFromDate(NSDate())).jpg"
}

func saveBackground(background : NSData) {
    println("Saving background...")
    background.writeToFile(getBackgroundImagePath(), atomically: true)
}

func setBackground() {
    println("Setting background...")
    let workspace = NSWorkspace.sharedWorkspace()
    let screen = NSScreen.mainScreen()!
    workspace.setDesktopImageURL(NSURL(fileURLWithPath: getBackgroundImagePath())!, forScreen: screen, options: nil, error: nil)
}

let urlBase = getBackgroundURLBase()
let background = downloadBackground(urlBase + getResolutionExtension(urlBase));
saveBackground(background)
setBackground()