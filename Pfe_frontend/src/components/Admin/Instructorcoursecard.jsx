import React from "react";
import {
  FiBookOpen,
  FiDollarSign,
  FiLayers,
  FiVideo,
} from "react-icons/fi";
import "../../styles/InstructorCourseCard.css";

const BASE_URL = "http://localhost:8080";

const LEVEL_COLORS = {
  BEGINNER:     { bg: "rgba(34,120,60,0.10)",  text: "#22783c" },
  INTERMEDIATE: { bg: "rgba(184,156,77,0.12)", text: "#8a7235" },
  ADVANCED:     { bg: "rgba(192,57,43,0.10)",  text: "#c0392b" },
};

const STATUS_COLORS = {
  PUBLISHED: { bg: "rgba(34,120,60,0.10)",  text: "#22783c" },
  PENDING:   { bg: "rgba(184,156,77,0.12)", text: "#8a7235" },
  ARCHIVED:  { bg: "rgba(90,86,71,0.10)",   text: "#5a5647" },
  DRAFT:     { bg: "rgba(90,86,71,0.10)",   text: "#5a5647" },
};

/**
 * Resolves a thumbnailUrl that may be:
 *   - a full URL already:  "http://localhost:8080/api/files/abc123"
 *   - a root-relative path: "/api/files/abc123"
 *   - a bare GridFS id:    "abc123"  (fallback)
 */
function resolveThumbnail(thumbnailUrl) {
  if (!thumbnailUrl) return null;
  if (thumbnailUrl.startsWith("http")) return thumbnailUrl;
  if (thumbnailUrl.startsWith("/")) return `${BASE_URL}${thumbnailUrl}`;
  // bare id
  return `${BASE_URL}/api/files/${thumbnailUrl}`;
}

export default function InstructorCourseCard({ course, onClick }) {
  const levelStyle  = LEVEL_COLORS[course.level]  ?? LEVEL_COLORS.BEGINNER;
  const statusStyle = STATUS_COLORS[course.status] ?? STATUS_COLORS.DRAFT;
  const thumbSrc    = resolveThumbnail(course.thumbnailUrl);

  const lessonCount = Array.isArray(course.lessons) ? course.lessons.length : 0;
  const quizCount   = Array.isArray(course.quizzes) ? course.quizzes.length : 0;

  return (
    <div 
      className="icc-card" 
      onClick={onClick}
      style={{ cursor: 'pointer', transition: 'all 0.3s ease' }}
      onMouseEnter={(e) => {
        e.currentTarget.style.transform = 'translateY(-4px)';
        e.currentTarget.style.boxShadow = '0 10px 25px rgba(0,0,0,0.1)';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.transform = 'translateY(0)';
        e.currentTarget.style.boxShadow = 'none';
      }}
    >
      {/* Thumbnail */}
      <div className="icc-thumb">
        {thumbSrc ? (
          <img
            src={thumbSrc}
            alt={course.title}
            className="icc-thumb-img"
            onError={(e) => { e.currentTarget.style.display = "none"; }}
          />
        ) : (
          <div className="icc-thumb-placeholder">
            <FiBookOpen size={28} />
          </div>
        )}
        <span
          className="icc-status-pill"
          style={{ background: statusStyle.bg, color: statusStyle.text }}
        >
          {course.status}
        </span>
      </div>

      {/* Body */}
      <div className="icc-body">
        <h3 className="icc-title">{course.title}</h3>

        <div className="icc-meta">
          <span
            className="icc-level"
            style={{ background: levelStyle.bg, color: levelStyle.text }}
          >
            {course.level}
          </span>
          <span className="icc-stat">
            <FiVideo size={12} />
            {lessonCount} lesson{lessonCount !== 1 ? "s" : ""}
          </span>
          <span className="icc-stat">
            <FiLayers size={12} />
            {quizCount} quiz{quizCount !== 1 ? "zes" : ""}
          </span>
        </div>

        <div className="icc-price">
          {course.isFree ? (
            <span className="icc-price-free">Free</span>
          ) : (
            <span className="icc-price-paid">
              <FiDollarSign size={13} />
              {Number(course.price ?? 0).toFixed(2)}
            </span>
          )}
        </div>
      </div>
    </div>
  );
}