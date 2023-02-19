import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        weak var registrar = self.registrar(forPlugin: "my-views")
        let viewRegistrar = self.registrar(forPlugin: "<my-views>")!
        let cealScanViewFactory = MyScanViewNativeViewFactory(messenger: registrar!.messenger())
        viewRegistrar.register(
            cealScanViewFactory,
            withId: "scanQrView")
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
