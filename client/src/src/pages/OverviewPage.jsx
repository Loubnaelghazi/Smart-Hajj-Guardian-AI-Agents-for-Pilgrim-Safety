import { useState } from "react";
import {
  AlertTriangle,
  ShieldAlert,
  UserRound,
  Users,
  RadioTower,
  ArrowUpRight,
} from "lucide-react";
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
          <span className="hero-label">AGENCY SAFETY OPERATIONS</span>
          <h2>
            One command center for
            <span> safer pilgrim journeys.</span>
          </h2>
          <p>
            Guardian combines telecom intelligence, risk scoring and operational
            workflows so your teams can act before situations escalate.
          </p>

          <div className="hero-badges">
            <span><span className="live-dot" /> Guardian live</span>
            <span><RadioTower size={13} /> CAMARA network signals</span>
          </div>
        </div>

        <div className="overview-hero-card">
          <div className="hero-card-icon">
            <ShieldAlert size={24} />
          </div>
          <div>
            <span>System status</span>
            <strong>
              {health?.mongodb ? "All systems operational" : "Monitoring active"}
            </strong>
            <small>
              MongoDB {health?.mongodb ? "connected" : "status unavailable"}
            </small>
          </div>
        </div>
      </section>

      <section className="metrics-grid">
        <StatCard
          title="Groups"
          value={summary.groups ?? overview?.groups_count}
          subtitle="Operational groups"
          icon={Users}
          tone="blue"
        />
        <StatCard
          title="Pilgrims"
          value={summary.pilgrims ?? overview?.pilgrims_count}
          subtitle="Registered pilgrims"
          icon={UserRound}
          tone="emerald"
        />
        <StatCard
          title="Active incidents"
          value={summary.active_incidents ?? overview?.active_incidents_count}
          subtitle="Cases needing attention"
          icon={AlertTriangle}
          tone="amber"
        />
        <StatCard
          title="Critical incidents"
          value={summary.critical_incidents ?? overview?.critical_incidents_count}
          subtitle="Highest priority"
          icon={ShieldAlert}
          tone="red"
        />
      </section>

      <section className="dashboard-grid">
        <div className="panel panel-large">
          <div className="panel-heading">
            <div>
              <span className="panel-kicker">LIVE OPERATIONS</span>
              <h2>Active incidents</h2>
            </div>
            <button className="link-button" type="button">
              View all <ArrowUpRight size={14} />
            </button>
          </div>

          {incidents.length === 0 ? (
            <div className="empty-state">
              <div className="empty-state-icon">
                <ShieldAlert size={26} />
              </div>
              <h3>No active incidents</h3>
              <p>Your agency is currently operating without active safety alerts.</p>
            </div>
          ) : (
            <div className="incident-list">
              {incidents.slice(0, 4).map((incident) => (
                <IncidentCard
                  key={incident.id}
                  incident={incident}
                  busy={busy === incident.id}
                  onAcknowledge={(id) => act("ack", id)}
                  onResolve={(id) => act("resolve", id)}
                />
              ))}
            </div>
          )}
        </div>

        <div className="panel">
          <div className="panel-heading">
            <div>
              <span className="panel-kicker">GROUP COVERAGE</span>
              <h2>Operational groups</h2>
            </div>
            <span className="count-chip">{groups.length}</span>
          </div>

          <div className="groups-mini-list">
            {groups.length === 0 ? (
              <div className="empty-small">No groups configured yet.</div>
            ) : (
              groups.map((group, index) => (
                <div className="group-mini-row" key={group.id}>
                  <div className="group-mini-index">
                    {String(index + 1).padStart(2, "0")}
                  </div>
                  <div className="group-mini-copy">
                    <strong>{group.name}</strong>
                    <span>{group.description || "Guardian protected group"}</span>
                  </div>
                  <span className="status-live">
                    <span />
                    Active
                  </span>
                </div>
              ))
            )}
          </div>
        </div>
      </section>
    </div>
  );
}
