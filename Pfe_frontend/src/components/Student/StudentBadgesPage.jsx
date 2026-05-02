import { useState, useEffect } from "react";
import api from "../services/api";
import { FiAward, FiLock } from "react-icons/fi";
import "../../styles/StudentBadges.css";

const API_BASE = "http://localhost:8080";

export default function StudentBadgesPage() {
  const [badges, setBadges] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .get("/badges/my-status")
      .then((res) => setBadges(res.data))
      .catch((err) => console.error("Failed to load badges:", err))
      .finally(() => setLoading(false));
  }, []);

  const earned = badges.filter((b) => b.earned);
  const locked = badges.filter((b) => !b.earned);

  if (loading) {
    return (
      <div className="sb-page">
        <div className="sb-header">
          <FiAward size={28} className="sb-header-icon" />
          <div>
            <h1 className="sb-title">Badges</h1>
            <p className="sb-subtitle">Loading your achievements…</p>
          </div>
        </div>
        <div className="sb-grid">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="sb-card sb-skeleton">
              <div className="sb-skeleton-icon" />
              <div className="sb-skeleton-line sb-sk-name" />
              <div className="sb-skeleton-line sb-sk-desc" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="sb-page">
      {/* Header */}
      <div className="sb-header">
        <FiAward size={28} className="sb-header-icon" />
        <div>
          <h1 className="sb-title">Badges</h1>
          <p className="sb-subtitle">
            {earned.length} of {badges.length} badges unlocked
          </p>
        </div>
      </div>

      {/* Progress bar */}
      <div className="sb-progress-wrap">
        <div className="sb-progress-bar">
          <div
            className="sb-progress-fill"
            style={{
              width: badges.length > 0 ? `${(earned.length / badges.length) * 100}%` : "0%",
            }}
          />
        </div>
        <span className="sb-progress-label">
          {badges.length > 0 ? Math.round((earned.length / badges.length) * 100) : 0}%
        </span>
      </div>

      {/* Earned */}
      {earned.length > 0 && (
        <>
          <h2 className="sb-section-title">
            <span className="sb-section-dot is-earned" /> Unlocked
          </h2>
          <div className="sb-grid">
            {earned.map((badge) => (
              <div key={badge.id} className="sb-card is-earned">
                <div className="sb-card-glow" />
                <div className="sb-icon-wrap is-earned">
                  <img
                    src={`${API_BASE}${badge.icon}`}
                    alt={badge.name}
                    className="sb-icon-img"
                  />
                </div>
                <h3 className="sb-badge-name">{badge.name}</h3>
                <p className="sb-badge-desc">{badge.achievement}</p>
                <span className="sb-earned-tag">🏆 Earned</span>
              </div>
            ))}
          </div>
        </>
      )}

      {/* Locked */}
      {locked.length > 0 && (
        <>
          <h2 className="sb-section-title">
            <span className="sb-section-dot is-locked" /> Locked
          </h2>
          <div className="sb-grid">
            {locked.map((badge) => (
              <div key={badge.id} className="sb-card is-locked">
                <div className="sb-lock-overlay">
                  <FiLock size={22} />
                </div>
                <div className="sb-icon-wrap is-locked">
                  <img
                    src={`${API_BASE}${badge.icon}`}
                    alt={badge.name}
                    className="sb-icon-img"
                  />
                </div>
                <h3 className="sb-badge-name">{badge.name}</h3>
                <p className="sb-badge-desc">{badge.achievement}</p>
              </div>
            ))}
          </div>
        </>
      )}

      {badges.length === 0 && (
        <div className="sb-empty">
          <FiAward size={48} />
          <h2>No Badges Yet</h2>
          <p>Complete activities to start earning badges!</p>
        </div>
      )}
    </div>
  );
}
