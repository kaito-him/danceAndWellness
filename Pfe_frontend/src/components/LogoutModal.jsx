import React, { useEffect } from "react";
import "../styles/LogoutModal.css";

export default function LogoutModal({ onConfirm, onCancel }) {
  // Close on Escape key
  useEffect(() => {
    const handler = (e) => { if (e.key === "Escape") onCancel(); };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [onCancel]);

  return (
    <div className="lm-backdrop" onClick={onCancel}>
      <div className="lm-card" onClick={(e) => e.stopPropagation()}>

        <div className="lm-icon-ring">
          <svg viewBox="0 0 24 24" fill="none" className="lm-icon">
            <path
              d="M15 3H19C20.1 3 21 3.9 21 5V19C21 20.1 20.1 21 19 21H15"
              stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"
            />
            <path
              d="M10 17L15 12L10 7"
              stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"
            />
            <path
              d="M15 12H3"
              stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"
            />
          </svg>
        </div>

        <h2 className="lm-title">Log Out</h2>
        <p className="lm-message">Are you sure you want to log out?</p>

        <div className="lm-actions">
          <button className="lm-btn-cancel" onClick={onCancel}>
            No, stay
          </button>
          <button className="lm-btn-confirm" onClick={onConfirm}>
            Yes, log out
          </button>
        </div>

      </div>
    </div>
  );
}