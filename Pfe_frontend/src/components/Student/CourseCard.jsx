import React from "react";
import { FiLayers, FiClock, FiChevronRight } from "react-icons/fi";

const LEVEL_META = {
  BEGINNER: { label: "Beginner", color: "#3a7d44" },
  INTERMEDIATE: { label: "Intermediate", color: "#b89c4d" },
  ADVANCED: { label: "Advanced", color: "#9b3a3a" },
};

const CourseCard = ({ course, index, onSelect, hideInstructorAvatar }) => {
  const meta = LEVEL_META[course.level] || LEVEL_META.BEGINNER;

  return (
    <article
      className="sd-card"
      style={{ animationDelay: `${index * 50}ms` }}
      onClick={() => onSelect(course.courseId)}
    >
      <div className="sd-card-thumb">
        {course.thumbnailUrl ? (
          <img
            src={`http://localhost:8080${course.thumbnailUrl}`}
            alt={course.title}
            style={{ width: "100%", height: "100%", objectFit: "cover" }}
          />
        ) : (
          <div className="sd-card-thumb-placeholder"><FiLayers size={36} /></div>
        )}
        <span className="sd-card-level" style={{ background: meta.color }}>{meta.label}</span>
        {course.isFree
          ? <span className="sd-card-price free">Free</span>
          : <span className="sd-card-price paid">${course.price?.toFixed(2)}</span>}
      </div>

      <div className="sd-card-body">
        <p className="sd-card-cat">{course.category}</p>
        <h3 className="sd-card-title">{course.title}</h3>
        <div className="sd-card-instructor">
          {!hideInstructorAvatar && (
            <div className="sd-card-instr-avatar">
              {course.instructor?.photo ? (
                <img src={`http://localhost:8080/api/files/${course.instructor.photo}`} alt={course.instructor.username} style={{ width: '100%', height: '100%', borderRadius: '50%', objectFit: 'cover' }} />
              ) : (
                course.instructor?.username?.charAt(0).toUpperCase() || "?"
              )}
            </div>
          )}
          <span className="sd-card-instr-name">
            {course.instructor?.username || "Unknown Instructor"}
          </span>
        </div>
        <div className="sd-card-stats">
          <span className="sd-card-stat"><FiLayers size={12} /> {course.lessons?.length ?? 0} lessons</span>
          <span className="sd-card-stat"><FiClock size={12} /> {course.quizzes?.length ?? 0} quizzes</span>
        </div>
        <button className="sd-card-cta">
          {course.isFree ? "Enroll Free" : "View Course"} <FiChevronRight size={14} />
        </button>
      </div>
    </article>
  );
};

export default CourseCard;
