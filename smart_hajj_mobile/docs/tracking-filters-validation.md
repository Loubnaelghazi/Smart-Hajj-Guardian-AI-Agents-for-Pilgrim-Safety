# Agency tracking filters — September 10, 2026

Implemented in the Debian React client, with workspace copies in `dashboard_patch/`.

Verified:
- Six Node tests pass: local expiration, missing/stale data, combined guide/group/search/status filters, attention ordering and offline behavior, pagination boundaries, invalid timestamps.
- Nine backend tests pass, including agency-scoped guide retrieval and observation lookup, stale GPS, uncertainty, and recalculation after safe-area changes.
- Final Vite production build passes.

The list defaults to 10 entries; 25 and 50 are available. Map markers match the displayed page, with a visible caption. Guide changes reset the group selection. Filter changes reset pagination and selection. Counts reflect guide/group/search scope before applying the status filter. Offline feed data is treated as last-known location.

Manual browser checks remain outstanding because no in-app browser was available. Validate the guide/group selectors, empty search, Next/Previous, map selection, guide dial link and navigation shortcuts before recording. These tests do not validate mobile background tracking or remedy the emulator launch issue.
