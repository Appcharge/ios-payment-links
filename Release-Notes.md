## ACPaymentLinks v1.8.0

### iOS Payment Links SDK
- New event system logic for better reliability and performance, including normalized SDK error codes for consistency across platforms.
- The main bridge delegate moved to be part of the initialization process.
- AddedorderResponseModelto theonPurchaseFailedcallback, allowing you to access full order details on failed purchases.
- SDK now includes network state support with retry functionality to handle cases of internet connection interruptions during order validation.
- Improved handling of internet connection interruptions during order validation polling (error code 9001).
- Enriched Debug mode data.
- Updated error codes with clearer, more specific errors that better match current SDK behavior. See the changes in theTroubleshootingguide.

