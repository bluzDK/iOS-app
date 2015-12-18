//
//  ListViewController.swift
//  bluz-iOS-app
//
//  Created by Eric Ely on 11/27/15.
//  Copyright © 2015 Eric Ely. All rights reserved.
//

import UIKit

class ListViewController: UITableViewController {
    @IBOutlet var scanButton: UIButton?
    @IBOutlet var loginButton: UIButton?
    
    var bleManager: BLEManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scanButton!.addTarget(self, action: "scanButtonPressed:", forControlEvents: .TouchUpInside)
        loginButton!.addTarget(self, action: "loginButtonPressed:", forControlEvents: .TouchUpInside)
        
        bleManager = BLEManager()
        bleManager.registerCallback(bleManagerCallback)
        self.startScanningWithTimer()
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewDidAppear(animated: Bool) {
        if SparkCloud.sharedInstance().isLoggedIn {
            loginButton!.setTitle("Logout", forState: .Normal)
        } else {
            loginButton!.setTitle("Login", forState: .Normal)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return bleManager.peripheralCount()
    }
    
    func startScanningWithTimer() {
        scanButton!.setTitle("Scanning...", forState: .Normal)
        scanButton!.enabled = false
        bleManager.clearScanResults()
        bleManager.startScanning()
        let _ = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "stopScanning", userInfo: nil, repeats: false)
    }
    
    func stopScanning() {
        scanButton!.setTitle("Scan", forState: .Normal)
        scanButton!.enabled = true
        bleManager.stopScanning()
    }
    
    func scanButtonPressed(sender: UIButton!) {
        startScanningWithTimer()
    }
    
    func loginButtonPressed(sender: UIButton!) {
        if SparkCloud.sharedInstance().isLoggedIn {
            SparkCloud.sharedInstance().logout()
            loginButton!.setTitle("Login", forState: .Normal)
        } else {
            performSegueWithIdentifier("showLoginSegue", sender: nil)
        }
    }
    
    func connectButtonPressed(sender: UIButton!) {
        if let peripheral = bleManager.peripheralAtIndex(sender.tag) {
            if (peripheral.state == BLEDeviceState.Connected) {
                bleManager.disconnectPeripheral(peripheral)
                sender.enabled = false;
                sender.setTitle("Disconnecting...", forState: .Normal)
            } else {
                bleManager.connectPeripheral(peripheral)
                sender.enabled = false;
                sender.setTitle("Connecting...", forState: .Normal)
            }
        }
    }
    
    func claimButtonPressed(sender: UIButton!) {
        sender.enabled = false
        if let peripheral = bleManager.peripheralAtIndex(sender.tag) {
            SparkCloud.sharedInstance().claimDevice(peripheral.cloudId as String, completion: { (error:NSError!) -> Void in
                if let _ = error {
                    NSLog("Unable to claim device")
                    NSLog("Error: " + error.debugDescription)
                }
                else {
                    sender.hidden = true
                    NSLog("Claimed")
                    peripheral.isClaimed = true
                }
            })
        }
    }
    
    func bleManagerCallback(event: BLEManager.BLEManagerEvent, peripheral: BLEDeviceInfo) {
        switch (event)
        {
            case BLEManager.BLEManagerEvent.DeviceUpdated:
                fallthrough
            case BLEManager.BLEManagerEvent.DeviceDiscovered:
                self.tableView.reloadData()
                break;
            case BLEManager.BLEManagerEvent.DeviceConnected:
                let row = bleManager.indexOfPeripheral(peripheral)
                let indexPath = NSIndexPath(forRow: row!, inSection:0)
                self.tableView.cellForRowAtIndexPath(indexPath)
                if let cell: ListCellViewController = self.tableView.cellForRowAtIndexPath(indexPath) as! ListCellViewController {
                    cell.connectButton!.enabled = true
                    cell.connectButton!.setTitle("Disconnect", forState: .Normal)
//                    cell.connectButton!.backgroundColor = UIColor(red: 209, green: 54, blue: 0, alpha: 1)
                }
                break;
            case BLEManager.BLEManagerEvent.DeviceDisconnected:
                let row = bleManager.indexOfPeripheral(peripheral)
                let indexPath = NSIndexPath(forRow: row!, inSection:0)
                if let cell: ListCellViewController = self.tableView.cellForRowAtIndexPath(indexPath) as! ListCellViewController {
                    cell.connectButton!.setTitle("Connect", forState: .Normal)
                    cell.connectButton!.enabled = true
//                    cell.connectButton!.backgroundColor = UIColor(red: 45, green: 145, blue: 93, alpha: 1)
                }
                break;
            case BLEManager.BLEManagerEvent.BLERadioChange:
                break;
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: ListCellViewController = tableView.dequeueReusableCellWithIdentifier("BLECell", forIndexPath: indexPath) as! ListCellViewController
        
        if let peripheral = bleManager.peripheralAtIndex(indexPath.row) {
            cell.claimButton!.enabled = false
            cell.claimButton!.hidden = true
            
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            cell.deviceName!.text = peripheral.peripheral!.name
            cell.deviceRSSI!.text = "RSSI: " + peripheral.rssi.stringValue
            cell.deviceServices!.text = String(peripheral.numberOfServices()) + " Services"
            
            cell.cloudId!.text = peripheral.cloudId as String
            cell.cloudName!.text = peripheral.cloudName as String
            
            if peripheral.isBluzCompatible() {
                cell.logo?.image = UIImage(named: "bluz_hw")
                cell.connectButton!.hidden = false
                cell.connectButton!.enabled = true
                
                cell.connectButton!.tag = indexPath.row
                cell.connectButton!.addTarget(self, action: "connectButtonPressed:", forControlEvents: .TouchUpInside)
                
                if (peripheral.state == BLEDeviceState.Connected) {
                    cell.connectButton!.setTitle("Disconnect", forState: .Normal)
//                    cell.connectButton!.backgroundColor = UIColor(red: 209, green: 54, blue: 0, alpha: 1)
                    
                    if peripheral.cloudId != "" && !peripheral.isClaimed {
                        cell.claimButton!.tag = indexPath.row
                        cell.claimButton!.enabled = true
                        cell.claimButton!.hidden = false
                        cell.claimButton!.addTarget(self, action: "claimButtonPressed:", forControlEvents: .TouchUpInside)
                    }
                    
                } else {
                    cell.connectButton!.setTitle("Connect", forState: .Normal)
//                    cell.connectButton!.backgroundColor = UIColor(red: 45, green: 145, blue: 93, alpha: 1)
                }
                
            } else {
                cell.logo?.image = UIImage(named: "Bluetooth_Logo")
                cell.connectButton!.hidden = true
                cell.connectButton!.enabled = false
            }
        }
        
        // Configure the cell...
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 120;
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
