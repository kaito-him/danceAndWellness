import React, { useState, useEffect, useRef } from "react";
import {
  FiArrowLeft,
  FiMail,
  FiCalendar,
  FiBookOpen,
  FiClock,
  FiAlertCircle,
  FiUser,
  FiMoreVertical,
  FiSlash,
  FiCheckCircle,
} from "react-icons/fi";
import api from "./../services/api";
import "../../styles/AdminStudentDetail.css";

const BASE_URL = "http://localhost:8080";

const STATUS_MAP = {
  ACTIVE: { label: "Active", cls: "asd-status--active" },
  INACTIVE: { label: "Inactive", cls: "asd-status--inactive" },
};

export default function AdminStudentDetail({ student, onBack, onCourseClick, onBan, onUnban }) {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [menuOpen, setMenuOpen] = useState(false);
  const menuRef = useRef(null);

  useEffect(() => {
    window.scrollTo({ top: 0, behavior: "smooth" });
    loadCourses();
  }, [student.id, student.userId]);

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
    // Use userId if available, as student endpoints usually expect the user identity ID
    const sid = student.userId || student.id;
    try {
      const [freeRes, paidRes, catsRes] = await Promise.all([
        api.get(`/students/${sid}/courses/free`),
        api.get(`/students/${sid}/courses/paid`),
        api.get("/categories")
      ]);

      const catMap = {};
      catsRes.data.forEach(c => catMap[c.id] = c.name);

      const free = freeRes.data.map(c => ({ 
        ...c, 
        enrollmentType: "FREE",
        category: catMap[c.categoryId] || "General"
      }));
      const paid = paidRes.data.map(c => ({ 
        ...c, 
        enrollmentType: "PAID",
        category: catMap[c.categoryId] || "General"
      }));

      // Combine and sort by date if available, or just concat
      setCourses([...paid, ...free]);
    } catch (err) {
      console.error("Failed to load student courses", err);
      setCourses([]);
    } finally {
      // Small delay for shimmer effect visibility
      setTimeout(() => setLoading(false), 500);
    }
  };

  const photoUrl = student.photo
    ? `${BASE_URL}/api/files/${student.photo}`
    : null;

  const statusInfo = STATUS_MAP[student.accountStatus] ?? {
    label: student.accountStatus ?? "Unknown",
    cls: "asd-status--inactive",
  };

  const InfoRow = ({ icon: Icon, label, value }) =>
    value ? (
      <div className="asd-info-row">
        <span className="asd-info-icon"><Icon size={14} /></span>
        <span className="asd-info-label">{label}</span>
        <span className="asd-info-value">{value}</span>
      </div>
    ) : null;

  return (
    <div className="asd-page">
      {/* ── Header Actions ── */}
      <div className="asd-header-actions">
        <button className="asd-back-btn" onClick={onBack} style={{ marginBottom: 0 }}>
          <FiArrowLeft size={15} />
          Back to Students
        </button>

        <div className="ai-card-menu-wrap" ref={menuRef}>
          <button
            className="ai-card-menu-btn asd-options-btn"
            onClick={() => setMenuOpen((o) => !o)}
            aria-label="Options"
          >
            <FiMoreVertical size={18} />
          </button>
          {menuOpen && (
            <div className="ai-card-dropdown asd-dropdown">
              {student.accountStatus === 'INACTIVE' ? (
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
      <div className="asd-hero">
        <div className="asd-hero-left">
          <div className="asd-avatar-wrap">
            {photoUrl ? (
              <img src={photoUrl} alt={student.username} className="asd-avatar-img" />
            ) : (
              <div className="asd-avatar-fallback">
                {(student.username ?? "?").charAt(0).toUpperCase()}
              </div>
            )}
            <span className={`asd-status-badge ${statusInfo.cls}`}>
              {statusInfo.label}
            </span>
          </div>

          <div className="asd-hero-info">
            <h1 className="asd-name">{student.username}</h1>
            <p className="asd-role">Student Account</p>

            <div className="asd-chips">
              <span className="asd-chip">
                <FiBookOpen size={12} />
                {courses.length} Course{courses.length !== 1 ? "s" : ""} Joined
              </span>
            </div>
          </div>
        </div>

        {/* ── Contact ── */}
        <div className="asd-hero-right">
          <InfoRow icon={FiMail} label="Email" value={student.email} />
          <InfoRow icon={FiCalendar} label="Joined" value={new Date(student.createdAt).toLocaleDateString()} />
          <InfoRow
            icon={FiClock}
            label="Last visit"
            value={student.lastLoginDate ? new Date(student.lastLoginDate).toLocaleDateString() : "Never"}
          />
        </div>
      </div>

      {/* ── Enrolled Courses ── */}
      <div className="asd-courses-section">
        <div className="asd-section-title">
          Enrolled Courses
          <span className="asd-courses-count">{courses.length}</span>
        </div>

        {loading ? (
          <div className="asd-courses-grid">
            {[1, 2, 3].map(i => <CourseCardSkeleton key={i} />)}
          </div>
        ) : courses.length === 0 ? (
          <div className="asd-empty">
            <FiAlertCircle size={36} />
            <p>This student is not enrolled in any courses yet.</p>
          </div>
        ) : (
          <div className="asd-courses-grid">
            {courses.map((course) => (
              <CourseRow 
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

/* Internal Skeleton Component */
function CourseCardSkeleton() {
  return (
    <div className="asd-skeleton-card">
      <div className="asd-skeleton-thumb" />
      <div className="asd-skeleton-info">
        <div className="asd-skeleton-line title" />
        <div className="asd-skeleton-line meta" />
      </div>
    </div>
  );
}

/* Internal Row Component for Course Display */
function CourseRow({ course, onClick }) {
  const thumbUrl = course.thumbnailUrl
    ? `${BASE_URL}${course.thumbnailUrl}`
    : null;

  return (
    <div 
      className="asd-course-item" 
      onClick={onClick}
      style={{ cursor: 'pointer', transition: 'all 0.2s ease' }}
      onMouseEnter={(e) => {
        e.currentTarget.style.transform = 'translateY(-2px)';
        e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.08)';
        e.currentTarget.style.borderColor = 'var(--ad-gold-border)';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.transform = 'translateY(0)';
        e.currentTarget.style.boxShadow = 'none';
        e.currentTarget.style.borderColor = 'transparent';
      }}
    >
      <div className="asd-course-thumb-wrap">
        {thumbUrl ? (
          <img src={thumbUrl} alt={course.title} className="asd-course-thumb" />
        ) : (
          <div className="asd-course-thumb-fallback"><FiBookOpen /></div>
        )}
        <span className={`asd-course-type-badge ${course.enrollmentType === 'PAID' ? 'paid' : 'free'}`}>
          {course.enrollmentType}
        </span>
      </div>
      <div className="asd-course-info">
        <h4 className="asd-course-title">{course.title}</h4>
        <p className="asd-course-meta">
          {course.category} • {course.level || "Beginner"}
        </p>
      </div>
    </div>
  );
}
