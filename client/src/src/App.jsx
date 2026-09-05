import { useEffect, useState } from "react";
import Sidebar from "./components/Sidebar";
import Topbar from "./components/Topbar";
import OverviewPage from "./pages/OverviewPage";
import GroupsPage from "./pages/GroupsPage";
import GroupDetailsPage from "./pages/GroupDetailsPage";
import PilgrimsPage from "./pages/PilgrimsPage";
import GuidesPage from "./pages/GuidesPage";
import AgencyPage from "./pages/AgencyPage";
import IncidentsPage from "./pages/IncidentsPage";
import { api, AGENCY_ID } from "./services/api";

export default function App() {
  const [page, setPage] = useState("overview");
  const [selectedGroupId, setSelectedGroupId] = useState(null);
  const [overview, setOverview] = useState(null);
  const [health, setHealth] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState("");

  async function load(full = false) {
    if (full) setLoading(true);
    else setRefreshing(true);

    setError("");

    try {
      const [overviewData, healthData] = await Promise.all([
        api.getAgencyOverview(AGENCY_ID),
        api.health().catch(() => null),
      ]);

      setOverview(overviewData);
      setHealth(healthData);
    } catch (e) {
      setError(e.message || "Unable to connect to backend.");
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => {
    load(true);
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

  const incidentCount =
    overview?.summary?.active_incidents ??
    overview?.active_incidents_count ??
    0;

  let content = null;

  if (page === "overview") {
    content = (
      <OverviewPage
        overview={overview}
        health={health}
        refresh={() => load(false)}
      />
    );
  } else if (page === "groups") {
    content = (
      <GroupsPage
        overview={overview}
        refresh={() => load(false)}
        onOpenGroup={openGroup}
      />
    );
  } else if (page === "group-details" && selectedGroupId) {
    content = (
      <GroupDetailsPage
        groupId={selectedGroupId}
        overview={overview}
        refresh={() => load(false)}
        onBack={() => navigate("groups")}
      />
    );
  } else if (page === "pilgrims") {
    content = (
      <PilgrimsPage
        overview={overview}
        refresh={() => load(false)}
        onOpenGroup={openGroup}
      />
    );
  } else if (page === "guides") {
    content = (
      <GuidesPage
        overview={overview}
        refresh={() => load(false)}
      />
    );
  } else if (page === "agency") {
    content = (
      <AgencyPage
        overview={overview}
        refresh={() => load(false)}
      />
    );
  } else if (page === "incidents") {
    content = (
      <IncidentsPage
        overview={overview}
        refresh={() => load(false)}
      />
    );
  }

  return (
    <div className="app-shell">
      <Sidebar
        activePage={page}
        onNavigate={navigate}
        incidentCount={incidentCount}
      />

      <main className="main-content">
        <Topbar
          page={page}
          agency={overview?.agency}
          refreshing={refreshing}
          onRefresh={() => load(false)}
        />

        {error && (
          <div className="error-banner">
            <strong>Backend connection failed.</strong>
            <span>{error}</span>
          </div>
        )}

        {loading ? (
          <div className="loading-screen">
            <div className="loader" />
            <span>Loading Guardian command center...</span>
          </div>
        ) : (
          content
        )}
      </main>
    </div>
  );
}
