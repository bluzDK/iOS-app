//
//  BLEAdvPeripheralBundle.swift
//  bluz-iOS-app
//
//  Created by Eric Ely on 11/27/15.
//  Copyright © 2015 Eric Ely. All rights reserved.
//

import Foundation
import CoreBluetooth

public class BLEDeviceInfo: NSObject {
    public var peripheral: CBPeripheral?
    public var rssi: NSNumber = 0
    public var advertisementData: [String : AnyObject]
    public var connected: Bool
    
    init(p: CBPeripheral, r: NSNumber, a: [String : AnyObject]){
        peripheral = p
        rssi = r
        advertisementData = a
        connected = false
    }
    
    func numberOfServices() -> Int {
        if let _ = self.advertisementData.indexForKey("kCBAdvDataServiceUUIDs") {
            let servicesCount = self.advertisementData["kCBAdvDataServiceUUIDs"]?.count
            return servicesCount!
        }
        return 0
    }
    
    func isBluzCompatible() -> Bool {
        if let _ = self.advertisementData.indexForKey("kCBAdvDataServiceUUIDs") {
            let services: NSArray = self.advertisementData["kCBAdvDataServiceUUIDs"] as! NSArray
            for service in services {
                NSLog("Serivce " + service.description + " for device " + (self.peripheral?.name)!)
                if service.description == BLUZ_UUID {
                    return true
                }
            }
        }
        return false
    }
}

