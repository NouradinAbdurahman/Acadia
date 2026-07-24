// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// PATCHED: upstream workmanager_apple 0.9.1+2 ships Package.swift directly at
// ios/Package.swift with Sources/Resources as siblings, but Flutter's plugin
// tooling only recognizes Swift Package Manager support when it finds
// ios/<plugin_name>/Package.swift (see Plugin.pluginSwiftPackagePath in
// flutter_tools/lib/src/plugins.dart) — that mismatch is why `flutter build
// ios` reported workmanager_apple as not supporting SPM even though it does.
// Sources/ and Resources/ were moved inside this subdirectory too: Swift
// Package Manager requires a target's path to stay within the package root
// (the directory containing Package.swift), so a `../` escape doesn't
// resolve ("target is outside the package root").
//
// The product is also renamed from "workmanager_apple" to "workmanager-apple":
// Flutter's generated FlutterGeneratedPluginSwiftPackage/Package.swift (built
// from the plugin's name with underscores replaced by hyphens) depends on a
// product literally called "workmanager-apple" — upstream's original product
// name doesn't match that and fails resolution with "product 'workmanager-apple'
// ... not found in package 'workmanager_apple'".

import PackageDescription

let package = Package(
    name: "workmanager_apple",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "workmanager-apple",
            targets: ["workmanager_apple"]
        )
    ],
    targets: [
        .target(
            name: "workmanager_apple",
            path: "Sources/workmanager_apple",
            resources: [
                .process("../../Resources")
            ]
        )
    ]
)
