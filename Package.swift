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
            url: "https://github.com/Appcharge/ios-payment-links/releases/download/1.8.0/ACPaymentLinks.xcframework.zip",
            checksum: "ceaf39d6cb95d895603ee1ac7e84d3c686823eac1185f9fdff4e40659c0368b3"
        )
    ]
)
