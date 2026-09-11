import { t } from "../i18n";import {
  AlertTriangle,
  Building2,
  LayoutDashboard,
  MapPinned,
  RadioTower,
  ShieldCheck,
  UserCog,
  Users } from
"lucide-react";

const items = [
{ id: "overview", label: "Overview", icon: LayoutDashboard },
{ id: "tracking", label: "Live tracking", icon: MapPinned },
{ id: "groups", label: "Groups", icon: Users },
{ id: "pilgrims", label: "Pilgrims", icon: MapPinned },
{ id: "guides", label: "Guides", icon: UserCog },
{ id: "incidents", label: "Incidents", icon: AlertTriangle },
{ id: "agency", label: "Agency settings", icon: Building2 }];


export default function Sidebar({
  health,
  activePage,
  onNavigate,
  incidentCount = 0
}) {
  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <div className="brand-logo">
          <ShieldCheck size={24} />
        </div>
        <div className="brand-copy">
          <strong>{t("Smart Hajj")}</strong>
          <span>{t("Guardian")}</span>
        </div>
      </div>

      <div className="sidebar-section-label">{t("COMMAND CENTER")}</div>

      <nav className="sidebar-nav">
        {t(items.map(({ id, label, icon: Icon }) =>
        <button
          key={id}
          className={`sidebar-link ${
          activePage === id ||
          activePage === "group-details" && id === "groups" ?
          "active" :
          ""}`
          }
          onClick={() => onNavigate(id)}>

            <Icon size={18} />
            <span>{t(label)}</span>

            {t(id === "incidents" && incidentCount > 0 &&
          <span className="sidebar-badge">{t(incidentCount)}</span>)
          }
          </button>
        ))}
      </nav>

      <div className="sidebar-network-card">
        <div className="network-icon-wrap">
          <RadioTower size={19} />
        </div>
        <div>
          <span className="network-label">{t("NETWORK STATUS")}</span>
          <strong>{t(health?.status === 'ok' ? 'Backend reachable' : 'Status unavailable')}</strong>
          <small>{t("Operator evidence varies by signal")}</small>
        </div>
      </div>
    </aside>);

}
