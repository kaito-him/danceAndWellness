import React, { useState, useEffect, useRef, useCallback } from "react";
import {
  FiPlus, FiX, FiUpload, FiAward,
  FiTrash2, FiCheckCircle, FiXCircle,
} from "react-icons/fi";
import api from "./../services/api";
import "../../styles/AdminBadges.css";

/* Fetches a protected image through the axios interceptor (sends token) */
function AuthImage({ path, alt, className }) {
  const [src, setSrc] = useState(null);

  useEffect(() => {
    if (!path) return;
    let objectUrl;
    api.get(path, { responseType: "blob" })
      .then((res) => {
        objectUrl = URL.createObjectURL(res.data);
        setSrc(objectUrl);
      })
      .catch(() => setSrc(null));
    return () => { if (objectUrl) URL.revokeObjectURL(objectUrl); };
  }, [path]);

  if (!src) return <FiAward size={48} className="badge-icon-fallback" />;
  return <img src={src} alt={alt} className={className} />;
}

export default function AdminBadges() {
  const [badges, setBadges]         = useState([]);
  const [loading, setLoading]       = useState(true);
  const [showModal, setShowModal]   = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [toast, setToast]           = useState(null);
  const [preview, setPreview]       = useState(null);
  const [iconFile, setIconFile]     = useState(null);
  const [form, setForm]             = useState({ name: "", achievement: "" });
  const fileInputRef = useRef();

  const showToast = (type, msg) => {
    setToast({ type, msg });
    setTimeout(() => setToast(null), 3500);
  };

  const resetModal = () => {
    setForm({ name: "", achievement: ""});
    setIconFile(null);
    setPreview(null);
    setShowModal(false);
  };

  const fetchBadges = async () => {
    setLoading(true);
    try {
      const res = await api.get("/badges");
      setBadges(res.data);
    } catch {
      showToast("error", "Failed to load badges.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchBadges(); }, []);

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    if (!file.type.startsWith("image/")) { showToast("error", "Please select an image file."); return; }
    setIconFile(file);
    setPreview(URL.createObjectURL(file));
  };

  const handleSubmit = async () => {
    if (!form.name.trim() || !form.achievement.trim()) {
      showToast("error", "Name and achievement are required.");
      return;
    }
    setSubmitting(true);
    try {
      let iconUrl = "";
      if (iconFile) {
        const fd = new FormData();
        fd.append("file", iconFile);
        const uploadRes = await api.post("/files/upload", fd, {
          headers: { "Content-Type": "multipart/form-data" },
        });
        iconUrl = uploadRes.data.url; // "/api/files/<id>"
      }
      await api.post("/badges", { ...form, icon: iconUrl });
      showToast("success", "Badge created successfully!");
      resetModal();
      fetchBadges();
    } catch {
      showToast("error", "Failed to create badge.");
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Delete this badge?")) return;
    try {
      await api.delete(`/badges/${id}`);
      setBadges((prev) => prev.filter((b) => b.id !== id));
      showToast("success", "Badge deleted.");
    } catch {
      showToast("error", "Failed to delete badge.");
    }
  };

  /* icon path is already "/api/files/<id>" — strip leading /api for the axios call */
  const iconPath = (icon) => icon ? icon.replace(/^\/api/, "") : null;

  return (
    <div className="badges-page">
      <div className="badges-header">
        <div>
          <h1 className="badges-title">Achievements &amp; Badges</h1>
          <p className="badges-sub">Manage the badge collection awarded to users</p>
        </div>
        <button className="badges-add-btn" onClick={() => setShowModal(true)}>
          <FiPlus size={16} /> Add Badge
        </button>
      </div>

      <div className="badges-statsbar">
        <div className="badges-stat">
          <span className="badges-stat-num">{badges.length}</span>
          <span className="badges-stat-label">Total Badges</span>
        </div>
      </div>

      {loading ? (
        <div className="badges-loading">
          <div className="badges-spinner" />
          <p>Loading badges…</p>
        </div>
      ) : badges.length === 0 ? (
        <div className="badges-empty">
          <FiAward size={52} />
          <h2>No badges yet</h2>
          <p>Create your first badge to get started.</p>
        </div>
      ) : (
        <div className="badges-grid">
          {badges.map((badge) => (
            <div className="badge-card" key={badge.id}>
              <div className="badge-icon-wrap">
                <AuthImage
                  path={iconPath(badge.icon)}
                  alt={badge.name}
                  className="badge-icon-img"
                />
              </div>
              <h3 className="badge-name">{badge.name}</h3>
              <span className="badge-achievement">{badge.achievement}</span>



              <div className="badge-actions">
                <button
                  className="badge-action-btn delete"
                  onClick={() => handleDelete(badge.id)}
                  title="Delete"
                >
                  <FiTrash2 size={14} />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {showModal && (
        <div className="badges-overlay" onClick={resetModal}>
          <div className="badges-modal" onClick={(e) => e.stopPropagation()}>
            <div className="badges-modal-header">
              <h2>New Badge</h2>
              <button className="badges-modal-close" onClick={resetModal}><FiX size={18} /></button>
            </div>
            <div className="badges-upload-area" onClick={() => fileInputRef.current.click()}>
              {preview ? (
                <img src={preview} alt="preview" className="badges-preview-img" />
              ) : (
                <>
                  <FiUpload size={28} className="badges-upload-icon" />
                  <p>Click to upload badge icon</p>
                  <span>PNG, JPG, SVG — recommended 256×256</span>
                </>
              )}
            </div>
            <input ref={fileInputRef} type="file" accept="image/*" style={{ display: "none" }} onChange={handleFileChange} />
            <div className="badges-form">
              <div className="badges-field">
                <label>Badge Name *</label>
                <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="e.g. Elite Champion" />
              </div>
              <div className="badges-field">
                <label>Achievement *</label>
                <input value={form.achievement} onChange={(e) => setForm({ ...form, achievement: e.target.value })} placeholder="e.g. Complete 50 courses" />
              </div>
            </div>
            <div className="badges-modal-footer">
              <button className="badges-btn-cancel" onClick={resetModal}>Cancel</button>
              <button className="badges-btn-submit" onClick={handleSubmit} disabled={submitting}>
                {submitting ? "Creating…" : "Create Badge"}
              </button>
            </div>
          </div>
        </div>
      )}

      {toast && (
        <div className={`badges-toast ${toast.type}`}>
          {toast.type === "success" ? <FiCheckCircle size={15} /> : <FiXCircle size={15} />}
          {toast.msg}
        </div>
      )}
    </div>
  );
}