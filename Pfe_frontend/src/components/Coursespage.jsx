import React, { useEffect, useState, useMemo } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import axios from "axios";
import { FiSearch, FiLayers, FiClock } from "react-icons/fi";
import "../styles/Courses.css";
import Navbar from "../components/Navbar";

/* ── Auth-gate modal ──────────────────────────────────────────── */
const AuthModal = ({ onLogin, onSignup, onClose }) => (
  <div
    style={{
      position: "fixed", inset: 0, zIndex: 9999,
      background: "rgba(20, 16, 8, 0.6)", backdropFilter: "blur(8px)",
      display: "flex", alignItems: "center", justifyContent: "center",
      padding: "20px"
    }}
    onClick={onClose}
  >
    <div
      style={{
        background: "#fff",
        border: "1px solid #e8e4da",
        borderRadius: 24, padding: "3rem 2.5rem",
        maxWidth: 440, width: "100%", textAlign: "center",
        boxShadow: "0 32px 80px rgba(28, 26, 20, 0.15)",
        color: "#1a1a1a",
        animation: "fadeUp 0.4s ease-out"
      }}
      onClick={(e) => e.stopPropagation()}
    >
      <div style={{
        width: 64, height: 64, borderRadius: "50%",
        background: "rgba(184, 156, 77, 0.1)",
        display: "flex", alignItems: "center", justifyContent: "center",
        margin: "0 auto 2rem",
      }}>
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none"
          stroke="#b89c4d" strokeWidth="2">
          <rect x="3" y="11" width="18" height="11" rx="2"/>
          <path d="M7 11V7a5 5 0 0110 0v4"/>
        </svg>
      </div>

      <h2 style={{ margin: "0 0 1rem", fontSize: "1.75rem", fontWeight: 700, fontFamily: "'Playfair Display', serif" }}>
        Start Your Journey
      </h2>
      <p style={{ margin: "0 0 2.5rem", color: "#666", fontSize: "1rem", lineHeight: 1.6 }}>
        Join our community of artists and wellness enthusiasts to access premium instruction, resources, and more.
      </p>

      <div style={{ display: "flex", gap: "1rem", flexDirection: "column" }}>
        <button
          onClick={onLogin}
          style={{
            padding: "1rem 1.5rem", borderRadius: 12, border: "none",
            background: "#b89c4d", color: "#fff",
            fontWeight: 700, fontSize: "1.05rem", cursor: "pointer",
            boxShadow: "0 4px 12px rgba(184, 156, 77, 0.25)",
            transition: "all 0.2s"
          }}
        >
          Sign In to Access
        </button>
        <button
          onClick={onSignup}
          style={{
            padding: "1rem 1.5rem", borderRadius: 12,
            border: "1px solid #e8e4da", background: "#fcfbf9",
            color: "#111", fontWeight: 600, fontSize: "1rem", cursor: "pointer",
            transition: "all 0.2s"
          }}
        >
          Create Free Account
        </button>
        <button
          onClick={onClose}
          style={{
            background: "none", border: "none", color: "#9a9284",
            fontSize: "0.9rem", cursor: "pointer", marginTop: "0.5rem",
            textDecoration: "underline"
          }}
        >
          Continue Browsing
        </button>
      </div>
    </div>
  </div>
);

/* ── Skeleton Loader ─────────────────────────────────────────── */
const CourseCardSkeleton = ({ index }) => (
  <div className="course-card-skeleton" style={{ animationDelay: `${index * 80}ms` }}>
    <div className="skeleton-thumb" />
    <div className="skeleton-body">
      <div className="skeleton-line cat" />
      <div className="skeleton-line title" />
      <div className="skeleton-line title-half" />
      <div className="skeleton-instructor">
        <div className="skeleton-avatar" />
        <div className="skeleton-line name" />
      </div>
      <div className="skeleton-stats">
        <div className="skeleton-line stat" />
        <div className="skeleton-line stat" />
      </div>
      <div className="skeleton-btn" />
    </div>
  </div>
);

/* ── Main page ────────────────────────────────────────────────── */
const CoursesPage = () => {
  const [courses, setCourses] = useState([]);
  const [cats, setCats] = useState([]);
  const [loading, setLoading] = useState(true);
  const [pendingCourseId, setPendingCourseId] = useState(null);
  
  const [searchParams, setSearchParams] = useSearchParams();
  const navigate = useNavigate();

  // Local state for search input (don't sync until search button click)
  const [searchInput, setSearchInput] = useState(searchParams.get("instructor") || "");

  const filterCat   = searchParams.get("category") || "ALL";
  const filterLevel = searchParams.get("level") || "ALL";
  const filterUser  = searchParams.get("instructor") || "";

  useEffect(() => {
    setLoading(true);
    Promise.all([
      axios.get("http://localhost:8080/api/courses/published"),
      axios.get("http://localhost:8080/api/categories")
    ])
      .then(([coursesRes, catsRes]) => {
        setCourses(coursesRes.data);
        setCats(catsRes.data);
        setTimeout(() => setLoading(false), 800);
      })
      .catch((err) => {
        console.error("Failed to fetch data:", err);
        setLoading(false);
      });
  }, []);

  const filtered = useMemo(() => {
    let list = [...courses];
    if (filterCat !== "ALL") {
      list = list.filter(c => {
        const cat = cats.find(cat => cat.id === c.categoryId);
        return cat?.name === filterCat;
      });
    }
    if (filterLevel !== "ALL") {
      list = list.filter(c => c.level === filterLevel);
    }
    if (filterUser) {
      const q = filterUser.toLowerCase();
      list = list.filter(c => 
        c.instructor?.username?.toLowerCase().includes(q) ||
        c.title?.toLowerCase().includes(q)
      );
    }
    return list;
  }, [courses, filterCat, filterLevel, filterUser, cats]);

  const handleSearch = () => {
    setLoading(true);
    const newParams = new URLSearchParams(searchParams);
    if (searchInput) newParams.set("instructor", searchInput);
    else newParams.delete("instructor");
    setSearchParams(newParams);
    setTimeout(() => setLoading(false), 800);
  };

  const handleFilterChange = (key, val) => {
    setLoading(true);
    const newParams = new URLSearchParams(searchParams);
    if (val === "ALL") newParams.delete(key);
    else newParams.set(key, val);
    setSearchParams(newParams);
    setTimeout(() => setLoading(false), 800);
  };

  const levelLabel = (level) =>
    ({ BEGINNER: "Beginner", INTERMEDIATE: "Intermediate", ADVANCED: "Advanced" }[level] || level);

  const levelColor = (level) =>
    ({ BEGINNER: "#27ae60", INTERMEDIATE: "#b89c4d", ADVANCED: "#c0392b" }[level] || "#b89c4d");

  /* ── Auth-gated card click ── */
  const handleCardClick = (courseId) => {
    const token = localStorage.getItem("token");
    if (token) {
      const role = localStorage.getItem("role");
      
      // Navigate based on role
      if (role === "STUDENT") {
        navigate(`/student/course/${courseId}`);
      } else if (role === "ADMIN") {
        navigate(`/admin?section=course-preview&courseId=${courseId}`);
      } else if (role === "INSTRUCTOR") {
        navigate(`/instructor?section=course-preview&courseId=${courseId}&showRoleWarning=true`);
      }
    } else {
      setPendingCourseId(courseId);
    }
  };

  return (
    <div className="courses-root">
      {pendingCourseId && (
        <AuthModal
          onLogin={() => {
            localStorage.setItem("pendingCourseId", pendingCourseId);
            navigate("/login", { state: { from: "/student" } });
          }}
          onSignup={() => navigate("/signup")}
          onClose={() => setPendingCourseId(null)}
        />
      )}

      <Navbar />

      <section className="courses-hero">
        <span className="courses-badge">Explore Our Catalog</span>
        <h1 className="courses-hero-title">
          Find Your <span className="courses-highlight">Perfect</span> Course
        </h1>
        <p className="courses-hero-sub">
          Premium dance &amp; wellness instruction — from total beginners to advanced artists.
        </p>

        <div className="courses-search-bar">
          <div className="courses-search-input-wrapper">
            <FiSearch className="search-icon" />
            <input 
              type="text" 
              placeholder="Search courses or instructors…" 
              className="courses-input"
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
            />
            <button className="courses-search-btn" onClick={handleSearch}>Search</button>
          </div>

          <div className="courses-select-group">
            <select 
              className="courses-select" 
              value={filterCat} 
              onChange={(e) => handleFilterChange("category", e.target.value)}
            >
              <option value="ALL">All Categories</option>
              {cats.map(cat => <option key={cat.id} value={cat.name}>{cat.name}</option>)}
            </select>

            <select 
              className="courses-select" 
              value={filterLevel} 
              onChange={(e) => handleFilterChange("level", e.target.value)}
            >
              <option value="ALL">All Levels</option>
              <option value="BEGINNER">Beginner</option>
              <option value="INTERMEDIATE">Intermediate</option>
              <option value="ADVANCED">Advanced</option>
            </select>
          </div>
        </div>
      </section>

      <main className="courses-main">
        {loading ? (
          <div className="courses-grid">
            {Array.from({ length: 8 }).map((_, idx) => (
              <CourseCardSkeleton key={idx} index={idx} />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div className="courses-empty">
            <div className="courses-empty-icon"><FiSearch size={40} /></div>
            <h2 className="courses-empty-title">No courses found</h2>
            <p className="courses-empty-sub">We couldn't find any courses matching your current search or filters.</p>
            <button className="courses-empty-reset" onClick={() => {
              setSearchInput("");
              setSearchParams({});
              setLoading(true);
              setTimeout(() => setLoading(false), 800);
            }}>Clear all filters</button>
          </div>
        ) : (
          <div className="courses-grid">
            {filtered.map((course, idx) => (
              <article
                key={course.courseId}
                className="course-card"
                style={{ animationDelay: `${idx * 60}ms` }}
                onClick={() => handleCardClick(course.courseId)}
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
                  <p className="course-card-category">
                    {cats.find(c => c.id === course.categoryId)?.name || ""}
                  </p>
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
                    {course.isFree ? "Enroll Free" : "View Course"}
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                      <path d="M5 12h14M12 5l7 7-7 7"/>
                    </svg>
                  </button>
                </div>
              </article>
            ))}
          </div>
        )}
      </main>

      <footer className="courses-footer">
        <span className="courses-logo-sm">Dance & Wellness</span>
        <p>© {new Date().getFullYear()} Dance & Wellness Platform. All rights reserved.</p>
      </footer>
    </div>
  );
};

export default CoursesPage;