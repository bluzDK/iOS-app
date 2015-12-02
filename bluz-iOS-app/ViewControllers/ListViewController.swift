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
    
    var bleManager: BLEManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scanButton!.addTarget(self, action: "scanButtonPressed:", forControlEvents: .TouchUpInside)
        
        bleManager = BLEManager()
        bleManager.registerCallback(bleManagerCallback)
        self.startScanningWithTimer()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
        let _ = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "stopScanning", userInfo: nil, repeats: true)
    }
    
    func stopScanning() {
        scanButton!.setTitle("Scan", forState: .Normal)
        scanButton!.enabled = true
        bleManager.stopScanning()
    }
    
    func scanButtonPressed(sender: UIButton!) {
        startScanningWithTimer()
    }
    
    func bleManagerCallback(event: BLEManager.BLEManagerEvent) {
        switch (event)
        {
            case BLEManager.BLEManagerEvent.DeviceDiscovered:
                self.tableView.reloadData()
                break;
            case BLEManager.BLEManagerEvent.DeviceConnected:
                break;
            case BLEManager.BLEManagerEvent.DeviceDisconnected:
                break;
            case BLEManager.BLEManagerEvent.BLERadioChange:
                break;
            default:
                break;
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: ListCellViewController = tableView.dequeueReusableCellWithIdentifier("BLECell", forIndexPath: indexPath) as! ListCellViewController
        
        if let peripheral = bleManager.peripheralAtIndex(indexPath.row) {
            cell.deviceName!.text = peripheral.peripheral!.name
            cell.deviceRSSI!.text = "RSSI: " + peripheral.rssi.stringValue
            cell.deviceServices!.text = String(peripheral.numberOfServices()) + " Services"
            if peripheral.isBluzCompatible() {
                cell.logo?.image = UIImage(named: "bluz_hw")
            } else {
                cell.logo?.image = UIImage(named: "Bluetooth_Logo")
            }
        }
        
        // Configure the cell...
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80;
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
