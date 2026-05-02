import React, { useState } from "react";
import "../../styles/AdminCourseDetail.css";

const BASE = "http://localhost:8080";
const toSrc = (url) => (url ? (url.startsWith("/api") ? `${BASE}${url}` : url) : null);

export default function AdminCourseDetail({ course, onClose, onArchive }) {
  const [activeLesson, setActiveLesson] = useState(0);
  const [activeTab,    setActiveTab]    = useState("lessons"); // "lessons" | "quizzes"

  const thumbSrc  = toSrc(course.thumbnailUrl);
  const lessons   = course.lessons  ?? [];
  const quizzes   = course.quizzes  ?? [];
  const currentLesson = lessons[activeLesson];

  const handleArchive = () => { onArchive(course.courseId); onClose(); };

  return (
    <div className="acd-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="acd-modal">

        {/* ── Header ── */}
        <div className="acd-head">
          <div className="acd-head-info">
            <h2 className="acd-title">{course.title}</h2>
            <div className="acd-tags">
              <span className="acd-tag acd-tag-cat">{course.category}</span>
              <span className="acd-tag acd-tag-lvl">{course.level}</span>
              <span className={`acd-tag ${course.isFree ? "acd-tag-free" : "acd-tag-paid"}`}>
                {course.isFree ? "Free" : `$${course.price}`}
              </span>
            </div>
          </div>
          <button className="acd-close" onClick={onClose}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" strokeWidth="2" strokeLinecap="round">
              <line x1="18" y1="6" x2="6" y2="18"/>
              <line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>

        {/* ── Body ── */}
        <div className="acd-body">

          {/* Thumbnail */}
          {thumbSrc && (
            <div className="acd-thumb-wrap">
              <img src={thumbSrc} alt="thumbnail" className="acd-thumb" />
            </div>
          )}

          {/* Course meta row */}
          <div className="acd-meta-row">
            <div className="acd-meta-item">
              <span className="acd-meta-label">Lessons</span>
              <span className="acd-meta-value">{lessons.length}</span>
            </div>
            <div className="acd-meta-item">
              <span className="acd-meta-label">Quizzes</span>
              <span className="acd-meta-value">{quizzes.length}</span>
            </div>
            <div className="acd-meta-item">
              <span className="acd-meta-label">Total Duration</span>
              <span className="acd-meta-value">
                {lessons.reduce((sum, l) => sum + (parseInt(l.duration) || 0), 0)} min
              </span>
            </div>
            <div className="acd-meta-item">
              <span className="acd-meta-label">Price</span>
              <span className="acd-meta-value">
                {course.isFree ? "Free" : `$${course.price}`}
              </span>
            </div>
          </div>

          {/* Tab switcher */}
          <div className="acd-tabs">
            <button
              className={`acd-tab ${activeTab === "lessons" ? "active" : ""}`}
              onClick={() => setActiveTab("lessons")}>
              Lessons ({lessons.length})
            </button>
            <button
              className={`acd-tab ${activeTab === "quizzes" ? "active" : ""}`}
              onClick={() => setActiveTab("quizzes")}>
              Quizzes ({quizzes.length})
            </button>
          </div>

          {/* ── Lessons tab ── */}
          {activeTab === "lessons" && (
            <div className="acd-lessons-layout">

              {/* Sidebar list */}
              <div className="acd-lesson-list">
                {lessons.length === 0 ? (
                  <p className="acd-empty-tab">No lessons added.</p>
                ) : (
                  lessons.map((lesson, idx) => (
                    <button
                      key={lesson.lessonId ?? idx}
                      className={`acd-lesson-item ${activeLesson === idx ? "active" : ""}`}
                      onClick={() => setActiveLesson(idx)}>
                      <span className="acd-lesson-idx">{idx + 1}</span>
                      <div className="acd-lesson-item-info">
                        <span className="acd-lesson-item-title">{lesson.title}</span>
                        <span className="acd-lesson-item-dur">{lesson.duration} min</span>
                      </div>
                    </button>
                  ))
                )}
              </div>

              {/* Video player */}
              {currentLesson && (
                <div className="acd-player">
                  {toSrc(currentLesson.mediaUrl) ? (
                    <video
                      key={currentLesson.lessonId}
                      src={toSrc(currentLesson.mediaUrl)}
                      className="acd-video"
                      controls
                    />
                  ) : (
                    <div className="acd-video-empty">
                      <svg width="36" height="36" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" strokeWidth="1.5" strokeLinecap="round">
                        <polygon points="23 7 16 12 23 17 23 7"/>
                        <rect x="1" y="5" width="15" height="14" rx="2"/>
                      </svg>
                      <span>No video available</span>
                    </div>
                  )}
                  <div className="acd-player-info">
                    <span className="acd-player-title">{currentLesson.title}</span>
                    <span className="acd-player-dur">{currentLesson.duration} min</span>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* ── Quizzes tab ── */}
          {activeTab === "quizzes" && (
            <div className="acd-quizzes">
              {quizzes.length === 0 ? (
                <p className="acd-empty-tab">No quizzes added.</p>
              ) : (
                quizzes.map((quiz, qi) => (
                  <div className="acd-quiz-card" key={quiz.quizId ?? qi}>
                    <div className="acd-quiz-head">
                      <span className="acd-quiz-num">Quiz {qi + 1}</span>
                      <span className="acd-quiz-title">{quiz.title}</span>
                      <span className="acd-quiz-count">
                        {quiz.questions?.length ?? 0} question{quiz.questions?.length !== 1 ? "s" : ""}
                      </span>
                    </div>

                    {quiz.questions?.length > 0 && (
                      <div className="acd-questions">
                        {quiz.questions.map((q, qi2) => (
                          <div className="acd-question" key={q.questionId ?? qi2}>
                            <span className="acd-q-num">Q{qi2 + 1}</span>
                            <div className="acd-q-body">
                              <p className="acd-q-text">{q.text}</p>
                              <span className={`acd-q-correct ${q.correct ? "yes" : "no"}`}>
                                {q.correct ? "✓ Correct answer" : "✗ Incorrect answer"}
                              </span>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                ))
              )}
            </div>
          )}
        </div>

        {/* ── Footer ── */}
        <div className="acd-footer">
          <button className="acd-btn-cancel" onClick={onClose}>Close</button>
          <button className="acd-btn-archive" onClick={handleArchive}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" strokeWidth="2" strokeLinecap="round">
              <polyline points="21 8 21 21 3 21 3 8"/>
              <rect x="1" y="3" width="22" height="5"/>
              <line x1="10" y1="12" x2="14" y2="12"/>
            </svg>
            Archive
          </button>
        </div>

      </div>
    </div>
  );
}