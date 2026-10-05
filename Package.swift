// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ios-payment-links",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ACPaymentLinks",
            targets: ["ACPaymentLinks"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "ACPaymentLinks",
            url: "https://github.com/Appcharge/ios-payment-links/releases/download/2.0.0/ACPaymentLinks.xcframework.zip",
            checksum: "bcb22d4e9180e50a95abcedfae131858dcac8980ab3ad702186d3c2d936cfaae"
        )
    ]
)
