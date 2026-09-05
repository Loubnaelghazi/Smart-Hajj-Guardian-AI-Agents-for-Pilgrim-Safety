export default function RiskBadge({ level }) {
  const value = String(level || "UNKNOWN").toUpperCase();

  return (
    <span className={`risk-badge risk-${value.toLowerCase()}`}>
      {value}
    </span>
  );
}
