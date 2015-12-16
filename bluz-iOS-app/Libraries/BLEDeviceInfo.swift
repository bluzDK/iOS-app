//
//  BLEAdvPeripheralBundle.swift
//  bluz-iOS-app
//
//  Created by Eric Ely on 11/27/15.
//  Copyright © 2015 Eric Ely. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum BLEDeviceState {
    case Disconnected
    case BLEConnecting
    case CloudConnecting
    case Connected
}

public class BLEDeviceInfo: NSObject {
    
    public var peripheral: CBPeripheral?
    public var rssi: NSNumber = 0
    public var advertisementData: [String : AnyObject]
    public var state: BLEDeviceState
    public var socket: ParticleSocket?
    public var rxBuffer: NSMutableData
    public var writeCharacteristic: CBCharacteristic?
    
    init(p: CBPeripheral, r: NSNumber, a: [String : AnyObject]){
        peripheral = p
        rssi = r
        advertisementData = a
        state = BLEDeviceState.Disconnected
        socket = ParticleSocket()
        writeCharacteristic = nil
        rxBuffer = NSMutableData()
        super.init()
        
        self.socket!.registerCallback(particleSocketCallback)
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
    
    func particleSocketCallback(data: NSData, length: Int) {
        sendParticleData(data, length: length)
        let eosBuffer = [0x03, 0x04] as [UInt8]
        sendParticleData(NSData(bytes: eosBuffer, length: eosBuffer.count), length: eosBuffer.count)
    }
    
    func sendParticleData(data: NSData, length: Int) {
        for var i = 0; i < length; i+=20 {
            let size = (length-i > 20 ? 20 : length-i)
            
            let dataSlice = data.subdataWithRange(NSMakeRange(i, size))
            
            NSLog("Sneding data of size " + String(dataSlice.length) + " to bluz")
            peripheral?.writeValue(dataSlice, forCharacteristic: writeCharacteristic!, type: CBCharacteristicWriteType.WithResponse)
        }
    }
}

