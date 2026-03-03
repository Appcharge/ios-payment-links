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
            url: "https://github.com/Appcharge/ios-payment-links/releases/download/1.7.0/ACPaymentLinks.xcframework.zip",
            checksum: "cf70f8ad7092001a78afd059697e00f17552f0676f939e5b18faad529c003c8a"
        )
    ]
)
