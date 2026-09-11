import { t } from "../i18n";export default function StatCard({
  title,
  value,
  subtitle,
  icon: Icon,
  tone = "emerald"
}) {
  return (
    <article className={`metric-card metric-${tone}`}>
      <div className="metric-head">
        <span>{t(title)}</span>
        <div className="metric-icon">
          <Icon size={19} />
        </div>
      </div>

      <div className="metric-value">{t(value ?? 0)}</div>
      <div className="metric-subtitle">{t(subtitle)}</div>
    </article>);

}
