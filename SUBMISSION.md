# Shipaton 2026 Submission Notes

## English feature description

**QRAlarm turns getting out of bed into a verifiable action.** The free app supports practical one-time and repeating alarms. QRAlarm Pro adds QR Wake Mission: the user saves a QR code placed away from the bed, and the alarm rejects every other code until that exact target is scanned. RevenueCat Test Store powers the complete purchase, entitlement, cancellation, failure, and restore experience without requiring an App Store release.

## English testing instructions

1. Install and launch QRAlarm on an iPhone running iOS 17 or later.
2. Allow notifications, create a standard alarm, and verify the scheduled notification appears.
3. Open **GO PRO**, tap **UNLOCK PRO**, and choose **Success** in the RevenueCat Test Store modal.
4. Confirm the toolbar changes to **PRO ✓**.
5. Create an alarm, enable **QR CODE UNLOCK**, and scan a target QR code.
6. Tap **TEST QR WAKE-UP** on the alarm list.
7. Scan a different code and verify it is rejected. Scan the saved target and verify the alarm closes.
8. Open **PRO ✓** and tap **RESTORE PURCHASES** to verify RevenueCat returns the active `qralarm_pro` entitlement.

Also test RevenueCat's **Cancel** and **Failure** outcomes before Success. Both must leave Pro locked.

## Two-minute English demo script

**0:00–0:15 — Problem**
“I am a 16-year-old student, and I built QRAlarm because dismissing an alarm is too easy when you are half asleep. QRAlarm makes waking up an action, not just a tap.”

**0:15–0:35 — Free app**
Show the alarm list and create a repeating alarm.
“The free app supports one-time and repeating alarms, labels, snooze, and real local-notification scheduling on iOS 17 and later.”

**0:35–1:05 — RevenueCat purchase**
Tap **GO PRO**, briefly show the paywall, then buy and choose Success in the Test Store modal.
“QR Wake Mission is unlocked by the `qralarm_pro` entitlement. This purchase is handled by the RevenueCat SDK and Test Store, so no real money or App Store product is needed. CustomerInfo is the source of truth, and restore purchases is built in.”

**1:05–1:35 — Pro setup**
Edit an alarm, enable QR unlock, and scan a QR code placed across the room.
“Pro users save a specific target code. QRAlarm stores the target locally and requires an exact match.”

**1:35–1:52 — Payoff**
Tap **TEST QR WAKE-UP**, scan a wrong code, then the correct code.
“A random QR code is rejected. The saved code stops the alarm, proving I got out of bed.”

**1:52–2:00 — Close**
Show **PRO ✓** and Restore Purchases.
“QRAlarm is open source, tested on iPhone, and built by a student for students. Thank you.”

## Before submitting

- [x] Configure the Debug build with a RevenueCat Test Store public SDK key.
- [x] Complete the `monthly` product → `qralarm_pro` entitlement → current Offering setup.
- [x] Prepare the 1024 × 1024 icon and frame-free simulator screenshots in `submission-assets/`.
- [x] Record a 60-second silent draft showing the real paywall, Test Store modal, and cancellation behavior.
- [ ] Record a successful purchase and verify it in RevenueCat sandbox data.
- [ ] Run the full test list in `README.md` on a camera-enabled iPhone.
- [ ] Keep the final English video at or below two minutes and make it publicly viewable.
- [x] Publish this source repository publicly with `LICENSE` included.
- [ ] Submit using the student's school email address.
- [ ] Obtain and retain parent or guardian consent required for a 16-year-old entrant.
- [ ] Recheck the official rules and submit before the deadline in Taiwan time.

Do not publish an App Store build that contains the RevenueCat Test Store key.

The draft video is intentionally incomplete: it cancels the Test Store purchase and does not demonstrate camera scanning. See `submission-assets/README.md` for exact file specifications and the remaining final-video checklist.
