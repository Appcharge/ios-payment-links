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
            url: "https://github.com/Appcharge/ios-payment-links/releases/download/1.6.1/ACPaymentLinks.xcframework.zip",
            checksum: "6b7bdde04ef4f35c575691ab49eb42a773eaf731af056e5519be4cce6a058546"
        )
    ]
)
