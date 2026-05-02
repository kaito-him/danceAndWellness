import React, { useState, useEffect, useMemo } from "react";
import { useSearchParams } from "react-router-dom";
import api from "./../services/api";
import { FiSearch, FiLayers, FiClock, FiUserCheck, FiX } from "react-icons/fi";
import "../../styles/InstructorFeed.css";
import "../../styles/Courses.css";

export default function InstructorFeed() {
  const [courses, setCourses] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showSwitchModal, setShowSwitchModal] = useState(false);

  // URL State
  const [searchParams, setSearchParams] = useSearchParams();
  
  // Local state initialized from URL
  const searchTerm = searchParams.get("q") || "";
  const filterCat = searchParams.get("category") || "ALL";
  const filterLevel = searchParams.get("level") || "ALL";

  // Search input state (only updates URL on submit)
  const [inputValue, setInputValue] = useState(searchTerm);

  useEffect(() => {
    const load = async () => {
      try {
        const [cRes, catRes] = await Promise.all([
          api.get("/courses/published"),
          api.get("/categories")
        ]);
        setCourses(cRes.data);
        setCategories(catRes.data);
      } catch (_) {
        setError("Failed to load feed data.");
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  // Keep input in sync with URL if URL changes (e.g. back button)
  useEffect(() => {
    setInputValue(searchTerm);
  }, [searchTerm]);

  const filtered = useMemo(() => {
    let list = [...courses];

    if (searchTerm) {
      const q = searchTerm.toLowerCase();
      list = list.filter(c =>
        c.title?.toLowerCase().includes(q) ||
        c.instructor?.username?.toLowerCase().includes(q)
      );
    }

    if (filterCat !== "ALL") {
      list = list.filter(c => c.category === filterCat);
    }

    if (filterLevel !== "ALL") {
      list = list.filter(c => c.level === filterLevel);
    }

    return list;
  }, [courses, searchTerm, filterCat, filterLevel]);

  const updateFilters = (key, value) => {
    const newParams = new URLSearchParams(searchParams);
    if (value && value !== "ALL") {
      newParams.set(key, value);
    } else {
      newParams.delete(key);
    }
    setSearchParams(newParams, { replace: true });
  };

  const handleSearchSubmit = (e) => {
    if (e) e.preventDefault();
    updateFilters("q", inputValue);
  };

  const handleClearSearch = () => {
    setInputValue("");
    updateFilters("q", "");
  };

  const handleSwitchToStudent = () => {
    localStorage.clear();
    window.location.href = "/signup/student";
  };

  const levelLabel = (level) =>
    ({ BEGINNER: "Beginner", INTERMEDIATE: "Intermediate", ADVANCED: "Advanced" }[level] || level);

  const levelColor = (level) =>
    ({ BEGINNER: "#27ae60", INTERMEDIATE: "#b89c4d", ADVANCED: "#c0392b" }[level] || "#b89c4d");

  if (loading) {
    return (
      <div className="id-placeholder">
        <div className="if-spinner" />
        <p>Loading the community feed…</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="id-placeholder">
        <p className="if-error">{error}</p>
      </div>
    );
  }

  return (
    <div className="if-root-v2">
      <div className="id-header">
        <div>
          <h1 className="id-heading">Community Feed</h1>
          <p className="id-subheading">See what other instructors are publishing on Dance&Wellness</p>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="if-filter-bar">
        <form className="if-search-wrap" onSubmit={handleSearchSubmit}>
          <button type="submit" className="if-search-submit-btn">
            <FiSearch className="if-search-icon" />
          </button>
          <input
            type="text"
            placeholder="Search courses or instructors…"
            className="if-search-input"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
          />
          {inputValue && (
            <button 
              type="button" 
              className="if-search-clear-btn"
              onClick={handleClearSearch}
            >
              <FiX />
            </button>
          )}
        </form>

        <div className="if-select-group">
          <div className="if-select-wrap">
            <select
              className="if-select"
              value={filterCat}
              onChange={(e) => updateFilters("category", e.target.value)}
            >
              <option value="ALL">All Categories</option>
              {categories.map(c => <option key={c.id} value={c.name}>{c.name}</option>)}
            </select>
          </div>

          <div className="if-select-wrap">
            <select
              className="if-select"
              value={filterLevel}
              onChange={(e) => updateFilters("level", e.target.value)}
            >
              <option value="ALL">All Levels</option>
              <option value="BEGINNER">Beginner</option>
              <option value="INTERMEDIATE">Intermediate</option>
              <option value="ADVANCED">Advanced</option>
            </select>
          </div>
        </div>

        <div className="if-results-count">
          {filtered.length} matching course{filtered.length !== 1 ? "s" : ""}
        </div>
      </div>

      {filtered.length === 0 ? (
        <div className="id-empty">
          <div className="id-empty-icon"><FiSearch size={48} /></div>
          <h2 className="id-empty-title">No results found</h2>
          <p className="id-empty-sub">Try adjusting your search or filters to find what you're looking for.</p>
        </div>
      ) : (
        <div className="courses-grid">
          {filtered.map((course, idx) => (
            <article
              key={course.courseId}
              className="course-card"
              style={{ animationDelay: `${idx * 60}ms` }}
              onClick={() => setShowSwitchModal(true)}
            >
              <div className="course-card-thumb">
                {course.thumbnailUrl ? (
                  <img src={`http://localhost:8080${course.thumbnailUrl}`} alt={course.title} />
                ) : (
                  <div className="course-card-thumb-placeholder">
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.2">
                      <path d="M15 10l4.553-2.277A1 1 0 0121 8.723v6.554a1 1 0 01-1.447.894L15 14M3 8a2 2 0 012-2h10a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"/>
                    </svg>
                  </div>
                )}
                <span className="course-card-level" style={{ background: levelColor(course.level) }}>
                  {levelLabel(course.level)}
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
                        src={`http://localhost:8080/api/files/${course.instructor.photo}`} 
                        alt={course.instructor.username} 
                        style={{ width: '100%', height: '100%', borderRadius: '50%', objectFit: 'cover' }}
                      />
                    ) : (
                      course.instructor?.username?.charAt(0).toUpperCase() || "?"
                    )}
                  </div>
                  <span>{course.instructor?.username || "Unknown Instructor"}</span>
                </div>
                <div className="course-card-stats">
                  <span><FiLayers size={14} /> {course.lessons?.length ?? 0} Lessons</span>
                  <span><FiClock size={14} /> {course.quizzes?.length ?? 0} Quizzes</span>
                </div>
                <button className="course-card-cta">
                  View Course
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                    <path d="M5 12h14M12 5l7 7-7 7"/>
                  </svg>
                </button>
              </div>
            </article>
          ))}
        </div>
      )}

      {/* Switch to Student Modal */}
      {showSwitchModal && (
        <div className="lm-backdrop" onClick={() => setShowSwitchModal(false)}>
          <div className="lm-card" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '400px' }}>
            <div className="lm-icon-wrap" style={{ color: 'var(--id-gold)', marginBottom: '16px' }}>
              <FiUserCheck size={40} />
            </div>
            <h2 className="lm-title">Switch to Student View</h2>
            <p className="lm-message" style={{ lineHeight: '1.6' }}>
              To view, enroll, or interact with courses as a student, you must use a student account.
              <br /><br />
              Would you like to log out and switch to the student registration?
            </p>
            <div className="lm-actions">
              <button className="lm-btn-cancel" onClick={() => setShowSwitchModal(false)}>Cancel</button>
              <button
                className="lm-btn-confirm"
                onClick={handleSwitchToStudent}
                style={{ background: 'var(--id-gold)' }}
              >
                Switch to Student
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
