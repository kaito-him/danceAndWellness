import React, { useState, useEffect } from "react";
import { FiAward, FiCheckCircle, FiXCircle, FiUsers } from "react-icons/fi";
import api from "./../services/api";
import "../../styles/AdminBadges.css"; // eslint-disable-line

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
  const [badges, setBadges]             = useState([]);
  const [earnerCounts, setEarnerCounts] = useState({});
  const [loading, setLoading]           = useState(true);
  const [toast, setToast]               = useState(null);

  const showToast = (type, msg) => {
    setToast({ type, msg });
    setTimeout(() => setToast(null), 3500);
  };

  const fetchData = async () => {
    setLoading(true);
    try {
      const badgesRes = await api.get("/badges");
      setBadges(badgesRes.data);
      // earner-counts requires backend restart — fail silently if not available
      try {
        const countsRes = await api.get("/badges/earner-counts");
        setEarnerCounts(countsRes.data || {});
      } catch {
        setEarnerCounts({});
      }
    } catch {
      showToast("error", "Failed to load badges.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(); }, []);

  const iconPath = (icon) => icon ? icon.replace(/^\/api/, "") : null;

  return (
    <div className="badges-page">
      <div className="badges-header">
        <div>
          <h1 className="badges-title">Achievements &amp; Badges</h1>
          <p className="badges-sub">Badge collection awarded to students on the platform</p>
        </div>
        <div className="badges-total-chip">
          <FiAward size={18} />
          <span className="badges-total-num">{badges.length}</span>
          <span className="badges-total-label">Total Badges</span>
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
          <p>Badges are awarded automatically based on student activity.</p>
        </div>
      ) : (
        <div className="badges-grid">
          {badges.map((badge) => {
            const count = earnerCounts[badge.id] ?? 0;
            return (
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
                <div className="badge-earners">
                  <FiUsers size={13} />
                  <span>{count} {count === 1 ? "student" : "students"} achieved</span>
                </div>
              </div>
            );
          })}
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
