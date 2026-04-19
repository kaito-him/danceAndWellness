import React, { useEffect, useState, useRef } from "react";
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

const LessonPlayerPage = () => {
  const { courseId, lessonId } = useParams();
  const navigate = useNavigate();
  const videoRef = useRef(null);

  const [course, setCourse] = useState(null);
  const [loading, setLoading] = useState(true);
  const [completed, setCompleted] = useState({});

  useEffect(() => {
    axios
      .get(`http://localhost:8080/api/courses/${courseId}`)
      .then((r) => { setCourse(r.data); setLoading(false); })
      .catch(() => setLoading(false));
  }, [courseId]);

  const lessons = course?.lessons ?? [];
  const currentIndex = lessons.findIndex((l) => String(l.lessonId) === String(lessonId));
  const current = lessons[currentIndex];
  const prev = lessons[currentIndex - 1];
  const next = lessons[currentIndex + 1];

  const completedCount = Object.values(completed).filter(Boolean).length;
  const progress = lessons.length > 0 ? Math.round((completedCount / lessons.length) * 100) : 0;

  const goTo = (lesson) => navigate(`/courses/${courseId}/lessons/${lesson.lessonId}`);

  const handleMarkDone = () => {
    if (current) setCompleted((p) => ({ ...p, [current.lessonId]: true }));
    if (next) goTo(next);
  };

  /* ── Loading ── */
  if (loading) {
    return (
      <div className="lesson-root">
        <div className="lesson-loading">
          <div className="lesson-spinner" />
          <p>Loading lesson…</p>
        </div>
      </div>
    );
  }

  /* ── Not found ── */
  if (!course || !current) {
    return (
      <div className="lesson-root">
        <div className="lesson-empty">Lesson not found.</div>
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
            onClick={() => navigate(`/courses/${courseId}/lessons`)}
          >
            ← All Lessons
          </button>
        </div>

        <div className="lesson-nav-progress">
          <span className="lesson-nav-course-title">{course.title}</span>
          <div className="lesson-progress-track">
            <div className="lesson-progress-fill" style={{ width: `${progress}%` }} />
          </div>
          <span>{progress}% Complete</span>
        </div>
      </header>

      {/* ── Body: player + playlist ── */}
      <div className="lp-body">

        {/* ══ LEFT: Player column ══ */}
        <div className="lp-player-col">

          {/* Video */}
          <div className="lp-video-box">
            {current.mediaUrl ? (
              <video
                ref={videoRef}
                key={current.lessonId}
                className="lp-video"
                controls
                src={`http://localhost:8080${current.mediaUrl}`}
                onEnded={() => setCompleted((p) => ({ ...p, [current.lessonId]: true }))}
              />
            ) : (
              <div className="lp-no-media">
                <svg width="54" height="54" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1">
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
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>
                  </svg>
                  {formatMin(current.duration)}
                </span>
              )}
              <span className="lp-chip">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                </svg>
                Chapter 1
              </span>
              {completed[current.lessonId] && (
                <span className="lp-chip done">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                    <path d="M20 6L9 17l-5-5"/>
                  </svg>
                  Completed
                </span>
              )}
            </div>

            {/* Navigation buttons */}
            <div className="lp-nav-btns">
              <button
                className="lp-btn lp-btn-prev"
                disabled={!prev}
                onClick={() => prev && goTo(prev)}
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                  <path d="M19 12H5M12 19l-7-7 7-7"/>
                </svg>
                Previous
              </button>

              <button className="lp-btn lp-btn-next" onClick={handleMarkDone}>
                {next ? "Mark Done & Next" : "Mark as Complete"}
                {next && (
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                    <path d="M5 12h14M12 5l7 7-7 7"/>
                  </svg>
                )}
              </button>
            </div>
          </div>
        </div>

        {/* ══ RIGHT: Playlist sidebar ══ */}
        <aside className="lp-playlist">
          {/* Header */}
          <div className="lp-playlist-header">
            <p className="lp-playlist-title">Playlist</p>
            <p className="lp-playlist-count">{lessons.length} Videos</p>
            <div className="lp-playlist-progress-track">
              <div className="lp-playlist-progress-fill" style={{ width: `${progress}%` }} />
            </div>
            <p className="lp-playlist-progress-label">{progress}% Complete</p>
          </div>

          {/* Items */}
          <div className="lp-playlist-list">
            {lessons.map((lesson, i) => {
              const isActive = String(lesson.lessonId) === String(lessonId);
              const isDone = !!completed[lesson.lessonId];

              return (
                <div
                  key={lesson.lessonId}
                  className={`lp-pl-item${isActive ? " active" : ""}`}
                  onClick={() => goTo(lesson)}
                >
                  {/* Thumbnail */}
                  <div className="lp-pl-thumb">
                    {lesson.thumbnailUrl ? (
                      <img
                        className="lp-pl-thumb-img"
                        src={`http://localhost:8080${lesson.thumbnailUrl}`}
                        alt=""
                      />
                    ) : (
                      <div className="lp-pl-thumb-placeholder">
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.3">
                          <path d="M15 10l4.553-2.277A1 1 0 0121 8.723v6.554a1 1 0 01-1.447.894L15 14M3 8a2 2 0 012-2h10a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"/>
                        </svg>
                      </div>
                    )}

                    <span className="lp-pl-chapter-badge">Ch.1</span>

                    <div className="lp-pl-thumb-overlay">
                      <div className="lp-pl-play-icon">
                        <svg width="8" height="9" viewBox="0 0 8 9" fill={isActive ? "#b89c4d" : "#555"}>
                          <path d="M0 0l8 4.5L0 9V0z"/>
                        </svg>
                      </div>
                    </div>
                  </div>

                  {/* Text info */}
                  <div className="lp-pl-info">
                    <p className="lp-pl-num">
                      {isActive && (
                        <svg width="8" height="9" viewBox="0 0 8 9" fill="#b89c4d">
                          <path d="M0 0l8 4.5L0 9V0z"/>
                        </svg>
                      )}
                      Video #{String(i + 1).padStart(2, "0")}
                    </p>
                    <p className="lp-pl-title">{lesson.title}</p>
                    <div className="lp-pl-meta">
                      <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>
                      </svg>
                      {lesson.duration ? formatMin(lesson.duration) : "—"} min
                      <span>|</span>
                      {isDone ? (
                        <>
                          <span className="lp-pl-done-dot" />
                          Completed
                        </>
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
};

export default LessonPlayerPage;