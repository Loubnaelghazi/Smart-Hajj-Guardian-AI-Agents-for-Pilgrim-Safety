import { t } from "../i18n";import {
  Check,
  CheckCircle2,
  MapPin,
  ShieldAlert,
  UserRound } from
"lucide-react";

function riskClass(level) {
  return String(level || "unknown").toLowerCase();
}

export default function IncidentCard({
  incident,
  onAcknowledge,
  onResolve,
  busy
}) {
  const status = String(incident.status || "OPEN").toUpperCase();

  return (
    <article className="incident-card">
      <div className="incident-card-top">
        <div className="incident-left">
          <div className="incident-icon-box">
            <ShieldAlert size={19} />
          </div>

          <div>
            <div className="incident-title-row">
              <h3>{t(incident.type || "Safety incident")}</h3>
              <span className={`incident-status status-${status.toLowerCase()}`}>
                {t(status)}
              </span>
            </div>
            <small>{incident.id}</small>
          </div>
        </div>

        <span className={`risk-pill risk-${riskClass(incident.risk_level)}`}>
          {t(String(incident.risk_level || "UNKNOWN").toUpperCase())}
        </span>
      </div>

      <div className="incident-metrics">
        <div>
          <span>{t("Risk score")}</span>
          <strong>{t(incident.risk_score ?? "—")}</strong>
        </div>
        <div>
          <span>{t("Confidence")}</span>
          <strong>{t(incident.confidence_score ?? "—")}</strong>
        </div>
        <div>
          <span>{t("Recommended action")}</span>
          <strong>{t(incident.navigation_action || "—")}</strong>
        </div>
      </div>

      <div className="incident-meta">
        <span><UserRound size={14} /> {t(incident.pilgrim_id || "Unknown pilgrim")}</span>
        <span><MapPin size={14} /> {t(incident.group_id || "Unknown group")}</span>
      </div>

      <div className="incident-card-actions">
        {t(status === "OPEN" &&
        <button
          className="action-btn action-ack"
          disabled={busy}
          onClick={() => onAcknowledge(incident.id)}>

            <Check size={15} />{t(" Acknowledge ")}

        </button>)
        }

        {t(status !== "RESOLVED" &&
        <button
          className="action-btn action-resolve"
          disabled={busy}
          onClick={() => onResolve(incident.id)}>

            <CheckCircle2 size={15} />{t(" Resolve ")}

        </button>)
        }
      </div>
    </article>);

}
