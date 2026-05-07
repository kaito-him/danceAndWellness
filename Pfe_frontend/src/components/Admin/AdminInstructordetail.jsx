import React, { useState, useEffect, useRef } from "react";
import {
  FiArrowLeft,
  FiMail,
  FiGlobe,
  FiLinkedin,
  FiCalendar,
  FiAward,
  FiBookOpen,
  FiClock,
  FiAlertCircle,
  FiMoreVertical,
  FiStar,
  FiSlash,
  FiCheckCircle,
} from "react-icons/fi";
import InstructorCourseCard from "./InstructorCourseCard";
import api from "./../services/api";
import "../../styles/AdminInstructorDetail.css";

const BASE_URL = "http://localhost:8080";

const STATUS_MAP = {
  ACTIVE:   { label: "Active",   cls: "aid-status--active"   },
  INACTIVE: { label: "Inactive", cls: "aid-status--inactive" },
  PENDING:  { label: "Pending",  cls: "aid-status--pending"  },
};

export default function AdminInstructorDetail({ instructor, onBack, onCourseClick, onHighlight, onBan, onUnban }) {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [menuOpen, setMenuOpen] = useState(false);
  const menuRef = useRef(null);

  // New states for search and filtering
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("ALL");
  const [isSearching, setIsSearching] = useState(false);

  useEffect(() => {
    window.scrollTo({ top: 0, behavior: "smooth" });
    loadCourses();
  }, [instructor.id]);

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
    if (fn) fn();
  };

  const loadCourses = async () => {
    setLoading(true);
    try {
      const res = await api.get(`/instructors/${instructor.id}/courses`);
      setCourses(res.data);
    } catch {
      setCourses([]);
    } finally {
      setLoading(false);
    }
  };

  // Resolve photo via GridFS
  const photoUrl = instructor.photo
    ? `${BASE_URL}/api/files/${instructor.photo}`
    : null;

  // Certification download link
  const certDownloadUrl = instructor.certificationFileId
    ? `${BASE_URL}/api/files/${instructor.certificationFileId}`
    : null;

  const statusInfo = STATUS_MAP[instructor.accountStatus] ?? {
    label: instructor.accountStatus ?? "Unknown",
    cls: "aid-status--pending",
  };

  const InfoRow = ({ icon: Icon, label, value }) =>
    value ? (
      <div className="aid-info-row">
        <span className="aid-info-icon"><Icon size={14} /></span>
        <span className="aid-info-label">{label}</span>
        <span className="aid-info-value">{value}</span>
      </div>
    ) : null;

  const filteredCourses = courses.filter((course) => {
    const matchesSearch = course.title?.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesStatus = statusFilter === "ALL" || course.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="aid-page">

      {/* ── Header Actions ── */}
      <div className="aid-header-actions">
        <button className="aid-back-btn" onClick={onBack}>
          <FiArrowLeft size={15} />
          Back to Instructors
        </button>

        <div className="ai-card-menu-wrap" ref={menuRef}>
          <button
            className="ai-card-menu-btn aid-options-btn"
            onClick={() => setMenuOpen((o) => !o)}
            aria-label="Options"
          >
            <FiMoreVertical size={18} />
          </button>
          {menuOpen && (
            <div className="ai-card-dropdown aid-dropdown">
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
                  <FiSlash size={13} /> Suspend Account
                </button>
              )}
            </div>
          )}
        </div>
      </div>

      {/* ── Hero card ── */}
      <div className="aid-hero">
        <div className="aid-hero-left">
          <div className="aid-avatar-wrap">
            {photoUrl ? (
              <img
                src={photoUrl}
                alt={instructor.username}
                className="aid-avatar-img"
                onError={(e) => { e.currentTarget.style.display = "none"; }}
              />
            ) : (
              <div className="aid-avatar-fallback">
                {(instructor.username ?? "?").charAt(0).toUpperCase()}
              </div>
            )}
            <span className={`aid-status-badge ${statusInfo.cls}`}>
              {statusInfo.label}
            </span>
          </div>

          <div className="aid-hero-info">
            <h1 className="aid-name">{instructor.username}</h1>
            <p  className="aid-specialty">{instructor.specialization ?? "Instructor"}</p>
            {instructor.studioName && (
              <p className="aid-studio">🏢 {instructor.studioName}</p>
            )}

            {/* Chips — points removed */}
            <div className="aid-chips">
              <span className="aid-chip">
                <FiClock size={12} />
                {instructor.yearsOfExperience ?? "—"} exp.
              </span>
              <span className="aid-chip">
                <FiBookOpen size={12} />
                {instructor.totalCourses} course{instructor.totalCourses !== 1 ? "s" : ""}
              </span>
            </div>
          </div>
        </div>

        {/* ── Contact & links ── */}
        <div className="aid-hero-right">
          <InfoRow icon={FiMail}     label="Email"  value={instructor.email} />
          <InfoRow icon={FiCalendar} label="Joined" value={instructor.appliedAt} />
          {instructor.linkedIn && (
            <div className="aid-info-row">
              <span className="aid-info-icon"><FiLinkedin size={14} /></span>
              <span className="aid-info-label">LinkedIn</span>
              <a href={instructor.linkedIn} target="_blank" rel="noopener noreferrer"
                 className="aid-info-link">View profile</a>
            </div>
          )}
          {instructor.website && (
            <div className="aid-info-row">
              <span className="aid-info-icon"><FiGlobe size={14} /></span>
              <span className="aid-info-label">Website</span>
              <a href={instructor.website} target="_blank" rel="noopener noreferrer"
                 className="aid-info-link">Visit site</a>
            </div>
          )}
          {certDownloadUrl && (
            <div className="aid-info-row">
              <span className="aid-info-icon"><FiAward size={14} /></span>
              <span className="aid-info-label">Cert.</span>
              <a href={certDownloadUrl} target="_blank" rel="noopener noreferrer"
                 className="aid-info-link">
                {instructor.certificationFileName ?? "View file"}
              </a>
            </div>
          )}
        </div>
      </div>

      {/* ── Bio ── */}
      {instructor.bio && (
        <div className="aid-bio-card">
          <h2 className="aid-section-title">About</h2>
          <p className="aid-bio-text">{instructor.bio}</p>
        </div>
      )}

      {/* ── Courses ── */}
      <div className="aid-courses-section">
        <div className="aid-courses-header">
          <h2 className="aid-section-title">
            Courses
            <span className="aid-courses-count">{courses.length}</span>
          </h2>
          
          <div className="aid-courses-filters">
            <div className="aid-search-wrap">
              <input
                type="text"
                placeholder="Search courses..."
                value={searchQuery}
                onChange={(e) => {
                  setSearchQuery(e.target.value);
                  setIsSearching(true);
                  // Simulate skeleton delay
                  setTimeout(() => setIsSearching(false), 400);
                }}
                className="aid-search-input"
              />
            </div>
            <select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value);
                setIsSearching(true);
                setTimeout(() => setIsSearching(false), 400);
              }}
              className="aid-status-select"
            >
              <option value="ALL">All Statuses</option>
              <option value="PUBLISHED">Published</option>
              <option value="DRAFT">Draft</option>
              <option value="ARCHIVED">Archived</option>
            </select>
          </div>
        </div>

        {loading || isSearching ? (
          <div className="aid-courses-grid">
            {[1, 2, 3].map((i) => (
              <CourseCardSkeleton key={i} />
            ))}
          </div>
        ) : filteredCourses.length === 0 ? (
          <div className="aid-empty">
            <FiAlertCircle size={36} />
            <p>No courses match your criteria.</p>
          </div>
        ) : (
          <div className="aid-courses-grid">
            {filteredCourses.map((course) => (
              <InstructorCourseCard 
                key={course.courseId} 
                course={course} 
                onClick={() => onCourseClick(course.courseId)}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

// Internal Skeleton Component for Courses
function CourseCardSkeleton() {
  return (
    <div className="aid-skeleton-card" style={{
      background: "var(--ad-surface)",
      border: "1px solid var(--ad-border)",
      borderRadius: "var(--ad-radius-md)",
      overflow: "hidden",
      height: "260px",
      display: "flex",
      flexDirection: "column"
    }}>
      <div className="aid-skeleton-thumb" style={{
        height: "140px",
        background: "var(--ad-surface3)",
        animation: "pulse 1.5s infinite"
      }} />
      <div className="aid-skeleton-body" style={{ padding: "14px 16px" }}>
        <div className="aid-skeleton-line" style={{
          height: "18px",
          width: "80%",
          background: "var(--ad-surface3)",
          marginBottom: "10px",
          borderRadius: "4px",
          animation: "pulse 1.5s infinite"
        }} />
        <div className="aid-skeleton-line" style={{
          height: "14px",
          width: "50%",
          background: "var(--ad-surface3)",
          marginBottom: "16px",
          borderRadius: "4px",
          animation: "pulse 1.5s infinite"
        }} />
        <div className="aid-skeleton-line" style={{
          height: "16px",
          width: "30%",
          background: "var(--ad-surface3)",
          borderRadius: "4px",
          animation: "pulse 1.5s infinite"
        }} />
      </div>
    </div>
  );
}