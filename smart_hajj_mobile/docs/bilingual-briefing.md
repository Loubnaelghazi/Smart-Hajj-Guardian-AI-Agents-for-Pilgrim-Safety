# English / Arabic incident briefing

The agency Incident Center and the mobile Emergency screen provide an English/العربية toggle and a Prepare / refresh briefing button. Arabic uses right-to-left layout. This feature translates the briefing, not every screen of the application.

`POST /api/incidents/{id}/briefing` collects incident status, recorded incident risk and available latest GPS facts. It distinguishes current GPS from stale/missing data and mock locations. It does not assert operator reachability or congestion when those signals are not verified by the briefing. Acknowledgment never claims rescue.

A LangGraph node calls an OpenAI-compatible Chat Completions endpoint to prioritize the verified facts. Output is a validated permutation of fact IDs. English and Arabic text are controlled, paired renderings of the same evidence; the model cannot add numbers or change safety instructions. This is AI-assisted evidence prioritization, not free-form medical advice, predictive crowd AI, or an autonomous rescue system.

## Enable AI

Configure these server-side variables in the Debian backend environment / project `.env` and restart or recreate the backend as required by your Docker setup:

```dotenv
BRIEFING_API_URL=https://YOUR-PROVIDER/v1/chat/completions
BRIEFING_MODEL=YOUR-MODEL-ID
BRIEFING_API_KEY=YOUR-PRIVATE-KEY
```

Use the full Chat Completions URL and a model supporting JSON object responses. Do not paste keys into chat or put them in Flutter, React, screenshots or git. The configured service receives anonymous fact text including incident severity and approximate distance, but not names, phone numbers, identifiers or exact GPS coordinates. Credentials go only to the configured endpoint.

Without configuration, or after a provider timeout/invalid output, the briefing remains usable and explicitly displays **Evidence summary — AI unavailable**. A valid provider response displays **AI-prioritized evidence**. There is no claim that a live model was tested until credentials, endpoint and model are configured.

The implementation validates model output itself because JSON mode guarantees JSON syntax rather than adherence to a particular schema. [Official documentation](https://developers.openai.com/api/docs/guides/structured-outputs).

Tests cover paired language facts, missing evidence, acknowledged status, unavailable provider, valid prioritization and rejection of fabricated/omitted/duplicate IDs. Model responses in automated tests are mocked.

Backend files: `backend_patch/briefing.py`, router registration in `backend_patch/main.py`. React files: `dashboard_patch/IncidentBriefing.jsx` and `IncidentsPage.jsx`. Flutter: `lib/widgets/incident_briefing.dart`.

Validation: 32 Flutter tests passed, including English/Arabic switching and RTL layout; four backend briefing tests passed with mocked model responses; the React production build passed. The deployed endpoint returned four bilingual facts for an existing incident in `evidence_summary` mode. No incident state was changed. A real provider call and visual device/browser validation remain pending.
