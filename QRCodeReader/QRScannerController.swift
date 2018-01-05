//
//  QRScannerController.swift
//  QRCodeReader
//
//  Created by Simon Ng on 13/10/2016.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import AVFoundation

class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet var messageLabel:UILabel!
    @IBOutlet var topbar: UIView!
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    var counter = 0
    
    let filter = CIFilter(name: "CIQRCodeGenerator")!
    var generatedQRCodeImageView = UIImageView()
    
    var featureFoundIndicatorSquare = UIView()
    var isSynchronized = false
    
    var capturePhotoOutput: AVCapturePhotoOutput?
    
    var capturedImage: UIImage!
    
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        QRReader()
        /*
        QRGenerator()
        */
    }
    
    /************************** QRCodeReader **************************/
    func QRReader() {
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            //Get an instance of the AVCpatureDeviceInput class using the previous device object
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session:captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            
            view.bringSubview(toFront: messageLabel)
            view.bringSubview(toFront: topbar)
            
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                
                view.addSubview(qrCodeFrameView)
                view.bringSubview(toFront: qrCodeFrameView)
            }
            
            // Get an instance of ACCapturePhotoOutput class
            capturePhotoOutput = AVCapturePhotoOutput()
            capturePhotoOutput?.isHighResolutionCaptureEnabled = true
            
            // Set the output on the capture session
            captureSession?.addOutput(capturePhotoOutput!)

            createQRReaderSquare()
            
        } catch {
            print(error)
            return
        }
    }
    
    func createQRReaderSquare() {
        
        featureFoundIndicatorSquare = UIView()
        featureFoundIndicatorSquare.layer.borderColor = UIColor.red.cgColor
        featureFoundIndicatorSquare.layer.borderWidth = 3
        
        let size = CGSize(width: self.view.bounds.size.width - 6, height: self.view.bounds.size.width - 6)
        
        featureFoundIndicatorSquare.frame.size = size
        featureFoundIndicatorSquare.center = self.view.center
        
        self.view.addSubview(featureFoundIndicatorSquare)
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                messageLabel.text = metadataObj.stringValue
                
                print("==================================================================")
                
                print(qrCodeFrameView!.frame.width, featureFoundIndicatorSquare.frame.width)
                print(qrCodeFrameView!.frame.height, featureFoundIndicatorSquare.frame.height)
                
                print(qrCodeFrameView!.frame.minX, featureFoundIndicatorSquare.frame.minX)
                print(qrCodeFrameView!.frame.minY, featureFoundIndicatorSquare.frame.minY)
                
                
                let widthDifference = (featureFoundIndicatorSquare.frame.width - qrCodeFrameView!.frame.width).rounded().distance(to: 0)
                let heightDifference = (featureFoundIndicatorSquare.frame.height - qrCodeFrameView!.frame.height).rounded().distance(to: 0)
                
                let xPositionDifference = (featureFoundIndicatorSquare.frame.minX - qrCodeFrameView!.frame.minX).rounded().distance(to: 0)
                let yPositionDifference = (featureFoundIndicatorSquare.frame.minY - qrCodeFrameView!.frame.minY).rounded().distance(to: 0)
                
                if (abs(widthDifference) < 5) && (abs(heightDifference) < 5) {
                    if (abs(xPositionDifference) < 5) && (abs(yPositionDifference) < 5) {
                        if (!isSynchronized) {
                            featureFoundIndicatorSquare.layer.borderColor = UIColor.blue.cgColor
                            print(widthDifference, heightDifference)
                            print(xPositionDifference, yPositionDifference)
                            isSynchronized = true
                        }
                    }
                }

                print(widthDifference, heightDifference)
                print(xPositionDifference, yPositionDifference)
                
                print("==================================================================")
            }
        }
        
    }
    
    /************************** QRCodeGenerator **************************/
    func QRGenerator() {
        setUpQrCodeImageView()
        scheduledCounterTimerWithTimeInterval()
    }
    
    func setUpQrCodeImageView() {
        let infoString = "Hey the count is \(counter)"
        
        let data = infoString.data(using: .ascii, allowLossyConversion: false)
        
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let image = UIImage(ciImage: filter.outputImage!.transformed(by: transform))
        
        generatedQRCodeImageView.image = image
        
        let size = CGSize(width: self.view.bounds.size.width / 3, height: self.view.bounds.size.width / 3)
        
        generatedQRCodeImageView.frame.size = size
        generatedQRCodeImageView.center = self.view.center
        
        self.view.addSubview(generatedQRCodeImageView)
    }
    
    
    func scheduledCounterTimerWithTimeInterval() {
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(generateNewQRCode), userInfo: nil, repeats: true)
    }
    
    @objc func generateNewQRCode() {
        counter += 1
        updateQRCode()
    }
    
    func updateQRCode() {
        let infoString = "Hey the count is \(counter)"
        
        let data = infoString.data(using: .ascii, allowLossyConversion: false)
        
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let image = UIImage(ciImage: filter.outputImage!.transformed(by: transform))
        
        generatedQRCodeImageView.image = image
        print(counter)
    }
    
    func findDistance(width: Int, height: Int) {
        
        var hypotenueseWidthOfDoubleTriangle = width * 2
        //var 
    }
    
}

extension QRScannerController : AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
                     previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                     resolvedSettings: AVCaptureResolvedPhotoSettings,
                     bracketSettings: AVCaptureBracketedStillImageSettings?,
                     error: Error?) {
        
        // get captured image
        // Make sure we get some photo sample buffer
        guard error == nil,
            let photoSampleBuffer = photoSampleBuffer else {
                print("Error capturing photo: \(String(describing: error))")
                return
        }
        
        // Convert photo same buffer to a jpeg image data by using // AVCapturePhotoOutput
        guard let imageData =
            AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
                return
        }
        
        // Initialise a UIImage with our image data
        let cameraImage = UIImage(data: imageData , scale: 1.0)
        
        if let image = cameraImage {
            // Save our captured image to photos album
            
            capturedImage = image
            
            let minx = featureFoundIndicatorSquare.frame.minX
            let maxy = featureFoundIndicatorSquare.frame.maxY
            
            let fromRect=CGRect(x: minx, y: maxy, width: featureFoundIndicatorSquare.bounds.width ,height: featureFoundIndicatorSquare.bounds.height)
            
            let drawImage = image.cgImage!.cropping(to: fromRect)
            let bimage = UIImage(cgImage: drawImage!)
            
            
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [:])
            let features = detector!.features(in: CIImage(image: bimage)!)

            print(features)

        }
    }
}
