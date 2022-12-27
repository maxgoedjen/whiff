// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WhiffPackages",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .whiffLibrary(name: "TootSniffer"),
        .whiffLibrary(name: "WhiffFeatures"),
        .whiffLibrary(name: "WhiffFeaturesPreviews"),
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture.git",
            from: Version(stringLiteral: "0.47.2")
        ),
        .package(
            url: "https://github.com/pointfreeco/xctest-dynamic-overlay.git",
            from: Version(stringLiteral: "0.4.1")
        ),
        .package(
            url: "https://github.com/nicklockwood/SwiftFormat",
            from: "0.50.4"
        ),
    ],
    targets: flatten([
        .whiffTargets(name: "WhiffFeatures",
                       dependencies: [
                        "TootSniffer",
                        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                       ]),
        .whiffTargets(name: "TootSniffer",
                       dependencies: []),
        .whiffTargets(name: "WhiffFeaturesPreviews",
                       tests: false,
                       dependencies: [
                        "TootSniffer",
                        "WhiffFeatures",
                        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                       ], concurrencyStrictness: .targeted) // Previews don't support strict conccurrency
    ])
)

extension PackageDescription.Product {

    class func whiffLibrary(name: String) -> PackageDescription.Product {
        .library(
            name: name,
            targets: [name]
        )
    }

}

extension Array<PackageDescription.Target> {

    static func whiffTargets(name: String, tests: Bool = true, dependencies: [PackageDescription.Target.Dependency] = [], testDependencies: [PackageDescription.Target.Dependency] = [], concurrencyStrictness: ConcurrencyStrictness = .complete) -> [PackageDescription.Target] {
        var base: [PackageDescription.Target] = [
            .target(
                name: name,
                dependencies: dependencies,
                swiftSettings: [
                    // Almost complete, except for SwiftUI Preview issues
                    // SwiftUI.PreviewProvider:4:34 Main actor-isolated static property '_previews' cannot be used to satisfy nonisolated protocol requirement
                    .unsafeFlags(["-warnings-as-errors", "-Xfrontend", "-strict-concurrency=\(concurrencyStrictness.rawValue)"])
                ]
            ),
        ]
        if tests {
            let baseTestDeps: [PackageDescription.Target.Dependency] = [.byName(name: name)]
            base.append(
                .testTarget(
                    name: "\(name)Tests",
                    dependencies: dependencies + baseTestDeps + testDependencies
                )
            )
        }
        return base
    }

}

enum ConcurrencyStrictness: String {
    case targeted
    case complete
}

func flatten(_ items: [[PackageDescription.Target]]) -> [PackageDescription.Target] {
    return items.flatMap { $0 }
}
