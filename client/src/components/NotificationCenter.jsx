import {
  AlertTriangle,
  BellRing,
  CheckCheck,
  ExternalLink,
  X,
} from "lucide-react";

function riskClass(level) {
  return String(level || "unknown").toLowerCase();
}

export default function NotificationCenter({
  open,
  notifications,
  unreadIds,
  onClose,
  onMarkAllRead,
  onOpenIncident,
}) {
  if (!open) return null;

  return (
    <>
      <button
        className="notification-overlay"
        aria-label="Close notifications"
        onClick={onClose}
      />

      <aside className="notification-panel">
        <div className="notification-panel-head">
          <div>
            <span className="panel-kicker">LIVE ALERTS</span>
            <h2>Notifications</h2>
          </div>

          <div className="notification-head-actions">
            {unreadIds.size > 0 && (
              <button
                className="notification-text-btn"
                onClick={onMarkAllRead}
              >
                <CheckCheck size={14} />
                Mark all read
              </button>
            )}

            <button
              className="icon-plain"
              onClick={onClose}
              aria-label="Close"
            >
              <X size={17} />
            </button>
          </div>
        </div>

        <div className="notification-panel-body">
          {notifications.length === 0 ? (
            <div className="notification-empty">
              <BellRing size={27} />
              <h3>No active alerts</h3>
              <p>New Guardian incidents will appear here automatically.</p>
            </div>
          ) : (
            notifications.map((incident) => {
              const unread = unreadIds.has(incident.id);

              return (
                <button
                  key={incident.id}
                  className={`notification-item ${
                    unread ? "unread" : ""
                  }`}
                  onClick={() => onOpenIncident(incident)}
                >
                  <div className="notification-alert-icon">
                    <AlertTriangle size={17} />
                  </div>

                  <div className="notification-item-copy">
                    <div className="notification-title-row">
                      <strong>
                        {incident.type || "Safety incident"}
                      </strong>

                      <span
                        className={`risk-pill risk-${riskClass(
                          incident.risk_level
                        )}`}
                      >
                        {String(
                          incident.risk_level || "ALERT"
                        ).toUpperCase()}
                      </span>
                    </div>

                    <span>
                      Risk {incident.risk_score ?? "—"}
                      {" · "}
                      {incident.navigation_action ||
                        "Agency attention required"}
                    </span>

                    <small>
                      {incident.pilgrim_id || "Unknown pilgrim"}
                      {" · "}
                      {incident.group_id || "Unknown group"}
                    </small>
                  </div>

                  <ExternalLink size={14} className="notification-open-icon" />
                </button>
              );
            })
          )}
        </div>
      </aside>
    </>
  );
}
