// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapacitorChromecast",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CapacitorChromecast",
            targets: ["ChromecastPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0"),
        .package(url: "https://github.com/SRGSSR/google-cast-sdk.git", exact: "4.8.4")
    ],
    targets: [
        .target(
            name: "ChromecastPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "GoogleCast", package: "google-cast-sdk")
            ],
            path: "ios/Sources/ChromecastPlugin"),
        .testTarget(
            name: "ChromecastPluginTests",
            dependencies: ["ChromecastPlugin"],
            path: "ios/Tests/ChromecastPluginTests")
    ]
)
