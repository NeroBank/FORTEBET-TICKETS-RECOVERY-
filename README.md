# ForteBet Ticket Recovery

Flutter Android app for recording individual ticket details from terminal result screens.

## Included
- ForteBet orange-and-white football app icon and matching in-app header
- Black/red interface with a properly formatted Nigerian naira symbol (₦)
- Camera capture and gallery import
- On-device OCR using Google ML Kit
- Editable review screen before saving
- Local SQLite storage on the phone
- Duplicate Ticket ID protection
- Ticket ID search and ticket history
- Delete an individual ticket or clear all history after confirmation
- Outstanding winnings calculated only for records marked WON and UNPAID

## Important limitations
This is a local recordkeeping prototype. It does not connect to Fortebet, verify ticket authenticity, retrieve secure codes, or bypass terminal verification. Confirm each ticket and payment status through Fortebet's authorised process. OCR may misread details; review all fields before saving. No ticket records are preloaded.

## Build with GitHub Actions
The workflow is at `.github/workflows/build-android-apk.yml`. Push the project to GitHub, then open Actions and run **Build ForteBet Ticket Recovery APK**. Download the artifact named `fortbet-ticket-recovery-testing-apk`.

The workflow generates Android project files, runs `dart run flutter_launcher_icons` to create the Android launcher icon from `assets/fortebet_football.png`, and builds a debug testing APK.

## Local build
Run `flutter pub get`, `dart run flutter_launcher_icons`, then `flutter build apk --release`.
