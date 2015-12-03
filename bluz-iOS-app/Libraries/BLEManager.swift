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
let BLUZ_SERVICE_UUID = "0223"
let BLUZ_CHAR_RX_UUID = "0224"
let BLUZ_CHAR_TX_UUID = "0225"

public class BLEManager: NSObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager?
    public var peripherals = [NSUUID: BLEDeviceInfo]()
    var eventCallback: ((BLEManagerEvent, BLEDeviceInfo) -> (Void))?
    var startScanOnPowerup: Bool?
    var discoverOnlyBluz: Bool?
    
    enum BLEManagerEvent {
        case DeviceDiscovered
        case DeviceUpdated
        case DeviceConnected
        case DeviceDisconnected
        case BLERadioChange
    }

    override init(){
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
        peripherals.removeAll()
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
    
    public func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("peripheral connected")
        if let _ = peripherals.indexForKey(peripheral.identifier) {
            peripherals[peripheral.identifier]?.connected = true;
            eventCallback!(BLEManagerEvent.DeviceConnected, peripherals[peripheral.identifier]!)
//            peripherals[peripheral.identifier]?.peripheral?.discoverServices([CBUUID(string: BLUZ_UUID)])
        }
    }
    
    
    public func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("peripheral disconnected")
        if let _ = peripherals.indexForKey(peripheral.identifier) {
            peripherals[peripheral.identifier]?.connected = false;
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
        
    }

}
