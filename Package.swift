// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProIME",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "ProIME",
            targets: ["ProIME"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ProIME",
            path: "Sources",
            resources: [
                .copy("../Resources/Info.plist"),
                .copy("../Resources/icon.tiff"),
                .copy("../Resources/en.lproj"),
            ],
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("InputMethodKit"),
            ]
        )
    ]
)
