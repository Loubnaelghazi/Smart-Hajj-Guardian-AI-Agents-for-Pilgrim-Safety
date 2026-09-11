import { t } from "../i18n";import { AlertTriangle, X } from "lucide-react";

export default function AlertToast({ incident, onClose, onOpen }) {
  if (!incident) return null;

  return (
    <div className="alert-toast">
      <div className="alert-toast-icon">
        <AlertTriangle size={20} />
      </div>

      <div className="alert-toast-copy">
        <span>{t("NEW GUARDIAN ALERT")}</span>
        <strong>{t(incident.type || "Safety incident detected")}</strong>
        <small>{t(" Risk: ")}
          {t(String(incident.risk_level || "UNKNOWN").toUpperCase())}
          {t(" · ")}{t(" Score ")}
          {t(incident.risk_score ?? "—")}
        </small>
      </div>

      <button className="toast-view-btn" onClick={onOpen}>{t(" View ")}

      </button>

      <button
        className="toast-close-btn"
        onClick={onClose}
        aria-label={t("Close alert")}>

        <X size={15} />
      </button>
    </div>);

}
