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
    
    init(p: CBPeripheral, r: NSNumber, a: [String : AnyObject]){
        peripheral = p
        rssi = r
        advertisementData = a
    }
}

