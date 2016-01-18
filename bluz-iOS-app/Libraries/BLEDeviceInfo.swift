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
    public var cloudName: NSString
    public var cloudId: NSString
    public var particleDevice: SparkDevice?
    public var isClaimed: Bool
    public var lastByteCount: Int
    
    public var writeCharacteristic: CBCharacteristic?
    
    init(p: CBPeripheral, r: NSNumber, a: [String : AnyObject]){
        isClaimed = false
        peripheral = p
        rssi = r
        advertisementData = a
        state = BLEDeviceState.Disconnected
        socket = ParticleSocket()
        writeCharacteristic = nil
        rxBuffer = NSMutableData()
        cloudName = ""
        cloudId = ""
        lastByteCount = 0
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
                if service.description == BLUZ_UUID {
                    return true
                }
            }
        }
        return false
    }
    
    func requestParticleId() {
        let nameBuffer = [0x02, 0x00] as [UInt8]
        sendParticleData(NSData(bytes: nameBuffer, length: nameBuffer.count), header: nil)
    }
    
    func particleSocketCallback(data: NSData, header: NSData) {
        sendParticleData(data, header: header)
    }
    
    func sendParticleData(data: NSData, header: NSData?) {

        let maxChunk = 960
        
        var writeType = CBCharacteristicWriteType.WithResponse
        if let prop = writeCharacteristic?.properties {
            if prop.contains(CBCharacteristicProperties.WriteWithoutResponse) {
                NSLog("Can write without response")
                writeType = CBCharacteristicWriteType.WithoutResponse
            }
        }
        
        for var chunkPointer = 0; chunkPointer < data.length; chunkPointer += maxChunk {
            var chunkLength = (data.length-chunkPointer > maxChunk ? maxChunk : data.length-chunkPointer)
            
            var chunk = NSMutableData()
            if let _ = header {
                chunk = NSMutableData(data: header!)
                chunk.appendData(data.subdataWithRange(NSMakeRange(chunkPointer, chunkLength)))
                chunkLength += (header?.length)!
            } else {
                chunk = NSMutableData(data: data.subdataWithRange(NSMakeRange(chunkPointer, chunkLength)))
            }
            
            for var i = 0; i < chunkLength; i+=20 {
                let size = (chunkLength-i > 20 ? 20 : chunkLength-i)
                
                let dataSlice = chunk.subdataWithRange(NSMakeRange(i, size))
                
                peripheral?.writeValue(dataSlice, forCharacteristic: writeCharacteristic!, type: writeType)
                NSLog("Sent data of size " + String(dataSlice.length) + " to bluz")
            }
            
            let eosBuffer = [0x03, 0x04] as [UInt8]
            let eos = NSData(bytes: eosBuffer, length: eosBuffer.count)
            peripheral?.writeValue(eos, forCharacteristic: writeCharacteristic!, type: writeType)
            NSLog("Sent eos to bluz")
            
        }
    }
}

