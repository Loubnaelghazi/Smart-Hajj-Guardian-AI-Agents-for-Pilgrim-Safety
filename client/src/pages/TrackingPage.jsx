import { t } from "../i18n";import { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { API_BASE_URL, AGENCY_ID } from '../services/api';
import { displayStatus, statusLabel, selectTracking } from '../services/tracking';
import '../tracking.css';

const colors = { inside: '#087a5b', outside: '#c24235', uncertain: '#a6660c', unknown: '#536879', stale: '#747d84' };

function TrackingMap({ entries, groups, selected, onSelect, elapsed, scope }) {
  const host = useRef(null),map = useRef(null),layer = useRef(null),fitted = useRef(false);
  useEffect(() => {
    const instance = L.map(host.current).setView([21.4133, 39.8933], 13);
    map.current = instance;
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>', maxZoom: 19
    }).addTo(instance);
    layer.current = L.layerGroup().addTo(instance);
    const observer = new ResizeObserver(() => instance.invalidateSize());
    observer.observe(host.current);
    return () => {observer.disconnect();instance.remove();map.current = null;fitted.current = false;};
  }, []);
  useEffect(() => {fitted.current = false;}, [scope]);
  useEffect(() => {
    if (!map.current) return;
    layer.current.clearLayers();
    const bounds = [];
    groups.forEach((g) => {
      const z = g.safe_zone;
      if (!z) return;
      const circle = L.circle([z.latitude, z.longitude], { radius: z.radius_m, color: '#087a5b', weight: 2, fillOpacity: 0.07 }).addTo(layer.current);
      const label = document.createElement('span');label.textContent = `${g.name}: ${z.name || t('Meeting point')}`;
      circle.bindTooltip(label);bounds.push([z.latitude, z.longitude]);
    });
    entries.forEach((p) => {
      const o = p.observation;if (!o) return;
      const status = displayStatus(p, elapsed),color = colors[status] || colors.unknown;
      const point = [o.latitude, o.longitude];bounds.push(point);
      const marker = L.circleMarker(point, { radius: selected === p.pilgrim_id ? 11 : 7, color, fillColor: color, fillOpacity: status === 'stale' ? 0.3 : 0.9, weight: 3 }).addTo(layer.current);
      const label = document.createElement('span');label.textContent = `${p.name} — ${t(statusLabel[status])}`;
      marker.bindTooltip(label).on('click', () => onSelect(p.pilgrim_id));
      if (selected === p.pilgrim_id) L.circle(point, { radius: o.accuracy_m, color, weight: 1, dashArray: '4 4', fillOpacity: 0.08 }).addTo(layer.current);
    });
    if (!fitted.current && bounds.length) {map.current.fitBounds(bounds, { padding: [35, 35], maxZoom: 16 });fitted.current = true;}
  }, [entries, groups, selected, elapsed, onSelect, scope]);
  useEffect(() => {
    const o = entries.find((p) => p.pilgrim_id === selected)?.observation;
    if (o && map.current) map.current.setView([o.latitude, o.longitude], 16);
  }, [selected]);
  return <div className="tracking-map" ref={host} aria-label={t("Pilgrim locations and agency safe areas")} />;
}

export default function TrackingPage({ onOpenGroup, onOpenIncidents }) {
  const [data, setData] = useState(null),[error, setError] = useState('');
  const [selected, setSelected] = useState(null);
  const [filters, setFilters] = useState({ group: '', guide: '', status: 'all', query: '', sort: 'attention', page: 1, size: 10 });
  const [fitVersion, setFitVersion] = useState(0);
  function changeFilter(patch) {setFilters((f) => ({ ...f, ...patch, page: patch.page || 1 }));setSelected(null);}
  const [elapsed, setElapsed] = useState(0),[receivedAt, setReceivedAt] = useState(null);
  useEffect(() => {
    let disposed = false,timer,active;
    async function poll() {
      if (disposed || document.hidden) return;
      active = new AbortController();
      const timeout = setTimeout(() => active?.abort(), 10000);
      try {
        const response = await fetch(`${API_BASE_URL}/api/agencies/${encodeURIComponent(AGENCY_ID)}/tracking`, { signal: active.signal });
        if (!response.ok) throw new Error('Tracking feed unavailable');
        const payload = await response.json();
        if (!Array.isArray(payload.pilgrims) || !Array.isArray(payload.groups)) throw new Error('Invalid tracking response');
        if (!disposed) {setData(payload);setError('');setElapsed(0);setReceivedAt(Date.now());}
      } catch (e) {if (!disposed) setError('Connection interrupted. Positions below are last received, not confirmed live.');} finally
      {clearTimeout(timeout);active = null;if (!disposed && !document.hidden) timer = setTimeout(poll, 5000);}
    }
    function visibility() {clearTimeout(timer);if (!document.hidden && !active) poll();}
    document.addEventListener('visibilitychange', visibility);poll();
    return () => {disposed = true;clearTimeout(timer);active?.abort();document.removeEventListener('visibilitychange', visibility);};
  }, []);
  useEffect(() => {
    if (!receivedAt) return;
    const timer = setInterval(() => setElapsed(Math.floor((Date.now() - receivedAt) / 1000)), 1000);
    return () => clearInterval(timer);
  }, [receivedAt]);
  const allGroups = data?.groups || [];
  const guideGroups = allGroups.filter((g) => !filters.guide || (filters.guide === 'unassigned' ? !g.guide_id : g.guide_id === filters.guide));
  const groups = guideGroups.filter((g) => !filters.group || g.id === filters.group);
  const { counts, entries, filtered, page, pages, size } = selectTracking(data, filters, elapsed, Boolean(error));
  const current = counts.all - counts.stale - counts.no_location;
  const scope = `${filters.group}|${filters.guide}|${filters.status}|${filters.query}|${page}|${size}|${fitVersion}`;
  const chosen = entries.find((p) => p.pilgrim_id === selected);
  const chosenGroup = allGroups.find((g) => g.id === chosen?.group_id);
  const chosenGuide = (data?.guides || []).find((g) => g.id === chosenGroup?.guide_id);
  return <div className="page-stack">
    <section className="tracking-intro">
      <div><span className="panel-kicker">{t("PHONE LOCATION SHARING")}</span><h2>{t("Stay close, even across the crowd.")}</h2>
        <p>{t("Agency meeting points and the latest positions shared by your pilgrims. Outside the area does not automatically mean lost.")}</p></div>
      <div className="tracking-count"><strong>{t(current)}{t(" / ")}{t(counts.all)}</strong><span>{t("recent locations")}{t(error ? ' · feed unavailable' : '')}</span></div>
    </section>
    <section className="tracking-filters" aria-label={t("Filter pilgrims")}>
      <label>{t("Guide")}<select value={filters.guide} onChange={(e) => changeFilter({ guide: e.target.value, group: '' })}><option value="">{t("All guides")}</option><option value="unassigned">{t("No guide assigned")}</option>{t((data?.guides || []).map((g) => <option key={g.id} value={g.id}>{g.name}</option>))}</select></label>
      <label>{t("Group")}<select value={filters.group} onChange={(e) => changeFilter({ group: e.target.value })}><option value="">{t("All matching groups")}</option>{t(guideGroups.map((g) => <option key={g.id} value={g.id}>{g.name}</option>))}</select></label>
      <label className="tracking-search">{t("Find a pilgrim")}<input type="search" placeholder={t("Search name or pilgrim ID")} value={filters.query} onChange={(e) => changeFilter({ query: e.target.value })} /></label>
      <label>{t("Sort")}<select value={filters.sort} onChange={(e) => changeFilter({ sort: e.target.value })}><option value="attention">{t("Needs attention first")}</option><option value="name">{t("Name A\u2013Z")}</option></select></label>
      <button type="button" className="tracking-reset" onClick={() => changeFilter({ group: '', guide: '', query: '', status: 'all', sort: 'attention' })}>{t("Clear filters")}</button>
    </section>
    <div className="tracking-status-filters" aria-label={t("Location status")}>{t(['all', 'outside', 'uncertain', 'stale', 'no_location', 'inside', 'unknown'].map((status) => <button type="button" key={status} aria-pressed={filters.status === status} onClick={() => changeFilter({ status })}>{t(status === 'all' ? 'All pilgrims' : statusLabel[status])} <strong>{t(counts[status])}</strong></button>))}</div>
    <div className="tracking-toolbar"><span>{t(filtered.length)}{t(" matching pilgrims \xB7 map shows this page only")}</span><span role="status">{t(error ? 'Feed unavailable' : receivedAt ? `Updated ${elapsed}s ago · refreshes every 5s` : 'Connecting to location feed…')}</span><button type="button" className="tracking-reset" onClick={() => setFitVersion((v) => v + 1)}>{t("Fit visible locations")}</button></div>
    {t(error && <div className="error-banner" role="alert">{t(error)}</div>)}
    <section className="tracking-layout">
      <div className="panel tracking-map-panel"><TrackingMap entries={error ? entries.map((p) => ({ ...p, status: 'stale' })) : entries} groups={groups} selected={selected} onSelect={setSelected} elapsed={elapsed} scope={scope} />
        <p className="tracking-caption">{t("Green circles: agency safe areas. Dashed circle: selected GPS accuracy. Grey dots: last known positions. Map tiles require internet.")}</p></div>
      <div className="panel tracking-people" aria-label={t("Pilgrim locations")}>
        <h3>{t("Pilgrims ")}<span className="count-chip">{t(filtered.length)}</span></h3>
        {t(!data && !error && <p>{t("Loading locations\u2026")}</p>)}
        {t(data && entries.length === 0 && <p>{t("No pilgrims match these filters. Try another guide, group or status.")}</p>)}
        {t(entries.map((p) => {const o = p.observation;const status = error && o ? 'stale' : displayStatus(p, elapsed);return <button type="button" className={`tracking-person ${selected === p.pilgrim_id ? 'selected' : ''}`} key={p.pilgrim_id} onClick={() => setSelected(p.pilgrim_id)}>
          <strong>{p.name}</strong><span>{t(allGroups.find((g) => g.id === p.group_id)?.name || 'Group unavailable')}</span>
          <span className={`tracking-state ${status}`}>{t(statusLabel[status])}</span>
          {t(o ? <><span>{t(status === 'stale' ? 'Position age' : 'Measured')}{t(": ")}{t(Math.max(0, o.age_seconds + elapsed))}{t("s ago \xB7 \xB1")}{t(Math.round(o.accuracy_m))}{t(" m")}</span>
            {t(status !== 'stale' && o.distance_to_meeting_point_m != null && <span>{t(Math.round(o.distance_to_meeting_point_m))}{t(" m to meeting point")}</span>)}
            <small>{t(o.mocked ? 'Mock / emulator location' : 'Phone GPS')}{t(" \xB7 ")}{t((o.connection || []).join(', ') || 'Connection unknown')}</small></> :
            <small>{t("Ask the pilgrim to start monitoring in the phone app.")}</small>)}
        </button>;}))}
      </div>
    </section>
    <div className="tracking-pagination" aria-label={t("Pilgrim list pages")}><label>{t("Per page ")}<select value={size} onChange={(e) => changeFilter({ size: Number(e.target.value) })}>{t([10, 25, 50].map((n) => <option key={n} value={n}>{t(n)}</option>))}</select></label><span>{t("Page ")}{t(page)}{t(" of ")}{t(pages)}</span><button type="button" disabled={page <= 1} onClick={() => changeFilter({ page: page - 1 })}>{t("Previous")}</button><button type="button" disabled={page >= pages} onClick={() => changeFilter({ page: page + 1 })}>{t("Next")}</button></div>
    {t(chosen && <section className="panel tracking-handoff"><div><span className="panel-kicker">{t("COORDINATE A RESPONSE")}</span><h3>{chosen.name}</h3><p>{t(chosenGroup?.name || 'Group unavailable')}{t(" \xB7 Guide: ")}{t(chosenGuide?.name || 'Not assigned')}</p><p>{t("Check location freshness before contacting the group. A map marker does not confirm someone is lost.")}</p></div><div className="tracking-handoff-actions">{t(chosenGuide?.phone_number && <a href={`tel:${chosenGuide.phone_number.replace(/[^+\d]/g, '')}`}>{t("Call guide")}</a>)}<button type="button" disabled={!chosenGroup} onClick={() => onOpenGroup?.(chosen.group_id)}>{t("Open group")}</button><button type="button" onClick={onOpenIncidents}>{t("Open incident center")}</button></div></section>)}
    <p className="tracking-caption">{t("Locations older than two minutes are stale. Phone GPS is separate from operator verification and congestion. This page shows each pilgrim\u2019s latest shared position, not a movement history.")}</p>
  </div>;
}
