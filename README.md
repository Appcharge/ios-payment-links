# 💳 ACPaymentLinks

ACPaymentLinks is a lightweight, in-app iOS checkout SDK by Appcharge.
This repository contains the public Swift Package Manager (SPM) integration and a prebuilt static `.xcframework`.

## 📦 SDK Requirements

- **Minimum iOS:** 13.0  
- **Framework type:** Static `.xcframework`  
- **Distribution:** Swift Package Manager (SPM)   
- **Swift:** 5.7–5.10  
- **Xcode:** 15 or newer  

## 📲 Installation (Swift Package Manager)

### Add via Xcode (Recommended):

#### 1. Open your iOS project in Xcode.

#### 2. Go to:
```bash
File → Add Package Dependencies…
```

#### 3. Enter the repository URL:
```bash
https://github.com/Appcharge/ios-payment-links
```

#### 4. Choose your version rule:
- **a** Up to Next Major Version (recommended)
- **b** Select a specific version tag

#### 5. Select the ACPaymentLinks library product.

#### 6. Add it to your app target.

## Basic Usage Example

```swift
import UIKit
import ACPaymentLinks

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Example usage here
    }
}
```

## Updating the SDK
#### To update to the latest compatible version:

#### Go to:
```swift
File → Packages → Update to Latest Package Versions
```

#### Or via Swift CLI:
```swift
swift package update
```

## 🚨 Troubleshooting

- Ensure your deployment target matches iOS 13+
- Clean build folder: Shift + Cmd + K
- Delete Derived Data if needed
- Make sure you are using Xcode 15+

## License
MIT
