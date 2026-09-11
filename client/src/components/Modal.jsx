import { t } from "../i18n";import { X } from "lucide-react";

export default function Modal({ title, children, onClose, width = 560 }) {
  return (
    <div className="modal-backdrop" onMouseDown={onClose}>
      <section
        className="modal-card"
        style={{ maxWidth: width }}
        onMouseDown={(event) => event.stopPropagation()}>

        <div className="modal-head">
          <h2>{t(title)}</h2>
          <button type="button" className="icon-plain" onClick={onClose}>
            <X size={18} />
          </button>
        </div>
        <div className="modal-body">{t(children)}</div>
      </section>
    </div>);

}
