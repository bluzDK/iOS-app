//
//  ParticleSocket.swift
//  bluz-iOS-app
//
//  Created by Eric Ely on 12/1/15.
//  Copyright © 2015 Eric Ely. All rights reserved.
//

import Foundation

public class ParticleSocket: NSObject, NSStreamDelegate {
    let publicServerAddress: CFString = "device.spark.io"
    let serverPort: UInt32 = 5683
    
    private var inputStream: NSInputStream!
    private var outputStream: NSOutputStream!
    
    var dataCallback: ((NSData, NSData) -> (Void))?
    
    func registerCallback(callback: (data: NSData, length: NSData) -> Void) {
        dataCallback = callback
    }
    
    public func connect() {
        //get the setting for which server to use
        var server = publicServerAddress
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.synchronize()
        let s = defaults.objectForKey("stagingServer")
        if s != nil && s as! Bool == true {
            server = "staging-device.spark.io"
        }

        
        var readStream : Unmanaged<CFReadStream>?
        var writeStream : Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(nil, server, self.serverPort, &readStream, &writeStream)
        
        inputStream = readStream!.takeUnretainedValue()
        outputStream = writeStream!.takeUnretainedValue()
        
        inputStream!.delegate = self
        outputStream!.delegate = self
        
        inputStream!.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream!.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        
        inputStream!.open()
        outputStream!.open()
    }
    
    public func disconnect() {
        inputStream!.close()
        outputStream!.close()
    }
    
    public func write(data: UnsafePointer<UInt8>, len: Int) {
        NSLog("Sending data of size " + String(len) + " to Particle")
        outputStream.write(data, maxLength: len)
    }
    
    public func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch (eventCode){
        case NSStreamEvent.ErrorOccurred:
            NSLog("ErrorOccurred")
            break
        case NSStreamEvent.EndEncountered:
            NSLog("EndEncountered")
            break
        case NSStreamEvent.None:
            NSLog("None")
            break
        case NSStreamEvent.HasBytesAvailable:
            NSLog("HasBytesAvaible")
            var buffer = [UInt8](count: 200000, repeatedValue: 0)
            if ( aStream == inputStream){
                
                while (inputStream.hasBytesAvailable){
                    let len = inputStream.read(&buffer, maxLength: buffer.count)
                    
                    var header = [UInt8](count: 2, repeatedValue: 0x00)
                    header[0] = 0x01
                    header[1] = 0x00
                    
                    if(len > 0) {
                        dataCallback!( NSData(bytes: buffer, length: len), NSData(bytes: header, length: header.count))
                    }
                }
            }
            break
        case NSStreamEvent.OpenCompleted:
            NSLog("OpenCompleted")
            break
        case NSStreamEvent.HasSpaceAvailable:
            NSLog("HasSpaceAvailable")
            break
        default:
            NSLog("Unknown Network Event")
            break
        }
    }
}