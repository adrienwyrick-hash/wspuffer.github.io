import Foundation
import Capacitor
import StoreKit

@objc(IAPPlugin)
public class IAPPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "IAPPlugin"
    public let jsName = "IAP"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isAvailable",  returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getProducts",  returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "purchase",     returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "restore",      returnType: CAPPluginReturnPromise)
    ]

    private var transactionListener: Task<Void, Error>?
    private var loadedProducts: [String: Any] = [:]

    public override func load() {
        if #available(iOS 15.0, *) {
            transactionListener = startTransactionListener()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    @objc func isAvailable(_ call: CAPPluginCall) {
        if #available(iOS 15.0, *) {
            call.resolve(["available": true])
        } else {
            call.resolve(["available": false, "reason": "iOS 15 or later required"])
        }
    }

    @objc func getProducts(_ call: CAPPluginCall) {
        guard #available(iOS 15.0, *) else {
            call.reject("In-App Purchases require iOS 15 or later")
            return
        }
        guard let ids = call.getArray("productIds", String.self), !ids.isEmpty else {
            call.reject("Missing productIds")
            return
        }
        Task { await self.loadProducts(ids: ids, call: call) }
    }

    @objc func purchase(_ call: CAPPluginCall) {
        guard #available(iOS 15.0, *) else {
            call.reject("In-App Purchases require iOS 15 or later")
            return
        }
        guard let id = call.getString("productId") else {
            call.reject("Missing productId")
            return
        }
        Task { await self.runPurchase(id: id, call: call) }
    }

    @objc func restore(_ call: CAPPluginCall) {
        guard #available(iOS 15.0, *) else {
            call.reject("In-App Purchases require iOS 15 or later")
            return
        }
        Task { await self.runRestore(call: call) }
    }

    @available(iOS 15.0, *)
    private func startTransactionListener() -> Task<Void, Error> {
        return Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { continue }
                if case .verified(let tx) = result {
                    await tx.finish()
                    await MainActor.run {
                        self.notifyListeners("transactionUpdate", data: ["productId": tx.productID])
                    }
                }
            }
        }
    }

    @available(iOS 15.0, *)
    private func loadProducts(ids: [String], call: CAPPluginCall) async {
        do {
            let products = try await Product.products(for: ids)
            var out: [[String: Any]] = []
            for p in products {
                self.loadedProducts[p.id] = p
                out.append([
                    "id": p.id,
                    "title": p.displayName,
                    "description": p.description,
                    "displayPrice": p.displayPrice
                ])
            }
            var owned: [String] = []
            for await result in Transaction.currentEntitlements {
                if case .verified(let tx) = result {
                    owned.append(tx.productID)
                }
            }
            call.resolve(["products": out, "owned": owned])
        } catch {
            call.reject(error.localizedDescription)
        }
    }

    @available(iOS 15.0, *)
    private func runPurchase(id: String, call: CAPPluginCall) async {
        do {
            let product: Product
            if let cached = self.loadedProducts[id] as? Product {
                product = cached
            } else if let fetched = try await Product.products(for: [id]).first {
                self.loadedProducts[id] = fetched
                product = fetched
            } else {
                call.reject("Product not available")
                return
            }
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let tx):
                    await tx.finish()
                    call.resolve(["status": "purchased", "productId": tx.productID])
                case .unverified(_, let err):
                    call.reject("Unverified transaction: \(err.localizedDescription)")
                }
            case .userCancelled:
                call.resolve(["status": "cancelled"])
            case .pending:
                call.resolve(["status": "pending"])
            @unknown default:
                call.resolve(["status": "unknown"])
            }
        } catch {
            call.reject(error.localizedDescription)
        }
    }

    @available(iOS 15.0, *)
    private func runRestore(call: CAPPluginCall) async {
        do {
            try await AppStore.sync()
            var owned: [String] = []
            for await result in Transaction.currentEntitlements {
                if case .verified(let tx) = result {
                    owned.append(tx.productID)
                }
            }
            call.resolve(["owned": owned])
        } catch {
            call.reject(error.localizedDescription)
        }
    }
}
