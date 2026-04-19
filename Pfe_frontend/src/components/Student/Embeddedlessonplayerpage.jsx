import React, { useEffect, useState, useRef } from "react";
import axios from "axios";
import { FiArrowLeft, FiClock, FiLayers, FiArrowRight, FiCheckCircle, FiPlay } from "react-icons/fi";
import "../../styles/Lesson.css";

/* ════════════════════════════════════════════════════════════
   Props:
     courseId       – string | number
     lessonId       – string | number
     onBack         – () => void              → back to lesson cards
     onLessonChange – (lessonId) => void      → jump to another lesson
════════════════════════════════════════════════════════════ */

const formatMin = (min) => {
  if (!min) return "—";
  const h = Math.floor(min / 60), m = min % 60;
  return h > 0 ? `${h}h ${m}m` : `${m}m`;
};

export default function EmbeddedLessonPlayerPage({ courseId, lessonId, onBack, onLessonChange }) {
  const videoRef = useRef(null);

  const [course,    setCourse]    = useState(null);
  const [loading,   setLoading]   = useState(true);
  const [completed, setCompleted] = useState({});

  useEffect(() => {
    setLoading(true);
    axios
      .get(`http://localhost:8080/api/courses/${courseId}`)
      .then(res  => { setCourse(res.data); setLoading(false); })
      .catch(err => { console.error(err); setLoading(false); });
  }, [courseId]);

  const lessons      = course?.lessons ?? [];
  const currentIndex = lessons.findIndex(l => String(l.lessonId) === String(lessonId));
  const current      = lessons[currentIndex];
  const prev         = lessons[currentIndex - 1];
  const next         = lessons[currentIndex + 1];

  const completedCount = Object.values(completed).filter(Boolean).length;
  const progress       = lessons.length > 0 ? Math.round((completedCount / lessons.length) * 100) : 0;

  const handleMarkDone = () => {
    if (current) setCompleted(p => ({ ...p, [current.lessonId]: true }));
    if (next)    onLessonChange(next.lessonId);
  };

  /* ── Loading ── */
  if (loading) return (
    <div className="lesson-loading" style={{ minHeight: "60vh" }}>
      <div className="lesson-spinner" /><p>Loading lesson…</p>
    </div>
  );

  if (!course || !current) return (
    <div className="lesson-empty" style={{ minHeight: "60vh" }}>Lesson not found.</div>
  );

  return (
    <div style={{ display: "flex", flexDirection: "column", minHeight: "100%" }}>

      {/* ── Breadcrumb bar ── */}
      <div className="emb-breadcrumb">
        <button className="emb-back-btn" onClick={onBack}>
          <FiArrowLeft size={14} /> All Lessons
        </button>
        <span className="emb-breadcrumb-sep">›</span>
        <span className="emb-breadcrumb-course">{course.title}</span>
        <span className="emb-breadcrumb-sep">›</span>
        <span className="emb-breadcrumb-current">{current.title}</span>

        {/* Progress in breadcrumb */}
        <div className="emb-progress-wrap">
          <div className="emb-progress-track">
            <div className="emb-progress-fill" style={{ width: `${progress}%` }} />
          </div>
          <span className="emb-progress-label">{progress}% complete</span>
        </div>
      </div>

      {/* ── Player + Playlist ── */}
      <div className="lp-body" style={{ minHeight: "calc(100vh - 130px)" }}>

        {/* ══ LEFT: Player ══ */}
        <div className="lp-player-col">
          <div className="lp-video-box">
            {current.mediaUrl ? (
              <video
                ref={videoRef}
                key={current.lessonId}
                className="lp-video"
                controls
                src={`http://localhost:8080${current.mediaUrl}`}
                onEnded={() => setCompleted(p => ({ ...p, [current.lessonId]: true }))}
              />
            ) : (
              <div className="lp-no-media">
                <svg width="54" height="54" viewBox="0 0 24 24" fill="none"
                  stroke="currentColor" strokeWidth="1">
                  <path d="M15 10l4.553-2.277A1 1 0 0121 8.723v6.554a1 1 0 01-1.447.894L15 14M3 8a2 2 0 012-2h10a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"/>
                </svg>
                <p>No media available for this lesson.</p>
              </div>
            )}
          </div>

          {/* Lesson info */}
          <div className="lp-info">
            <p className="lp-video-index">
              Video #{String(currentIndex + 1).padStart(2, "0")} of {lessons.length}
            </p>
            <h2 className="lp-video-title">{current.title}</h2>

            <div className="lp-meta">
              {current.duration && (
                <span className="lp-chip">
                  <FiClock size={12} /> {formatMin(current.duration)}
                </span>
              )}
              <span className="lp-chip">
                <FiLayers size={12} /> Chapter 1
              </span>
              {completed[current.lessonId] && (
                <span className="lp-chip done">
                  <FiCheckCircle size={12} /> Completed
                </span>
              )}
            </div>

            <div className="lp-nav-btns">
              <button
                className="lp-btn lp-btn-prev"
                disabled={!prev}
                onClick={() => prev && onLessonChange(prev.lessonId)}
              >
                <FiArrowLeft size={14} /> Previous
              </button>
              <button className="lp-btn lp-btn-next" onClick={handleMarkDone}>
                {next ? "Mark Done & Next" : "Mark as Complete"}
                {next && <FiArrowRight size={14} />}
              </button>
            </div>
          </div>
        </div>

        {/* ══ RIGHT: Playlist ══ */}
        <aside className="lp-playlist">
          <div className="lp-playlist-header">
            <p className="lp-playlist-title">Playlist</p>
            <p className="lp-playlist-count">{lessons.length} Videos</p>
            <div className="lp-playlist-progress-track">
              <div className="lp-playlist-progress-fill" style={{ width: `${progress}%` }} />
            </div>
            <p className="lp-playlist-progress-label">{progress}% Complete</p>
          </div>

          <div className="lp-playlist-list">
            {lessons.map((lesson, i) => {
              const isActive = String(lesson.lessonId) === String(lessonId);
              const isDone   = !!completed[lesson.lessonId];

              return (
                <div
                  key={lesson.lessonId}
                  className={`lp-pl-item${isActive ? " active" : ""}`}
                  onClick={() => onLessonChange(lesson.lessonId)}
                >
                  <div className="lp-pl-thumb">
                    {lesson.thumbnailUrl ? (
                      <img className="lp-pl-thumb-img"
                        src={`http://localhost:8080${lesson.thumbnailUrl}`} alt="" />
                    ) : (
                      <div className="lp-pl-thumb-placeholder">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                          stroke="currentColor" strokeWidth="1.3">
                          <path d="M15 10l4.553-2.277A1 1 0 0121 8.723v6.554a1 1 0 01-1.447.894L15 14M3 8a2 2 0 012-2h10a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"/>
                        </svg>
                      </div>
                    )}
                    <span className="lp-pl-chapter-badge">Ch.1</span>
                    <div className="lp-pl-thumb-overlay">
                      <div className="lp-pl-play-icon">
                        <FiPlay size={8} fill={isActive ? "#b89c4d" : "#555"} />
                      </div>
                    </div>
                  </div>

                  <div className="lp-pl-info">
                    <p className="lp-pl-num">
                      {isActive && <FiPlay size={8} fill="#b89c4d" style={{ marginRight: 3 }} />}
                      Video #{String(i + 1).padStart(2, "0")}
                    </p>
                    <p className="lp-pl-title">{lesson.title}</p>
                    <div className="lp-pl-meta">
                      <FiClock size={10} />
                      {lesson.duration ? formatMin(lesson.duration) : "—"}
                      <span>|</span>
                      {isDone ? (
                        <><span className="lp-pl-done-dot" /> Completed</>
                      ) : (
                        <span>{isActive ? "In Progress" : "0% Completed"}</span>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </aside>
      </div>
    </div>
  );
}