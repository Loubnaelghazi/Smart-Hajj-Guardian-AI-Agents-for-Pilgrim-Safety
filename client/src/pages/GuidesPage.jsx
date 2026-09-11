import { t } from "../i18n";import { useState } from "react";
import { Pencil, Plus, Trash2, UserCog } from "lucide-react";
import Modal from "../components/Modal";
import { api, AGENCY_ID } from "../services/api";

const empty = {
  name: "",
  phone_number: "",
  email: ""
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
      email: guide.email || ""
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
          ...form
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
    if (!confirm(t(`Delete guide "${guide.name}"?`))) return;

    try {
      await api.deleteGuide(guide.id);
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
            <span className="panel-kicker">{t("OPERATIONS TEAM")}</span>
            <h2>{t("Guides")}</h2>
          </div>

          <button className="primary-btn" onClick={openCreate}>
            <Plus size={16} />{t(" Add guide ")}

          </button>
        </div>

        <div className="data-table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>{t("Guide")}</th>
                <th>{t("Phone")}</th>
                <th>{t("Email")}</th>
                <th>{t("Assigned groups")}</th>
                <th className="actions-column">{t("Actions")}</th>
              </tr>
            </thead>

            <tbody>
              {t(guides.map((guide) =>
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
                  <td>{t(guide.phone_number || "—")}</td>
                  <td>{t(guide.email || "—")}</td>
                  <td>
                    {t(
                    groups.filter(
                      (group) => group.guide_id === guide.id
                    ).length)
                  }
                  </td>
                  <td className="row-actions">
                    <button
                    className="table-action"
                    onClick={() => openEdit(guide)}>

                      <Pencil size={15} />
                    </button>
                    <button
                    className="table-action danger"
                    onClick={() => remove(guide)}>

                      <Trash2 size={15} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      {t(modal &&
      <Modal
        title={t(modal.type === "create" ? "Add guide" : "Edit guide")}
        onClose={() => setModal(null)}>

          <form className="form-stack" onSubmit={save}>
            {t(error && <div className="form-error">{t(error)}</div>)}

            <label>{t(" Full name ")}

            <input
              required
              value={form.name}
              onChange={(e) =>
              setForm({ ...form, name: e.target.value })
              } />

            </label>

            <label>{t(" Phone ")}

            <input
              value={form.phone_number}
              onChange={(e) =>
              setForm({ ...form, phone_number: e.target.value })
              } />

            </label>

            <label>{t(" Email ")}

            <input
              type="email"
              value={form.email}
              onChange={(e) =>
              setForm({ ...form, email: e.target.value })
              } />

            </label>

            <div className="modal-actions">
              <button
              type="button"
              className="secondary-btn"
              onClick={() => setModal(null)}>{t(" Cancel ")}


            </button>
              <button className="primary-btn" disabled={busy}>
                {t(busy ? "Saving..." : "Save guide")}
              </button>
            </div>
          </form>
        </Modal>)
      }
    </div>);

}
