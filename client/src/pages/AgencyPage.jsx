import { useEffect, useState } from "react";
import { Building2, Save } from "lucide-react";
import { api, AGENCY_ID } from "../services/api";

export default function AgencyPage({ overview, refresh }) {
  const agency = overview?.agency || {};
  const [form, setForm] = useState({
    name: "",
    country: "",
    contact_email: "",
    contact_phone: "",
  });
  const [status, setStatus] = useState("");

  useEffect(() => {
    setForm({
      name: agency.name || "",
      country: agency.country || "",
      contact_email: agency.contact_email || "",
      contact_phone: agency.contact_phone || "",
    });
  }, [agency.id, agency.name]);

  async function save(event) {
    event.preventDefault();
    setStatus("Saving...");

    try {
      await api.updateAgency(AGENCY_ID, form);
      await refresh();
      setStatus("Saved");
      setTimeout(() => setStatus(""), 1600);
    } catch (e) {
      setStatus(e.message);
    }
  }

  return (
    <div className="page-stack">
      <section className="panel settings-panel">
        <div className="panel-heading">
          <div>
            <span className="panel-kicker">AGENCY SETTINGS</span>
            <h2>Agency profile</h2>
          </div>
          <div className="entity-icon large">
            <Building2 size={20} />
          </div>
        </div>

        <form className="form-stack" onSubmit={save}>
          <div className="form-grid-2">
            <label>
              Agency name
              <input
                required
                value={form.name}
                onChange={(e) =>
                  setForm({ ...form, name: e.target.value })
                }
              />
            </label>

            <label>
              Country
              <input
                value={form.country}
                onChange={(e) =>
                  setForm({ ...form, country: e.target.value })
                }
              />
            </label>
          </div>

          <div className="form-grid-2">
            <label>
              Contact email
              <input
                type="email"
                value={form.contact_email}
                onChange={(e) =>
                  setForm({
                    ...form,
                    contact_email: e.target.value,
                  })
                }
              />
            </label>

            <label>
              Contact phone
              <input
                value={form.contact_phone}
                onChange={(e) =>
                  setForm({
                    ...form,
                    contact_phone: e.target.value,
                  })
                }
              />
            </label>
          </div>

          <div className="settings-footer">
            <span>{status}</span>
            <button className="primary-btn">
              <Save size={16} />
              Save changes
            </button>
          </div>
        </form>
      </section>
    </div>
  );
}
