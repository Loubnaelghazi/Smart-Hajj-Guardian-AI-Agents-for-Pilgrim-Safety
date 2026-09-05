import {
  AlertTriangle,
  Building2,
  LayoutDashboard,
  MapPinned,
  RadioTower,
  ShieldCheck,
  UserCog,
  Users,
} from "lucide-react";

const items = [
  { id: "overview", label: "Overview", icon: LayoutDashboard },
  { id: "groups", label: "Groups", icon: Users },
  { id: "pilgrims", label: "Pilgrims", icon: MapPinned },
  { id: "guides", label: "Guides", icon: UserCog },
  { id: "incidents", label: "Incidents", icon: AlertTriangle },
  { id: "agency", label: "Agency settings", icon: Building2 },
];

export default function Sidebar({
  activePage,
  onNavigate,
  incidentCount = 0,
}) {
  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <div className="brand-logo">
          <ShieldCheck size={24} />
        </div>
        <div className="brand-copy">
          <strong>Smart Hajj</strong>
          <span>Guardian</span>
        </div>
      </div>

      <div className="sidebar-section-label">COMMAND CENTER</div>

      <nav className="sidebar-nav">
        {items.map(({ id, label, icon: Icon }) => (
          <button
            key={id}
            className={`sidebar-link ${
              activePage === id ||
              (activePage === "group-details" && id === "groups")
                ? "active"
                : ""
            }`}
            onClick={() => onNavigate(id)}
          >
            <Icon size={18} />
            <span>{label}</span>

            {id === "incidents" && incidentCount > 0 && (
              <span className="sidebar-badge">{incidentCount}</span>
            )}
          </button>
        ))}
      </nav>

      <div className="sidebar-network-card">
        <div className="network-icon-wrap">
          <RadioTower size={19} />
        </div>
        <div>
          <span className="network-label">NETWORK STATUS</span>
          <strong>CAMARA Connected</strong>
          <small>Live telecom safety signals</small>
        </div>
      </div>
    </aside>
  );
}
