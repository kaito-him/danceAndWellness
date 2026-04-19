import React, { useEffect, useState } from "react";
import { Link, useParams, useNavigate } from "react-router-dom";
import axios from "axios";
import "../styles/Lesson.css";

/* ── helper ── */
const formatMin = (min) => {
  if (!min) return "—";
  const h = Math.floor(min / 60);
  const m = min % 60;
  return h > 0 ? `${h}h ${m}m` : `${m}m`;
};

const LessonCardsPage = () => {
  const { courseId } = useParams();
  const navigate = useNavigate();
  const [course, setCourse] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    axios
      .get(`http://localhost:8080/api/courses/${courseId}`)
      .then((r) => { setCourse(r.data); setLoading(false); })
      .catch(() => setLoading(false));
  }, [courseId]);

  const lessons = course?.lessons ?? [];

  /* ── Loading ── */
  if (loading) {
    return (
      <div className="lesson-root">
        <div className="lesson-loading">
          <div className="lesson-spinner" />
          <p>Loading lessons…</p>
        </div>
      </div>
    );
  }

  /* ── Not found ── */
  if (!course) {
    return (
      <div className="lesson-root">
        <div className="lesson-empty">Course not found.</div>
      </div>
    );
  }

  return (
    <div className="lesson-root">
      {/* ── Navbar ── */}
      <header className="lesson-nav">
        <div className="lesson-nav-left">
          <Link to="/" className="lesson-logo">Dance &amp; Wellness</Link>
          <span className="lesson-nav-divider">|</span>
          <button
            className="lesson-back-btn"
            onClick={() => navigate(`/courses/${courseId}`)}
          >
            ← Back to Course
          </button>
        </div>
        <span className="lesson-nav-course-title">{course.title}</span>
      </header>

      {/* ── Hero ── */}
      <section className="lc-hero">
        <p className="lc-hero-cat">{course.category}</p>
        <h1 className="lc-hero-title">{course.title}</h1>
        <p className="lc-hero-sub">
          {lessons.length} lesson{lessons.length !== 1 ? "s" : ""} · Click any card to start watching
        </p>
      </section>

      {/* ── Cards Grid ── */}
      <main className="lc-main">
        {lessons.length === 0 ? (
          <div className="lesson-empty">No lessons available yet.</div>
        ) : (
          <div className="lc-grid">
            {lessons.map((lesson, i) => (
              <article
                key={lesson.lessonId}
                className="lc-card"
                style={{ animationDelay: `${i * 55}ms` }}
                onClick={() => navigate(`/courses/${courseId}/lessons/${lesson.lessonId}`)}
              >
                {/* Thumbnail */}
                <div className="lc-thumb">
                  {lesson.thumbnailUrl ? (
                    <img
                      className="lc-thumb-img"
                      src={`http://localhost:8080${lesson.thumbnailUrl}`}
                      alt={lesson.title}
                    />
                  ) : lesson.mediaUrl ? (
                    <video
                      className="lc-thumb-img"
                      src={`http://localhost:8080${lesson.mediaUrl}`}
                      muted
                      style={{ opacity: 0.7 }}
                    />
                  ) : (
                    <div className="lc-thumb-placeholder">
                      <svg width="44" height="44" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.2">
                        <path d="M15 10l4.553-2.277A1 1 0 0121 8.723v6.554a1 1 0 01-1.447.894L15 14M3 8a2 2 0 012-2h10a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"/>
                      </svg>
                    </div>
                  )}

                  {/* Chapter badge */}
                  <span className="lc-chapter-badge">
                    <svg width="7" height="7" viewBox="0 0 10 10" fill="currentColor"><circle cx="5" cy="5" r="5"/></svg>
                    Chapter 1
                  </span>

                  {/* Blue bar with video title */}
                  <div className="lc-thumb-bar">
                    Video #{String(i + 1).padStart(2, "0")}: {lesson.title}
                  </div>

                  {/* Play button */}
                  <div className="lc-play-overlay">
                    <div className="lc-play-btn">
                      <svg width="14" height="16" viewBox="0 0 14 16" fill="currentColor">
                        <path d="M0 0l14 8-14 8V0z"/>
                      </svg>
                    </div>
                  </div>
                </div>

                {/* Body */}
                <div className="lc-card-body">
                  <h3 className="lc-card-title">{lesson.title}</h3>

                  <p className="lc-card-dur">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>
                    </svg>
                    {lesson.duration ? formatMin(lesson.duration) : "—"} min
                  </p>

                  <div className="lc-card-progress-wrap">
                    <div className="lc-card-progress-track">
                      <div className="lc-card-progress-fill" />
                    </div>
                    <p className="lc-card-progress-label">0% Complete</p>
                  </div>
                </div>
              </article>
            ))}
          </div>
        )}
      </main>

      {/* ── Footer ── */}
      <footer className="lesson-footer">
        <span className="lesson-footer-logo">Dance &amp; Wellness</span>
        <p className="lesson-footer-copy">© {new Date().getFullYear()} Dance &amp; Wellness Platform. All rights reserved.</p>
      </footer>
    </div>
  );
};

export default LessonCardsPage;