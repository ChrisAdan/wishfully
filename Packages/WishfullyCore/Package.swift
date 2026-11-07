// swift-tools-version: 6.0
// WishfullyCore: Wishfully's domain logic in pure Swift. No UI, no persistence,
// no Apple-only frameworks, so it builds and tests on Linux CI in seconds.
import PackageDescription

let package = Package(
    name: "WishfullyCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "WishfullyCore", targets: ["WishfullyCore"]),
    ],
    targets: [
        .target(name: "WishfullyCore"),
        .testTarget(name: "WishfullyCoreTests", dependencies: ["WishfullyCore"]),
    ]
)
