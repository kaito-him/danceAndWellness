import React, { useEffect, useState } from "react";
import axios from "axios";
import { FiArrowLeft, FiClock, FiPlay } from "react-icons/fi";
import "../../styles/Lesson.css";

/* ════════════════════════════════════════════════════════════
   Props:
     courseId       – string | number
     onBack         – () => void              → back to course detail
     onSelectLesson – (lessonId) => void      → open lesson player
════════════════════════════════════════════════════════════ */

const formatMin = (min) => {
  if (!min) return "—";
  const h = Math.floor(min / 60), m = min % 60;
  return h > 0 ? `${h}h ${m}m` : `${m}m`;
};

export default function EmbeddedLessonCardsPage({ courseId, onBack, onSelectLesson }) {
  const [course,  setCourse]  = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    axios
      .get(`http://localhost:8080/api/courses/${courseId}`)
      .then(res  => { setCourse(res.data); setLoading(false); })
      .catch(err => { console.error(err); setLoading(false); });
  }, [courseId]);

  const lessons = course?.lessons ?? [];

  if (loading) return (
    <div className="lesson-loading" style={{ minHeight: "60vh" }}>
      <div className="lesson-spinner" /><p>Loading lessons…</p>
    </div>
  );

  if (!course) return (
    <div className="lesson-empty" style={{ minHeight: "60vh" }}>Course not found.</div>
  );

  return (
    <div style={{ display: "flex", flexDirection: "column", minHeight: "100%" }}>

      {/* ── Breadcrumb bar ── */}
      <div className="emb-breadcrumb">
        <button className="emb-back-btn" onClick={onBack}>
          <FiArrowLeft size={14} /> Back to Course
        </button>
        <span className="emb-breadcrumb-sep">›</span>
        <span className="emb-breadcrumb-course">{course.title}</span>
        <span className="emb-breadcrumb-sep">›</span>
        <span className="emb-breadcrumb-current">Lessons</span>
      </div>

      {/* ── Hero ── */}
      <section className="lc-hero" style={{ padding: "40px 60px 32px" }}>
        <p className="lc-hero-cat">{course.category}</p>
        <h1 className="lc-hero-title">{course.title}</h1>
        <p className="lc-hero-sub">
          {lessons.length} lesson{lessons.length !== 1 ? "s" : ""} · Click any card to start watching
        </p>
      </section>

      {/* ── Grid ── */}
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
                onClick={() => onSelectLesson(lesson.lessonId)}
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
                      <svg width="44" height="44" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" strokeWidth="1.2">
                        <path d="M15 10l4.553-2.277A1 1 0 0121 8.723v6.554a1 1 0 01-1.447.894L15 14M3 8a2 2 0 012-2h10a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"/>
                      </svg>
                    </div>
                  )}

                  <span className="lc-chapter-badge">
                    <svg width="7" height="7" viewBox="0 0 10 10" fill="currentColor">
                      <circle cx="5" cy="5" r="5"/>
                    </svg>
                    Chapter 1
                  </span>

                  <div className="lc-thumb-bar">
                    Video #{String(i + 1).padStart(2, "0")}: {lesson.title}
                  </div>

                  <div className="lc-play-overlay">
                    <div className="lc-play-btn">
                      <FiPlay size={13} fill="currentColor" />
                    </div>
                  </div>
                </div>

                {/* Body */}
                <div className="lc-card-body">
                  <h3 className="lc-card-title">{lesson.title}</h3>
                  <p className="lc-card-dur">
                    <FiClock size={12} />
                    {lesson.duration ? formatMin(lesson.duration) : "—"}
                  </p>
                  <div className="lc-card-progress-wrap">
                    <div className="lc-card-progress-track">
                      <div className="lc-card-progress-fill" style={{ width: "0%" }} />
                    </div>
                    <p className="lc-card-progress-label">0% Complete</p>
                  </div>
                </div>
              </article>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}