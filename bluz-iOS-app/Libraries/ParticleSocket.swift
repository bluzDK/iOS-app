//
//  ParticleSocket.swift
//  bluz-iOS-app
//
//  Created by Eric Ely on 12/1/15.
//  Copyright © 2015 Eric Ely. All rights reserved.
//

import Foundation

public class ParticleSocket: NSObject, NSStreamDelegate {
    let serverAddress: CFString = "device.spark.io"
    let serverPort: UInt32 = 5683
    
    private var inputStream: NSInputStream!
    private var outputStream: NSOutputStream!
    
    var dataCallback: ((NSData, Int) -> (Void))?
    
    func registerCallback(callback: (data: NSData, length: Int) -> Void) {
        dataCallback = callback
    }
    
    public func connect() {
        var readStream : Unmanaged<CFReadStream>?
        var writeStream : Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocketToHost(nil, self.serverAddress, self.serverPort, &readStream, &writeStream)
        
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
            var buffer = [UInt8](count: 4096, repeatedValue: 0)
            if ( aStream == inputStream){
                
                while (inputStream.hasBytesAvailable){
                    let len = inputStream.read(&buffer+2, maxLength: buffer.count)
                    buffer[0] = 0x01;
                    buffer[1] = 0x00;
                    
                    if(len > 0) {
                        dataCallback!( NSData(bytes: buffer, length: len+2), len+2)
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