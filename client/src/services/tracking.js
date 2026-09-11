export function displayStatus(entry, elapsedSeconds = 0) {
  if (!entry.observation) return 'no_location';
  if (entry.status !== 'fresh' || !Number.isFinite(entry.observation.age_seconds) || entry.observation.age_seconds + elapsedSeconds > 120) return 'stale';
  return entry.observation.zone_state || 'unknown';
}

export function selectTracking(data, filters, elapsed = 0, unavailable = false) {
  const groups = new Map((data?.groups || []).map(g => [g.id, g]));
  const query = (filters.query || '').trim().toLocaleLowerCase();
  const scoped = (data?.pilgrims || []).filter(p => {
    const group = groups.get(p.group_id);
    return (!filters.group || p.group_id === filters.group)
      && (!filters.guide || (filters.guide === 'unassigned' ? !group?.guide_id : group?.guide_id === filters.guide))
      && (!query || `${p.name} ${p.pilgrim_id}`.toLocaleLowerCase().includes(query));
  });
  const statusOf = p => unavailable && p.observation ? 'stale' : displayStatus(p, elapsed);
  const counts = {all: scoped.length, inside: 0, outside: 0, uncertain: 0, unknown: 0, stale: 0, no_location: 0};
  scoped.forEach(p => { counts[statusOf(p)] = (counts[statusOf(p)] || 0) + 1; });
  const priorities = {outside: 0, uncertain: 1, stale: 2, no_location: 3, unknown: 4, inside: 5};
  const filtered = scoped.filter(p => !filters.status || filters.status === 'all' || statusOf(p) === filters.status);
  filtered.sort((a, b) => {
    if (filters.sort === 'attention') {
      const difference = priorities[statusOf(a)] - priorities[statusOf(b)];
      if (difference) return difference;
    }
    return a.name.localeCompare(b.name) || a.pilgrim_id.localeCompare(b.pilgrim_id);
  });
  const size = [10, 25, 50].includes(filters.size) ? filters.size : 10;
  const pages = Math.max(1, Math.ceil(filtered.length / size));
  const page = Math.max(1, Math.min(filters.page || 1, pages));
  return {counts, filtered, entries: filtered.slice((page - 1) * size, page * size), page, pages, size};
}

export const statusLabel = {
  no_location: 'No location shared', stale: 'Last known location',
  inside: 'Inside safe area', outside: 'Outside safe area',
  uncertain: 'Near boundary · uncertain', unknown: 'No safe area configured',
};
