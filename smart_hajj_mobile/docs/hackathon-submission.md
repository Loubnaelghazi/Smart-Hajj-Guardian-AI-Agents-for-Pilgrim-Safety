# Smart Hajj Guardian — submission preparation

Prepared September 10, 2026. This is a project-specific demo and submission guide, not a verified copy of every competition rule.

## Official information checked

The [HackerEarth challenge page](https://www.hackerearth.com/community/challenges/hackathon/mena-ignite-hackathon/) lists the prototype phase ending **September 13, 2026 at 18:29 UTC**. Confirm the deadline in your submission portal. The detailed Evaluation Criteria and Submission Format tabs were not available through the page reader; video limits, required attachments and scoring weights remain unverified.

[GSMA's event announcement](https://www.gsma.com/solutions-and-impact/gsma-open-gateway/gsma_events/gsma-mena-ignite-open-gateway-hackathon/) says teams must combine CAMARA network APIs and AI to solve regional challenges. The announcement's wider event schedule extends into October; do not use that as an extension of the prototype deadline.

## Suggested project description

Smart Hajj Guardian helps Hajj agencies coordinate assistance when pilgrims move away from their assigned meeting area. A Flutter companion shares consented phone GPS, offers guidance and an explicit SOS action. A FastAPI workflow combines available telecom evidence with backend risk rules and produces actionable incidents. Agency staff use a React dashboard to locate pilgrims by guide and group, identify stale or missing locations, and acknowledge and resolve incidents.

The prototype connects individual assistance with agency operations. GPS provides meeting-point distance; network verification and reachability provide distinct evidence. The interface keeps missing data and simulator signals visible rather than claiming continuous coverage or guaranteed rescue.

## Recommended demo sequence — approximately three minutes

This is a suggested narrative, not an official duration requirement.

| Segment | Show | Explain |
| --- | --- | --- |
| 0:00–0:20 | Agency, group, guide and safe area | Who uses the product and the practical separation problem |
| 0:20–0:50 | Registered demo pilgrim starts location sharing | Permission, GPS accuracy and actual server receipt |
| 0:50–1:20 | Live Tracking: guide/group filter, status chips, name search | An agency can find a person without scanning a long list; list and map show the same page |
| 1:20–1:50 | A controlled move outside the demo safe area | Distance, measurement time, uncertainty and backend guidance; clearly identify emulator/simulator data |
| 1:50–2:25 | Explicit SOS, then agency acknowledgment and resolution | A complete response workflow; acknowledgment is not proof of physical rescue |
| 2:25–2:45 | Stale location or disconnected feed | Honest fallback; missing updates never mean safe |
| 2:45–3:00 | Architecture and next pilot | Distinct contribution of phone data, CAMARA calls and the agent workflow |

Use a dedicated demo account and test meeting point. Do not change a real group's safe area for a recording. Keep SOS tests deliberate. Do not record credentials, real phone numbers or unrelated pilgrims. Use the existing controlled scenario files as preparation; their presence does not prove a successful rehearsal.

## Evidence to attach or demonstrate

- A working repository checkout with run instructions for FastAPI/MongoDB, React and Flutter; keep API credentials out of the submission.
- The actual CAMARA endpoints used, with sanitized example responses, source labels and error behavior. A successful HTTP call to a simulator is simulator evidence, not proof of a live deployment in Mina.
- A small architecture diagram: phone → FastAPI → telemetry / workflow → incident → agency acknowledgment. Separate network calls from device GPS.
- A reproducible demo scenario with expected inputs and outputs; include a stale-location case and explicit SOS confirmation.
- A short validation table distinguishing automated tests, emulator checks and physical-phone checks. Report only measured timings; do not invent rescue-time reductions or accuracy statistics.
- Describe the AI contribution precisely. The inspected backend uses LangGraph orchestration, deterministic risk scoring and navigation rules, plus in-memory history. LangGraph by itself does not prove an LLM, trained prediction model or learned crowd forecasting. If there is another AI component, show its actual code and input/output. Clarify eligibility with the organizers if the rules require more than this workflow.

## Features delivered for agency triage

- Group and guide filters, including unassigned guides; guide selection narrows the available group options.
- Search by pilgrim name or ID; filters compose.
- Status filters with counts: outside, inside, uncertain, stale, no location and no safe area.
- Attention-first or alphabetical sorting; 10/25/50 rows per page with matching map markers.
- Fit-visible-locations control, GPS accuracy circle and safe-area boundaries.
- Selected-pilgrim handoff: guide phone link, group details and incident center. Calling requires the operator's action.
- Backend availability text no longer claims that all CAMARA signals are connected.

These are client-side filters on an agency-scoped feed. They improve operational readability, but are not evidence of large-scale performance or secure tenant authentication.

## Honest readiness assessment

**Strong points:** a regionally relevant use case; useful dual interfaces for pilgrims and agencies; a clear opportunity to demonstrate CAMARA value beyond GPS; explicit SOS, confidence and stale-data handling; traceable incidents.

**Before submission:**

1. Restore a reliable Android launch and record a successful full scenario. The latest attempt compiled successfully but emulator ADB install/uninstall commands timed out. An ADB reset was declined, so that repair remains open.
2. Verify the exact AI and submission requirements in the portal. Avoid calling deterministic rules predictive AI.
3. Verify background GPS on a physical Android phone. The native service builds, but a successful minimized-app upload/Stop test has not yet been recorded. No iOS background support is claimed.
4. Review the dashboard in a browser and on a narrow screen. The in-app browser was unavailable in this session; build and logic tests are not visual QA.
5. Explain prototype limitations: exact phone lookup is not OTP authentication; agency URL filtering is not authorization; GPS distance is to a fixed meeting point, not a moving guide; connectivity is not crowd density; congestion may come from a simulator; there is no guaranteed rescue or uninterrupted tracking.

**After the demo:** prioritize authenticated sessions and agency roles, a defined location retention policy, physical-device battery/offline measurements, and a small agency pilot before adding more screens. Arabic/RTL and accessibility validation are valuable for the target audience, but should be tested as complete user flows.

The project has a credible hackathon story. Submission strength will depend most on a dependable end-to-end demonstration and precise evidence for network and AI claims. A winning outcome cannot be predicted from the current prototype alone.
