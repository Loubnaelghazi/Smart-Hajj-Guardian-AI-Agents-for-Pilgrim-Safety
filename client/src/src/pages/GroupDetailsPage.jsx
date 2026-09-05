import { useEffect, useMemo, useState } from "react";
import {
  ArrowLeft,
  MapPin,
  Pencil,
  Plus,
  ShieldCheck,
  Trash2,
  UserRound,
} from "lucide-react";
import Modal from "../components/Modal";
import { api } from "../services/api";

const pilgrimEmpty = {
  name: "",
  phone_number: "",
  nationality: "",
};

const zoneEmpty = {
  name: "",
  latitude: "",
  longitude: "",
  radius_m: 250,
};

export default function GroupDetailsPage({
  groupId,
  overview,
  refresh,
  onBack,
}) {
  const [details, setDetails] = useState(null);
  const [pilgrims, setPilgrims] = useState([]);
  const [safeZone, setSafeZone] = useState(null);
  const [modal, setModal] = useState(null);
  const [pilgrimForm, setPilgrimForm] = useState(pilgrimEmpty);
  const [zoneForm, setZoneForm] = useState(zoneEmpty);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const guides = overview?.guides || [];

  async function load() {
    const [groupData, pilgrimData] = await Promise.all([
      api.getGroup(groupId),
      api.listGroupPilgrims(groupId),
    ]);

    setDetails(groupData);
    setPilgrims(pilgrimData);

    try {
      setSafeZone(await api.getSafeZone(groupId));
    } catch {
      setSafeZone(null);
    }
  }

  useEffect(() => {
    load();
  }, [groupId]);

  if (!details) {
    return <div className="loading-screen"><div className="loader" /></div>;
  }

  const group = details.group || details;
  const guide =
    details.guide ||
    guides.find((item) => item.id === group.guide_id);

  function openAddPilgrim() {
    setPilgrimForm(pilgrimEmpty);
    setError("");
    setModal({ type: "add-pilgrim" });
  }

  function openEditPilgrim(pilgrim) {
    setPilgrimForm({
      name: pilgrim.name || "",
      phone_number: pilgrim.phone_number || "",
      nationality: pilgrim.nationality || "",
    });
    setError("");
    setModal({ type: "edit-pilgrim", pilgrim });
  }

  function openZone() {
    setZoneForm(
      safeZone
        ? {
            name: safeZone.name || "",
            latitude: safeZone.latitude,
            longitude: safeZone.longitude,
            radius_m: safeZone.radius_m,
          }
        : zoneEmpty
    );
    setError("");
    setModal({ type: "safe-zone" });
  }

  async function savePilgrim(event) {
    event.preventDefault();
    setBusy(true);
    setError("");

    try {
      const payload = {
        name: pilgrimForm.name,
        phone_number: pilgrimForm.phone_number,
        nationality: pilgrimForm.nationality || null,
      };

      if (modal.type === "add-pilgrim") {
        await api.createPilgrim(groupId, payload);
      } else {
        await api.updatePilgrim(modal.pilgrim.id, payload);
      }

      await Promise.all([load(), refresh()]);
      setModal(null);
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  }

  async function deletePilgrim(pilgrim) {
    if (!confirm(`Delete pilgrim "${pilgrim.name}"?`)) return;

    try {
      await api.deletePilgrim(pilgrim.id);
      await Promise.all([load(), refresh()]);
    } catch (e) {
      alert(e.message);
    }
  }

  async function saveZone(event) {
    event.preventDefault();
    setBusy(true);
    setError("");

    const payload = {
      name: zoneForm.name,
      latitude: Number(zoneForm.latitude),
      longitude: Number(zoneForm.longitude),
      radius_m: Number(zoneForm.radius_m),
    };

    try {
      if (safeZone) {
        await api.updateSafeZone(groupId, payload);
      } else {
        await api.createSafeZone(groupId, payload);
      }

      await load();
      setModal(null);
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  }

  async function deleteZone() {
    if (!confirm("Delete this group's safe zone?")) return;

    try {
      await api.deleteSafeZone(groupId);
      await load();
    } catch (e) {
      alert(e.message);
    }
  }

  return (
    <div className="page-stack">
      <button className="back-button" onClick={onBack}>
        <ArrowLeft size={16} />
        Back to groups
      </button>

      <section className="group-detail-hero">
        <div>
          <span className="panel-kicker">GROUP OPERATIONS</span>
          <h2>{group.name}</h2>
          <p>{group.description || "No description provided."}</p>
        </div>

        <div className="group-detail-stats">
          <div>
            <ShieldCheck size={17} />
            <span>Guide</span>
            <strong>{guide?.name || "Unassigned"}</strong>
          </div>
          <div>
            <UserRound size={17} />
            <span>Pilgrims</span>
            <strong>{pilgrims.length}</strong>
          </div>
          <div>
            <MapPin size={17} />
            <span>Safe zone</span>
            <strong>{safeZone?.name || "Not configured"}</strong>
          </div>
        </div>
      </section>

      <section className="panel">
        <div className="panel-heading">
          <div>
            <span className="panel-kicker">GROUP SAFETY AREA</span>
            <h2>Safe zone</h2>
          </div>

          <div className="heading-actions">
            {safeZone && (
              <button className="danger-text-btn" onClick={deleteZone}>
                <Trash2 size={15} />
                Delete
              </button>
            )}
            <button className="secondary-btn" onClick={openZone}>
              <Pencil size={15} />
              {safeZone ? "Edit safe zone" : "Configure safe zone"}
            </button>
          </div>
        </div>

        {safeZone ? (
          <div className="safe-zone-summary">
            <div><span>Name</span><strong>{safeZone.name}</strong></div>
            <div><span>Latitude</span><strong>{safeZone.latitude}</strong></div>
            <div><span>Longitude</span><strong>{safeZone.longitude}</strong></div>
            <div><span>Radius</span><strong>{safeZone.radius_m} m</strong></div>
          </div>
        ) : (
          <div className="empty-small">No safe zone configured.</div>
        )}
      </section>

      <section className="panel">
        <div className="panel-heading">
          <div>
            <span className="panel-kicker">GROUP MEMBERS</span>
            <h2>Pilgrims</h2>
          </div>

          <button className="primary-btn" onClick={openAddPilgrim}>
            <Plus size={16} />
            Add pilgrim
          </button>
        </div>

        <div className="data-table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Pilgrim</th>
                <th>Phone</th>
                <th>Nationality</th>
                <th>Guardian</th>
                <th className="actions-column">Actions</th>
              </tr>
            </thead>

            <tbody>
              {pilgrims.map((pilgrim) => (
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
                  <td>{pilgrim.phone_number}</td>
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
                      onClick={() => openEditPilgrim(pilgrim)}
                    >
                      <Pencil size={15} />
                    </button>
                    <button
                      className="table-action danger"
                      onClick={() => deletePilgrim(pilgrim)}
                    >
                      <Trash2 size={15} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {pilgrims.length === 0 && (
          <div className="empty-small">No pilgrims in this group.</div>
        )}
      </section>

      {modal?.type?.includes("pilgrim") && (
        <Modal
          title={
            modal.type === "add-pilgrim"
              ? "Add pilgrim"
              : "Edit pilgrim"
          }
          onClose={() => setModal(null)}
        >
          <form className="form-stack" onSubmit={savePilgrim}>
            {error && <div className="form-error">{error}</div>}

            <label>
              Full name
              <input
                required
                value={pilgrimForm.name}
                onChange={(e) =>
                  setPilgrimForm({
                    ...pilgrimForm,
                    name: e.target.value,
                  })
                }
              />
            </label>

            <label>
              Phone number
              <input
                required
                value={pilgrimForm.phone_number}
                onChange={(e) =>
                  setPilgrimForm({
                    ...pilgrimForm,
                    phone_number: e.target.value,
                  })
                }
              />
            </label>

            <label>
              Nationality
              <input
                value={pilgrimForm.nationality}
                onChange={(e) =>
                  setPilgrimForm({
                    ...pilgrimForm,
                    nationality: e.target.value,
                  })
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
                {busy ? "Saving..." : "Save pilgrim"}
              </button>
            </div>
          </form>
        </Modal>
      )}

      {modal?.type === "safe-zone" && (
        <Modal
          title={safeZone ? "Edit safe zone" : "Configure safe zone"}
          onClose={() => setModal(null)}
        >
          <form className="form-stack" onSubmit={saveZone}>
            {error && <div className="form-error">{error}</div>}

            <label>
              Zone name
              <input
                required
                value={zoneForm.name}
                onChange={(e) =>
                  setZoneForm({ ...zoneForm, name: e.target.value })
                }
              />
            </label>

            <div className="form-grid-2">
              <label>
                Latitude
                <input
                  required
                  type="number"
                  step="any"
                  value={zoneForm.latitude}
                  onChange={(e) =>
                    setZoneForm({
                      ...zoneForm,
                      latitude: e.target.value,
                    })
                  }
                />
              </label>

              <label>
                Longitude
                <input
                  required
                  type="number"
                  step="any"
                  value={zoneForm.longitude}
                  onChange={(e) =>
                    setZoneForm({
                      ...zoneForm,
                      longitude: e.target.value,
                    })
                  }
                />
              </label>
            </div>

            <label>
              Radius (meters)
              <input
                required
                min="1"
                type="number"
                value={zoneForm.radius_m}
                onChange={(e) =>
                  setZoneForm({
                    ...zoneForm,
                    radius_m: e.target.value,
                  })
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
                {busy ? "Saving..." : "Save safe zone"}
              </button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
