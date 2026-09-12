# Registered-phone login · 2026-09-09

The backend now exposes `POST /api/pilgrims/lookup`. Flutter sends the entered
phone in its JSON body, receives the matching pilgrim and persists that record's
ID, group, agency and phone. It no longer compares against the fixed demo ID.

Validation completed:

- Existing demo phone and a second already-registered phone matched their own
  backend identities through live HTTP requests.
- Unknown phone returned 404; whitespace-only phone returned 422.
- Existing `GET /api/pilgrims/{id}` behavior remained intact.
- Python syntax compilation passed for the updated backend route file.
- Flutter static analysis: no issues. Unit/widget tests: 31 passed.
- Android emulator integration: entered the second registered phone in the
  actual onboarding screen, reached Home, and verified the persisted pilgrim,
  group and agency against its real backend record. Passed.

The complete backend replacement is `backend_patch/routes/operations.py` and is
already applied to the live Debian source mount. No records were created or
modified by these lookup tests. The emulator's local session was switched to the
second registered pilgrim during validation. Log out through Profile to try a
different registered phone.

Phone ownership is not verified. This remains prototype/demo identification,
not new registration or OTP authentication. Only outer whitespace is trimmed;
country-code and internal number formatting must match the registered value.
