// swift-tools-version: 5.9

// Projet « app » au format Swift Playgrounds : s'ouvre tel quel dans Xcode (Mac)
// ou dans Swift Playgrounds (iPad / Mac). Compilé et envoyé sur TestFlight par GitHub Actions.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Culture Fight",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "Culture Fight",
            targets: ["AppModule"],
            bundleIdentifier: "fr.hugomorana.culturefight",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .asset("AccentColor"),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            // iPhone : portrait seulement. iPad : toutes les orientations (exigé pour le multitâche).
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight(.when(deviceFamilies: [.pad])),
                .landscapeLeft(.when(deviceFamilies: [.pad])),
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
