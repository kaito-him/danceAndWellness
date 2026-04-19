import React, { useState, useEffect, useRef } from "react";
import api from "./../services/api";
import "../../styles/InstructorProfile.css";

export default function InstructorProfile() {
  const [form, setForm] = useState({
    username: "", email: "", studioName: "", bio: "",
    linkedIn: "", website: "", currentPassword: "", newPassword: "", confirmPassword: "",
  });
  const [original, setOriginal] = useState({});
  const [instructorId, setInstructorId] = useState(null);
  const [photoUrl, setPhotoUrl] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);
  const [errors, setErrors] = useState({});
  const [photoModal, setPhotoModal] = useState(false);

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
    const fetchProfile = async () => {
      try {
        const userId = localStorage.getItem("userId");
        if (!userId) throw new Error("No userId");
        const res = await api.get(`/instructors/by-user/${userId}`);
        const data = res.data;
        setInstructorId(data.id);
        const o = {
          username: data.username || "", email: data.email || "",
          studioName: data.studioName || "", bio: data.bio || "",
          linkedIn: data.linkedIn || "", website: data.website || "",
        };
        setOriginal(o);
        setForm((f) => ({ ...f, ...o }));
        if (data.photo) {
          const blobUrl = await fetchImageAsBlob(data.photo);
          if (blobUrl) setPhotoUrl(blobUrl);
        }
      } catch {
        showToast("error", "Failed to load profile.");
      } finally {
        setLoading(false);
      }
    };
    fetchProfile();
  }, []);

  const showToast = (type, msg) => {
    setToast({ type, msg });
    setTimeout(() => setToast(null), 4000);
  };

  const validate = () => {
    const e = {};
    if (!form.username.trim()) e.username = "Username is required.";
    if (!form.email.trim()) e.email = "Email is required.";
    else if (!/\S+@\S+\.\S+/.test(form.email)) e.email = "Invalid email address.";
    if (!form.currentPassword) e.currentPassword = "Current password is required.";
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

  /* ── photo modal actions ── */
  const openPhotoModal = () => setPhotoModal(true);
  const closePhotoModal = () => setPhotoModal(false);

  const handleUploadClick = () => {
    closePhotoModal();
    fileRef.current?.click();
  };

  const handleRemovePhoto = async () => {
    closePhotoModal();
    if (!instructorId) return;
    setUploading(true);
    try {
      await api.delete(`/instructors/${instructorId}/photo`);
      setPhotoUrl(null);
      showToast("success", "Photo removed.");
    } catch {
      showToast("error", "Failed to remove photo.");
    } finally {
      setUploading(false);
    }
  };

  const handlePhotoChange = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    closePhotoModal();
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
      if (instructorId)
        await api.patch(`/instructors/${instructorId}/photo`, { photo: fileId });
      showToast("success", "Photo updated!");
    } catch {
      showToast("error", "Failed to upload photo.");
    } finally {
      setUploading(false);
      e.target.value = "";
    }
  };

  /* ── save ── */
  const handleSubmit = async (e) => {
    e.preventDefault();
    const errs = validate();
    if (Object.keys(errs).length) { setErrors(errs); return; }
    setSaving(true);
    try {
      const instructorFields = {};
      if (form.username !== original.username) instructorFields.username = form.username;
      if (form.email !== original.email) instructorFields.email = form.email;
      if (form.studioName !== original.studioName) instructorFields.studioName = form.studioName;
      if (form.bio !== original.bio) instructorFields.bio = form.bio;
      if (form.linkedIn !== original.linkedIn) instructorFields.linkedIn = form.linkedIn;
      if (form.website !== original.website) instructorFields.website = form.website;

      const res = await api.patch(`/instructors/${instructorId}`, {
        currentPassword: form.currentPassword,
        instructor: instructorFields,
      });
      
      let data = res.data;
      let token = null;

      // Handle the case where the response is { instructor, token }
      if (data.instructor) {
        token = data.token;
        data = data.instructor;
        if (token) localStorage.setItem("token", token);
      }

      const o = {
        username: data.username || "", email: data.email || "",
        studioName: data.studioName || "", bio: data.bio || "",
        linkedIn: data.linkedIn || "", website: data.website || "",
      };
      setOriginal(o);
      setForm((f) => ({ ...f, ...o, currentPassword: "", newPassword: "", confirmPassword: "" }));
      localStorage.setItem("username", data.username || "");
      showToast("success", "Profile updated successfully!");
    } catch (err) {
      const msg = err?.response?.data?.error || "Failed to update profile.";
      if (msg.toLowerCase().includes("password")) setErrors({ currentPassword: msg });
      else if (msg.toLowerCase().includes("username")) setErrors({ username: msg });
      else if (msg.toLowerCase().includes("email")) setErrors({ email: msg });
      else showToast("error", msg);
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="ip-loading">
        <div className="ip-spinner" />
        <p>Loading profile…</p>
      </div>
    );
  }

  const initials = original.username ? original.username.slice(0, 2).toUpperCase() : "IN";

  return (
    <div className="ip-wrapper">

      {/* ── Header ── */}
      <div className="ip-header">
        <div className="ip-photo-area" onClick={openPhotoModal}>
          {photoUrl ? (
            <img src={photoUrl} alt="Profile" className="ip-photo" />
          ) : (
            <div className="ip-avatar-lg">{initials}</div>
          )}
          <div className="ip-photo-overlay">
            {uploading ? "Uploading…" : "Edit Photo"}
          </div>
          <input
            ref={fileRef} type="file" accept="image/*" hidden
            onChange={handlePhotoChange}
          />
        </div>
        <div className="ip-header-text">
          <h1 className="ip-title">Manage Profile</h1>
          <p className="ip-subtitle">Update your instructor details and credentials</p>
        </div>
      </div>

      {/* ── Photo Modal ── */}
      {photoModal && (
        <div className="ip-modal-backdrop" onClick={closePhotoModal}>
          <div className="ip-modal" onClick={(e) => e.stopPropagation()}>
            <div className="ip-modal-avatar">
              {photoUrl
                ? <img src={photoUrl} alt="Current" className="ip-modal-photo" />
                : <div className="ip-modal-initials">{initials}</div>
              }
            </div>
            <h3 className="ip-modal-title">Change Profile Picture</h3>
            <p className="ip-modal-sub">Choose an action below</p>

            <div className="ip-modal-actions">
              <button className="ip-modal-btn upload" onClick={handleUploadClick}>
                <span className="ip-modal-icon">↑</span>
                Upload Picture
              </button>
              {photoUrl && (
                <button className="ip-modal-btn remove" onClick={handleRemovePhoto}>
                  <span className="ip-modal-icon">✕</span>
                  Remove Picture
                </button>
              )}
              <button className="ip-modal-btn cancel" onClick={closePhotoModal}>
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Two-column Form ── */}
      <form className="ip-form" onSubmit={handleSubmit} noValidate>

        {/* ── Left Column ── */}
        <div className="ip-col-left">

          <div className="ip-section">
            <h2 className="ip-section-title">Account Information</h2>
            <div className="ip-row">
              <div className={`ip-field ${errors.username ? "has-error" : ""}`}>
                <label>Username</label>
                <input
                  type="text"
                  value={form.username}
                  onChange={handleChange("username")}
                  placeholder="Enter username"
                />
                {errors.username && <span className="ip-error">{errors.username}</span>}
              </div>
              <div className={`ip-field ${errors.email ? "has-error" : ""}`}>
                <label>Email Address</label>
                <input
                  type="email"
                  value={form.email}
                  onChange={handleChange("email")}
                  placeholder="Enter email"
                />
                {errors.email && <span className="ip-error">{errors.email}</span>}
              </div>
            </div>
          </div>

          <div className="ip-section">
            <h2 className="ip-section-title">Instructor Details</h2>
            <div className="ip-field">
              <label>Studio Name</label>
              <input
                type="text"
                value={form.studioName}
                onChange={handleChange("studioName")}
                placeholder="Your studio or brand name"
              />
            </div>
            <div className="ip-field">
              <label>Bio</label>
              <textarea
                rows={4}
                value={form.bio}
                onChange={handleChange("bio")}
                placeholder="Tell students about yourself…"
              />
            </div>
            <div className="ip-row">
              <div className="ip-field">
                <label>LinkedIn</label>
                <input
                  type="url"
                  value={form.linkedIn}
                  onChange={handleChange("linkedIn")}
                  placeholder="https://linkedin.com/in/yourprofile"
                />
              </div>
              <div className="ip-field">
                <label>Website</label>
                <input
                  type="url"
                  value={form.website}
                  onChange={handleChange("website")}
                  placeholder="https://yourwebsite.com"
                />
              </div>
            </div>
          </div>

        </div>

        {/* ── Right Column ── */}
        <div className="ip-col-right">

          <div className="ip-section">
            <h2 className="ip-section-title">Change Password</h2>
            <p className="ip-section-note">
              Your current password is required to save <em>any</em> changes.
            </p>
            <div className={`ip-field ${errors.currentPassword ? "has-error" : ""}`}>
              <label>Current Password <span className="ip-required">*</span></label>
              <input
                type="password"
                value={form.currentPassword}
                onChange={handleChange("currentPassword")}
                placeholder="Required to confirm changes"
              />
              {errors.currentPassword && (
                <span className="ip-error">{errors.currentPassword}</span>
              )}
            </div>
            <div className="ip-row">
              <div className={`ip-field ${errors.newPassword ? "has-error" : ""}`}>
                <label>New Password <span className="ip-optional">(optional)</span></label>
                <input
                  type="password"
                  value={form.newPassword}
                  onChange={handleChange("newPassword")}
                  placeholder="Leave blank to keep current"
                />
                {errors.newPassword && (
                  <span className="ip-error">{errors.newPassword}</span>
                )}
              </div>
              <div className={`ip-field ${errors.confirmPassword ? "has-error" : ""}`}>
                <label>Confirm New Password</label>
                <input
                  type="password"
                  value={form.confirmPassword}
                  onChange={handleChange("confirmPassword")}
                  placeholder="Repeat new password"
                />
                {errors.confirmPassword && (
                  <span className="ip-error">{errors.confirmPassword}</span>
                )}
              </div>
            </div>
          </div>

          <div className="ip-actions">
            <button
              type="button"
              className="ip-btn-secondary"
              onClick={() => {
                setForm((f) => ({
                  ...f, ...original,
                  currentPassword: "", newPassword: "", confirmPassword: "",
                }));
                setErrors({});
              }}
            >
              Reset
            </button>
            <button type="submit" className="ip-btn-primary" disabled={saving}>
              {saving ? "Saving…" : "Save Changes"}
            </button>
          </div>

        </div>

      </form>

      {/* ── Toast (top-right) ── */}
      {toast && (
        <div className={`ip-toast ${toast.type}`}>
          {toast.type === "success" ? "✓" : "✕"} {toast.msg}
        </div>
      )}

    </div>
  );
}