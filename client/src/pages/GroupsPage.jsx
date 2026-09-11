import { t } from "../i18n";import { useMemo, useState } from "react";
import {
  Eye,
  Pencil,
  Plus,
  Trash2,
  Users,
  ShieldCheck } from
"lucide-react";
import Modal from "../components/Modal";
import { api, AGENCY_ID } from "../services/api";

const emptyForm = {
  name: "",
  guide_id: "",
  description: ""
};

export default function GroupsPage({ overview, refresh, onOpenGroup }) {
  const groups = overview?.groups || [];
  const guides = overview?.guides || [];
  const pilgrims = overview?.pilgrims || [];

  const [modal, setModal] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  function openCreate() {
    setForm(emptyForm);
    setError("");
    setModal({ type: "create" });
  }

  function openEdit(group) {
    setForm({
      name: group.name || "",
      guide_id: group.guide_id || "",
      description: group.description || ""
    });
    setError("");
    setModal({ type: "edit", group });
  }

  async function save(event) {
    event.preventDefault();
    setBusy(true);
    setError("");

    try {
      const payload = {
        name: form.name,
        guide_id: form.guide_id || null,
        description: form.description || null
      };

      if (modal.type === "create") {
        await api.createGroup({
          agency_id: AGENCY_ID,
          ...payload
        });
      } else {
        await api.updateGroup(modal.group.id, payload);
      }

      await refresh();
      setModal(null);
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  }

  async function remove(group) {
    if (!confirm(t(`Delete "${group.name}"?`))) return;

    try {
      await api.deleteGroup(group.id);
      await refresh();
    } catch (e) {
      alert(t(e.message));
    }
  }

  return (
    <div className="page-stack">
      <section className="panel">
        <div className="panel-heading">
          <div>
            <span className="panel-kicker">{t("AGENCY STRUCTURE")}</span>
            <h2>{t("Operational groups")}</h2>
          </div>

          <button className="primary-btn" onClick={openCreate}>
            <Plus size={16} />{t(" Add group ")}

          </button>
        </div>

        <div className="data-table-wrap">
          <table className="data-table clickable-table">
            <thead>
              <tr>
                <th>{t("Group")}</th>
                <th>{t("Guide")}</th>
                <th>{t("Pilgrims")}</th>
                <th>{t("Status")}</th>
                <th className="actions-column">{t("Actions")}</th>
              </tr>
            </thead>

            <tbody>
              {t(groups.map((group) => {
                const guide = guides.find((g) => g.id === group.guide_id);
                const count = pilgrims.filter(
                  (p) => p.group_id === group.id
                ).length;

                return (
                  <tr key={group.id}>
                    <td onClick={() => onOpenGroup(group.id)}>
                      <div className="entity-cell">
                        <div className="entity-icon"><Users size={16} /></div>
                        <div>
                          <strong>{group.name}</strong>
                          <span>{t(group.description || group.id)}</span>
                        </div>
                      </div>
                    </td>

                    <td onClick={() => onOpenGroup(group.id)}>
                      <span className="table-inline">
                        <ShieldCheck size={15} />
                        {t(guide?.name || "Unassigned")}
                      </span>
                    </td>

                    <td onClick={() => onOpenGroup(group.id)}>
                      {t(count)}
                    </td>

                    <td onClick={() => onOpenGroup(group.id)}>
                      <span className="status-live">
                        <span />{t(" Operational ")}

                      </span>
                    </td>

                    <td className="row-actions">
                      <button
                        className="table-action"
                        title={t("Open")}
                        onClick={() => onOpenGroup(group.id)}>

                        <Eye size={15} />
                      </button>
                      <button
                        className="table-action"
                        title={t("Edit")}
                        onClick={() => openEdit(group)}>

                        <Pencil size={15} />
                      </button>
                      <button
                        className="table-action danger"
                        title={t("Delete")}
                        onClick={() => remove(group)}>

                        <Trash2 size={15} />
                      </button>
                    </td>
                  </tr>);

              }))}
            </tbody>
          </table>
        </div>
      </section>

      {t(modal &&
      <Modal
        title={t(modal.type === "create" ? "Add group" : "Edit group")}
        onClose={() => setModal(null)}>

          <form className="form-stack" onSubmit={save}>
            {t(error && <div className="form-error">{t(error)}</div>)}

            <label>{t(" Group name ")}

            <input
              required
              value={form.name}
              onChange={(e) =>
              setForm({ ...form, name: e.target.value })
              } />

            </label>

            <label>{t(" Assigned guide ")}

            <select
              value={form.guide_id}
              onChange={(e) =>
              setForm({ ...form, guide_id: e.target.value })
              }>

                <option value="">{t("No guide")}</option>
                {t(guides.map((guide) =>
              <option key={guide.id} value={guide.id}>
                    {guide.name}
                  </option>
              ))}
              </select>
            </label>

            <label>{t(" Description ")}

            <textarea
              rows="4"
              value={form.description}
              onChange={(e) =>
              setForm({ ...form, description: e.target.value })
              } />

            </label>

            <div className="modal-actions">
              <button
              type="button"
              className="secondary-btn"
              onClick={() => setModal(null)}>{t(" Cancel ")}


            </button>
              <button className="primary-btn" disabled={busy}>
                {t(busy ? "Saving..." : "Save group")}
              </button>
            </div>
          </form>
        </Modal>)
      }
    </div>);

}
