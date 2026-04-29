# Bug Fix: Settings Screen Crash

## Issue
The application was encountering a `setState() called after dispose()` error in `_SettingsScreenState`. This typically happens when an asynchronous operation (fetching employee details) completes after the user has already navigated away from the `SettingsScreen` (disposing the widget).

## Analysis
- **File**: `lib/views/home/settings.dart`
- **Method**: `_fetchEmployeeDetails`
- **Cause**: The `_fetchEmployeeDetails` method is called in `initState`. It performs an asynchronous API call. If the user leaves the screen before the API responds, `setState` is called on a disposed widget, causing an exception.
- **Log Evidence**: `I/flutter (22763): Error fetching employee details: setState() called after dispose(): _SettingsScreenState#88d46(lifecycle state: defunct, not mounted)`

## Fix
- Added `if (!mounted) return;` checks before every `setState` call within the asynchronous `_fetchEmployeeDetails` method.
- Added a `mounted` check in the `catch` block as well.

## Files Modified
- `lib/views/home/settings.dart`

## Verification
- This change ensures that UI updates are only attempted if the widget is still currently in the widget tree.
- The `Payroll API` errors seen in the logs are server-side "Access Denied" errors. The application correctly handles these by catching the resulting `FormatException` (since the error is text/HTML, not JSON) and displaying a user-friendly error message, as seen in `lib/models/payroll_api.dart`. No client-side code changes are needed for the Payroll API issue unless the server is fixed to return proper JSON errors.
