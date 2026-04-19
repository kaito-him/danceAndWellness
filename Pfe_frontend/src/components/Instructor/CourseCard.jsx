import React from "react";
import "../../styles/Coursecard.css";

const STATUS_LABELS = {
  PENDING:   { label: "Pending Review", className: "status-pending"   },
  PUBLISHED: { label: "Published",      className: "status-published" },
  ARCHIVED:  { label: "Archived",       className: "status-archived"  },
};

export default function CourseCard({ course, onDelete, onEdit }) {
  const thumbnailSrc = course.thumbnailUrl
    ? `http://localhost:8080${course.thumbnailUrl}`
    : null;

  const status = STATUS_LABELS[course.status] ?? STATUS_LABELS.PENDING;

  return (
    <div className="course-card">

      {/* Thumbnail */}
      <div className="course-card-thumb">
        {thumbnailSrc ? (
          <img src={thumbnailSrc} alt={course.title} />
        ) : (
          <div className="course-card-thumb-placeholder">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
              <rect x="3" y="3" width="18" height="18" rx="2" />
              <circle cx="8.5" cy="8.5" r="1.5" />
              <polyline points="21 15 16 10 5 21" />
            </svg>
          </div>
        )}
        <span className={`course-card-status ${status.className}`}>
          {status.label}
        </span>
      </div>

      {/* Body */}
      <div className="course-card-body">
        <h3 className="course-card-title">{course.title}</h3>

        <div className="course-card-tags">
          <span className="tag tag-category">{course.category}</span>
          <span className="tag tag-level">{course.level}</span>
          <span className={`tag tag-price ${course.isFree ? "tag-free" : "tag-paid"}`}>
            {course.isFree ? "Free" : `$${course.price}`}
          </span>
        </div>

        <p className="course-card-meta">
          {course.lessons?.length ?? 0} lesson{course.lessons?.length !== 1 ? "s" : ""}
        </p>
      </div>

      {/* Actions */}
      <div className="course-card-actions">
        <button className="card-btn card-btn-edit" onClick={() => onEdit(course)}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
            stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
          </svg>
          Edit
        </button>
        <button className="card-btn card-btn-delete" onClick={() => onDelete(course.courseId)}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
            stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <polyline points="3 6 5 6 21 6"/>
            <path d="M19 6l-1 14H6L5 6"/>
            <path d="M10 11v6M14 11v6"/>
            <path d="M9 6V4h6v2"/>
          </svg>
          Delete
        </button>
      </div>

    </div>
  );
}