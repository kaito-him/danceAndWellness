import React, { useState, useEffect, useMemo } from "react";
import { createPortal } from "react-dom";
import { FiSlash, FiCheckCircle, FiXCircle, FiRefreshCw, FiSearch, FiFilter } from "react-icons/fi";
import api from "./../services/api";
import "../../styles/BannedAccount.css";

export default function BannedAccount() {
  const [bannedUsers, setBannedUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState(null);
  const [unbanCandidate, setUnbanCandidate] = useState(null);
  const [actionUserId, setActionUserId] = useState(null);

  // Filter states
  const [search, setSearch] = useState("");
  const [roleFilter, setRoleFilter] = useState("ALL");

  const showToast = (type, msg) => {
    setToast({ type, msg });
    setTimeout(() => setToast(null), 3200);
  };

  const loadBannedUsers = async () => {
    setLoading(true);
    try {
      const res = await api.get("/admin/users/banned");
      setBannedUsers(res.data);
    } catch {
      showToast("error", "Failed to load banned accounts.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadBannedUsers();
  }, []);

  const filtered = useMemo(() => {
    let list = [...bannedUsers];
    if (roleFilter !== "ALL") {
      list = list.filter(u => u.role === roleFilter);
    }
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(u => 
        u.username?.toLowerCase().includes(q) || 
        u.email?.toLowerCase().includes(q)
      );
    }
    return list;
  }, [bannedUsers, search, roleFilter]);

  const handleUnban = async () => {
    if (!unbanCandidate) return;
    setActionUserId(unbanCandidate.userId);
    try {
      await api.patch(`/admin/users/${unbanCandidate.userId}/unban`);
      showToast("success", `"${unbanCandidate.username}" has been successfully reinstated.`);
      setUnbanCandidate(null);
      loadBannedUsers();
    } catch {
      showToast("error", "Failed to unban user.");
    } finally {
      setActionUserId(null);
    }
  };

  return (
    <div className="banned-accounts-page">
      <div className="banned-accounts-header">
        <div>
          <h1 className="banned-accounts-heading">Banned Accounts</h1>
          <p className="banned-accounts-subheading">Review and reinstate suspended platform users</p>
        </div>
        <div className="ai-stats-row">
          <div className="ai-stat-chip active">
            <span className="ai-stat-num">{bannedUsers.length}</span>
            <span className="ai-stat-label">Total Banned</span>
          </div>
        </div>
      </div>

      <div className="ai-toolbar" style={{ marginBottom: 24 }}>
        <div className="ai-search-wrap">
          <FiSearch size={14} className="ai-search-icon" />
          <input
            className="ai-search"
            type="text"
            placeholder="Search by username or email…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <div className="ai-filter-pills">
          {["ALL", "INSTRUCTOR", "STUDENT"].map((r) => (
            <button
              key={r}
              className={`ai-filter-pill ${roleFilter === r ? "active" : ""}`}
              onClick={() => setRoleFilter(r)}
            >
              <FiFilter size={11} />
              {r === "ALL" ? "All Roles" : r.charAt(0) + r.slice(1).toLowerCase()}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div className="banned-accounts-loading">
          <div className="admin-spinner" style={{ marginBottom: 16 }} />
          <span>Loading banned records…</span>
        </div>
      ) : filtered.length === 0 ? (
        <div className="banned-accounts-empty">
          <FiCheckCircle size={44} color="#38a169" style={{ marginBottom: 16 }} />
          <h2>{search || roleFilter !== "ALL" ? "No matches found" : "No Banned Accounts"}</h2>
          <p>
            {search || roleFilter !== "ALL" 
              ? "Try adjusting your search or filters." 
              : "Everyone is following the rules! There are no inactive or suspended accounts right now."}
          </p>
        </div>
      ) : (
        <div className="banned-accounts-grid">
          {filtered.map((user) => (
            <div className="banned-account-card" key={user.userId}>
              <div className="banned-account-header">
                <span className={`banned-account-role ${user.role.toLowerCase()}`}>
                  {user.role}
                </span>
              </div>
              <div className="banned-account-body">
                <h3>{user.username}</h3>
                <p>{user.email}</p>
              </div>
              
              <div className="banned-account-meta">
                <FiSlash size={14} />
                <span>Currently Suspended</span>
              </div>

              <button 
                className="banned-unban-btn" 
                onClick={() => setUnbanCandidate(user)}
                disabled={actionUserId === user.userId}
              >
                {actionUserId === user.userId ? (
                   <FiRefreshCw className="fa-spin" />
                ) : (
                   <FiCheckCircle />
                )}
                {actionUserId === user.userId ? "Reinstating..." : "Unban Account"}
              </button>
            </div>
          ))}
        </div>
      )}

      {/* ── Unban Confirmation Modal ── */}
      {unbanCandidate && createPortal(
        <div className="lm-backdrop" onClick={() => setUnbanCandidate(null)}>
          <div className="lm-card" onClick={(e) => e.stopPropagation()}>
            <div className="lm-icon-ring" style={{ background: 'linear-gradient(135deg, #f0faf4 0%, #d4f0e1 100%)', border: '1.5px solid #a8dfc0' }}>
              <FiCheckCircle size={26} color="#22783c" />
            </div>

            <h2 className="lm-title">Reinstate Account</h2>
            <p className="lm-message">
              Are you sure you want to unban <strong>{unbanCandidate.username}</strong>?<br/>
              <span style={{ fontSize: "12px", opacity: 0.8 }}>This user will regain access to their account and receive a notification.</span>
            </p>

            <div className="lm-actions">
              <button className="lm-btn-cancel" onClick={() => setUnbanCandidate(null)}>
                No, cancel
              </button>
              <button 
                className="lm-btn-confirm" 
                onClick={handleUnban}
                style={{ background: "#22783c", boxShadow: "0 4px 14px rgba(34, 120, 60, 0.25)", borderColor: "#22783c" }}
                disabled={actionUserId === unbanCandidate.userId}
              >
                {actionUserId === unbanCandidate.userId ? "Reinstating..." : "Yes, Unban Account"}
              </button>
            </div>
          </div>
        </div>,
        document.body
      )}

      {toast && (
        <div className={`admin-toast ${toast.type}`}>
          {toast.type === "success" ? <FiCheckCircle size={15} /> : <FiXCircle size={15} />}
          {toast.msg}
        </div>
      )}
    </div>
  );
}
