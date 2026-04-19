import React, { useState, useEffect } from "react";
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

export default function AdminInstructorDetail({ instructor, onBack }) {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    window.scrollTo({ top: 0, behavior: "smooth" });
    loadCourses();
  }, [instructor.id]);

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

  return (
    <div className="aid-page">

      {/* ── Back ── */}
      <button className="aid-back-btn" onClick={onBack}>
        <FiArrowLeft size={15} />
        Back to Instructors
      </button>

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
        </div>

        {loading ? (
          <div className="aid-loading">
            <div className="admin-spinner" />
            <span>Loading courses…</span>
          </div>
        ) : courses.length === 0 ? (
          <div className="aid-empty">
            <FiAlertCircle size={36} />
            <p>No courses yet.</p>
          </div>
        ) : (
          <div className="aid-courses-grid">
            {courses.map((course) => (
              <InstructorCourseCard key={course.courseId} course={course} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}