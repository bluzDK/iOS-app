//
//  BLELister.swift
//  bluz-iOS-app
//
//  Created by Eric Ely on 11/27/15.
//  Copyright © 2015 Eric Ely. All rights reserved.
//

import Foundation
import CoreBluetooth

let BLUZ_UUID = "871E0223-38FF-77B1-ED41-9FB3AA142DB2"
let BLUZ_CHAR_RX_UUID = "871E0224-38FF-77B1-ED41-9FB3AA142DB2"
let BLUZ_CHAR_TX_UUID = "871E0225-38FF-77B1-ED41-9FB3AA142DB2"

public class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager?
    public var peripherals = [NSUUID: BLEDeviceInfo]()
    var eventCallback: ((BLEManagerEvent, BLEDeviceInfo) -> (Void))?
    var startScanOnPowerup: Bool?
    var discoverOnlyBluz: Bool?
    var lastService: UInt8
    
    enum BLEManagerEvent {
        case DeviceDiscovered
        case DeviceUpdated
        case DeviceConnected
        case DeviceDisconnected
        case BLERadioChange
    }

    override init(){
        lastService = 0
        super.init()
        discoverOnlyBluz = false
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let val = defaults.objectForKey("discoverOnlyBluz")

        if val != nil {
            discoverOnlyBluz = val as! Bool
        }
        startScanOnPowerup = false
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func registerCallback(callback: (result: BLEManagerEvent, peripheral: BLEDeviceInfo) -> Void) {
        eventCallback = callback
    }
    
    func startScanning() {
        if let _ = centralManager {
            if (centralManager!.state == CBCentralManagerState.PoweredOn) {
                centralManager!.scanForPeripheralsWithServices(nil, options: nil)
            } else {
                startScanOnPowerup = true
            }
        }
    }
    
    func stopScanning() {
        if let _ = centralManager {
            centralManager?.stopScan()
        }
    }
    
    func clearScanResults() {
//        peripherals.removeAll()
        
        for (uuid, dev) in peripherals {
            if dev.state != BLEDeviceState.Connected {
                peripherals.removeValueForKey(uuid)
            }
        }

    }
    
    func peripheralCount() -> Int {
        return peripherals.count
    }
    
    func peripheralAtIndex(index: Int) -> BLEDeviceInfo? {
        let peripheralIndex = peripherals.startIndex.advancedBy(index)
        let peripheralKey = peripherals.keys[peripheralIndex]
        
        return peripherals[peripheralKey]
    }
    
    func indexOfPeripheral(peripheral: BLEDeviceInfo) -> Int? {
        if let index = peripherals.keys.indexOf((peripheral.peripheral?.identifier)!) {
            return peripherals.count - index.distanceTo(peripherals.endIndex)
        }
        return nil
    }
    
    //peripheral commands
    func connectPeripheral(peripheral: BLEDeviceInfo) {
        peripheral.state = BLEDeviceState.BLEConnecting
        centralManager!.connectPeripheral(peripheral.peripheral!, options: nil)
    }
    
    func disconnectPeripheral(peripheral: BLEDeviceInfo) {
        centralManager!.cancelPeripheralConnection(peripheral.peripheral!)
    }
    
    
    //delegate methods
    public func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        if let _ = peripherals.indexForKey(peripheral.identifier) {
            //TO DO: update the objecta advertisiment data and RSSI
            peripherals[peripheral.identifier]?.advertisementData = advertisementData
            peripherals[peripheral.identifier]?.rssi = RSSI
            eventCallback!(BLEManagerEvent.DeviceUpdated, peripherals[peripheral.identifier]!)
        } else {
            let dIno = BLEDeviceInfo(p: peripheral, r: RSSI, a: advertisementData)
            if self.discoverOnlyBluz == true && dIno.isBluzCompatible() {
                peripherals[peripheral.identifier] = dIno
                eventCallback!(BLEManagerEvent.DeviceDiscovered, dIno)
            } else if self.discoverOnlyBluz == false {
                peripherals[peripheral.identifier] = dIno
                eventCallback!(BLEManagerEvent.DeviceDiscovered, dIno)
            }
        }
    }
    
    func requestId(timer: NSTimer) {
        let peripheral = timer.userInfo as! BLEDeviceInfo
        peripheral.requestParticleId()
    }
    
    public func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("peripheral connected")
        if let _ = peripherals.indexForKey(peripheral.identifier) {
            peripherals[peripheral.identifier]?.state = BLEDeviceState.CloudConnecting
            eventCallback!(BLEManagerEvent.DeviceConnected, peripherals[peripheral.identifier]!)
            peripherals[peripheral.identifier]?.peripheral?.delegate = self;
            peripherals[peripheral.identifier]?.peripheral?.discoverServices([CBUUID(string: BLUZ_UUID)])
            let _ = NSTimer.scheduledTimerWithTimeInterval(22, target: self, selector: "requestId:", userInfo: peripherals[peripheral.identifier], repeats: false)
        }
    }
    
    
    public func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("peripheral disconnected")
        if let _ = peripherals.indexForKey(peripheral.identifier) {
            peripherals[peripheral.identifier]?.state = BLEDeviceState.Disconnected
            peripherals[peripheral.identifier]?.socket?.disconnect()
            peripherals[peripheral.identifier]?.lastByteCount = 0
            peripherals[peripheral.identifier]?.rxBuffer.length = 0
            eventCallback!(BLEManagerEvent.DeviceDisconnected, peripherals[peripheral.identifier]!)
        }
    }
    
    public func centralManagerDidUpdateState(central: CBCentralManager) {
        switch (central.state) {
            case CBCentralManagerState.PoweredOff:
                print("Power off")
                
            case CBCentralManagerState.Unauthorized:
                print("Unauthorized")
                // Indicate to user that the iOS device does not support BLE.
                break
                
            case CBCentralManagerState.Unknown:
                print("Unknown")
                // Wait for another event
                break
                
            case CBCentralManagerState.PoweredOn:
                print("Powered on")
                if let _ = startScanOnPowerup {
                    centralManager!.scanForPeripheralsWithServices(nil, options: nil)
                }
                
            case CBCentralManagerState.Resetting:
                print("resetting")
                
            case CBCentralManagerState.Unsupported:
                print("unsupported")
                break
                
            default:
                break
        }
    }
    
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        for service in peripheral.services! {
            if service.UUID == CBUUID(string: BLUZ_UUID) {
                peripheral.discoverCharacteristics([CBUUID(string: BLUZ_CHAR_RX_UUID), CBUUID(string: BLUZ_CHAR_TX_UUID)], forService: service)
            }
        }
        
    }
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        for characteristic in service.characteristics! {
            if characteristic.UUID == CBUUID(string: BLUZ_CHAR_RX_UUID) {
                print("found the right thing")
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            } else if characteristic.UUID == CBUUID(string: BLUZ_CHAR_TX_UUID) {
                peripherals[peripheral.identifier]?.writeCharacteristic = characteristic
            }
        }
    }
    
    public func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let _ = peripherals.indexForKey(peripheral.identifier) {
            peripheral.readValueForCharacteristic(characteristic)
        }
    }
    
    public func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            NSLog(error.debugDescription)
        }
    }

    public func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if characteristic.UUID != CBUUID(string: BLUZ_CHAR_RX_UUID) {
            return
        }
        
        if let _ = peripherals.indexForKey(peripheral.identifier) {
            let peripheral = peripherals[peripheral.identifier]
            let eosBuffer = NSData(bytes: [0x03, 0x04] as [UInt8], length: 2)
            
            NSLog("Got data from bluz of size " + String(characteristic.value!.length))
            if peripheral!.state == BLEDeviceState.CloudConnecting && characteristic.value!.isEqualToData(eosBuffer) && peripheral?.lastByteCount > 0 {
               
                var bytes = "" as NSMutableString
                let length = characteristic.value!.length
                var byteArray = [UInt8](count: length, repeatedValue: 0x0)
                characteristic.value!.getBytes(&byteArray, length:length)
                
                for byte in byteArray {
                    bytes.appendFormat("%02x ", byte)
                }
                NSLog("As we connect, bluz data is: " + String(bytes))
                
                peripheral?.socket?.connect()
                peripheral?.rxBuffer.length = 0
                peripheral!.state = BLEDeviceState.Connected
            } else if peripheral!.state == BLEDeviceState.Connected {
                if (characteristic.value!.length == 2 && characteristic.value!.isEqualToData(eosBuffer)) {
                    if lastService == 0x01 {
                        peripheral?.socket?.write( UnsafePointer<UInt8>((peripheral?.rxBuffer.bytes)!), len: (peripheral?.rxBuffer.length)!)
                    } else if lastService == 2 {
                        let length = peripheral?.rxBuffer.length
                        var deviceId = "" as NSMutableString

                        var byteArray = [UInt8](count: length!, repeatedValue: 0x0)
                        peripheral?.rxBuffer.getBytes(&byteArray, length:length!)
                        
                        for byte in byteArray {
                            deviceId.appendFormat("%02x", byte)
                        }
                        
                        peripheral?.cloudId = deviceId
                        getCloudName(peripheral!)
                    }
                    peripheral?.rxBuffer.length = 0
                } else {
                    if peripheral?.rxBuffer.length == 0 {
                        var array = [UInt8](count: (characteristic.value?.length)!, repeatedValue: 0)
                        characteristic.value!.getBytes(&array, length: (characteristic.value?.length)!)
                        lastService = array.first!
                        
                        var headerBytes = 1
                        if lastService == 1 {
                            headerBytes = 2
                        }
                        peripheral?.rxBuffer.appendData(characteristic.value!.subdataWithRange(NSMakeRange(headerBytes, characteristic.value!.length-headerBytes)))
                    } else {
                        peripheral?.rxBuffer.appendData(characteristic.value!)
                    }
                }
            } else {
                //this is to catch issues when reconnecting
                //with beacons, for some reason we are seeing the eos characters sent immediately upon connection, not sure why yet
                peripheral?.lastByteCount = characteristic.value!.length

                var bytes = "" as NSMutableString
                let length = characteristic.value!.length
                var byteArray = [UInt8](count: length, repeatedValue: 0x0)
                characteristic.value!.getBytes(&byteArray, length:length)
                
                for byte in byteArray {
                    bytes.appendFormat("%02x ", byte)
                }
                NSLog("Bluz data is: " + String(bytes))
            }
        }
    }
    
    public func getCloudName(peripheral: BLEDeviceInfo) {
        SparkCloud.sharedInstance().getDevices { (sparkDevices:[AnyObject]!, error:NSError!) -> Void in
            if let e = error {
                NSLog("Check your internet connectivity")
            }
            else {
                if let devices = sparkDevices as? [SparkDevice] {
                    for device in devices {
                        if device.id == peripheral.cloudId {
                            peripheral.cloudName = device.name
                            peripheral.particleDevice = device
                            peripheral.isClaimed = true
                        }
                    }
                }
            }
            self.eventCallback!(BLEManagerEvent.DeviceUpdated, peripheral)
        }
    }
}
