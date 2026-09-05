export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "";
export const AGENCY_ID = import.meta.env.VITE_AGENCY_ID || "demo-agency-001";

async function request(path, options = {}) {
  const headers = { ...(options.headers || {}) };

  if (options.body && !headers["Content-Type"]) {
    headers["Content-Type"] = "application/json";
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers,
  });

  const contentType = response.headers.get("content-type") || "";
  const data = contentType.includes("application/json")
    ? await response.json()
    : await response.text();

  if (!response.ok) {
    throw new Error(
      (typeof data === "object" && (data.detail || data.message)) ||
      `${response.status} ${response.statusText}`
    );
  }

  return data;
}

const json = (method, body) => ({
  method,
  body: JSON.stringify(body),
});

export const api = {
  health: () => request("/health"),

  getAgencyOverview: (agencyId = AGENCY_ID) =>
    request(`/api/agencies/${agencyId}/overview`),

  updateAgency: (agencyId, data) =>
    request(`/api/agencies/${agencyId}`, json("PATCH", data)),

  listGuides: (agencyId = AGENCY_ID) =>
    request(`/api/agencies/${agencyId}/guides`),

  createGuide: (data) =>
    request("/api/guides", json("POST", data)),

  updateGuide: (guideId, data) =>
    request(`/api/guides/${guideId}`, json("PATCH", data)),

  deleteGuide: (guideId) =>
    request(`/api/guides/${guideId}`, { method: "DELETE" }),

  listGroups: (agencyId = AGENCY_ID) =>
    request(`/api/agencies/${agencyId}/groups`),

  createGroup: (data) =>
    request("/api/groups", json("POST", data)),

  getGroup: (groupId) =>
    request(`/api/groups/${groupId}`),

  updateGroup: (groupId, data) =>
    request(`/api/groups/${groupId}`, json("PATCH", data)),

  deleteGroup: (groupId) =>
    request(`/api/groups/${groupId}`, { method: "DELETE" }),

  listGroupPilgrims: (groupId) =>
    request(`/api/groups/${groupId}/pilgrims`),

  createPilgrim: (groupId, data) =>
    request(`/api/groups/${groupId}/pilgrims`, json("POST", data)),

  updatePilgrim: (pilgrimId, data) =>
    request(`/api/pilgrims/${pilgrimId}`, json("PATCH", data)),

  deletePilgrim: (pilgrimId) =>
    request(`/api/pilgrims/${pilgrimId}`, { method: "DELETE" }),

  getSafeZone: (groupId) =>
    request(`/api/groups/${groupId}/safe-zone`),

  createSafeZone: (groupId, data) =>
    request(`/api/groups/${groupId}/safe-zone`, json("POST", data)),

  updateSafeZone: (groupId, data) =>
    request(`/api/groups/${groupId}/safe-zone`, json("PATCH", data)),

  deleteSafeZone: (groupId) =>
    request(`/api/groups/${groupId}/safe-zone`, { method: "DELETE" }),

  acknowledgeIncident: (incidentId) =>
    request(`/api/incidents/${incidentId}/acknowledge`, {
      method: "PATCH",
    }),

  resolveIncident: (incidentId) =>
    request(`/api/incidents/${incidentId}/resolve`, {
      method: "PATCH",
    }),
};
