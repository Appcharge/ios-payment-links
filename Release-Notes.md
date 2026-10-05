## ACPaymentLinks v2.0.0

### iOS Payment Links SDK
- Initialization no longer relies on customerId.
- Improved initialization and deeplink performance.
- The customerId parameter is now required when opening the checkout.
- Price points have been removed and are now managed from the server.
- Callback interface now includes onPurchaseCanceled.
- SDK restores order information on failed or canceled purchases when returning via deeplink.
- Replaced the sfsvc browser mode with internal. You can now only switch between internal and external. The SDK selects the specific browser implementation.

