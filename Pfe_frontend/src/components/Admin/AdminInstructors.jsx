import React, { useState, useEffect, useRef, useCallback } from "react";
import { createPortal } from "react-dom";
import { useSearchParams } from "react-router-dom";
import {
  FiUsers,
  FiSearch,
  FiMoreVertical,
  FiStar,
  FiSlash,
  FiCheckCircle,
  FiXCircle,
  FiFilter,
} from "react-icons/fi";

import api from "./../services/api";
import "../../styles/AdminInstructors.css";
import "../../styles/LogoutModal.css";
import AdminInstructorDetail from "./AdminInstructordetail";

const BASE_URL = "http://localhost:8080";

const STATUS_MAP = {
  ACTIVE:   { label: "Active",   cls: "ai-badge--active"   },
  INACTIVE: { label: "Inactive", cls: "ai-badge--inactive" },
  PENDING:  { label: "Pending",  cls: "ai-badge--pending"  },
};

/* ─── Instructor Card ──────────────────────────────────────────────────── */
function InstructorCard({ instructor, onSelect, onHighlight, onBan, onUnban }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const menuRef = useRef(null);

  const photoUrl = instructor.photo
    ? `${BASE_URL}/api/files/${instructor.photo}`
    : null;

  const statusInfo = STATUS_MAP[instructor.accountStatus] ?? {
    label: instructor.accountStatus ?? "Unknown",
    cls: "ai-badge--pending",
  };

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
    fn(instructor);
  };

  return (
    <div className="ai-card" onClick={() => onSelect(instructor)}>

      {/* Three-dot menu */}
      <div className="ai-card-menu-wrap" ref={menuRef}
           onClick={(e) => e.stopPropagation()}>
        <button
          className="ai-card-menu-btn"
          onClick={(e) => { e.stopPropagation(); setMenuOpen((o) => !o); }}
          aria-label="Options"
        >
          <FiMoreVertical size={16} />
        </button>
        {menuOpen && (
          <div className="ai-card-dropdown">

            {instructor.accountStatus === 'ACTIVE' && (
              <button className="ai-card-dropdown-item"
                      onClick={(e) => handleMenuAction(e, onHighlight)}>
                <FiStar size={13} />
                {instructor.featured ? "Remove Highlight" : "Highlight Instructor"}
              </button>
            )}
            {instructor.accountStatus === 'INACTIVE' ? (
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

      {/* Photo */}
      <div className="ai-card-photo-wrap">
        {instructor.featured && (
          <FiStar className="ai-card-featured-star" style={{ position: 'absolute', top: 8, left: 8, color: '#FFD700', fill: '#FFD700', zIndex: 1 }} size={16} />
        )}
        {photoUrl ? (
          <img src={photoUrl} alt={instructor.username} className="ai-card-photo" />
        ) : (
          <div className="ai-card-photo-fallback">
            {(instructor.username ?? "?").charAt(0).toUpperCase()}
          </div>
        )}
        <span className={`ai-card-status ${statusInfo.cls}`}>{statusInfo.label}</span>
      </div>

      {/* Info */}
      <div className="ai-card-body">
        <h3 className="ai-card-name">{instructor.username}</h3>
        <p  className="ai-card-spec">{instructor.specialization ?? "Instructor"}</p>

        {/* Courses + Experience only — points removed */}
        <div className="ai-card-meta">
          <span className="ai-card-meta-item">
            <span className="ai-card-meta-label">Courses</span>
            <span className="ai-card-meta-val">{instructor.totalCourses}</span>
          </span>
          <span className="ai-card-meta-sep" />
          <span className="ai-card-meta-item">
            <span className="ai-card-meta-label">Experience</span>
            <span className="ai-card-meta-val">{instructor.yearsOfExperience ?? "—"}</span>
          </span>
        </div>
      </div>
    </div>
  );
}

/* ─── Main page ───────────────────────────────────────────────────────── */
export default function AdminInstructors({ onCourseClick }) {
  const [searchParams, setSearchParams] = useSearchParams();

  // Bootstrap state from URL so a refresh lands in the same spot
  const [instructors, setInstructors]     = useState([]);
  const [filtered, setFiltered]           = useState([]);
  const [loading, setLoading]             = useState(true);
  const [search, setSearch]               = useState(searchParams.get("q") ?? "");
  const [statusFilter, setStatusFilter]   = useState(searchParams.get("status") ?? "ALL");
  const [selected, setSelected]           = useState(null);
  const [toast, setToast]                 = useState(null);

  // Modal State
  const [banCandidate, setBanCandidate]   = useState(null);
  const [unbanCandidate, setUnbanCandidate] = useState(null);
  const [banLoading, setBanLoading]       = useState(false);

  const showToast = (type, msg) => {
    setToast({ type, msg });
    setTimeout(() => setToast(null), 3200);
  };

  // ── Generic URL sync helper ─────────────────────────────────────────────
  // Merges only the keys you pass; everything else (section, etc.) stays.
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

  // ── Load instructors ────────────────────────────────────────────────────
  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get("/instructors");
      setInstructors(res.data);

      // Restore selected instructor from URL after data arrives
      const urlId = new URLSearchParams(window.location.search).get("instructorId");
      if (urlId) {
        const found = res.data.find((i) => i.id === urlId);
        if (found) setSelected(found);
      }
    } catch {
      showToast("error", "Failed to load instructors.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  // ── Filter ──────────────────────────────────────────────────────────────
  useEffect(() => {
    let list = [...instructors];
    if (statusFilter !== "ALL")
      list = list.filter((i) => i.accountStatus === statusFilter);
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (i) =>
          i.username?.toLowerCase().includes(q) ||
          i.specialization?.toLowerCase().includes(q) ||
          i.email?.toLowerCase().includes(q)
      );
    }
    setFiltered(list);
  }, [search, statusFilter, instructors]);

  // ── State + URL handlers ────────────────────────────────────────────────
  const handleSearchChange = (val) => {
    setSearch(val);
    pushUrl({ q: val });
  };

  const handleStatusChange = (val) => {
    setStatusFilter(val);
    pushUrl({ status: val });
  };

  const handleSelect = (instructor) => {
    setSelected(instructor);
    pushUrl({ instructorId: instructor.id });
  };

  const handleBack = () => {
    setSelected(null);
    pushUrl({ instructorId: null });
  };

  const handleHighlight = async (instructor) => {
    const isFeatured = instructor.featured;
    const action = isFeatured ? "unhighlight" : "highlight";
    try {
      await api.patch(`/admin/instructors/${instructor.id}/${action}`);
      showToast(
        "success",
        `"${instructor.username}" ${isFeatured ? "removed from" : "added to"} highlights.`
      );
      load(); // refresh the list
    } catch {
      showToast("error", `Failed to ${action} instructor.`);
    }
  };

  const handleBan = async () => {
    if (!banCandidate) return;
    setBanLoading(true);
    try {
      await api.patch(`/admin/users/${banCandidate.userId}/ban`);
      showToast("success", `"${banCandidate.username}" account suspended.`);
      setBanCandidate(null);
      load(); // refresh the list
    } catch {
      showToast("error", "Failed to suspend account.");
    } finally {
      setBanLoading(false);
    }
  };

  const handleUnban = async () => {
    if (!unbanCandidate) return;
    setBanLoading(true);
    try {
      await api.patch(`/admin/users/${unbanCandidate.userId}/unban`);
      showToast("success", `"${unbanCandidate.username}" account reinstated.`);
      setUnbanCandidate(null);
      load();
    } catch {
      showToast("error", "Failed to reinstate account.");
    } finally {
      setBanLoading(false);
    }
  };

  const counts = instructors.reduce((acc, i) => {
    acc[i.accountStatus] = (acc[i.accountStatus] ?? 0) + 1;
    return acc;
  }, {});

  if (selected) {
    return <AdminInstructorDetail 
      instructor={selected} 
      onBack={handleBack} 
      onCourseClick={(cid) => onCourseClick(cid, selected.id)}
      onHighlight={handleHighlight}
      onBan={() => setBanCandidate(selected)}
      onUnban={() => setUnbanCandidate(selected)}
    />;
  }

  return (
    <div className="ai-page">

      {/* ── Header ── */}
      <div className="ai-header">
        <div>
          <h1 className="ai-heading">Instructors</h1>
          <p className="ai-subheading">Manage all registered instructors on the platform</p>
        </div>

        <div className="ai-stats-row">
          {[
            { label: "Total",    val: instructors.length,   key: "ALL"      },
            { label: "Active",   val: counts.ACTIVE   ?? 0, key: "ACTIVE"   },
            { label: "Inactive", val: counts.INACTIVE ?? 0, key: "INACTIVE" },
            { label: "Pending",  val: counts.PENDING  ?? 0, key: "PENDING"  },
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

      {/* ── Toolbar ── */}
      <div className="ai-toolbar">
        <div className="ai-search-wrap">
          <FiSearch size={14} className="ai-search-icon" />
          <input
            className="ai-search"
            type="text"
            placeholder="Search by name, specialization or email…"
            value={search}
            onChange={(e) => handleSearchChange(e.target.value)}
          />
        </div>

        <div className="ai-filter-pills">
          {["ALL", "ACTIVE", "INACTIVE", "PENDING"].map((s) => (
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

      {/* ── Content ── */}
      {loading ? (
        <div className="ai-loading">
          <div className="admin-spinner" />
          <span>Loading instructors…</span>
        </div>
      ) : filtered.length === 0 ? (
        <div className="ai-empty">
          <FiUsers size={44} />
          <h2>No instructors found</h2>
          <p>
            {search || statusFilter !== "ALL"
              ? "Try adjusting your search or filter."
              : "No instructors registered yet."}
          </p>
        </div>
      ) : (
        <>
          <p className="ai-result-count">
            Showing <strong>{filtered.length}</strong> instructor{filtered.length !== 1 ? "s" : ""}
          </p>
          <div className="ai-grid">
            {filtered.map((inst) => (
              <InstructorCard
                key={inst.id}
                instructor={inst}
                onSelect={handleSelect}
                onHighlight={handleHighlight}
                onBan={setBanCandidate}
                onUnban={setUnbanCandidate}
              />
            ))}
          </div>
        </>
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
              Are you sure you want to ban <strong>{banCandidate.username}</strong>?<br/>
              <span style={{ fontSize: "12px", opacity: 0.8 }}>This will lock them out and send a notification email.</span>
            </p>

            <div className="lm-actions">
              <button className="lm-btn-cancel" onClick={() => setBanCandidate(null)}>
                No, cancel
              </button>
              <button 
                className="lm-btn-confirm" 
                onClick={handleBan}
                disabled={banLoading}
                style={{ background: "#e53e3e", boxShadow: "0 4px 14px rgba(229, 62, 62, 0.25)" }}
              >
                {banLoading ? <span className="lm-btn-spinner" /> : "Yes, Ban Account"}
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
              Are you sure you want to unban <strong>{unbanCandidate.username}</strong>?<br/>
              <span style={{ fontSize: "12px", opacity: 0.8 }}>They will regain full platform access and receive a welcome-back email.</span>
            </p>

            <div className="lm-actions">
              <button className="lm-btn-cancel" onClick={() => setUnbanCandidate(null)}>
                No, cancel
              </button>
              <button 
                className="lm-btn-confirm" 
                onClick={handleUnban}
                disabled={banLoading}
                style={{ background: "#22783c", boxShadow: "0 4px 14px rgba(34, 120, 60, 0.25)", borderColor: "#22783c" }}
              >
                {banLoading ? <span className="lm-btn-spinner" /> : "Yes, Unban Account"}
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