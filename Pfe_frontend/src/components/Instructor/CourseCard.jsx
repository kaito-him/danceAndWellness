import React, { useState, useEffect, useRef } from "react";
import "../../styles/Coursecard.css";
import { FiMoreVertical, FiArchive, FiRefreshCw, FiTrash2, FiEdit3, FiUsers } from "react-icons/fi";

const STATUS_LABELS = {
  DRAFT: { label: "Draft", className: "status-pending" },
  PUBLISHED: { label: "Published", className: "status-published" },
  ARCHIVED: { label: "Archived", className: "status-archived" },
};

export default function CourseCard({
  course,
  enrollmentCount = 0,
  onDelete,
  onEdit,
  onPublish,
  publishLabel = "Publish",
  deleteLabel = "Delete",
}) {
  const [showDropdown, setShowDropdown] = useState(false);
  const dropdownRef = useRef(null);

  const thumbnailSrc = course.thumbnailUrl
    ? `http://localhost:8080${course.thumbnailUrl}`
    : null;

  const status = STATUS_LABELS[course.status] ?? STATUS_LABELS.DRAFT;

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setShowDropdown(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const isArchivedByAdmin = course.status === 'ARCHIVED' && course.archivedByAdmin;

  return (
    <div className="course-card course-card-clickable" onClick={() => onEdit(course)}>

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

        {/* Options Menu */}
        <div className="course-card-options" ref={dropdownRef}>
          <button
            className="options-btn"
            onClick={(e) => {
              e.stopPropagation();
              setShowDropdown(!showDropdown);
            }}
          >
            <FiMoreVertical />
          </button>

          {showDropdown && (
            <div className="options-dropdown">
              <button className="dropdown-item" onClick={(e) => { e.stopPropagation(); setShowDropdown(false); onEdit(course); }}>
                <FiEdit3 /> Edit / View
              </button>

              {/* Archive Action */}
              {onDelete && deleteLabel === "Archive" && (
                <button className="dropdown-item" onClick={(e) => { e.stopPropagation(); setShowDropdown(false); onDelete(course); }}>
                  <FiArchive /> Archive
                </button>
              )}

              {/* Unarchive Action */}
              {onPublish && publishLabel === "Unarchive" && !isArchivedByAdmin && (
                <button className="dropdown-item" onClick={(e) => { e.stopPropagation(); setShowDropdown(false); onPublish(course); }}>
                  <FiRefreshCw /> Unarchive
                </button>
              )}

              {/* Delete Action (Drafts or Permanent) */}
              {onDelete && deleteLabel !== "Archive" && (
                <button className="dropdown-item delete" onClick={(e) => { e.stopPropagation(); setShowDropdown(false); onDelete(course); }}>
                  <FiTrash2 /> {deleteLabel}
                </button>
              )}
            </div>
          )}
        </div>

        <span className={`course-card-status ${status.className}`}>
          {status.label}
        </span>
      </div>

      {/* Body */}
      <div className="course-card-body">
        <h3 className="course-card-title">{course.title}</h3>

        <div className="course-card-tags">
          {course.category && <span className="tag tag-category">{course.category}</span>}
          {course.level && <span className="tag tag-level">{course.level}</span>}
          {course.isFree !== undefined && (
            <span className={`tag tag-price ${course.isFree ? "tag-free" : "tag-paid"}`}>
              {course.isFree ? "Free" : `$${course.price}`}
            </span>
          )}
        </div>

        <p className="course-card-meta">
          <span>{course.lessons?.length ?? 0} lesson{course.lessons?.length !== 1 ? "s" : ""}</span>
          <span className="course-card-meta-sep">·</span>
          <span className="course-card-enrollment">
            <FiUsers size={12} />
            {enrollmentCount} student{enrollmentCount !== 1 ? "s" : ""}
          </span>
        </p>
      </div>

      {/* Actions (Only Publish/Submit and locked status) */}
      <div className="course-card-actions">
        {onPublish && publishLabel !== "Unarchive" && (
          <button
            className="card-btn card-btn-publish"
            onClick={(e) => { e.stopPropagation(); onPublish(course); }}
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" strokeWidth="2" strokeLinecap="round">
              <path d="M12 5v14" />
              <path d="M5 12h14" />
            </svg>
            {publishLabel}
          </button>
        )}

        {isArchivedByAdmin && (
          <button
            className="card-btn card-btn-publish"
            disabled
            style={{ opacity: 0.5, cursor: 'not-allowed', background: '#f5f5f5', color: '#999' }}
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" strokeWidth="2" strokeLinecap="round">
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
              <path d="M7 11V7a5 5 0 0 1 10 0v4" />
            </svg>
            Locked
          </button>
        )}
      </div>

    </div>
  );
}
