# Dashboard language switch · 2026-09-10

The dashboard now has an **العربية / English** button beside Refresh. The selection is saved locally as `guardian.dashboard.language`. Switching updates document language and direction without remounting the current page or clearing its form state.

Translations cover navigation, overview, tracking filters/statuses, group and pilgrim management, guide and agency forms, notifications, incident actions, and confirmation dialogs. The incident briefing also follows the dashboard language, while retaining its separate language control. API payloads and identifiers remain unchanged; names and agency-authored text are supplied by the backend.

Validated: four locale/render tests, six tracking regression tests, and the Vite production build. Render tests cover seven main pages in both languages, navigation, notifications, briefing direction, persistence writes, and blocked browser storage. Browser visual inspection was unavailable in this session.

Sources are deployed to the Debian project's `client/src`; workspace review copies are in `dashboard_patch/src`. Refresh the dashboard if an older page is still open.
