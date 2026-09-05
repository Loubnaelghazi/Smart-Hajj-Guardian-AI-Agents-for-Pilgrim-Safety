import { useMemo, useState } from "react";
import {
  Eye,
  Pencil,
  Search,
  Smartphone,
  Trash2,
  Users,
} from "lucide-react";
import Modal from "../components/Modal";
import { api } from "../services/api";

export default function PilgrimsPage({
  overview,
  refresh,
  onOpenGroup,
}) {
  const pilgrims = overview?.pilgrims || [];
  const groups = overview?.groups || [];

  const [query, setQuery] = useState("");
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState({
    name: "",
    phone_number: "",
    nationality: "",
    group_id: "",
  });
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return pilgrims;

    return pilgrims.filter((p) =>
      [p.name, p.phone_number, p.nationality, p.id]
        .filter(Boolean)
        .some((value) =>
          String(value).toLowerCase().includes(q)
        )
    );
  }, [pilgrims, query]);

  function openEdit(pilgrim) {
    setEditing(pilgrim);
    setForm({
      name: pilgrim.name || "",
      phone_number: pilgrim.phone_number || "",
      nationality: pilgrim.nationality || "",
      group_id: pilgrim.group_id || "",
    });
    setError("");
  }

  async function save(event) {
    event.preventDefault();
    setBusy(true);
    setError("");

    try {
      await api.updatePilgrim(editing.id, {
        name: form.name,
        phone_number: form.phone_number,
        nationality: form.nationality || null,
        group_id: form.group_id,
      });
      await refresh();
      setEditing(null);
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  }

  async function remove(pilgrim) {
    if (!confirm(`Delete pilgrim "${pilgrim.name}"?`)) return;

    try {
      await api.deletePilgrim(pilgrim.id);
      await refresh();
    } catch (e) {
      alert(e.message);
    }
  }

  return (
    <div className="page-stack">
      <section className="panel">
        <div className="panel-heading panel-heading-search">
          <div>
            <span className="panel-kicker">PILGRIM REGISTRY</span>
            <h2>Protected pilgrims</h2>
          </div>

          <label className="search-box">
            <Search size={16} />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search name, phone, nationality..."
            />
          </label>
        </div>

        <div className="data-table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Pilgrim</th>
                <th>Phone</th>
                <th>Group</th>
                <th>Nationality</th>
                <th>Guardian</th>
                <th className="actions-column">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((pilgrim) => {
                const group = groups.find(
                  (g) => g.id === pilgrim.group_id
                );

                return (
                  <tr key={pilgrim.id}>
                    <td>
                      <div className="entity-cell">
                        <div className="entity-avatar">
                          {(pilgrim.name || "P")[0]}
                        </div>
                        <div>
                          <strong>{pilgrim.name}</strong>
                          <span>{pilgrim.id}</span>
                        </div>
                      </div>
                    </td>
                    <td>
                      <span className="table-inline">
                        <Smartphone size={15} />
                        {pilgrim.phone_number}
                      </span>
                    </td>
                    <td>
                      <span className="table-inline">
                        <Users size={15} />
                        {group?.name || pilgrim.group_id}
                      </span>
                    </td>
                    <td>{pilgrim.nationality || "—"}</td>
                    <td>
                      <span className="status-live">
                        <span />
                        Protected
                      </span>
                    </td>
                    <td className="row-actions">
                      <button
                        className="table-action"
                        title="Open group"
                        onClick={() => onOpenGroup(pilgrim.group_id)}
                      >
                        <Eye size={15} />
                      </button>
                      <button
                        className="table-action"
                        title="Edit"
                        onClick={() => openEdit(pilgrim)}
                      >
                        <Pencil size={15} />
                      </button>
                      <button
                        className="table-action danger"
                        title="Delete"
                        onClick={() => remove(pilgrim)}
                      >
                        <Trash2 size={15} />
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </section>

      {editing && (
        <Modal title="Edit pilgrim" onClose={() => setEditing(null)}>
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
                required
                value={form.phone_number}
                onChange={(e) =>
                  setForm({
                    ...form,
                    phone_number: e.target.value,
                  })
                }
              />
            </label>

            <label>
              Nationality
              <input
                value={form.nationality}
                onChange={(e) =>
                  setForm({
                    ...form,
                    nationality: e.target.value,
                  })
                }
              />
            </label>

            <label>
              Group
              <select
                required
                value={form.group_id}
                onChange={(e) =>
                  setForm({ ...form, group_id: e.target.value })
                }
              >
                {groups.map((group) => (
                  <option key={group.id} value={group.id}>
                    {group.name}
                  </option>
                ))}
              </select>
            </label>

            <div className="modal-actions">
              <button
                type="button"
                className="secondary-btn"
                onClick={() => setEditing(null)}
              >
                Cancel
              </button>
              <button className="primary-btn" disabled={busy}>
                {busy ? "Saving..." : "Save pilgrim"}
              </button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
