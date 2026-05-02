import React, { useEffect, useState } from "react";
import api from "../services/api";
import { FiArrowLeft, FiClock, FiPlay, FiCheckCircle, FiTrendingUp } from "react-icons/fi";
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

/* ── Lesson Card Skeleton ── */
const LessonCardSkeleton = ({ index }) => (
  <article className="lc-card lc-card-skeleton" style={{ animationDelay: `${index * 55}ms` }}>
    <div className="lc-thumb lc-skel-thumb">
      <div className="lc-skel-shimmer" />
    </div>
    <div className="lc-card-body">
      <div className="lc-skel-line lc-skel-title" />
      <div className="lc-skel-line lc-skel-dur" />
      <div className="lc-card-progress-wrap">
        <div className="lc-skel-line lc-skel-bar" />
        <div className="lc-skel-line lc-skel-label" />
      </div>
    </div>
  </article>
);

export default function EmbeddedLessonCardsPage({ courseId, onBack, onSelectLesson }) {
  const [course,  setCourse]  = useState(null);
  const [loading, setLoading] = useState(true);
  const [categoryName, setCategoryName] = useState("");

  const studentId = localStorage.getItem("userId");

  /* Backend progress state */
  const [courseProgress, setCourseProgress]   = useState(0);
  const [completedCount, setCompletedCount]   = useState(0);
  const [totalLessons, setTotalLessons]       = useState(0);
  const [lessonProgress, setLessonProgress]   = useState({}); // { lessonId: { percent, completed } }

  useEffect(() => {
    setLoading(true);
    api
      .get(`/courses/${courseId}`)
      .then(async res => {
        setCourse(res.data);

        // Set category name from categoryId
        const courseData = res.data;
        if (courseData.categoryId) {
          try {
            const catRes = await api.get(`/categories/${courseData.categoryId}`);
            setCategoryName(catRes.data.name);
          } catch {
            setCategoryName(courseData.categoryId);
          }
        }

        setTimeout(() => setLoading(false), 500);
      })
      .catch(err => { console.error(err); setLoading(false); });
  }, [courseId]);

  /* Fetch progress from backend */
  useEffect(() => {
    if (!studentId || !courseId) return;

    // Course-level progress
    api.get("/progress/course", { params: { studentId, courseId } })
      .then(res => {
        const d = res.data;
        setCourseProgress(d.courseCompletionPercent ?? 0);
        setCompletedCount(d.completedLessons ?? 0);
        setTotalLessons(d.totalLessons ?? 0);
      })
      .catch(() => {});

    // Per-lesson progress
    api.get("/progress/lessons", { params: { studentId, courseId } })
      .then(res => {
        const map = {};
        (res.data || []).forEach(lp => {
          map[lp.lessonId] = {
            percent: Math.round(lp.completionPercent ?? lp.lessonCompletionPercent ?? 0),
            completed: lp.completed ?? false,
          };
        });
        setLessonProgress(map);
      })
      .catch(() => {});
  }, [studentId, courseId]);

  const lessons = course?.lessons ?? [];

  /* Compute effective progress: fallback to client-side calc if API returns 0 */
  const effectiveTotal = totalLessons || lessons.length;
  const effectiveProgress = courseProgress > 0
    ? courseProgress
    : (effectiveTotal > 0 ? Math.round((completedCount / effectiveTotal) * 100) : 0);

  if (!course && !loading) return (
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
        <span className="emb-breadcrumb-course">{course?.title || "…"}</span>
        <span className="emb-breadcrumb-sep">›</span>
        <span className="emb-breadcrumb-current">Lessons</span>

        {/* Course progress in breadcrumb */}
        {effectiveProgress > 0 && (
          <div className="emb-progress-wrap">
            <div className="emb-progress-track">
              <div className="emb-progress-fill" style={{ width: `${effectiveProgress}%` }} />
            </div>
            <span className="emb-progress-label">
              {effectiveProgress}% complete · {completedCount}/{effectiveTotal} lessons
            </span>
          </div>
        )}
      </div>

      {/* ── Hero ── */}
      <section className="lc-hero" style={{ padding: "40px 60px 32px" }}>
        <div className="lc-hero-row">
          <div className="lc-hero-left">
            <p className="lc-hero-cat">{categoryName || course?.category}</p>
            <h1 className="lc-hero-title">{course?.title || "Loading…"}</h1>
            <p className="lc-hero-sub">
              {lessons.length} lesson{lessons.length !== 1 ? "s" : ""}
              {completedCount > 0 && ` · ${completedCount} completed`}
              {" · "}Click any card to start watching
            </p>
          </div>

          {/* ── Global course progress — top right ── */}
          <div className="lc-hero-progress">
            <div className="lc-hero-progress-ring">
              <svg viewBox="0 0 36 36" className="lc-progress-svg">
                <path
                  className="lc-progress-bg-circle"
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                />
                <path
                  className="lc-progress-fg-circle"
                  strokeDasharray={`${effectiveProgress}, 100`}
                  d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                />
              </svg>
              <span className="lc-progress-ring-value">{effectiveProgress}%</span>
            </div>
            <div className="lc-hero-progress-info">
              <span className="lc-hero-progress-label">Course Progress</span>
              <span className="lc-hero-progress-detail">
                {completedCount}/{effectiveTotal} lessons done
              </span>
            </div>
          </div>
        </div>
      </section>

      {/* ── Grid ── */}
      <main className="lc-main">
        {loading ? (
          <div className="lc-grid">
            {Array.from({ length: 6 }).map((_, idx) => (
              <LessonCardSkeleton key={idx} index={idx} />
            ))}
          </div>
        ) : lessons.length === 0 ? (
          <div className="lesson-empty">No lessons available yet.</div>
        ) : (
          <div className="lc-grid">
            {lessons.map((lesson, i) => {
              const lp = lessonProgress[lesson.lessonId] || { percent: 0, completed: false };

              return (
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

                    {/* Completed overlay badge */}
                    {lp.completed && (
                      <div className="lc-completed-badge">
                        <FiCheckCircle size={12} /> Completed
                      </div>
                    )}

                    {/* Video index badge — top left */}
                    <span className="lc-video-index-badge">
                      #{String(i + 1).padStart(2, "0")}
                    </span>

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
                        <div
                          className={`lc-card-progress-fill${lp.completed ? " lc-progress-done" : ""}`}
                          style={{ width: `${lp.completed ? 100 : lp.percent}%` }}
                        />
                      </div>
                      <p className={`lc-card-progress-label${lp.completed ? " lc-label-done" : ""}`}>
                        {lp.completed
                          ? "✓ Completed"
                          : lp.percent > 0
                            ? `In Progress · ${lp.percent}%`
                            : "Not started"}
                      </p>
                    </div>
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </main>
    </div>
  );
}