import React, { useState } from "react";

export default function InstructorApplicationCard({ application, onApprove, onDecline }) {
  const [confirmAction, setConfirmAction] = useState(null);

  const {
    userId, username, email, bio,
    specialization, yearsOfExperience,
    studioName, linkedIn, website, appliedAt,
    certificationFileName, certificationFileId,
  } = application;

  const initials = username ? username.charAt(0).toUpperCase() : "?";

  const formatDate = (raw) => {
    if (!raw) return "—";
    if (Array.isArray(raw)) {
      const [y, m, d] = raw;
      return new Date(y, m - 1, d).toLocaleDateString("en-US", {
        year: "numeric", month: "short", day: "numeric",
      });
    }
    return new Date(raw).toLocaleDateString("en-US", {
      year: "numeric", month: "short", day: "numeric",
    });
  };

  const handleConfirm = () => {
    if (confirmAction === "approve") onApprove(userId);
    else onDecline(userId);
    setConfirmAction(null);
  };

  return (
    <div className="ia-card">

      {/* ── Header ── */}
      <div className="ia-card-header">
        <div className="ia-avatar">{initials}</div>
        <div className="ia-card-identity">
          <h3 className="ia-card-name">{username}</h3>
          <span className="ia-card-email">{email}</span>
        </div>
        <div className="ia-card-date">
          <span className="ia-date-label">Applied</span>
          <span className="ia-date-value">{formatDate(appliedAt)}</span>
        </div>
      </div>

      {/* ── Info grid ── */}
      <div className="ia-info-grid">
        <div className="ia-info-item">
          <span className="ia-info-label">Specialization</span>
          <span className="ia-info-value">{specialization || "—"}</span>
        </div>
        <div className="ia-info-item">
          <span className="ia-info-label">Experience</span>
          <span className="ia-info-value">{yearsOfExperience || "—"}</span>
        </div>
        <div className="ia-info-item">
          <span className="ia-info-label">Studio</span>
          <span className="ia-info-value">{studioName || "—"}</span>
        </div>
      </div>

      {/* ── Bio ── */}
      {bio && (
        <div className="ia-bio">
          <span className="ia-bio-label">Bio</span>
          <p className="ia-bio-text">{bio}</p>
        </div>
      )}

      {/* ── Links + Certification ── */}
      <div className="ia-links">
        {linkedIn && (
          <a href={linkedIn} target="_blank" rel="noreferrer" className="ia-link">
            🔗 LinkedIn
          </a>
        )}
        {website && (
          <a href={website} target="_blank" rel="noreferrer" className="ia-link">
            🌐 Website
          </a>
        )}

        {certificationFileId ? (
          <a                     
            href={`http://localhost:8080/api/files/${certificationFileId}`}
            download={certificationFileName || "certification"}
            className="ia-link"
          >
            📄 {certificationFileName || "Download Certification"}
          </a>
        ) : (
          <span className="ia-link" style={{ color: "#aaa", cursor: "default" }}>
            📄 No file uploaded
          </span>
        )}
      </div>

      {/* ── Actions / Confirm ── */}
      {confirmAction ? (
        <div className="ia-confirm">
          <p>
            {confirmAction === "approve"
              ? "Approve this instructor and activate their account?"
              : "Decline this application and deactivate the account?"}
          </p>
          <div className="ia-confirm-btns">
            <button
              className={`ia-confirm-yes ${confirmAction}`}
              onClick={handleConfirm}
            >
              Yes, {confirmAction === "approve" ? "Approve" : "Decline"}
            </button>
            <button className="ia-confirm-no" onClick={() => setConfirmAction(null)}>
              Cancel
            </button>
          </div>
        </div>
      ) : (
        <div className="ia-actions">
          <button className="ia-btn-approve" onClick={() => setConfirmAction("approve")}>
            ✓ Approve
          </button>
          <button className="ia-btn-decline" onClick={() => setConfirmAction("decline")}>
            ✕ Decline
          </button>
        </div>
      )}

    </div>
  );
}