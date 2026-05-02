import React, { useEffect } from "react";
import { FiAlertCircle } from "react-icons/fi";
import "../../styles/LogoutModal.css";

export default function RoleWarningModal({ onSwitchAccount, onCancel }) {
  // Close on Escape key
  useEffect(() => {
    const handler = (e) => { if (e.key === "Escape") onCancel(); };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [onCancel]);

  return (
    <div className="lm-backdrop" onClick={onCancel}>
      <div className="lm-card" onClick={(e) => e.stopPropagation()}>

        <div className="lm-icon-ring" style={{ background: "rgba(255, 152, 0, 0.1)" }}>
          <FiAlertCircle className="lm-icon" size={24} strokeWidth={1.8} style={{ color: "#ff9800" }} />
        </div>

        <h2 className="lm-title">Switch to Student Account</h2>
        <p className="lm-message">
          To view and enroll in courses, you need to switch to a student account. 
          Would you like to create or switch to a student account now?
        </p>

        <div className="lm-actions">
          <button className="lm-btn-cancel" onClick={onCancel}>
            Cancel
          </button>
          <button className="lm-btn-confirm" onClick={onSwitchAccount}>
            Switch Account
          </button>
        </div>

      </div>
    </div>
  );
}
