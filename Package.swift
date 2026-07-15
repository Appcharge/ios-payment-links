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
            url: "https://github.com/Appcharge/ios-payment-links/releases/download/1.9.0/ACPaymentLinks.xcframework.zip",
            checksum: "b916759f849c5e3696af7697f46466b84804d38b10169b8089b8ca0779157bdb"
        )
    ]
)
