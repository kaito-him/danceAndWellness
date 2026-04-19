import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import "../styles/Courses.css";
import Navbar from "../components/Navbar";

/* ── Auth-gate modal ──────────────────────────────────────────── */
const AuthModal = ({ onLogin, onSignup, onClose }) => (
  <div
    style={{
      position: "fixed", inset: 0, zIndex: 9999,
      background: "rgba(0,0,0,0.65)", backdropFilter: "blur(4px)",
      display: "flex", alignItems: "center", justifyContent: "center",
    }}
    onClick={onClose}
  >
    <div
      style={{
        background: "var(--clr-surface, #1a1a2e)",
        border: "1px solid rgba(255,255,255,0.1)",
        borderRadius: 16, padding: "2.5rem 2rem",
        maxWidth: 420, width: "90%", textAlign: "center",
        boxShadow: "0 24px 64px rgba(0,0,0,0.5)",
        color: "#fff",
      }}
      onClick={(e) => e.stopPropagation()}
    >
      {/* Icon */}
      <div style={{
        width: 56, height: 56, borderRadius: "50%",
        background: "rgba(212,175,55,0.15)",
        display: "flex", alignItems: "center", justifyContent: "center",
        margin: "0 auto 1.25rem",
      }}>
        <svg width="26" height="26" viewBox="0 0 24 24" fill="none"
          stroke="var(--clr-gold, #d4af37)" strokeWidth="2">
          <rect x="3" y="11" width="18" height="11" rx="2"/>
          <path d="M7 11V7a5 5 0 0110 0v4"/>
        </svg>
      </div>

      <h2 style={{ margin: "0 0 .5rem", fontSize: "1.35rem", fontWeight: 700 }}>
        Sign in to view this course
      </h2>
      <p style={{ margin: "0 0 1.75rem", color: "rgba(255,255,255,0.55)", fontSize: ".93rem", lineHeight: 1.6 }}>
        Create a free account or sign in to access the full course detail, lessons, and quizzes.
      </p>

      <div style={{ display: "flex", gap: "0.75rem", flexDirection: "column" }}>
        <button
          onClick={onLogin}
          style={{
            padding: "0.75rem 1.5rem", borderRadius: 10, border: "none",
            background: "var(--clr-gold, #d4af37)", color: "#0f0f1a",
            fontWeight: 700, fontSize: "0.95rem", cursor: "pointer",
          }}
        >
          Sign In
        </button>
        <button
          onClick={onSignup}
          style={{
            padding: "0.75rem 1.5rem", borderRadius: 10,
            border: "1px solid rgba(255,255,255,0.2)", background: "transparent",
            color: "#fff", fontWeight: 600, fontSize: "0.95rem", cursor: "pointer",
          }}
        >
          Create a Free Account
        </button>
        <button
          onClick={onClose}
          style={{
            background: "none", border: "none", color: "rgba(255,255,255,0.35)",
            fontSize: "0.85rem", cursor: "pointer", marginTop: "0.25rem",
          }}
        >
          Maybe later
        </button>
      </div>
    </div>
  </div>
);

/* ── Main page ────────────────────────────────────────────────── */
const CoursesPage = () => {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter]   = useState("ALL");
  const [pendingCourseId, setPendingCourseId] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    axios.get("http://localhost:8080/api/courses/published")
      .then((res) => { setCourses(res.data); setLoading(false); })
      .catch((err) => { console.error("Failed to fetch courses:", err); setLoading(false); });
  }, []);

  const categories = ["ALL", ...new Set(courses.map((c) => c.category).filter(Boolean))];
  const filtered   = filter === "ALL" ? courses : courses.filter((c) => c.category === filter);

  const levelLabel = (level) =>
    ({ BEGINNER: "Beginner", INTERMEDIATE: "Intermediate", ADVANCED: "Advanced" }[level] || level);

  const levelColor = (level) =>
    ({ BEGINNER: "var(--clr-green)", INTERMEDIATE: "var(--clr-gold)", ADVANCED: "var(--clr-rose)" }[level] || "var(--clr-gold)");

  /* ── Auth-gated card click ── */
  const handleCardClick = (courseId) => {
  const token = localStorage.getItem("token");
  if (token) {
    navigate(`/courses/${courseId}`);
  } else {
    setPendingCourseId(courseId);
  }
};

  return (
    <div className="courses-root">

      {/* Auth-gate modal */}
      {pendingCourseId && (
        <AuthModal
         onLogin={() => {
        localStorage.setItem("pendingCourseId", pendingCourseId); // ← add this
        navigate("/login", { state: { from: "/student" } }); // send to dashboard, not /courses/:id
      }}
          onSignup={() => navigate("/signup")}
          onClose={() => setPendingCourseId(null)}
        />
      )}

      <Navbar />

      {/* Hero */}
      <section className="courses-hero">
        <span className="courses-badge">Explore Our Catalog</span>
        <h1 className="courses-hero-title">
          Find Your <span className="courses-highlight">Perfect</span> Course
        </h1>
        <p className="courses-hero-sub">
          Premium dance &amp; wellness instruction — from total beginners to advanced artists.
        </p>
        <div className="courses-filters">
          {categories.map((cat) => (
            <button
              key={cat}
              className={`courses-filter-btn ${filter === cat ? "active" : ""}`}
              onClick={() => setFilter(cat)}
            >
              {cat.charAt(0) + cat.slice(1).toLowerCase()}
            </button>
          ))}
        </div>
      </section>

      {/* Grid */}
      <main className="courses-main">
        {loading ? (
          <div className="courses-loading">
            <div className="courses-spinner" />
            <p>Loading courses…</p>
          </div>
        ) : filtered.length === 0 ? (
          <div className="courses-empty">No courses found.</div>
        ) : (
          <div className="courses-grid">
            {filtered.map((course, idx) => (
              <article
                key={course.courseId}
                className="course-card"
                style={{ animationDelay: `${idx * 60}ms` }}
                onClick={() => handleCardClick(course.courseId)} // ← use gated handler
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
                  {course.isFree ? (
                    <span className="course-card-free">Free</span>
                  ) : (
                    <span className="course-card-paid">${course.price?.toFixed(2)}</span>
                  )}
                </div>

                <div className="course-card-body">
                  <p className="course-card-category">{course.category}</p>
                  <h3 className="course-card-title">{course.title}</h3>
                  <div className="course-card-instructor">
                    <div className="course-card-avatar">
                      {course.instructor?.username?.charAt(0).toUpperCase() || "?"}
                    </div>
                    <span>{course.instructor?.username || "Unknown Instructor"}</span>
                  </div>
                  <div className="course-card-stats">
                    <span>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                      </svg>
                      {course.lessons?.length ?? 0} Lessons
                    </span>
                    <span>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>
                      </svg>
                      {course.quizzes?.length ?? 0} Quizzes
                    </span>
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