import React, { useState, useEffect, useRef } from "react";
import api from "./../services/api";
import "../../styles/AdminProfile.css";
import { FiCamera, FiUpload, FiTrash2, FiX } from "react-icons/fi";

export default function AdminProfile({ onUpdate }) {
  const [form, setForm] = useState({
    username:        "",
    email:           "",
    currentPassword: "",
    newPassword:     "",
    confirmPassword: "",
  });
  const [original, setOriginal] = useState({ username: "", email: "" });
  const [photoUrl, setPhotoUrl] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [photoModal, setPhotoModal] = useState(false);
  const [loading,  setLoading]  = useState(true);
  const [saving,   setSaving]   = useState(false);
  const [toast,    setToast]    = useState(null);
  const [errors,   setErrors]   = useState({});

  const fileRef = useRef();

  const fetchImageAsBlob = async (fileId) => {
    try {
      const res = await api.get(`/files/${fileId}`, { responseType: "blob" });
      return URL.createObjectURL(res.data);
    } catch (e) {
      console.error("Failed to load image blob", e);
      return null;
    }
  };

  useEffect(() => {
    const fetchMe = async () => {
      try {
        const res = await api.get("/users/me");
        const { username, email, photo } = res.data;
        setOriginal({ username, email });
        setForm((f) => ({ ...f, username, email }));
        if (photo) {
          const blobUrl = await fetchImageAsBlob(photo);
          if (blobUrl) setPhotoUrl(blobUrl);
        }
      } catch {
        showToast("error", "Failed to load profile.");
      } finally {
        setLoading(false);
      }
    };
    fetchMe();
  }, []);

  const showToast = (type, msg) => {
    setToast({ type, msg });
    setTimeout(() => setToast(null), 4000);
  };

  const validate = () => {
    const e = {};
    if (!form.username.trim())       e.username = "Username is required.";
    if (!form.email.trim())          e.email    = "Email is required.";
    else if (!/\S+@\S+\.\S+/.test(form.email)) e.email = "Invalid email address.";
    if (!form.currentPassword)       e.currentPassword = "Current password is required.";
    if (form.newPassword && form.newPassword.length < 6)
      e.newPassword = "New password must be at least 6 characters.";
    if (form.newPassword && form.newPassword !== form.confirmPassword)
      e.confirmPassword = "Passwords do not match.";
    return e;
  };

  const handleChange = (field) => (e) => {
    setForm((f) => ({ ...f, [field]: e.target.value }));
    setErrors((er) => ({ ...er, [field]: undefined }));
  };

  const handlePhotoChange = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setPhotoModal(false);
    setUploading(true);
    try {
      const fd = new FormData();
      fd.append("file", file);
      const res = await api.post("/files/upload", fd, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      const fileId = res.data.id;
      const blobUrl = await fetchImageAsBlob(fileId);
      if (blobUrl) setPhotoUrl(blobUrl);
      
      await api.patch("/users/me/photo", { photo: fileId });
      showToast("success", "Photo updated!");
      if (onUpdate) onUpdate({ photo: fileId });
    } catch {
      showToast("error", "Failed to upload photo.");
    } finally {
      setUploading(false);
      if (fileRef.current) fileRef.current.value = "";
    }
  };

  const handleRemovePhoto = async () => {
    setPhotoModal(false);
    setUploading(true);
    try {
      await api.delete("/users/me/photo");
      setPhotoUrl(null);
      showToast("success", "Photo removed.");
      if (onUpdate) onUpdate({ photo: null });
    } catch {
      showToast("error", "Failed to remove photo.");
    } finally {
      setUploading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const errs = validate();
    if (Object.keys(errs).length) { setErrors(errs); return; }

    setSaving(true);
    try {
      const payload = {
        currentPassword: form.currentPassword,
        username:        form.username !== original.username ? form.username : undefined,
        email:           form.email    !== original.email    ? form.email    : undefined,
        newPassword:     form.newPassword || undefined,
      };

      const res = await api.put("/users/me", payload);
      const { username, email, token } = res.data;

      // Sync localStorage so topbar stays updated
      localStorage.setItem("username", username);
      if (token) {
        localStorage.setItem("token", token);
      }
      
      setOriginal({ username, email });
      if (onUpdate) onUpdate({ username, email });
      setForm((f) => ({
        ...f,
        username,
        email,
        currentPassword: "",
        newPassword:     "",
        confirmPassword: "",
      }));
      showToast("success", "Profile updated successfully!");
    } catch (err) {
      const msg = err?.response?.data?.message || "Failed to update profile.";
      if (msg.toLowerCase().includes("password")) {
        setErrors({ currentPassword: msg });
      } else if (msg.toLowerCase().includes("username")) {
        setErrors({ username: msg });
      } else if (msg.toLowerCase().includes("email")) {
        setErrors({ email: msg });
      } else {
        showToast("error", msg);
      }
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="ap-loading">
        <div className="ap-spinner" />
        <p>Loading profile…</p>
      </div>
    );
  }

  const initials = original.username
    ? original.username.slice(0, 2).toUpperCase()
    : "AD";

  return (
    <div className="ap-wrapper">
      <div className="ap-header">
        <div className="ap-photo-area" onClick={() => setPhotoModal(true)}>
          {photoUrl ? (
            <img src={photoUrl} alt="Profile" className="ap-photo" />
          ) : (
            <div className="ap-avatar-lg">{initials}</div>
          )}
          <div className="ap-photo-overlay">
            {uploading ? "Updating…" : "Edit"}
          </div>
          <input
            ref={fileRef} type="file" accept="image/*" hidden
            onChange={handlePhotoChange}
          />
        </div>
        <div>
          <h1 className="ap-title">Manage Profile</h1>
          <p className="ap-subtitle">Update your account credentials and photo</p>
        </div>
      </div>

      {/* ── Photo Modal ── */}
      {photoModal && (
        <div className="ap-modal-backdrop" onClick={() => setPhotoModal(false)}>
          <div className="ap-modal" onClick={(e) => e.stopPropagation()}>
            <div className="ap-modal-avatar">
              {photoUrl ? (
                <img src={photoUrl} alt="Current" className="ap-modal-photo" />
              ) : (
                <div className="ap-modal-initials">{initials}</div>
              )}
            </div>
            <h3 className="ap-modal-title">Profile Picture</h3>
            <p className="ap-modal-sub">Choose an action below</p>

            <div className="ap-modal-actions">
              <button className="ap-modal-btn upload" onClick={() => { setPhotoModal(false); fileRef.current.click(); }}>
                <FiUpload className="ap-modal-icon" /> Upload New
              </button>
              {photoUrl && (
                <button className="ap-modal-btn remove" onClick={handleRemovePhoto}>
                  <FiTrash2 className="ap-modal-icon" /> Remove
                </button>
              )}
              <button className="ap-modal-btn cancel" onClick={() => setPhotoModal(false)}>
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      <form className="ap-form" onSubmit={handleSubmit} noValidate>
        <div className="ap-cols">
          {/* ── Left Column: Account info ── */}
          <div className="ap-col-left">
            <div className="ap-section">
              <h2 className="ap-section-title">Account Information</h2>
              
              <div className={`ap-field ${errors.username ? "has-error" : ""}`}>
                <label>Username</label>
                <input
                  type="text"
                  value={form.username}
                  onChange={handleChange("username")}
                  placeholder="Enter username"
                />
                {errors.username && <span className="ap-error">{errors.username}</span>}
              </div>

              <div className={`ap-field ${errors.email ? "has-error" : ""}`}>
                <label>Email Address</label>
                <input
                  type="email"
                  value={form.email}
                  onChange={handleChange("email")}
                  placeholder="Enter email"
                />
                {errors.email && <span className="ap-error">{errors.email}</span>}
              </div>
            </div>
          </div>

          {/* ── Right Column: Password ── */}
          <div className="ap-col-right">
            <div className="ap-section">
              <h2 className="ap-section-title">Change Password</h2>
              <p className="ap-section-note">
                Your current password is required to save <em>any</em> changes.
              </p>

              <div className={`ap-field ${errors.currentPassword ? "has-error" : ""}`}>
                <label>Current Password <span className="ap-required">*</span></label>
                <input
                  type="password"
                  value={form.currentPassword}
                  onChange={handleChange("currentPassword")}
                  placeholder="Required to confirm changes"
                />
                {errors.currentPassword && (
                  <span className="ap-error">{errors.currentPassword}</span>
                )}
              </div>

              <div className="ap-row">
                <div className={`ap-field ${errors.newPassword ? "has-error" : ""}`}>
                  <label>New Password <span className="ap-optional">(optional)</span></label>
                  <input
                    type="password"
                    value={form.newPassword}
                    onChange={handleChange("newPassword")}
                    placeholder="Leave blank"
                  />
                  {errors.newPassword && (
                    <span className="ap-error">{errors.newPassword}</span>
                  )}
                </div>

                <div className={`ap-field ${errors.confirmPassword ? "has-error" : ""}`}>
                  <label>Confirm Password</label>
                  <input
                    type="password"
                    value={form.confirmPassword}
                    onChange={handleChange("confirmPassword")}
                    placeholder="Repeat"
                  />
                  {errors.confirmPassword && (
                    <span className="ap-error">{errors.confirmPassword}</span>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* ── Actions ── */}
        <div className="ap-actions">
          <button
            type="button"
            className="ap-btn-secondary"
            onClick={() => {
              setForm((f) => ({
                ...f,
                username:        original.username,
                email:           original.email,
                currentPassword: "",
                newPassword:     "",
                confirmPassword: "",
              }));
              setErrors({});
            }}
          >
            Reset
          </button>
          <button type="submit" className="ap-btn-primary" disabled={saving}>
            {saving ? "Saving…" : "Save Changes"}
          </button>
        </div>
      </form>

      {/* Toast */}
      {toast && (
        <div className={`ap-toast ${toast.type}`}>
          {toast.type === "success" ? "✓" : "✕"} {toast.msg}
        </div>
      )}
    </div>
  );
}