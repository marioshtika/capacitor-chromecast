import Capacitor
import Foundation

@objc(ChromecastPlugin)
public class ChromecastPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ChromecastPlugin"
    public let jsName = "Chromecast"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "initialize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "show", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "loadMedia", returnType: CAPPluginReturnPromise)
    ]

    private let implementation = Chromecast()

    public override func load() {
        implementation.sessionStateChangedHandler = { [weak self] state in
            self?.notifyListeners("sessionStateChanged", data: ["state": state])
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            do {
                try self.implementation.prepare(configuredReceiverApplicationId: self.getConfig().getString("receiverApplicationId"))
            } catch {
                print("ChromecastPlugin configuration warning: \(error)")
            }
        }
    }

    @objc func initialize(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            do {
                try self.implementation.initialize(receiverApplicationId: call.getString("receiverApplicationId") ?? "")
                call.resolve()
            } catch let error as ChromecastPluginError {
                call.reject(error.message, error.code)
            } catch {
                call.reject("Failed to initialize Google Cast.", ChromecastPluginError.castConnectionFailed.code, error)
            }
        }
    }

    @objc func show(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            do {
                try self.implementation.show(configuredReceiverApplicationId: self.getConfig().getString("receiverApplicationId"))
                call.resolve()
            } catch let error as ChromecastPluginError {
                call.reject(error.message, error.code)
            } catch {
                call.reject("Failed to open the Google Cast device picker.", ChromecastPluginError.castNotAvailable.code, error)
            }
        }
    }

    @objc func loadMedia(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            do {
                try self.implementation.loadMedia(
                    url: call.getString("url") ?? "",
                    configuredReceiverApplicationId: self.getConfig().getString("receiverApplicationId")
                ) { error in
                    guard let error else {
                        call.resolve()
                        return
                    }
                    call.reject(error.message, error.code)
                }
            } catch let error as ChromecastPluginError {
                call.reject(error.message, error.code)
            } catch {
                call.reject(ChromecastPluginError.mediaLoadFailed.message, ChromecastPluginError.mediaLoadFailed.code, error)
            }
        }
    }
}
