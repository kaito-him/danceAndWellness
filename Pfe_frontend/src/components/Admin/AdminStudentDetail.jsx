import React, { useState, useEffect } from "react";
import {
  FiArrowLeft,
  FiMail,
  FiCalendar,
  FiBookOpen,
  FiClock,
  FiAlertCircle,
  FiUser
} from "react-icons/fi";
import api from "./../services/api";
import "../../styles/AdminStudentDetail.css";

const BASE_URL = "http://localhost:8080";

const STATUS_MAP = {
  ACTIVE: { label: "Active", cls: "asd-status--active" },
  INACTIVE: { label: "Inactive", cls: "asd-status--inactive" },
};

export default function AdminStudentDetail({ student, onBack }) {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    window.scrollTo({ top: 0, behavior: "smooth" });
    loadCourses();
  }, [student.id]);

  const loadCourses = async () => {
    setLoading(true);
    try {
      const res = await api.get(`/students/${student.id}/courses`);
      setCourses(res.data);
    } catch (err) {
      console.error("Failed to load student courses", err);
      setCourses([]);
    } finally {
      setLoading(false);
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
      {/* ── Back ── */}
      <button className="asd-back-btn" onClick={onBack}>
        <FiArrowLeft size={15} />
        Back to Students
      </button>

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
          <div className="asd-loading">
            <div className="admin-spinner" />
            <span>Loading courses…</span>
          </div>
        ) : courses.length === 0 ? (
          <div className="asd-empty">
            <FiAlertCircle size={36} />
            <p>This student is not enrolled in any courses yet.</p>
          </div>
        ) : (
          <div className="asd-courses-grid">
            {courses.map((course) => (
              <CourseRow key={course.courseId} course={course} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

/* Internal Row Component for Course Display */
function CourseRow({ course }) {
  const photoUrl = course.photo
    ? `${BASE_URL}/api/files/${course.photo}`
    : "https://via.placeholder.com/100x60?text=No+Image";

  return (
    <div style={{
      background: 'white',
      border: '1.5px solid var(--ad-border)',
      borderRadius: '16px',
      padding: '1rem',
      display: 'flex',
      alignItems: 'center',
      gap: '1rem',
      transition: 'all 0.2s',
      cursor: 'default'
    }}>
      <img
        src={photoUrl}
        alt={course.title}
        style={{ width: '80px', height: '50px', borderRadius: '10px', objectFit: 'cover' }}
      />
      <div>
        <h4 style={{ margin: 0, fontSize: '1rem', color: 'var(--ad-text)', fontWeight: 700 }}>{course.title}</h4>
        <p style={{ margin: '2px 0 0', fontSize: '0.8rem', color: 'var(--ad-muted)' }}>
          By {course.instructor?.username || "Instructor"} • {course.category || "General"}
        </p>
      </div>
    </div>
  );
}
