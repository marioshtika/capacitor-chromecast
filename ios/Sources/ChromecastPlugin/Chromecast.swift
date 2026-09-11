import Foundation
import GoogleCast
import UIKit

enum ChromecastPluginError: String, Error {
    case notInitialized = "NOT_INITIALIZED"
    case invalidReceiverApplicationId = "INVALID_RECEIVER_APPLICATION_ID"
    case castNotAvailable = "CAST_NOT_AVAILABLE"
    case castConnectionFailed = "CAST_CONNECTION_FAILED"
    case unsupportedPlatform = "UNSUPPORTED_PLATFORM"

    var code: String {
        rawValue
    }

    var message: String {
        switch self {
        case .notInitialized:
            return "Google Cast has not been initialized. Call Chromecast.initialize(...) or configure plugins.Chromecast.receiverApplicationId in capacitor.config.*."
        case .invalidReceiverApplicationId:
            return "Receiver application ID must be an 8-character hexadecimal Google Cast receiver application ID."
        case .castNotAvailable:
            return "The native Google Cast device picker is not currently available."
        case .castConnectionFailed:
            return "Google Cast is already initialized with a different receiver application ID. Restart the app before changing it."
        case .unsupportedPlatform:
            return "Chromecast is not supported on the web platform."
        }
    }
}

final class Chromecast: NSObject, GCKSessionManagerListener {
    private enum Constants {
        static let defaultsSuiteName = "capacitor.chromecast"
        static let receiverApplicationIdKey = "receiverApplicationId"
        static let temporaryCastButtonTag = 9133701
    }

    private let userDefaults: UserDefaults
    private var activeReceiverApplicationId: String?
    private var sessionListenerAttached = false

    var sessionStateChangedHandler: ((String) -> Void)?

    override init() {
        userDefaults = UserDefaults(suiteName: Constants.defaultsSuiteName) ?? .standard
        super.init()
    }

    deinit {
        if sessionListenerAttached, GCKCastContext.isSharedInstanceInitialized() {
            GCKCastContext.sharedInstance().sessionManager.remove(self)
        }
    }

    func prepare(configuredReceiverApplicationId: String?) throws {
        if let configuredReceiverApplicationId, !configuredReceiverApplicationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let normalizedReceiverApplicationId = try Self.validateReceiverApplicationId(configuredReceiverApplicationId)
            storeReceiverApplicationId(normalizedReceiverApplicationId)
        }

        if let receiverApplicationId = try resolveReceiverApplicationId(configuredReceiverApplicationId: configuredReceiverApplicationId) {
            try initializeCastContextIfNeeded(receiverApplicationId: receiverApplicationId)
        }
    }

    func initialize(receiverApplicationId: String) throws {
        let normalizedReceiverApplicationId = try Self.validateReceiverApplicationId(receiverApplicationId)
        try initializeCastContextIfNeeded(receiverApplicationId: normalizedReceiverApplicationId)
    }

    func show(configuredReceiverApplicationId: String?) throws {
        guard let receiverApplicationId = try resolveReceiverApplicationId(configuredReceiverApplicationId: configuredReceiverApplicationId) else {
            throw ChromecastPluginError.notInitialized
        }

        try initializeCastContextIfNeeded(receiverApplicationId: receiverApplicationId)

        guard let hostView = activeHostView() else {
            throw ChromecastPluginError.castNotAvailable
        }

        let castButton = reusableCastButton(in: hostView)
        castButton.sendActions(for: .touchUpInside)
    }

    static func validateReceiverApplicationId(_ value: String?) throws -> String {
        let normalizedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
        let fullRange = NSRange(location: 0, length: normalizedValue.utf16.count)
        let regex = try! NSRegularExpression(pattern: "^[A-F0-9]{8}$")

        guard !normalizedValue.isEmpty, regex.firstMatch(in: normalizedValue, options: [], range: fullRange) != nil else {
            throw ChromecastPluginError.invalidReceiverApplicationId
        }

        return normalizedValue
    }

    private func resolveReceiverApplicationId(configuredReceiverApplicationId: String?) throws -> String? {
        if let configuredReceiverApplicationId, !configuredReceiverApplicationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let normalizedReceiverApplicationId = try Self.validateReceiverApplicationId(configuredReceiverApplicationId)
            storeReceiverApplicationId(normalizedReceiverApplicationId)
            return normalizedReceiverApplicationId
        }

        guard let storedReceiverApplicationId = userDefaults.string(forKey: Constants.receiverApplicationIdKey) else {
            return nil
        }

        return try Self.validateReceiverApplicationId(storedReceiverApplicationId)
    }

    private func initializeCastContextIfNeeded(receiverApplicationId: String) throws {
        let normalizedReceiverApplicationId = try Self.validateReceiverApplicationId(receiverApplicationId)

        if let activeReceiverApplicationId, activeReceiverApplicationId != normalizedReceiverApplicationId {
            throw ChromecastPluginError.castConnectionFailed
        }

        storeReceiverApplicationId(normalizedReceiverApplicationId)

        if !GCKCastContext.isSharedInstanceInitialized() {
            let discoveryCriteria = GCKDiscoveryCriteria(applicationID: normalizedReceiverApplicationId)
            let options = GCKCastOptions(discoveryCriteria: discoveryCriteria)
            options.physicalVolumeButtonsWillControlDeviceVolume = true
            GCKCastContext.setSharedInstanceWith(options)
        }

        activeReceiverApplicationId = normalizedReceiverApplicationId
        attachSessionListenerIfNeeded()
    }

    private func attachSessionListenerIfNeeded() {
        guard !sessionListenerAttached, GCKCastContext.isSharedInstanceInitialized() else {
            return
        }

        GCKCastContext.sharedInstance().sessionManager.add(self)
        sessionListenerAttached = true
    }

    private func activeHostView() -> UIView? {
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }

        let hostWindow = windowScene?.windows.first(where: \.isKeyWindow)
            ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)

        return hostWindow?.rootViewController?.view
    }

    private func reusableCastButton(in hostView: UIView) -> GCKUICastButton {
        if let existingButton = hostView.viewWithTag(Constants.temporaryCastButtonTag) as? GCKUICastButton {
            return existingButton
        }

        let castButton = GCKUICastButton(frame: CGRect(x: -100, y: -100, width: 44, height: 44))
        castButton.alpha = 0.01
        castButton.tag = Constants.temporaryCastButtonTag
        hostView.addSubview(castButton)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak castButton] in
            castButton?.removeFromSuperview()
        }

        return castButton
    }

    private func storeReceiverApplicationId(_ receiverApplicationId: String) {
        userDefaults.set(receiverApplicationId, forKey: Constants.receiverApplicationIdKey)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, willStart session: GCKSession) {
        sessionStateChangedHandler?("connecting")
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        sessionStateChangedHandler?("connected")
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
        sessionStateChangedHandler?("connected")
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        sessionStateChangedHandler?("disconnected")
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStartSessionWithError error: Error) {
        sessionStateChangedHandler?("disconnected")
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didFailToResumeSession session: GCKSession, withError error: Error?) {
        sessionStateChangedHandler?("disconnected")
    }
}
