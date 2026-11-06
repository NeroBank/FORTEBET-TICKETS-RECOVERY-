# FORTBET TICKET RECOVERY — Starter Project

This ZIP contains a Flutter Android starter prototype.

## Included
- Black/red/gold app theme and simple logo asset
- Camera capture and gallery import
- On-device OCR using Google ML Kit
- Review and edit OCR fields before saving
- Local SQLite storage on the Android phone
- Unique Ticket ID protection against duplicate records
- Ticket ID search
- Ticket history
- Dashboard calculation for records marked WON + UNPAID

## Important limitations
- This is a prototype, not a production-ready financial or payment system.
- It does not connect to Fortebet, alter the terminal, retrieve secure codes, or bypass verification.
- A ticket's WON result is separate from its PAID/UNPAID status.
- OCR can make mistakes. Compare all extracted fields with the terminal before saving.
- The app does not independently prove that a ticket is genuine or unpaid. Confirm through Fortebet's authorised process.
- No customer records or sample ticket IDs are preloaded.

## Build APK on a computer with Flutter installed
1. Extract this ZIP.
2. Open a terminal inside the `fortbet_ticket_recovery` folder.
3. Run `flutter pub get`.
4. Connect an Android phone with USB debugging enabled.
5. Run `flutter run`.
6. To build a release APK, run `flutter build apk --release`.
7. APK output: `build/app/outputs/flutter-apk/app-release.apk`.

## GitHub Actions
A starter workflow is included at `.github/workflows/build-android-apk.yml`. Push the project to a GitHub repository and run the workflow from the Actions tab.

## Next stages
1. Test and tune OCR against more terminal result screens.
2. Add better field confidence indicators and Fortebet-specific parsing.
3. Add encrypted backup/export.
4. Add a customer collection audit trail.
5. Add secure-code retrieval only if Fortebet provides written authorisation and a documented integration.
