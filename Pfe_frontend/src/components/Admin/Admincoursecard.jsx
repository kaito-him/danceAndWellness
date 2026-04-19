import React from "react";
import "../../styles/Admincoursecard.css";

const BASE = "http://localhost:8080";
const toSrc = (url) => (url ? (url.startsWith("/api") ? `${BASE}${url}` : url) : null);

export default function AdminCourseCard({ course, onApprove, onArchive, onViewDetails }) {
  const thumbSrc = toSrc(course.thumbnailUrl);

  return (
    <div className="acc-card">

      {/* Thumbnail */}
      <div className="acc-thumb">
        {thumbSrc ? (
          <img src={thumbSrc} alt={course.title} />
        ) : (
          <div className="acc-thumb-empty">
            <svg width="30" height="30" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
              <rect x="3" y="3" width="18" height="18" rx="2"/>
              <circle cx="8.5" cy="8.5" r="1.5"/>
              <polyline points="21 15 16 10 5 21"/>
            </svg>
          </div>
        )}
        <span className="acc-badge">Pending Review</span>
      </div>

      {/* Info */}
      <div className="acc-body">
        <h3 className="acc-title">{course.title}</h3>
        <div className="acc-tags">
          <span className="acc-tag acc-tag-cat">{course.category}</span>
          <span className="acc-tag acc-tag-lvl">{course.level}</span>
          <span className={`acc-tag ${course.isFree ? "acc-tag-free" : "acc-tag-paid"}`}>
            {course.isFree ? "Free" : `$${course.price}`}
          </span>
        </div>
        <p className="acc-meta">
          {course.lessons?.length ?? 0} lesson{course.lessons?.length !== 1 ? "s" : ""}
          {" · "}
          {course.quizzes?.length ?? 0} quiz{course.quizzes?.length !== 1 ? "zes" : ""}
        </p>
      </div>

      {/* Actions */}
      <div className="acc-actions">
        <button className="acc-btn acc-btn-details" onClick={() => onViewDetails(course)}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none"
            stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <circle cx="11" cy="11" r="8"/>
            <line x1="21" y1="21" x2="16.65" y2="16.65"/>
          </svg>
          View Details
        </button>
      </div>

      <div className="acc-actions acc-actions-verdict">
        <button className="acc-btn acc-btn-approve" onClick={() => onApprove(course.courseId)}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none"
            stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
            <polyline points="20 6 9 17 4 12"/>
          </svg>
          Approve
        </button>
        <button className="acc-btn acc-btn-archive" onClick={() => onArchive(course.courseId)}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none"
            stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <polyline points="21 8 21 21 3 21 3 8"/>
            <rect x="1" y="3" width="22" height="5"/>
            <line x1="10" y1="12" x2="14" y2="12"/>
          </svg>
          Archive
        </button>
      </div>

    </div>
  );
}