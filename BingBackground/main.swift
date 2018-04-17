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
    
    let data = try! Data(contentsOf: URL(string: "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US")!)
    var json: NSDictionary? = nil
    
    do {
        json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? NSDictionary
    } catch let error as NSError {
        NSLog("\(error.localizedDescription)")
    }
    
    return json!
}

func getBackgroundURLBase() -> String {
    let jsonObject = downloadJSON()
    return "https://www.bing.com/" + ((((jsonObject["images"] as! NSArray)[0]) as! NSDictionary)["urlbase"] as! String)
}

func websiteExists(_ url: String) -> Bool {
    let request = URLRequest(url: URL(string: url)!)
    var response: URLResponse? = nil
    
    do {
        let data = try NSURLConnection.sendSynchronousRequest(request, returning: &response) as NSData?
        return ((data?.length)! > 256)
    } catch let error as NSError {
        NSLog("\(error.localizedDescription)")
    }
    return false
}

func getResolutionExtension(_ url: String) -> String {
    let screen = NSScreen.main!
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

func downloadBackground(_ url: String) -> Data {
    print("Downloading background...")
    return (try! Data(contentsOf: URL(string: url)!))
}

func getBackgroundImagePath() -> String {
    let picturesDirectory = NSSearchPathForDirectoriesInDomains(.picturesDirectory, .userDomainMask, true)[0]
    let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    let year = (calendar as NSCalendar?)?.component(.year, from: Date())
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "M-d-yyyy"
    let saveDirectory = picturesDirectory + "/Bing Backgrounds" + "/\(year!)"
    
    do {
        try FileManager.default.createDirectory(atPath: saveDirectory, withIntermediateDirectories: true, attributes: nil)
    } catch let error as NSError {
        NSLog("\(error.localizedDescription)")
    }

    return saveDirectory + "/\(dateFormatter.string(from: Date())).jpg"
}

func saveBackground(_ background: Data) {
    print("Saving background...")
    try? background.write(to: URL(fileURLWithPath: getBackgroundImagePath()), options: [.atomic])
}

func setBackground() {
    print("Setting background...")
    
    let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
    let applicationSupportDirectory = paths.first! as NSString?
    let dbPath = applicationSupportDirectory?.appendingPathComponent("Dock/desktoppicture.db")
    
    var db: OpaquePointer? = nil
    if sqlite3_open(dbPath, &db) == SQLITE_OK {
        if sqlite3_exec(db, "UPDATE DATA SET VALUE = ('\(getBackgroundImagePath())');", nil, nil, nil) == SQLITE_OK {
            let process = Process()
            process.launchPath = "/usr/bin/killall"
            process.arguments = ["Dock"]
            process.launch()
        } else {
            print(sqlite3_errmsg(db))
        }
    } else {
        print(sqlite3_errmsg(db))
    }
    sqlite3_close(db)
}

let urlBase = getBackgroundURLBase()
let background = downloadBackground(urlBase + getResolutionExtension(urlBase))
saveBackground(background)
setBackground()
