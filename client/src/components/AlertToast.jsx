import { AlertTriangle, X } from "lucide-react";

export default function AlertToast({ incident, onClose, onOpen }) {
  if (!incident) return null;

  return (
    <div className="alert-toast">
      <div className="alert-toast-icon">
        <AlertTriangle size={20} />
      </div>

      <div className="alert-toast-copy">
        <span>NEW GUARDIAN ALERT</span>
        <strong>{incident.type || "Safety incident detected"}</strong>
        <small>
          Risk: {String(incident.risk_level || "UNKNOWN").toUpperCase()}
          {" · "}
          Score {incident.risk_score ?? "—"}
        </small>
      </div>

      <button className="toast-view-btn" onClick={onOpen}>
        View
      </button>

      <button
        className="toast-close-btn"
        onClick={onClose}
        aria-label="Close alert"
      >
        <X size={15} />
      </button>
    </div>
  );
}
