# Submission Asset Manifest

These files were captured from the QRAlarm Debug build running on an iPhone 16 Pro simulator (iOS 18.6). They contain no personal information.

## App icon

- `app-icon-1024.png` — 1024 × 1024, RGB PNG, no alpha channel.
- This is the project's existing icon artwork converted from a mislabeled JPEG source into a genuine PNG. No new brand artwork was generated.

## Frame-free screenshots

All screenshots are 1206 × 2622 RGBA PNG files captured directly from the simulator without a device frame.

- `screenshots/alarm-list.png` — the alarm list and Pro entry point.
- `screenshots/pro-paywall.png` — the current RevenueCat Offering at US$9.99 after a cancelled test purchase.
- `screenshots/test-store-modal.png` — the real RevenueCat Test Store modal for product `monthly`.

## Demo video

- `video/qralarm-test-store-demo.mp4` — 60.32 seconds, 1206 × 2622, H.264, silent.
- Honest partial flow: open an existing alarm, encounter the locked QR feature, view the paywall and current Offering, open the RevenueCat Test Store modal, cancel, and confirm that Pro remains locked.
- The recording does **not** claim a successful purchase, `PRO ✓`, a saved target QR code, or a completed QR camera scan.

## Still required for the final competition demo

Record the remaining flow on a camera-enabled iPhone with the entrant present:

1. Create a new alarm and show its notification scheduling.
2. Intentionally choose **Success** in the RevenueCat Test Store and show `PRO ✓`.
3. Save a target QR code.
4. Show rejection of a different code, then successful dismissal with the target code.
5. Add the English narration from `SUBMISSION.md`, export at no more than two minutes, and upload it to a public video host.
