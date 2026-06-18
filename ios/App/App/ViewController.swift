import UIKit
import Capacitor

/// App-side Capacitor bridge view controller.
///
/// Explicitly registers our custom Swift plugins on the bridge after it
/// finishes loading. Capacitor's reflection-based auto-discovery does not
/// always pick up plugins added directly to the app target, so we register
/// them by hand here — the documented "in-app custom code" pattern.
public class ViewController: CAPBridgeViewController {
    public override func capacitorDidLoad() {
        print("⚡️  WSPuffer ViewController.capacitorDidLoad — registering plugins")
        guard let bridge = bridge else {
            print("⚡️  ❌  bridge is nil — plugins will NOT be registered")
            return
        }
        bridge.registerPluginInstance(IAPPlugin())
        bridge.registerPluginInstance(GameCenterPlugin())
        bridge.registerPluginInstance(SignInWithApplePlugin())
        print("⚡️  ✅  Registered IAP, GameCenter, SignInWithApple")
    }
}
