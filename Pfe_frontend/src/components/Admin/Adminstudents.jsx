import React, { useState, useEffect, useRef, useCallback } from "react";
import { createPortal } from "react-dom";
import { useSearchParams } from "react-router-dom";
import { FiUsers, FiClock, FiCalendar, FiSearch, FiFilter, FiMoreVertical, FiSlash, FiXCircle, FiCheckCircle } from "react-icons/fi";
import api from "./../services/api";
import "../../styles/AdminStudents.css";
import "../../styles/LogoutModal.css";
import AdminStudentDetail from "./AdminStudentDetail";

const BASE_URL = "http://localhost:8080";

// Setup relative time formatter
const formatRelativeTime = (dateString) => {
  if (!dateString) return "Never logged in";
  
  const date = new Date(dateString);
  const now = new Date();
  const diffInSeconds = Math.floor((now - date) / 1000);
  
  if (diffInSeconds < 60) return "Just now";
  const diffInMinutes = Math.floor(diffInSeconds / 60);
  if (diffInMinutes < 60) return `${diffInMinutes} min ago`;
  const diffInHours = Math.floor(diffInMinutes / 60);
  if (diffInHours < 24) return `${diffInHours} hour${diffInHours > 1 ? 's' : ''} ago`;
  const diffInDays = Math.floor(diffInHours / 24);
  if (diffInDays < 30) return `${diffInDays} day${diffInDays > 1 ? 's' : ''} ago`;
  const diffInMonths = Math.floor(diffInDays / 30);
  if (diffInMonths < 12) return `${diffInMonths} month${diffInMonths > 1 ? 's' : ''} ago`;
  
  return date.toLocaleDateString();
};

function StudentCard({ student, onSelect, onBan, onUnban }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const menuRef = useRef(null);

  const photoUrl = student.photo
    ? `${BASE_URL}/api/files/${student.photo}`
    : null;

  const isActive = student.accountStatus === 'ACTIVE';

  useEffect(() => {
    if (!menuOpen) return;
    const handler = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target))
        setMenuOpen(false);
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, [menuOpen]);

  const handleMenuAction = (e, fn) => {
    e.stopPropagation();
    setMenuOpen(false);
    fn(student);
  };

  return (
    <div className="admin-student-card" onClick={() => onSelect(student)}>
      <div className="ai-card-menu-wrap" ref={menuRef} onClick={(e) => e.stopPropagation()} style={{ position: 'absolute', top: 12, right: 12 }}>
        <button
          className="ai-card-menu-btn"
          onClick={(e) => { e.stopPropagation(); setMenuOpen((o) => !o); }}
          aria-label="Options"
        >
          <FiMoreVertical size={16} />
        </button>
        {menuOpen && (
          <div className="ai-card-dropdown" style={{ right: 0, top: '100%', position: 'absolute' }}>
            {student.accountStatus === 'INACTIVE' ? (
              <button className="ai-card-dropdown-item" 
                      onClick={(e) => handleMenuAction(e, onUnban)}
                      style={{ color: '#22783c' }}>
                <FiCheckCircle size={13} /> Unban Account
              </button>
            ) : (
              <button className="ai-card-dropdown-item ai-card-dropdown-item--danger"
                      onClick={(e) => handleMenuAction(e, onBan)}>
                <FiSlash size={13} /> Ban Account
              </button>
            )}
          </div>
        )}
      </div>

      <div className="admin-student-photo-wrap">
        {photoUrl ? (
          <img src={photoUrl} alt={student.username} className="admin-student-photo" />
        ) : (
          <div className="admin-student-photo-fallback">
            {(student.username ?? "?").charAt(0).toUpperCase()}
          </div>
        )}
        <div className={`admin-student-status ${isActive ? 'active' : 'inactive'}`} title={student.accountStatus} />
      </div>

      <h3 className="admin-student-name">{student.username}</h3>
      <p className="admin-student-email">{student.email}</p>

      <div className="admin-student-meta">
        <div className="admin-student-meta-item">
          <FiClock className="admin-student-meta-icon" size={14} />
          <span>Active {formatRelativeTime(student.lastLoginDate)}</span>
        </div>
        <div className="admin-student-meta-item" style={{ marginTop: 4 }}>
          <FiCalendar className="admin-student-meta-icon" size={14} />
          <span>Joined {new Date(student.createdAt).toLocaleDateString()}</span>
        </div>
      </div>
    </div>
  );
}

export default function AdminStudents() {
  const [searchParams, setSearchParams] = useSearchParams();

  const [students, setStudents]     = useState([]);
  const [filtered, setFiltered]     = useState([]);
  const [loading, setLoading]       = useState(true);
  const [search, setSearch]         = useState(searchParams.get("q") ?? "");
  const [statusFilter, setStatusFilter] = useState(searchParams.get("status") ?? "ALL");
  const [selected, setSelected]         = useState(null);
  const [toast, setToast]           = useState(null);
  const [banCandidate, setBanCandidate] = useState(null);
  const [unbanCandidate, setUnbanCandidate] = useState(null);

  const showToast = (type, msg) => {
    setToast({ type, msg });
    setTimeout(() => setToast(null), 3200);
  };

  const pushUrl = useCallback((patch) => {
    setSearchParams((prev) => {
      const next = new URLSearchParams(prev);
      Object.entries(patch).forEach(([k, v]) => {
        if (v == null || v === "" || v === "ALL") next.delete(k);
        else next.set(k, v);
      });
      return next;
    }, { replace: true });
  }, [setSearchParams]);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get("/students");
      setStudents(res.data);

      // Restore selected student from URL after data arrives
      const urlId = new URLSearchParams(window.location.search).get("studentId");
      if (urlId) {
        // Redirection from payments uses userId, while direct links use student.id
        const found = res.data.find((s) => s.id === urlId || s.userId === urlId);
        if (found) setSelected(found);
      }
    } catch (err) {
      console.error("Failed to fetch students", err);
      showToast("error", "Failed to load students.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  useEffect(() => {
    let list = [...students];
    if (statusFilter !== "ALL")
      list = list.filter((s) => s.accountStatus === statusFilter);
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (s) =>
          s.username?.toLowerCase().includes(q) ||
          s.email?.toLowerCase().includes(q)
      );
    }
    setFiltered(list);
  }, [search, statusFilter, students]);

  const handleSearchChange = (val) => {
    setSearch(val);
    pushUrl({ q: val });
  };

  const handleStatusChange = (val) => {
    setStatusFilter(val);
    pushUrl({ status: val });
  };

  const handleSelect = (student) => {
    setSelected(student);
    pushUrl({ studentId: student.id });
  };

  const handleBack = () => {
    setSelected(null);
    pushUrl({ studentId: null });
  };

  const handleBan = async () => {
    if (!banCandidate) return;
    try {
      await api.patch(`/admin/users/${banCandidate.userId}/ban`);
      showToast("success", `"${banCandidate.username}" account suspended.`);
      setBanCandidate(null);
      load();
    } catch {
      showToast("error", "Failed to suspend account.");
    }
  };

  const handleUnban = async () => {
    if (!unbanCandidate) return;
    try {
      await api.patch(`/admin/users/${unbanCandidate.userId}/unban`);
      showToast("success", `"${unbanCandidate.username}" account reinstated.`);
      setUnbanCandidate(null);
      load();
    } catch {
      showToast("error", "Failed to reinstate account.");
    }
  };

  const counts = students.reduce((acc, s) => {
    acc[s.accountStatus] = (acc[s.accountStatus] ?? 0) + 1;
    return acc;
  }, {});

  if (selected) {
    return <AdminStudentDetail student={selected} onBack={handleBack} />;
  }

  return (
    <div className="admin-students-page">
      <div className="admin-students-header">
        <div>
          <h1 className="admin-students-heading">Students</h1>
          <p className="admin-students-subheading">Manage all registered students on the platform</p>
        </div>
        <div className="ai-stats-row">
          {[
            { label: "Total",    val: students.length,   key: "ALL"      },
            { label: "Active",   val: counts.ACTIVE   ?? 0, key: "ACTIVE"   },
            { label: "Inactive", val: counts.INACTIVE ?? 0, key: "INACTIVE" },
          ].map(({ label, val, key }) => (
            <button
              key={key}
              className={`ai-stat-chip ${statusFilter === key ? "active" : ""}`}
              onClick={() => handleStatusChange(key)}
            >
              <span className="ai-stat-num">{val}</span>
              <span className="ai-stat-label">{label}</span>
            </button>
          ))}
        </div>
      </div>

      <div className="ai-toolbar" style={{ marginBottom: 24 }}>
        <div className="ai-search-wrap">
          <FiSearch size={14} className="ai-search-icon" />
          <input
            className="ai-search"
            type="text"
            placeholder="Search by name or email…"
            value={search}
            onChange={(e) => handleSearchChange(e.target.value)}
          />
        </div>

        <div className="ai-filter-pills">
          {["ALL", "ACTIVE", "INACTIVE"].map((s) => (
            <button
              key={s}
              className={`ai-filter-pill ${statusFilter === s ? "active" : ""}`}
              onClick={() => handleStatusChange(s)}
            >
              <FiFilter size={11} />
              {s === "ALL" ? "All Status" : s.charAt(0) + s.slice(1).toLowerCase()}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div className="admin-students-loading">
          <div className="admin-students-spinner" />
          <span>Loading students…</span>
        </div>
      ) : filtered.length === 0 ? (
        <div className="admin-students-empty">
          <FiUsers size={44} style={{ marginBottom: 16 }} />
          <h2>No students found</h2>
          <p>{search || statusFilter !== "ALL" ? "Try adjusting your search or filter." : "No students registered yet."}</p>
        </div>
      ) : (
        <div className="admin-students-grid">
          {filtered.map((student) => (
            <StudentCard 
              key={student.id} 
              student={student} 
              onSelect={handleSelect}
              onBan={setBanCandidate} 
              onUnban={setUnbanCandidate} 
            />
          ))}
        </div>
      )}

      {/* ── Ban Confirmation Modal ── */}
      {banCandidate && createPortal(
        <div className="lm-backdrop" onClick={() => setBanCandidate(null)}>
          <div className="lm-card" onClick={(e) => e.stopPropagation()}>
            <div className="lm-icon-ring" style={{ background: 'linear-gradient(135deg, #fff5f5 0%, #fed7d7 100%)', border: '1.5px solid #feb2b2' }}>
              <FiSlash size={26} color="#e53e3e" />
            </div>

            <h2 className="lm-title">Suspend Account</h2>
            <p className="lm-message">
              Are you sure you want to ban student <strong>{banCandidate.username}</strong>?<br/>
              <span style={{ fontSize: "12px", opacity: 0.8 }}>This will restrict their access and notify them via email.</span>
            </p>

            <div className="lm-actions">
              <button className="lm-btn-cancel" onClick={() => setBanCandidate(null)}>
                No, cancel
              </button>
              <button 
                className="lm-btn-confirm" 
                onClick={handleBan}
                style={{ background: "#e53e3e", boxShadow: "0 4px 14px rgba(229, 62, 62, 0.25)" }}
              >
                Yes, Ban Account
              </button>
            </div>
          </div>
        </div>,
        document.body
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
              Are you sure you want to unban student <strong>{unbanCandidate.username}</strong>?<br/>
              <span style={{ fontSize: "12px", opacity: 0.8 }}>They will regain access to their courses and receive a welcome-back email.</span>
            </p>

            <div className="lm-actions">
              <button className="lm-btn-cancel" onClick={() => setUnbanCandidate(null)}>
                No, cancel
              </button>
              <button 
                className="lm-btn-confirm" 
                onClick={handleUnban}
                style={{ background: "#22783c", boxShadow: "0 4px 14px rgba(34, 120, 60, 0.25)", borderColor: "#22783c" }}
              >
                Yes, Unban Account
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
