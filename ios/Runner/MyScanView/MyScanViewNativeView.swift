import Foundation
import UIKit
import AVFoundation
import Flutter

class MyScanViewNativeView: NSObject,FlutterPlatformView,AVCaptureMetadataOutputObjectsDelegate {
    
    private var _view: UIView
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var isSessionRunning = false
    
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let metadataOutput = AVCaptureMetadataOutput()
    private let metadataObjectsQueue = DispatchQueue(label: "metadata objects queue", attributes: [], target: nil)
    private var channel: FlutterMethodChannel?
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView()
        super.init()
        if let args = args as? Dictionary<String, Any>,
           let widthValue = args["width"] as? Double, let heightValue = args["height"] as? Double {
            setUpView(width: widthValue,height: heightValue)
        }
        channel = FlutterMethodChannel(name: "scanQrView", binaryMessenger: messenger!)
    }
    
    func view() -> UIView {
        return _view
    }
    
    private func setUpView(width: Double,height: Double){
        
        _view.backgroundColor = UIColor.clear
        
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: metadataObjectsQueue)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0,width: width,height: height)
        previewLayer.videoGravity = .resizeAspectFill
        _view.layer.addSublayer(previewLayer)
        
        
        sessionQueue.async {
            if !self.isSessionRunning {
                self.captureSession.startRunning()
                self.isSessionRunning = self.captureSession.isRunning
            }
        }
    }
    
    deinit{
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Device does not support scanning", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Ok", style: .default))
        UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }?.rootViewController?.present(ac, animated: true)
        captureSession = nil
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .first { $0.isKeyWindow }?.rootViewController?.dismiss(animated: true)
            
        }
    }
    
    func found(code: String) {
        debugPrint("Code is \(code)")
        channel?.invokeMethod("sendFromNative", arguments: code)
    }
    
    
}
