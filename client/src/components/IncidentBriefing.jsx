import { useEffect, useState, useSyncExternalStore } from 'react';
import { getLanguage, subscribeLanguage } from '../i18n';
import { API_BASE_URL } from '../services/api';

export default function IncidentBriefing({incident}) {
  const appLanguage = useSyncExternalStore(subscribeLanguage, getLanguage, getLanguage);
  const [language, setLanguage] = useState(appLanguage);
  useEffect(() => { setLanguage(appLanguage); }, [appLanguage]);
  const [data, setData] = useState(null), [busy, setBusy] = useState(false), [error, setError] = useState('');
  const arabic = language === 'ar';
  useEffect(() => { setData(null); }, [incident.id, incident.status]);
  async function generate() {
    if (busy) return;
    setBusy(true); setError('');
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 20000);
    try {
      const response = await fetch(`${API_BASE_URL}/api/incidents/${encodeURIComponent(incident.id)}/briefing`, {method:'POST', signal:controller.signal});
      if (!response.ok) throw new Error();
      const value = await response.json();
      if (value.incident_id !== incident.id || value.incident_status !== incident.status || !Array.isArray(value.facts)) throw new Error();
      setData(value);
    } catch { setError(arabic ? 'تعذّر تحميل الملخص. حاول مجدداً.' : 'Briefing unavailable. Please retry.'); }
    finally { clearTimeout(timeout); setBusy(false); }
  }
  return <section dir={arabic ? 'rtl' : 'ltr'} lang={language} style={{padding:'16px', border:'1px solid #d7e3df', borderRadius:12, margin:'8px 0 24px', background:'#f5faf7'}}>
    <div style={{display:'flex', gap:12, alignItems:'center', flexWrap:'wrap'}}>
      <strong>{arabic ? 'ملخص البلاغ' : 'Incident briefing'}</strong>
      <button type="button" onClick={() => setLanguage(arabic ? 'en' : 'ar')}>{arabic ? 'English' : 'العربية'}</button>
      <button type="button" disabled={busy} onClick={generate}>{busy ? (arabic ? 'جارٍ التحضير…' : 'Preparing…') : (arabic ? 'تحديث الملخص' : 'Prepare / refresh briefing')}</button>
    </div>
    {error && <p role="alert">{error}</p>}
    {data && <><p><strong>{data.mode === 'ai_prioritized' ? (arabic ? 'ترتيب الأولويات بمساعدة الذكاء الاصطناعي' : 'AI-prioritized evidence') : (arabic ? 'ملخص البيانات — الذكاء الاصطناعي غير متاح' : 'Evidence summary — AI unavailable')}</strong></p>
      <ul>{data.facts.map(f => <li key={f.id} style={{marginBottom:10,lineHeight:1.7}}>{f[language]}</li>)}</ul>
      <small>{data.notice[language]}<br/>{new Date(data.generated_at).toLocaleString(arabic ? 'ar' : 'en')}</small></>}
  </section>;
}
