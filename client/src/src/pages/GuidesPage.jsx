import { useState } from "react";
import { Pencil, Plus, Trash2, UserCog } from "lucide-react";
import Modal from "../components/Modal";
import { api, AGENCY_ID } from "../services/api";

const empty = {
  name: "",
  phone_number: "",
  email: "",
};

export default function GuidesPage({ overview, refresh }) {
  const guides = overview?.guides || [];
  const groups = overview?.groups || [];
  const [modal, setModal] = useState(null);
  const [form, setForm] = useState(empty);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  function openCreate() {
    setForm(empty);
    setModal({ type: "create" });
    setError("");
  }

  function openEdit(guide) {
    setForm({
      name: guide.name || "",
      phone_number: guide.phone_number || "",
      email: guide.email || "",
    });
    setModal({ type: "edit", guide });
    setError("");
  }

  async function save(event) {
    event.preventDefault();
    setBusy(true);
    setError("");

    try {
      if (modal.type === "create") {
        await api.createGuide({
          agency_id: AGENCY_ID,
          ...form,
        });
      } else {
        await api.updateGuide(modal.guide.id, form);
      }

      await refresh();
      setModal(null);
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  }

  async function remove(guide) {
    if (!confirm(`Delete guide "${guide.name}"?`)) return;

    try {
      await api.deleteGuide(guide.id);
      await refresh();
    } catch (e) {
      alert(e.message);
    }
  }

  return (
    <div className="page-stack">
      <section className="panel">
        <div className="panel-heading">
          <div>
            <span className="panel-kicker">OPERATIONS TEAM</span>
            <h2>Guides</h2>
          </div>

          <button className="primary-btn" onClick={openCreate}>
            <Plus size={16} />
            Add guide
          </button>
        </div>

        <div className="data-table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Guide</th>
                <th>Phone</th>
                <th>Email</th>
                <th>Assigned groups</th>
                <th className="actions-column">Actions</th>
              </tr>
            </thead>

            <tbody>
              {guides.map((guide) => (
                <tr key={guide.id}>
                  <td>
                    <div className="entity-cell">
                      <div className="entity-icon">
                        <UserCog size={16} />
                      </div>
                      <div>
                        <strong>{guide.name}</strong>
                        <span>{guide.id}</span>
                      </div>
                    </div>
                  </td>
                  <td>{guide.phone_number || "—"}</td>
                  <td>{guide.email || "—"}</td>
                  <td>
                    {
                      groups.filter(
                        (group) => group.guide_id === guide.id
                      ).length
                    }
                  </td>
                  <td className="row-actions">
                    <button
                      className="table-action"
                      onClick={() => openEdit(guide)}
                    >
                      <Pencil size={15} />
                    </button>
                    <button
                      className="table-action danger"
                      onClick={() => remove(guide)}
                    >
                      <Trash2 size={15} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      {modal && (
        <Modal
          title={modal.type === "create" ? "Add guide" : "Edit guide"}
          onClose={() => setModal(null)}
        >
          <form className="form-stack" onSubmit={save}>
            {error && <div className="form-error">{error}</div>}

            <label>
              Full name
              <input
                required
                value={form.name}
                onChange={(e) =>
                  setForm({ ...form, name: e.target.value })
                }
              />
            </label>

            <label>
              Phone
              <input
                value={form.phone_number}
                onChange={(e) =>
                  setForm({ ...form, phone_number: e.target.value })
                }
              />
            </label>

            <label>
              Email
              <input
                type="email"
                value={form.email}
                onChange={(e) =>
                  setForm({ ...form, email: e.target.value })
                }
              />
            </label>

            <div className="modal-actions">
              <button
                type="button"
                className="secondary-btn"
                onClick={() => setModal(null)}
              >
                Cancel
              </button>
              <button className="primary-btn" disabled={busy}>
                {busy ? "Saving..." : "Save guide"}
              </button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
