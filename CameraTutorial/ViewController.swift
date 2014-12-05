//
//  ViewController.swift
//  CameraTutorial
//
//  Created by Jameson Quave on 9/20/14.
//  Copyright (c) 2014 JQ Software. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, /* For capturing barcodes */AVCaptureMetadataOutputObjectsDelegate {

    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    // If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                    if captureDevice != nil {
                        println("Capture device found")
                        beginSession()
                    }
                }
            }
        }
        
    }
    
    func beginSession() {
        
        var err : NSError? = nil
        captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))
        
        if err != nil {
            println("error: \(err?.localizedDescription)")
        }
        
        addOutputForBarcodeMetadata()
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.addSublayer(previewLayer)
        previewLayer?.frame = self.view.layer.frame
        captureSession.startRunning()
        
    }
    
    // Capture metadata for barcodes
    var metadataOutput = AVCaptureMetadataOutput()
    func addOutputForBarcodeMetadata() {
        metadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        captureSession.addOutput(metadataOutput)
        
        // This line is required, as little sense at that makes
        metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
    }
    
    // MARK: AVCaptureMetadataOutputObjectsDelegate
    var canCaptureBarcode = true
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {

        if !canCaptureBarcode {
            return
        }
        
        // Types of barcodes AVKit will be able to find
        let barcodeTypes = [AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code,
            AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code,
            AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode] as [String]

        // Loop through the returned metadata objects (might include a barcode)
        for metadata in metadataObjects {
            
            // Use Swift's find() function to get the index of the metadata type, to see if it's in the list of barcode types
            // e.g. is the metadata object a barcode
            if find(barcodeTypes, String(metadata.type)) != nil {
                // If it is, print out the type so we can see what it is
                
                println("Barcode type is \(String(metadata.type))")
                
                // Get the barcode object in machine readable format
                if let barcode = self.previewLayer?.transformedMetadataObjectForMetadataObject(metadata as AVMetadataObject) as? AVMetadataMachineReadableCodeObject {
                
                    // Get the barcode string
                    let barcodeString = barcode.stringValue
                    
                    // Show the user
                    let alert = UIAlertController(title: "Found a barcode", message: "Bar code is: \(barcodeString)", preferredStyle: .Alert)

                    alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (alertAction) -> Void in
                        self.canCaptureBarcode = false
                    }))
                    self.presentViewController(alert, animated: true, completion: nil)
                    return
                
                }

            }
        }
    }

}

