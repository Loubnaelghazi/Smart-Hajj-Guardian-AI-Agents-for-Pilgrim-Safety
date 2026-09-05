export default function StatCard({
  title,
  value,
  subtitle,
  icon: Icon,
  tone = "emerald",
}) {
  return (
    <article className={`metric-card metric-${tone}`}>
      <div className="metric-head">
        <span>{title}</span>
        <div className="metric-icon">
          <Icon size={19} />
        </div>
      </div>

      <div className="metric-value">{value ?? 0}</div>
      <div className="metric-subtitle">{subtitle}</div>
    </article>
  );
}
