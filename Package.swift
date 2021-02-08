// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Emoji-Logger",
    platforms: [
        .iOS(.v11)
    ],
      products: [
        .library(name: "GeoFire", targets: ["GeoFire"]),
    ],
    dependencies: [
    ],
  
    targets: [
        .target(name: "GeoFire", dependencies: [], path: "./Sources/Soto/Services/ACM"),
    ]
)
