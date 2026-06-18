import UIKit
import Capacitor

/// App-side Capacitor bridge view controller.
///
/// Explicitly registers our custom Swift plugins on the bridge after it
/// finishes loading. Capacitor's reflection-based auto-discovery does not
/// always pick up custom plugins added directly to the app target, so we
/// register them by hand here — this is the supported, recommended pattern
/// for "in-app custom code" plugins.
public class ViewController: CAPBridgeViewController {
    public override func capacitorDidLoad() {
        bridge?.registerPluginInstance(IAPPlugin())
        bridge?.registerPluginInstance(GameCenterPlugin())
        bridge?.registerPluginInstance(SignInWithApplePlugin())
    }
}
