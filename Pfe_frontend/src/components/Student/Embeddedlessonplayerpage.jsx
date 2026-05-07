import React, { useEffect, useState, useRef, useCallback } from "react";
import api from "../services/api";
import { FiArrowLeft, FiClock, FiArrowRight, FiCheckCircle, FiPlay } from "react-icons/fi";
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

const TICK_INTERVAL = 5000; // send progress every 5 seconds

export default function EmbeddedLessonPlayerPage({ courseId, lessonId, onBack, onLessonChange }) {
  const videoRef = useRef(null);
  const tickRef  = useRef(null);
  const sseRef   = useRef(null);
  const maxWatchedRef  = useRef(0);

  const studentId = localStorage.getItem("userId");

  const [course,    setCourse]    = useState(null);
  const [loading,   setLoading]   = useState(true);

  /* Backend-driven progress state */
  const [courseProgress, setCourseProgress]   = useState(0);
  const [lessonProgress, setLessonProgress]   = useState({});

  /* ── Fetch course data ── */
  useEffect(() => {
    setLoading(true);
    api
      .get(`/courses/${courseId}`)
      .then(res  => { setCourse(res.data); setLoading(false); })
      .catch(err => { console.error(err); setLoading(false); });
  }, [courseId]);

  /* ── Fetch initial progress from backend ── */
  useEffect(() => {
    if (!studentId || !courseId) return;

    // Course-level progress
    api.get("/progress/course", { params: { studentId, courseId } })
      .then(res => {
        const d = res.data;
        setCourseProgress(d.courseCompletionPercent ?? 0);
      })
      .catch(() => {});

    // Per-lesson progress list
    api.get("/progress/lessons", { params: { studentId, courseId } })
      .then(res => {
        const map = {};
        (res.data || []).forEach(lp => {
          map[lp.lessonId] = {
            percent: Math.round(lp.completionPercent ?? lp.lessonCompletionPercent ?? 0),
            completed: lp.completed ?? false,
          };
          // Seed maxWatchedRef with the previously saved position for this lesson
          if (String(lp.lessonId) === String(lessonId) && lp.watchedSeconds) {
            maxWatchedRef.current = lp.watchedSeconds;
          }
        });
        setLessonProgress(map);
      })
      .catch(() => {});
  }, [studentId, courseId]);

  /* ── SSE stream — live updates pushed from the backend ── */
  useEffect(() => {
    if (!studentId || !courseId) return;

    const token = localStorage.getItem("token");
    const url = `http://localhost:8080/api/progress/stream?studentId=${studentId}&courseId=${courseId}&token=${token}`;
    const es = new EventSource(url);
    sseRef.current = es;

    es.addEventListener("progress", (e) => {
      try {
        const data = JSON.parse(e.data);
        setCourseProgress(data.courseCompletionPercent ?? 0);
        if (data.lessonId) {
          setLessonProgress(prev => ({
            ...prev,
            [data.lessonId]: {
              percent: Math.round(data.completionPercent ?? data.lessonCompletionPercent ?? 0),
              completed: data.lessonCompleted ?? data.completed ?? false,
            },
          }));
        }
      } catch { /* ignore bad data */ }
    });

    es.onerror = () => {
      // SSE will auto-reconnect; just log
      console.warn("SSE connection lost, will retry…");
    };

    return () => { es.close(); sseRef.current = null; };
  }, [studentId, courseId]);

  /* ── Video progress tick every 5s ── */
  const sendTick = useCallback(() => {
    const video = videoRef.current;
    if (!video || video.paused || !studentId) return;

    const currentTime = Math.floor(video.currentTime);
    // Update max watched position (only moves forward, never backward)
    if (currentTime > maxWatchedRef.current) {
      maxWatchedRef.current = currentTime;
    }

    api.post("/progress/update", {
      studentId,
      courseId,
      lessonId,
      watchedSeconds: maxWatchedRef.current, // Send the farthest point reached
      totalSeconds:   Math.floor(video.duration || 0),
    }).catch(() => {});
  }, [studentId, courseId, lessonId]);

  /* Start / stop tick interval when video plays / pauses */
  const startTicking = useCallback(() => {
    if (tickRef.current) return;
    sendTick(); // immediate first tick
    tickRef.current = setInterval(sendTick, TICK_INTERVAL);
  }, [sendTick]);

  const stopTicking = useCallback(() => {
    if (tickRef.current) {
      clearInterval(tickRef.current);
      tickRef.current = null;
    }
    sendTick(); // one final tick when pausing
  }, [sendTick]);

  /* ── Derived ── */
  const lessons      = course?.lessons ?? [];
  const currentIndex = lessons.findIndex(l => String(l.lessonId) === String(lessonId));
  const current      = lessons[currentIndex];
  const prev         = lessons[currentIndex - 1];
  const next         = lessons[currentIndex + 1];

  /* Clean up on lesson change */
  useEffect(() => {
    // Reset maxWatchedRef, but it will be updated from backend progress
    maxWatchedRef.current = 0;
    
    // Fetch the saved progress for this specific lesson
    if (studentId && courseId && lessonId) {
      api.get("/progress/lessons", { params: { studentId, courseId } })
        .then(res => {
          const lessonData = (res.data || []).find(lp => String(lp.lessonId) === String(lessonId));
          if (lessonData && lessonData.watchedSeconds) {
            maxWatchedRef.current = lessonData.watchedSeconds;
          }
        })
        .catch(() => {});
    }
    
    // Update video source when lesson changes
    const video = videoRef.current;
    if (video && current?.mediaUrl) {
      const newSrc = `http://localhost:8080${current.mediaUrl}`;
      if (video.src !== newSrc) {
        video.src = newSrc;
        video.load();
      }
    }
    return () => {
      if (tickRef.current) clearInterval(tickRef.current);
    };
  }, [lessonId, current?.mediaUrl, studentId, courseId]);

  const currentLessonProg   = lessonProgress[current?.lessonId] || { percent: 0, completed: false };
  const isCurrentCompleted  = currentLessonProg.completed;

  const handleMarkDone = () => {
    // Send a tick with full duration to mark 100%
    const video = videoRef.current;
    if (video && studentId) {
      const totalSec = Math.floor(video.duration || 0);
      maxWatchedRef.current = totalSec; // force full progress
      api.post("/progress/update", {
        studentId, courseId,
        lessonId: current.lessonId,
        watchedSeconds: totalSec,
        totalSeconds: totalSec,
      }).catch(() => {});
    }
    if (next) onLessonChange(next.lessonId);
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
    <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>

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
            <div className="emb-progress-fill" style={{ width: `${courseProgress}%` }} />
          </div>
          <span className="emb-progress-label">{courseProgress}% complete</span>
        </div>
      </div>

      {/* ── Player + Playlist ── */}
      <div className="lp-body">

        {/* ══ LEFT: Player ══ */}
        <div className="lp-player-col">
          <div className="lp-video-box">
            {current.mediaUrl ? (
              <>
                <video
                  ref={videoRef}
                  className="lp-video"
                  controls
                  controlsList="nodownload"
                  src={`http://localhost:8080${current.mediaUrl}`}
                  onLoadedMetadata={() => {
                    const video = videoRef.current;
                    if (!video) return;
                    
                    // Only restore position if there's meaningful saved progress
                    const lp = lessonProgress[current.lessonId];
                    if (lp && lp.percent > 0 && lp.percent < 90 && maxWatchedRef.current > 0) {
                      const saved = maxWatchedRef.current;
                      if (saved > 0 && saved < video.duration) {
                        video.currentTime = saved;
                      }
                    }
                  }}
                  onPlay={startTicking}
                  onPause={stopTicking}
                  onTimeUpdate={() => {
                    const video = videoRef.current;
                    if (!video) return;
                    const t = Math.floor(video.currentTime);
                    if (t > maxWatchedRef.current) maxWatchedRef.current = t;
                  }}
                  onSeeked={() => {
                    const video = videoRef.current;
                    if (!video) return;
                    
                    const t = Math.floor(video.currentTime);
                    
                    // Always update maxWatchedRef to the furthest point reached
                    if (t > maxWatchedRef.current) {
                      maxWatchedRef.current = t;
                    }
                    
                    if (!studentId) return;
                    api.post("/progress/update", {
                      studentId,
                      courseId,
                      lessonId: current.lessonId,
                      watchedSeconds: maxWatchedRef.current,
                      totalSeconds: Math.floor(video.duration || 0),
                    }).catch(() => {});
                  }}
                  onEnded={() => {
                    stopTicking();
                    if (studentId) {
                      const video = videoRef.current;
                      const totalSec = Math.floor(video?.duration || 0);
                      maxWatchedRef.current = totalSec;
                      api.post("/progress/update", {
                        studentId, courseId,
                        lessonId: current.lessonId,
                        watchedSeconds: totalSec,
                        totalSeconds: totalSec,
                      }).catch(() => {});
                    }
                  }}
                />
              </>
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
        
            <h2 className="lp-video-title">{current.title}</h2>

            <div className="lp-meta">
              {current.duration && (
                <span className="lp-chip">
                  <FiClock size={12} /> {formatMin(current.duration)}
                </span>
              )}
      
              {isCurrentCompleted && (
                <span className="lp-chip done">
                  <FiCheckCircle size={12} /> Completed
                </span>
              )}
              {!isCurrentCompleted && currentLessonProg.percent > 0 && (
                <span className="lp-chip">
                  {currentLessonProg.percent}% watched
                </span>
              )}            </div>

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
              <div className="lp-playlist-progress-fill" style={{ width: `${courseProgress}%` }} />
            </div>
            <p className="lp-playlist-progress-label">{courseProgress}% Complete</p>
          </div>

          <div className="lp-playlist-list">
            {lessons.map((lesson, i) => {
              const isActive = String(lesson.lessonId) === String(lessonId);
              const lp       = lessonProgress[lesson.lessonId] || { percent: 0, completed: false };
              const isDone   = lp.completed;

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
                    <div className="lp-pl-thumb-overlay">
                      <div className="lp-pl-play-icon">
                        <FiPlay size={10} fill={isActive ? "#b89c4d" : "#fff"} />
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
                      ) : lp.percent > 0 ? (
                        <span>{lp.percent}% Watched</span>
                      ) : (
                        <span>{isActive ? "In Progress" : "Not Started"}</span>
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