import {
  Bell,
  ChevronDown,
  RefreshCw,
  ShieldCheck,
} from "lucide-react";

const TITLES = {
  overview: ["Operations Overview", "Monitor pilgrim safety across your agency in real time."],
  groups: ["Groups", "Manage groups, guides and pilgrim membership."],
  "group-details": ["Group Details", "Manage pilgrims and the group's safe zone."],
  pilgrims: ["Pilgrims", "Review all registered pilgrims."],
  guides: ["Guides", "Manage operational guides and group assignments."],
  incidents: ["Incident Center", "Prioritize, acknowledge and resolve safety events."],
  agency: ["Agency Settings", "Manage your agency profile and contact information."],
};

export default function Topbar({
  page,
  agency,
  refreshing,
  onRefresh,
}) {
  const [title, subtitle] = TITLES[page] || TITLES.overview;

  return (
    <header className="topbar">
      <div className="topbar-copy">
        <span className="topbar-kicker">SMART HAJJ GUARDIAN</span>
        <h1>{title}</h1>
        <p>{subtitle}</p>
      </div>

      <div className="topbar-actions">
        <button className="topbar-icon-btn" type="button">
          <Bell size={18} />
          <span className="notification-dot" />
        </button>

        <button
          className="topbar-refresh-btn"
          type="button"
          disabled={refreshing}
          onClick={onRefresh}
        >
          <RefreshCw size={17} className={refreshing ? "spin" : ""} />
          {refreshing ? "Refreshing" : "Refresh"}
        </button>

        <div className="agency-profile-card">
          <div className="agency-logo-wrap">
            <div className="agency-logo-ring">
              <ShieldCheck size={20} />
            </div>
          </div>
          <div className="agency-profile-copy">
            <strong>{agency?.name || "Smart Hajj Demo Agency"}</strong>
            <span>{agency?.country || "Morocco"}</span>
          </div>
          <ChevronDown size={16} className="agency-chevron" />
        </div>
      </div>
    </header>
  );
}
