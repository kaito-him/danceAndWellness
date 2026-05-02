import React, { useState, useEffect, useRef } from "react";
import { FiMoreVertical, FiArchive, FiBookOpen, FiLayers, FiClock } from "react-icons/fi";
import "../../styles/Coursecard.css";

const BASE = "http://localhost:8080";

export default function AdminCatalogCard({ course, onArchive, onPreview }) {
  const [showDropdown, setShowDropdown] = useState(false);
  const dropdownRef = useRef(null);

  const thumbSrc = course.thumbnailUrl ? `${BASE}${course.thumbnailUrl}` : null;

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setShowDropdown(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const levelColor = (level) =>
    ({ BEGINNER: "#27ae60", INTERMEDIATE: "#b89c4d", ADVANCED: "#c0392b" }[level] || "#b89c4d");

  return (
    <article
      className="course-card"
      style={{ cursor: 'pointer' }}
      onClick={() => onPreview(course.courseId)}
    >
      <div className="course-card-thumb">
        {thumbSrc ? (
          <img src={thumbSrc} alt={course.title} />
        ) : (
          <div className="course-card-thumb-placeholder">
            <FiBookOpen size={48} strokeWidth={1.2} />
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
              <button
                className="dropdown-item"
                onClick={(e) => {
                  e.stopPropagation();
                  setShowDropdown(false);
                  onArchive(e, course);
                }}
              >
                <FiArchive /> Archive Course
              </button>
            </div>
          )}
        </div>

        <span className="course-card-level" style={{ background: levelColor(course.level) }}>
          {course.level}
        </span>
        {!course.isFree && (
          <span className="course-card-paid">${course.price?.toFixed(2)}</span>
        )}
      </div>

      <div className="course-card-body">
        <p className="course-card-category">{course.category}</p>
        <h3 className="course-card-title">{course.title}</h3>
        <div className="course-card-instructor">
          <div className="course-card-avatar">
            {course.instructor?.photo ? (
              <img
                src={`${BASE}/api/files/${course.instructor.photo}`}
                alt={course.instructor.username}
                style={{ width: '100%', height: '100%', borderRadius: '50%', objectFit: 'cover' }}
              />
            ) : (
              course.instructor?.username?.charAt(0).toUpperCase() || "?"
            )}
          </div>
          <span>{course.instructor?.username || "Unknown"}</span>
        </div>
        <div className="course-card-stats">
          <span><FiLayers size={14} /> {course.lessons?.length || 0} Lessons</span>
          <span><FiClock size={14} /> {course.quizzes?.length || 0} Quizzes</span>
        </div>
      </div>
    </article>
  );
}
