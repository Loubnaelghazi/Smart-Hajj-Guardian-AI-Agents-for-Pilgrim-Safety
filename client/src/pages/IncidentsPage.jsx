import { t } from "../i18n";import { useState } from "react";
import { AlertTriangle } from "lucide-react";
import IncidentCard from "../components/IncidentCard";
import IncidentBriefing from "../components/IncidentBriefing";
import { api } from "../services/api";

export default function IncidentsPage({ overview, refresh }) {
  const [busy, setBusy] = useState("");
  const [error, setError] = useState("");
  const incidents = overview?.active_incidents || [];

  async function act(type, id) {
    setBusy(id);
    setError("");

    try {
      if (type === "ack") {
        await api.acknowledgeIncident(id);
      } else {
        await api.resolveIncident(id);
      }
      await refresh();
    } catch (e) {
      setError(e.message || "Unable to update incident.");
    } finally {
      setBusy("");
    }
  }

  return (
    <div className="page-stack">
      {t(error && <div className="error-banner">{t(error)}</div>)}

      <section className="panel">
        <div className="panel-heading">
          <div>
            <span className="panel-kicker">{t("INCIDENT OPERATIONS")}</span>
            <h2>{t("Active safety incidents")}</h2>
          </div>
          <span className="critical-chip">{t(incidents.length)}{t(" active")}</span>
        </div>

        {t(incidents.length === 0 ?
        <div className="empty-state">
            <div className="empty-state-icon">
              <AlertTriangle size={26} />
            </div>
            <h3>{t("No active incidents")}</h3>
            <p>{t("Guardian is monitoring registered pilgrims and groups.")}</p>
          </div> :

        <div className="incident-list">
            {t(incidents.map((incident) =>
          <div key={incident.id}>
              <IncidentCard
              key={incident.id}
              incident={incident}
              busy={busy === incident.id}
              onAcknowledge={(id) => act("ack", id)}
              onResolve={(id) => act("resolve", id)} />

              <IncidentBriefing key={`${incident.id}:${incident.status}`} incident={incident} />
              </div>
          ))}
          </div>)
        }
      </section>
    </div>);

}
