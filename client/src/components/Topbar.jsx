import { t } from "../i18n";import {
  Bell,
  ChevronDown,
  RefreshCw,
  ShieldCheck } from
"lucide-react";

import { getLanguage, setLanguage } from '../i18n';
const TITLES = {
  tracking: ["Live Pilgrim Tracking", "Locate your pilgrims relative to the agency safe areas."],
  overview: ["Operations Overview", "Monitor pilgrim safety across your agency in real time."],
  groups: ["Groups", "Manage groups, guides and pilgrim membership."],
  "group-details": ["Group Details", "Manage pilgrims and the group's safe zone."],
  pilgrims: ["Pilgrims", "Review all registered pilgrims."],
  guides: ["Guides", "Manage operational guides and group assignments."],
  incidents: ["Incident Center", "Prioritize, acknowledge and resolve safety events."],
  agency: ["Agency Settings", "Manage your agency profile and contact information."]
};

export default function Topbar({
  page,
  agency,
  refreshing,
  onRefresh,
  unreadCount = 0,
  onToggleNotifications
}) {
  const [title, subtitle] = TITLES[page] || TITLES.overview;

  return (
    <header className="topbar">
      <div className="topbar-copy">
        <span className="topbar-kicker">{t("SMART HAJJ GUARDIAN")}</span>
        <h1>{t(title)}</h1>
        <p>{t(subtitle)}</p>
      </div>

      <div className="topbar-actions">
        <button className="topbar-refresh-btn language-switch" type="button" lang={getLanguage() === 'ar' ? 'en' : 'ar'} onClick={() => setLanguage(getLanguage() === 'ar' ? 'en' : 'ar')}>
          {getLanguage() === 'ar' ? 'English' : 'العربية'}
        </button>
        <button
          className="topbar-icon-btn"
          type="button"
          onClick={onToggleNotifications}
          title={t("Notifications")}>

          <Bell size={18} />

          {t(unreadCount > 0 &&
          <span className="notification-count">
              {t(unreadCount > 99 ? "99+" : unreadCount)}
            </span>)
          }
        </button>

        <button
          className="topbar-refresh-btn"
          type="button"
          disabled={refreshing}
          onClick={onRefresh}>

          <RefreshCw
            size={17}
            className={refreshing ? "spin" : ""} />

          {t(refreshing ? "Refreshing" : "Refresh")}
        </button>

        <div className="agency-profile-card">
          <div className="agency-logo-wrap">
            <div className="agency-logo-ring">
              <ShieldCheck size={20} />
            </div>
          </div>

          <div className="agency-profile-copy">
            <strong>
              {t(agency?.name || "Smart Hajj Demo Agency")}
            </strong>
            <span>{t(agency?.country || "Morocco")}</span>
          </div>

          <ChevronDown size={16} className="agency-chevron" />
        </div>
      </div>
    </header>);

}
