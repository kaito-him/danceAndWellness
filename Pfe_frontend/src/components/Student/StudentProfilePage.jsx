import React, { useState, useEffect, useRef } from "react";
import api from "./../services/api";
import useCurrentUser from "./../services/useCurrentUser";
import {
  FiEdit2, FiMail, FiUser, FiAward,
  FiBookOpen, FiActivity, FiBriefcase, FiDollarSign,
  FiLock, FiCamera, FiX, FiSave,
} from "react-icons/fi";

/* ── Design tokens (match the dashboard palette) ── */
const T = {
  gold:        "#b89c4d",
  goldHover:   "#c9ad5e",
  goldTint:    "rgba(184,156,77,0.10)",
  goldBorder:  "rgba(184,156,77,0.22)",
  goldShadow:  "rgba(184,156,77,0.28)",
  text:        "#1c1a14",
  textSub:     "#5a5647",
  muted:       "#9a9284",
  border:      "#e8e4da",
  surface:     "#ffffff",
  surface2:    "#fafaf8",
  red:         "#c0392b",
  redTint:     "#fdf3f2",
  redBorder:   "#f0b8b2",
  radius:      "14px",
  radiusSm:    "9px",
  font:        "'DM Sans', system-ui, sans-serif",
  fontDisplay: "'Playfair Display', Georgia, serif",
};

/* ── Reusable inline style objects ── */
const S = {
  page: {
    maxWidth: 920,
    width: "100%",
    margin: "0 auto",
    padding: "32px 28px 72px",
    fontFamily: T.font,
    color: T.text,
    boxSizing: "border-box",
  },
  card: {
    background: T.surface,
    border: `1px solid ${T.border}`,
    borderRadius: T.radius,
    padding: "24px",
    boxSizing: "border-box",
  },
  sectionTitle: {
    fontFamily: T.fontDisplay,
    fontSize: 15,
    fontWeight: 700,
    color: T.text,
    margin: "0 0 16px 0",
    padding: "0 0 12px 0",
    borderBottom: `1px solid ${T.border}`,
    display: "flex",
    alignItems: "center",
    gap: 8,
    boxSizing: "border-box",
  },
  label: {
    display: "block",
    fontSize: 11,
    fontWeight: 600,
    textTransform: "uppercase",
    letterSpacing: "0.5px",
    color: T.muted,
    margin: "0 0 6px 0",
    padding: 0,
    fontFamily: T.font,
  },
  input: {
    display: "block",
    width: "100%",
    padding: "11px 14px",
    border: `1.5px solid ${T.border}`,
    borderRadius: T.radiusSm,
    fontSize: 14,
    fontFamily: T.font,
    color: T.text,
    background: T.surface2,
    outline: "none",
    boxSizing: "border-box",
    margin: 0,
    lineHeight: "1.4",
  },
  inputDisabled: {
    display: "block",
    width: "100%",
    padding: "11px 14px",
    border: `1.5px solid ${T.border}`,
    borderRadius: T.radiusSm,
    fontSize: 14,
    fontFamily: T.font,
    color: "#aaa",
    background: "#f5f4f0",
    outline: "none",
    boxSizing: "border-box",
    margin: 0,
    cursor: "not-allowed",
    lineHeight: "1.4",
  },
  btnPrimary: {
    display: "inline-flex",
    alignItems: "center",
    gap: 7,
    padding: "11px 26px",
    background: T.gold,
    color: "#fff",
    border: "none",
    borderRadius: T.radiusSm,
    fontSize: 14,
    fontFamily: T.font,
    fontWeight: 600,
    cursor: "pointer",
    whiteSpace: "nowrap",
    boxSizing: "border-box",
    margin: 0,
    lineHeight: "1",
  },
  btnSecondary: {
    display: "inline-flex",
    alignItems: "center",
    gap: 7,
    padding: "11px 26px",
    background: T.surface2,
    color: T.textSub,
    border: `1.5px solid ${T.border}`,
    borderRadius: T.radiusSm,
    fontSize: 14,
    fontFamily: T.font,
    fontWeight: 500,
    cursor: "pointer",
    whiteSpace: "nowrap",
    boxSizing: "border-box",
    margin: 0,
    lineHeight: "1",
  },
  errorText: {
    display: "block",
    fontSize: 12,
    color: T.red,
    margin: "4px 0 0 0",
    padding: 0,
    fontFamily: T.font,
  },
  hintText: {
    display: "block",
    fontSize: 11.5,
    color: T.muted,
    margin: "4px 0 0 0",
    padding: 0,
    fontFamily: T.font,
    lineHeight: "1.4",
  },
};

export default function StudentProfilePage() {
  const { refresh: refreshCurrentUser } = useCurrentUser();

  const [form, setForm] = useState({
    username: "", email: "",
    currentPassword: "", newPassword: "", confirmPassword: "",
  });
  const [original,   setOriginal]   = useState({});
  const [photoUrl,   setPhotoUrl]   = useState(null);
  const [skillLevel, setSkillLevel] = useState("Not set");
  const [stats,      setStats]      = useState({
    enrollmentsCount: 0, paymentsCount: 0,
    loginStreak: 0,      categoriesWatched: 0,
  });
  const [uploading,  setUploading]  = useState(false);
  const [loading,    setLoading]    = useState(true);
  const [saving,     setSaving]     = useState(false);
  const [toast,      setToast]      = useState(null);
  const [errors,     setErrors]     = useState({});
  const [isEditing,  setIsEditing]  = useState(false);
  const [photoModal, setPhotoModal] = useState(false);

  const fileRef = useRef();

  /* ── helpers ── */
  const showToast = (type, msg) => {
    setToast({ type, msg });
    setTimeout(() => setToast(null), 4000);
  };

  const fetchBlob = async (fileId) => {
    try {
      const res = await api.get(`/files/${fileId}`, { responseType: "blob" });
      return URL.createObjectURL(res.data);
    } catch { return null; }
  };

  /* ── load ── */
  useEffect(() => {
    (async () => {
      try {
        const userId = localStorage.getItem("userId");
        if (!userId) throw new Error("No userId");

        const [stuRes, userRes, statsRes, skillRes] = await Promise.all([
          api.get(`/students/by-user/${userId}`),
          api.get(`/users/me`),
          api.get(`/students/stats/${userId}`),
          api.get(`/students/skill-level/${userId}`),
        ]);

        const u = userRes.data;
        const s = stuRes.data;

        setStats(statsRes.data);
        setSkillLevel(skillRes.data.skillLevel || "Not set");

        const o = { username: u.username || "", email: u.email || "" };
        setOriginal(o);
        setForm(f => ({ ...f, ...o }));

        const photoId = u.photo || s.photo;
        if (photoId) {
          const blob = await fetchBlob(photoId);
          if (blob) setPhotoUrl(blob);
        }
      } catch (err) {
        console.error(err);
        showToast("error", "Failed to load profile.");
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  /* ── validation ── */
  const validate = () => {
    const e = {};
    if (!form.username.trim())  e.username        = "Username is required.";
    if (!form.email.trim())     e.email           = "Email is required.";
    if (!form.currentPassword)  e.currentPassword = "Current password is required.";
    if (form.newPassword && form.newPassword.length < 8)
      e.newPassword = "New password must be at least 8 characters.";
    if (form.newPassword && form.newPassword !== form.confirmPassword)
      e.confirmPassword = "Passwords do not match.";
    return e;
  };

  const handleChange = field => e => {
    setForm(f => ({ ...f, [field]: e.target.value }));
    setErrors(er => ({ ...er, [field]: undefined }));
  };

  /* ── photo ── */
  const handleUploadClick = () => { setPhotoModal(false); fileRef.current?.click(); };

  const handleRemovePhoto = async () => {
    setPhotoModal(false);
    setUploading(true);
    try {
      await api.delete("/users/me/photo");
      setPhotoUrl(null);
      localStorage.setItem("userPhoto", "");
      refreshCurrentUser();
      showToast("success", "Photo removed.");
    } catch (err) {
      showToast("error", err?.response?.data?.message || "Failed to remove photo.");
    } finally { setUploading(false); }
  };

  const handlePhotoChange = async e => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    try {
      const fd = new FormData();
      fd.append("file", file);
      const up = await api.post("/files/upload", fd, {
        headers: { "Content-Type": "multipart/form-data" },
      });
      const fileId = up.data.id;
      if (!fileId) throw new Error("No file ID returned.");
      await api.patch("/users/me/photo", { photo: fileId });
      const blob = await fetchBlob(fileId);
      if (blob) setPhotoUrl(blob);
      localStorage.setItem("userPhoto", fileId);
      refreshCurrentUser();
      showToast("success", "Profile picture updated!");
    } catch (err) {
      const msg = err?.response?.status === 403
        ? "Upload not allowed. Please contact support."
        : err?.response?.data?.message || "Failed to upload photo.";
      showToast("error", msg);
    } finally { setUploading(false); e.target.value = ""; }
  };

  /* ── submit ── */
  const handleSubmit = async e => {
    e.preventDefault();
    const errs = validate();
    if (Object.keys(errs).length) { setErrors(errs); return; }
    setSaving(true);
    try {
      const res  = await api.put("/users/me", {
        currentPassword: form.currentPassword,
        username:        form.username,
        email:           form.email,
        newPassword:     form.newPassword || undefined,
      });
      const data = res.data;
      const o = { username: data.username, email: data.email };
      setOriginal(o);
      setForm(f => ({ ...f, ...o, currentPassword: "", newPassword: "", confirmPassword: "" }));
      if (data.token) localStorage.setItem("token", data.token);
      localStorage.setItem("username", data.username);
      showToast("success", "Profile updated successfully!");
      setIsEditing(false);
    } catch (err) {
      showToast("error", err?.response?.data?.message || "Failed to update profile.");
    } finally { setSaving(false); }
  };

  const cancelEdit = () => {
    setForm(f => ({ ...f, ...original, currentPassword: "", newPassword: "", confirmPassword: "" }));
    setErrors({});
    setIsEditing(false);
  };

  /* ── loading ── */
  if (loading) {
    return (
      <div style={{ display:"flex", flexDirection:"column", alignItems:"center",
                    justifyContent:"center", minHeight:"40vh", gap:14,
                    color: T.muted, fontSize:14, fontFamily: T.font }}>
        <div className="sp-spinner" />
        <p style={{ margin:0, padding:0 }}>Loading profile…</p>
      </div>
    );
  }

  const initials = original.username?.slice(0,2).toUpperCase() || "ST";

  return (
    <div style={S.page}>

      {/* ══ HEADER ══ */}
      <div style={{
        display: "flex", alignItems: "center", gap: 20,
        marginBottom: 24, padding: "22px 26px",
        background: T.surface, borderRadius: 16,
        border: `1px solid ${T.border}`,
        boxShadow: "0 1px 6px rgba(28,26,20,0.06)",
        boxSizing: "border-box",
      }}>
        {/* Photo */}
        <div
          className="sp-photo-wrap"
          onClick={() => setPhotoModal(true)}
          title="Change profile picture"
          style={{
            position: "relative", width: 72, height: 72,
            borderRadius: "50%", overflow: "hidden",
            cursor: "pointer", flexShrink: 0,
            boxShadow: `0 2px 10px ${T.goldShadow}`,
          }}
        >
          {photoUrl
            ? <img src={photoUrl} alt="Profile"
                style={{ width:"100%", height:"100%", objectFit:"cover", display:"block", margin:0, padding:0 }} />
            : <div style={{
                width:"100%", height:"100%",
                background: T.goldTint,
                display:"flex", alignItems:"center", justifyContent:"center",
                fontFamily: T.fontDisplay, fontSize:20, fontWeight:700, color: T.gold,
              }}>{initials}</div>
          }
          <div className="sp-photo-overlay">
            {uploading ? "Uploading…" : <><FiCamera size={12} /> Edit</>}
          </div>
          <input ref={fileRef} type="file" accept="image/*"
            style={{ display:"none" }} onChange={handlePhotoChange} />
        </div>

        {/* Title */}
        <div style={{ flex:1, minWidth:0 }}>
          <h1 style={{
            fontFamily: T.fontDisplay, fontSize:22, fontWeight:700,
            color: T.text, margin:0, padding:0, lineHeight:1.2,
            whiteSpace:"nowrap", overflow:"hidden", textOverflow:"ellipsis",
          }}>
            {original.username || "My Profile"}
          </h1>
          <p style={{ fontSize:13, color: T.muted, margin:"4px 0 0 0", padding:0, lineHeight:1.5 }}>
            Manage your account and track your learning progress
          </p>
        </div>

        {/* Edit button */}
        {!isEditing && (
          <button style={S.btnSecondary} onClick={() => setIsEditing(true)}>
            <FiEdit2 size={13} /> Edit Profile
          </button>
        )}
      </div>

      {/* ══ PHOTO MODAL ══ */}
      {photoModal && (
        <div
          onClick={() => setPhotoModal(false)}
          style={{
            position:"fixed", inset:0, background:"rgba(0,0,0,0.48)",
            backdropFilter:"blur(3px)", display:"flex",
            alignItems:"center", justifyContent:"center", zIndex:9000,
          }}
        >
          <div
            onClick={e => e.stopPropagation()}
            style={{
              background: T.surface, borderRadius:16, padding:"32px 28px 26px",
              width:320, maxWidth:"90vw", display:"flex", flexDirection:"column",
              alignItems:"center", gap:8, boxSizing:"border-box",
              boxShadow:"0 20px 60px rgba(0,0,0,0.18)",
              border: `1.5px solid ${T.border}`,
            }}
          >
            {/* Current photo preview */}
            <div style={{
              width:84, height:84, borderRadius:"50%", overflow:"hidden",
              marginBottom:4, border:`2px solid ${T.goldBorder}`,
              boxShadow:`0 2px 12px ${T.goldShadow}`, flexShrink:0,
            }}>
              {photoUrl
                ? <img src={photoUrl} alt="Current"
                    style={{ width:"100%", height:"100%", objectFit:"cover", display:"block" }} />
                : <div style={{
                    width:"100%", height:"100%", background: T.goldTint,
                    display:"flex", alignItems:"center", justifyContent:"center",
                    fontFamily: T.fontDisplay, fontSize:24, fontWeight:700, color: T.gold,
                  }}>{initials}</div>
              }
            </div>

            <h3 style={{ fontFamily: T.fontDisplay, fontSize:16, fontWeight:700,
                         color: T.text, margin:"4px 0 0 0", padding:0, textAlign:"center" }}>
              Change Profile Picture
            </h3>
            <p style={{ fontSize:13, color: T.muted, margin:"0 0 8px 0", padding:0, textAlign:"center" }}>
              Choose an action below
            </p>

            {/* Actions */}
            <div style={{ display:"flex", flexDirection:"column", gap:9, width:"100%", marginTop:4 }}>
              <button
                onClick={handleUploadClick}
                style={{ ...S.btnPrimary, width:"100%", justifyContent:"center", padding:"12px 16px" }}
              >
                ↑ Upload Picture
              </button>
              {photoUrl && (
                <button
                  onClick={handleRemovePhoto}
                  style={{
                    width:"100%", padding:"12px 16px", borderRadius: T.radiusSm,
                    fontSize:14, fontFamily: T.font, fontWeight:500, cursor:"pointer",
                    display:"flex", alignItems:"center", justifyContent:"center", gap:8,
                    background: T.redTint, color: T.red,
                    border:`1.5px solid ${T.redBorder}`, boxSizing:"border-box", margin:0,
                  }}
                >
                  ✕ Remove Picture
                </button>
              )}
              <button
                onClick={() => setPhotoModal(false)}
                style={{ ...S.btnSecondary, width:"100%", justifyContent:"center", padding:"12px 16px" }}
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ══ READ-ONLY VIEW ══ */}
      {!isEditing && (
        <div style={{
          display:"grid", gridTemplateColumns:"1fr 1fr", gap:20,
          boxSizing:"border-box",
        }}>
          {/* Account card */}
          <div style={{ ...S.card, border:`1px solid ${T.goldBorder}` }}>
            <h2 style={{ ...S.sectionTitle, color: T.gold, borderBottomColor: T.goldBorder }}>
              <FiUser size={14} /> Account Information
            </h2>
            <InfoRow icon={<FiUser size={14}/>}     label="Username"      value={original.username} />
            <InfoRow icon={<FiMail size={14}/>}     label="Email Address" value={original.email} />
            <InfoRow icon={<FiAward size={14}/>}    label="Skill Level"   value={skillLevel} last />
          </div>

          {/* Stats card */}
          <div style={{ ...S.card, border:`1px solid ${T.goldBorder}` }}>
            <h2 style={{ ...S.sectionTitle, color: T.gold, borderBottomColor: T.goldBorder }}>
              <FiActivity size={14} /> Learning Statistics
            </h2>
            <InfoRow icon={<FiBookOpen size={14}/>}  label="Enrollments"  value={stats.enrollmentsCount} />
            <InfoRow icon={<FiActivity size={14}/>}  label="Login Streak" value={`${stats.loginStreak} days`} />
            <InfoRow icon={<FiDollarSign size={14}/>} label="Paid Courses" value={stats.paymentsCount} />
            <InfoRow icon={<FiBriefcase size={14}/>} label="Styles Tried" value={stats.categoriesWatched} last />
          </div>
        </div>
      )}

      {/* ══ EDIT FORM ══ */}
      {isEditing && (
        <form
          onSubmit={handleSubmit}
          noValidate
          style={{
            display:"grid", gridTemplateColumns:"1fr 1fr", gap:20,
            margin:0, padding:0, boxSizing:"border-box",
          }}
        >
          {/* ── Left column ── */}
          <div style={{ display:"flex", flexDirection:"column", gap:20 }}>
            <div style={S.card}>
              <h2 style={S.sectionTitle}>Account Information</h2>

              <Field label="Username" error={errors.username}>
                <input
                  id="sp-username" type="text"
                  value={form.username} onChange={handleChange("username")}
                  placeholder="Enter username" autoComplete="username"
                  style={errors.username
                    ? { ...S.input, borderColor: T.red, boxShadow:`0 0 0 3px rgba(192,57,43,0.08)` }
                    : S.input}
                />
              </Field>

              <Field label="Email Address" error={errors.email}>
                <input
                  id="sp-email" type="email"
                  value={form.email} onChange={handleChange("email")}
                  placeholder="Enter email" autoComplete="email"
                  style={errors.email
                    ? { ...S.input, borderColor: T.red, boxShadow:`0 0 0 3px rgba(192,57,43,0.08)` }
                    : S.input}
                />
              </Field>

              <Field label="Skill Level"
                hint="Set during registration — contact support to change.">
                <input type="text" value={skillLevel} disabled style={S.inputDisabled} />
              </Field>
            </div>
          </div>

          {/* ── Right column ── */}
          <div style={{ display:"flex", flexDirection:"column", gap:20 }}>
            <div style={S.card}>
              <h2 style={S.sectionTitle}><FiLock size={13}/> Change Password</h2>
              <p style={{ fontSize:13, color: T.muted, margin:"0 0 16px 0", padding:0, lineHeight:1.5 }}>
                Your current password is required to save <em>any</em> changes.
              </p>

              <Field
                label={<>Current Password <span style={{ color: T.red }}>*</span></>}
                error={errors.currentPassword}
              >
                <input
                  id="sp-cur-pw" type="password"
                  value={form.currentPassword} onChange={handleChange("currentPassword")}
                  placeholder="Required to confirm any changes"
                  autoComplete="current-password"
                  style={errors.currentPassword
                    ? { ...S.input, borderColor: T.red, boxShadow:`0 0 0 3px rgba(192,57,43,0.08)` }
                    : S.input}
                />
              </Field>

              <Field
                label={<>New Password <span style={{ fontSize:11, color: T.muted, fontWeight:400,
                  textTransform:"none", letterSpacing:0 }}>(optional)</span></>}
                error={errors.newPassword}
              >
                <input
                  id="sp-new-pw" type="password"
                  value={form.newPassword} onChange={handleChange("newPassword")}
                  placeholder="Leave blank to keep current password"
                  autoComplete="new-password"
                  style={errors.newPassword
                    ? { ...S.input, borderColor: T.red, boxShadow:`0 0 0 3px rgba(192,57,43,0.08)` }
                    : S.input}
                />
              </Field>

              <Field label="Confirm New Password" error={errors.confirmPassword}>
                <input
                  id="sp-conf-pw" type="password"
                  value={form.confirmPassword} onChange={handleChange("confirmPassword")}
                  placeholder="Repeat new password"
                  autoComplete="new-password"
                  style={errors.confirmPassword
                    ? { ...S.input, borderColor: T.red, boxShadow:`0 0 0 3px rgba(192,57,43,0.08)` }
                    : S.input}
                />
              </Field>
            </div>
          </div>

          {/* ── Full-width action bar ── */}
          <div style={{
            gridColumn: "1 / -1",
            display:"flex", justifyContent:"flex-end", alignItems:"center",
            gap:12, padding:"4px 0 0 0", margin:0, boxSizing:"border-box",
          }}>
            <button type="button" style={S.btnSecondary} onClick={cancelEdit}>
              <FiX size={13}/> Cancel
            </button>
            <button
              type="submit"
              disabled={saving}
              style={saving
                ? { ...S.btnPrimary, opacity:0.6, cursor:"not-allowed" }
                : S.btnPrimary}
            >
              <FiSave size={13}/> {saving ? "Saving…" : "Save Changes"}
            </button>
          </div>
        </form>
      )}

      {/* ══ TOAST ══ */}
      {toast && (
        <div
          role="alert"
          style={{
            position:"fixed", top:80, right:28,
            padding:"13px 20px", borderRadius:11,
            fontSize:13.5, fontFamily: T.font,
            zIndex:9999, display:"flex", alignItems:"center", gap:9,
            boxShadow:"0 8px 24px rgba(0,0,0,0.12)", maxWidth:340,
            ...(toast.type === "success"
              ? { background:"#f0faf4", border:"1px solid #a8dfc0", color:"#1e8449" }
              : { background: T.redTint, border:`1px solid ${T.redBorder}`, color: T.red }),
          }}
        >
          {toast.type === "success" ? "✓" : "✕"} {toast.msg}
        </div>
      )}

      {/* spinner + photo overlay keyframes */}
      <style>{`
        .sp-spinner {
          width: 28px; height: 28px;
          border: 3px solid rgba(184,156,77,0.15);
          border-top-color: #b89c4d;
          border-radius: 50%;
          animation: spSpin 0.75s linear infinite;
          flex-shrink: 0;
        }
        @keyframes spSpin { to { transform: rotate(360deg); } }
        .sp-photo-overlay {
          position: absolute; inset: 0;
          background: rgba(0,0,0,0.52);
          display: flex; align-items: center; justify-content: center;
          gap: 4px; font-size: 11px; font-weight: 600; color: #fff;
          opacity: 0; transition: opacity 0.18s;
          pointer-events: none;
        }
        .sp-photo-wrap:hover .sp-photo-overlay { opacity: 1; }
      `}</style>
    </div>
  );
}

/* ── Field wrapper ── */
function Field({ label, error, hint, children }) {
  return (
    <div style={{ display:"flex", flexDirection:"column", margin:"0 0 16px 0", padding:0, boxSizing:"border-box" }}>
      <label style={S.label}>{label}</label>
      {children}
      {error && <span style={S.errorText}>{error}</span>}
      {hint  && <span style={S.hintText}>{hint}</span>}
    </div>
  );
}

/* ── Info row for read-only view ── */
function InfoRow({ icon, label, value, last }) {
  return (
    <div style={{
      display:"flex", alignItems:"flex-start", gap:12,
      padding:"10px 0", margin:0,
      borderBottom: last ? "none" : "1px solid rgba(232,228,218,0.5)",
      boxSizing:"border-box",
    }}>
      <span style={{ color:"#b89c4d", marginTop:2, flexShrink:0 }}>{icon}</span>
      <div style={{ flex:1, minWidth:0 }}>
        <span style={{
          display:"block", fontSize:10, textTransform:"uppercase",
          letterSpacing:"0.5px", color:"#9a9284",
          margin:"0 0 3px 0", padding:0, fontFamily: T.font,
        }}>{label}</span>
        <span style={{
          display:"block", fontSize:14, fontWeight:500,
          color:"#1c1a14", lineHeight:1.4, wordBreak:"break-word",
          margin:0, padding:0, fontFamily: T.font,
        }}>{value ?? "—"}</span>
      </div>
    </div>
  );
}
