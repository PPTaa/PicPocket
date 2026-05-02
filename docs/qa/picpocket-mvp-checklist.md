# PicPocket MVP QA Checklist

## Automated Checks

- Build app target for iOS Simulator.
- Build unit tests for iOS Simulator.
- Run unit tests when simulator launch is stable.

## Manual Device Checks

- Fresh install shows onboarding before the library.
- Photo permission prompt appears after tapping photo access.
- Limited photo access can continue into the app.
- Recent-year scan shows candidate, analyzed, classified, and unknown counts.
- Full-period scan can be started from the scan screen.
- Library shows counts for six categories and unknown.
- Search returns OCR text matches.
- Detail screen can change category and marks payment as sensitive.
- Settings shows current photo authorization status.
- Settings can open photo-access management.

## Privacy Checks

- No server upload path exists.
- No Photos delete, move, or album mutation is triggered by MVP scan.
- Classification records are stored only in SwiftData.
