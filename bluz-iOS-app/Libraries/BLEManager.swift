//
//  BLELister.swift
//  bluz-iOS-app
//
//  Created by Eric Ely on 11/27/15.
//  Copyright © 2015 Eric Ely. All rights reserved.
//

import Foundation
import CoreBluetooth

public class BLEManager: NSObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager?
    public var peripherals = Set<BLEDeviceInfo>()
    var eventCallback: ((BLEManagerEvent) -> (Void))?
    var startScanOnPowerup: Bool?
    
    enum BLEManagerEvent {
        case DeviceDiscovered
        case DeviceConnected
        case DeviceDisconnected
        case BLERadioChange
    }

    override init(){
        super.init()
        startScanOnPowerup = false
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func registerCallback(callback: (result: BLEManagerEvent) -> Void) {
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
    
    
    //delegate methods
    public func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        var dIno = BLEDeviceInfo(p: peripheral, r: RSSI, a: advertisementData)
        peripherals.insert(dIno)
        eventCallback!(BLEManagerEvent.DeviceDiscovered)
    }
    
    public func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("peripheral connected")
    }
    
    
    public func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
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


}
