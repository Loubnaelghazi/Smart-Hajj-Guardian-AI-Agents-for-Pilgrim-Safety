import { t } from "../i18n";import { useState } from "react";
import {
  AlertTriangle,
  ShieldAlert,
  UserRound,
  Users,
  RadioTower,
  ArrowUpRight } from
"lucide-react";
import StatCard from "../components/StatCard";
import IncidentCard from "../components/IncidentCard";
import { api } from "../services/api";

export default function OverviewPage({ overview, health, refresh }) {
  const [busy, setBusy] = useState("");

  const summary = overview?.summary || {};
  const incidents = overview?.active_incidents || [];
  const groups = overview?.groups || [];

  async function act(type, id) {
    setBusy(id);
    try {
      if (type === "ack") {
        await api.acknowledgeIncident(id);
      } else {
        await api.resolveIncident(id);
      }
      await refresh();
    } finally {
      setBusy("");
    }
  }

  return (
    <div className="page-stack">
      <section className="overview-hero">
        <div className="overview-hero-content">
          <span className="hero-label">{t("AGENCY SAFETY OPERATIONS")}</span>
          <h2>{t(" One command center for ")}

            <span>{t(" safer pilgrim journeys.")}</span>
          </h2>
          <p>{t(" Guardian combines telecom intelligence, risk scoring and operational workflows so your teams can act before situations escalate. ")}


          </p>

          <div className="hero-badges">
            <span>{t(health?.status === 'ok' ? 'Guardian backend reachable' : 'Backend status unavailable')}</span>
            <span><RadioTower size={13} />{t(" CAMARA network signals")}</span>
          </div>
        </div>

        <div className="overview-hero-card">
          <div className="hero-card-icon">
            <ShieldAlert size={24} />
          </div>
          <div>
            <span>{t("System status")}</span>
            <strong>
              {t(health?.status === 'ok' && health?.mongodb ? "Backend and database available" : "Check backend connection")}
            </strong>
            <small>{t(" MongoDB ")}
              {t(health?.mongodb ? "connected" : "status unavailable")}
            </small>
          </div>
        </div>
      </section>

      <section className="metrics-grid">
        <StatCard
          title={t("Groups")}
          value={summary.groups ?? overview?.groups_count}
          subtitle={t("Operational groups")}
          icon={Users}
          tone="blue" />

        <StatCard
          title={t("Pilgrims")}
          value={summary.pilgrims ?? overview?.pilgrims_count}
          subtitle={t("Registered pilgrims")}
          icon={UserRound}
          tone="emerald" />

        <StatCard
          title={t("Active incidents")}
          value={summary.active_incidents ?? overview?.active_incidents_count}
          subtitle={t("Cases needing attention")}
          icon={AlertTriangle}
          tone="amber" />

        <StatCard
          title={t("Critical incidents")}
          value={summary.critical_incidents ?? overview?.critical_incidents_count}
          subtitle={t("Highest priority")}
          icon={ShieldAlert}
          tone="red" />

      </section>

      <section className="dashboard-grid">
        <div className="panel panel-large">
          <div className="panel-heading">
            <div>
              <span className="panel-kicker">{t("LIVE OPERATIONS")}</span>
              <h2>{t("Active incidents")}</h2>
            </div>
            <button className="link-button" type="button">{t(" View all ")}
              <ArrowUpRight size={14} />
            </button>
          </div>

          {t(incidents.length === 0 ?
          <div className="empty-state">
              <div className="empty-state-icon">
                <ShieldAlert size={26} />
              </div>
              <h3>{t("No active incidents")}</h3>
              <p>{t("Your agency is currently operating without active safety alerts.")}</p>
            </div> :

          <div className="incident-list">
              {t(incidents.slice(0, 4).map((incident) =>
            <IncidentCard
              key={incident.id}
              incident={incident}
              busy={busy === incident.id}
              onAcknowledge={(id) => act("ack", id)}
              onResolve={(id) => act("resolve", id)} />

            ))}
            </div>)
          }
        </div>

        <div className="panel">
          <div className="panel-heading">
            <div>
              <span className="panel-kicker">{t("GROUP COVERAGE")}</span>
              <h2>{t("Operational groups")}</h2>
            </div>
            <span className="count-chip">{t(groups.length)}</span>
          </div>

          <div className="groups-mini-list">
            {t(groups.length === 0 ?
            <div className="empty-small">{t("No groups configured yet.")}</div> :

            groups.map((group, index) =>
            <div className="group-mini-row" key={group.id}>
                  <div className="group-mini-index">
                    {t(String(index + 1).padStart(2, "0"))}
                  </div>
                  <div className="group-mini-copy">
                    <strong>{group.name}</strong>
                    <span>{t(group.description || "Guardian protected group")}</span>
                  </div>
                  <span className="status-live">
                    <span />{t(" Active ")}

              </span>
                </div>
            ))
            }
          </div>
        </div>
      </section>
    </div>);

}
