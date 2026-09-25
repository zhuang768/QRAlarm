# QRAlarm

QRAlarm is an iOS alarm app that helps people get out of bed instead of dismissing an alarm on autopilot. Its optional Pro feature, **QR Wake Mission**, requires the user to scan a previously saved QR code before the alarm can be stopped.

Built for the RevenueCat Shipaton 2026 Next Gen Award.

## What works

- One-time and weekly repeating alarms using local notifications
- Alarm labels, enable/disable, editing, deletion, and nine-minute snooze
- Free hold-to-stop alarm flow
- Pro QR Wake Mission with a saved target-code match
- RevenueCat Test Store paywall, purchase, entitlement refresh, and restore
- Instant `TEST QR WAKE-UP` flow for a reliable live demo

## Requirements

- Xcode 26.6 or later recommended
- iOS 17 or later
- A camera-enabled iPhone for QR scanning
- A free RevenueCat project for Test Store purchases

The RevenueCat SDK is installed with Swift Package Manager. The project requires SDK `5.43.0` or later because that is the minimum version supporting RevenueCat Test Store on iOS.

## RevenueCat Test Store setup

No App Store Connect product or paid Apple Developer membership is required for this test flow.

1. In RevenueCat, create a project and add a **Test Store** app.
2. Create the monthly Test Store product with identifier `monthly`.
3. Create an entitlement with the exact identifier `qralarm_pro` and attach the product.
4. Create a current Offering and add the product as its monthly package.
5. Leave **Sandbox Testing Access** set to `Anybody` for judging, or allow the specific anonymous App User ID used for the demo.
6. Copy the Test Store public SDK key into the `REVENUECAT_API_KEY` build setting for the Debug configuration. This repository's Debug configuration is already set up for its QRAlarm Test Store project.

The Release configuration leaves this value empty, and the app also refuses to configure RevenueCat Test Store outside `DEBUG`. A Test Store key must never be used in an App Store build; configure a separate Apple app and public SDK key before any future production release.

## Build

Open `QRAlarm.xcodeproj`, choose the `QRAlarm` scheme, and run on an iPhone or iOS Simulator. From Terminal:

```sh
DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer \
  xcodebuild -project QRAlarm.xcodeproj \
  -scheme QRAlarm \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

## Test the purchase and entitlement

1. Launch the app and allow notifications.
2. Tap **GO PRO** and verify the current Offering and price load.
3. Tap **UNLOCK PRO**. In the RevenueCat Test Store modal, test **Cancel** and **Failure**; neither may unlock Pro.
4. Repeat and choose **Success**. The app must show `PRO ✓` immediately.
5. Add or edit an alarm, enable **QR CODE UNLOCK**, and scan a target QR code.
6. Save the alarm and tap **TEST QR WAKE-UP**.
7. Verify that a different QR code is rejected and the saved code stops the alarm.
8. Relaunch the app and verify Pro remains active after CustomerInfo refresh.
9. Tap **PRO ✓**, then **RESTORE PURCHASES**, and verify the active entitlement is restored.
10. Confirm the sandbox customer and transaction are visible in the RevenueCat dashboard.

RevenueCat Test Store monthly subscriptions renew every five minutes, up to five times, and then expire. After expiration, relaunch or refresh the paywall to verify the Pro feature locks again.

## Platform limitation

QRAlarm uses standard local notifications so it works from iOS 17 onward. iOS controls notification presentation and does not allow third-party apps to behave exactly like Apple's Clock app or use critical alerts without a special entitlement. For the clearest demo, keep the app open and use **TEST QR WAKE-UP**; also verify one real scheduled notification on an iPhone.

## License

MIT — see [LICENSE](LICENSE).
