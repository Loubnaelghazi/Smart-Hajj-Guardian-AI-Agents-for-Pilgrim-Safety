import { t } from "./i18n";import { useEffect, useRef, useState } from "react";
import Sidebar from "./components/Sidebar";
import Topbar from "./components/Topbar";
import NotificationCenter from "./components/NotificationCenter";
import AlertToast from "./components/AlertToast";
import OverviewPage from "./pages/OverviewPage";
import TrackingPage from "./pages/TrackingPage";
import GroupsPage from "./pages/GroupsPage";
import GroupDetailsPage from "./pages/GroupDetailsPage";
import PilgrimsPage from "./pages/PilgrimsPage";
import GuidesPage from "./pages/GuidesPage";
import AgencyPage from "./pages/AgencyPage";
import IncidentsPage from "./pages/IncidentsPage";
import { api, AGENCY_ID } from "./services/api";

const POLL_INTERVAL_MS = 5000;
import { useSyncExternalStore } from 'react';
import { getLanguage, setLanguage, subscribeLanguage } from './i18n';
import './rtl.css';

export default function App() {
  const language = useSyncExternalStore(subscribeLanguage, getLanguage, getLanguage);
  useEffect(() => { setLanguage(language); }, [language]);
  const [page, setPage] = useState("overview");
  const [selectedGroupId, setSelectedGroupId] = useState(null);

  const [overview, setOverview] = useState(null);
  const [health, setHealth] = useState(null);

  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState("");

  const [notifications, setNotifications] = useState([]);
  const [unreadIds, setUnreadIds] = useState(new Set());
  const [notificationOpen, setNotificationOpen] = useState(false);
  const [toastIncident, setToastIncident] = useState(null);

  const initializedIncidentsRef = useRef(false);
  const knownIncidentIdsRef = useRef(new Set());

  async function load(full = false) {
    if (full) setLoading(true);else
    setRefreshing(true);

    setError("");

    try {
      const [overviewData, healthData] = await Promise.all([
      api.getAgencyOverview(AGENCY_ID),
      api.health().catch(() => null)]
      );

      setOverview(overviewData);
      setHealth(healthData);
    } catch (e) {
      setError(
        e.message || "Unable to connect to the Guardian backend."
      );
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  async function pollIncidents() {
    try {
      const incidents = await api.listActiveIncidents();

      const sorted = [...incidents].sort((a, b) => {
        const aTime =
        a.created_at ||
        a.triggered_at ||
        a.timestamp ||
        "";
        const bTime =
        b.created_at ||
        b.triggered_at ||
        b.timestamp ||
        "";
        return String(bTime).localeCompare(String(aTime));
      });

      setNotifications(sorted);

      const currentIds = new Set(
        sorted.map((incident) => incident.id)
      );

      // First poll: establish baseline, do not show every existing incident
      // as a "new" notification.
      if (!initializedIncidentsRef.current) {
        knownIncidentIdsRef.current = currentIds;
        initializedIncidentsRef.current = true;
        return;
      }

      const newIncidents = sorted.filter(
        (incident) =>
        !knownIncidentIdsRef.current.has(incident.id)
      );

      if (newIncidents.length > 0) {
        setUnreadIds((previous) => {
          const next = new Set(previous);
          newIncidents.forEach((incident) =>
          next.add(incident.id)
          );
          return next;
        });

        // Show the newest detected incident as an in-app toast.
        setToastIncident(newIncidents[0]);

        // Refresh dashboard counts/details automatically too.
        load(false);
      }

      knownIncidentIdsRef.current = currentIds;
    } catch (e) {
      // Polling errors should not break the dashboard.
      console.warn("Incident polling failed:", e);
    }
  }

  useEffect(() => {
    load(true);
    pollIncidents();

    const timer = window.setInterval(
      pollIncidents,
      POLL_INTERVAL_MS
    );

    return () => window.clearInterval(timer);
  }, []);

  function navigate(nextPage) {
    setPage(nextPage);

    if (nextPage !== "group-details") {
      setSelectedGroupId(null);
    }
  }

  function openGroup(groupId) {
    setSelectedGroupId(groupId);
    setPage("group-details");
  }

  function openIncidentCenter(incident) {
    if (incident?.id) {
      setUnreadIds((previous) => {
        const next = new Set(previous);
        next.delete(incident.id);
        return next;
      });
    }

    setNotificationOpen(false);
    setToastIncident(null);
    setPage("incidents");
  }

  function markAllRead() {
    setUnreadIds(new Set());
  }

  async function manualRefresh() {
    await Promise.all([
    load(false),
    pollIncidents()]
    );
  }

  const incidentCount =
  overview?.summary?.active_incidents ??
  overview?.active_incidents_count ??
  0;

  let content = null;

  if (page === "tracking") {
    content = <TrackingPage onOpenGroup={openGroup} onOpenIncidents={() => navigate("incidents")} />;
  } else if (page === "overview") {
    content =
    <OverviewPage
      overview={overview}
      health={health}
      refresh={manualRefresh} />;


  } else if (page === "groups") {
    content =
    <GroupsPage
      overview={overview}
      refresh={manualRefresh}
      onOpenGroup={openGroup} />;


  } else if (
  page === "group-details" &&
  selectedGroupId)
  {
    content =
    <GroupDetailsPage
      groupId={selectedGroupId}
      overview={overview}
      refresh={manualRefresh}
      onBack={() => navigate("groups")} />;


  } else if (page === "pilgrims") {
    content =
    <PilgrimsPage
      overview={overview}
      refresh={manualRefresh}
      onOpenGroup={openGroup} />;


  } else if (page === "guides") {
    content =
    <GuidesPage
      overview={overview}
      refresh={manualRefresh} />;


  } else if (page === "agency") {
    content =
    <AgencyPage
      overview={overview}
      refresh={manualRefresh} />;


  } else if (page === "incidents") {
    content =
    <IncidentsPage
      overview={overview}
      refresh={manualRefresh} />;


  }

  return (
    <div className="app-shell">
      <Sidebar
        health={health}
        activePage={page}
        onNavigate={navigate}
        incidentCount={incidentCount} />


      <main className="main-content">
        <Topbar
          page={page}
          agency={overview?.agency}
          refreshing={refreshing}
          onRefresh={manualRefresh}
          unreadCount={unreadIds.size}
          onToggleNotifications={() =>
          setNotificationOpen((value) => !value)
          } />


        {t(error &&
        <div className="error-banner">
            <strong>{t("Backend connection failed.")}</strong>
            <span>{t(error)}</span>
          </div>)
        }

        {t(loading ?
        <div className="loading-screen">
            <div className="loader" />
            <span>{t(" Loading Guardian command center... ")}

          </span>
          </div> :

        content)
        }
      </main>

      <NotificationCenter
        open={notificationOpen}
        notifications={notifications}
        unreadIds={unreadIds}
        onClose={() => setNotificationOpen(false)}
        onMarkAllRead={markAllRead}
        onOpenIncident={openIncidentCenter} />


      <AlertToast
        incident={toastIncident}
        onClose={() => setToastIncident(null)}
        onOpen={() => openIncidentCenter(toastIncident)} />

    </div>);

}
