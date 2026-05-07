import React, { useEffect, useMemo, useState } from "react";
import api from "../services/api";
import {
  FiArrowLeft, FiLayers, FiClock, FiHelpCircle, FiPlay, FiUsers, FiBarChart2,
  FiEdit3, FiVideo, FiFileText, FiChevronDown, FiChevronUp, FiMessageCircle,
  FiCheckCircle, FiXCircle, FiAward
} from "react-icons/fi";
import CourseDetails from "./CourseDetails";
import CourseComments from "../Student/CourseComments";
import "../../styles/AdminCoursePreview.css";
import "../../styles/Courses.css";
import "../../styles/InstructorPayment.css";

const fmtDate = (raw) => {
  if (!raw) return "—";
  const d = Array.isArray(raw)
    ? new Date(raw[0], raw[1] - 1, raw[2], raw[3] || 0, raw[4] || 0)
    : new Date(raw);
  return d.toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" });
};

export default function InstructorCoursePreview({
  courseId,
  instructorId,
  instructor,
  onBack,
  onStudentProfile,
  openCommentsOnLoadToken,
}) {
  const [course, setCourse] = useState(null);
  const [loading, setLoading] = useState(true);
  const [categoryName, setCategoryName] = useState("");
  const [enrollmentCount, setEnrollmentCount] = useState(0);
  const [analyticsOpen, setAnalyticsOpen] = useState(false);
  const [analyticsTab, setAnalyticsTab] = useState("enrollments"); // "enrollments" | "quizzes"
  const [rows, setRows] = useState([]);
  const [activeLesson, setActiveLesson] = useState(null);
  const [showEditForm, setShowEditForm] = useState(false);
  const [showComments, setShowComments] = useState(false);

  // Quiz analytics state
  const [quizAttempts, setQuizAttempts] = useState([]);
  const [quizAttemptsLoading, setQuizAttemptsLoading] = useState(false);
  const [selectedQuizId, setSelectedQuizId] = useState(null);
  const [expandedAttempt, setExpandedAttempt] = useState(null);

  useEffect(() => {
    if (openCommentsOnLoadToken) {
      setShowComments(true);
    }
  }, [openCommentsOnLoadToken]);
  const [progressTarget, setProgressTarget] = useState(null);
  const [progressData, setProgressData] = useState(null);
  const [progressLoading, setProgressLoading] = useState(false);

  useEffect(() => {
    const init = async () => {
      setLoading(true);
      try {
        const [courseRes, countRes] = await Promise.all([
          api.get(`/courses/${courseId}`),
          api.get(`/courses/${courseId}/enrollments/count`),
        ]);
        setCourse(courseRes.data);
        setEnrollmentCount(countRes.data || 0);

        if (courseRes.data?.categoryId) {
          try {
            const catRes = await api.get(`/categories/${courseRes.data.categoryId}`);
            setCategoryName(catRes.data?.name || "Category");
          } catch {
            setCategoryName("Category");
          }
        }
      } finally {
        setLoading(false);
      }
    };
    init();
  }, [courseId]);

  useEffect(() => {
    if (!analyticsOpen || !instructorId) return;
    api.get(`/instructor/payments/${instructorId}/enrollments`)
      .then((res) => setRows(Array.isArray(res.data) ? res.data : []))
      .catch(() => setRows([]));
  }, [analyticsOpen, instructorId]);

  useEffect(() => {
    if (!analyticsOpen || analyticsTab !== "quizzes") return;
    setQuizAttemptsLoading(true);
    api.get("/quizzes/instructor/attempts", { params: { courseId } })
      .then((res) => {
        setQuizAttempts(Array.isArray(res.data) ? res.data : []);
      })
      .catch(() => setQuizAttempts([]))
      .finally(() => setQuizAttemptsLoading(false));
  }, [analyticsOpen, analyticsTab, courseId]);

  const courseRows = useMemo(
    () => rows.filter((r) => r.courseId === courseId),
    [rows, courseId]
  );

  const openProgress = async (row) => {
    setProgressTarget(row);
    setProgressLoading(true);
    try {
      const res = await api.get("/progress/instructor/student-course", {
        params: { studentId: row.studentId, courseId },
      });
      setProgressData(res.data);
    } catch {
      setProgressData(null);
    } finally {
      setProgressLoading(false);
    }
  };

  const levelLabel = { BEGINNER: "Beginner", INTERMEDIATE: "Intermediate", ADVANCED: "Advanced" };
  const formatMin = (min) => {
    if (!min) return "0m";
    const h = Math.floor(min / 60), m = min % 60;
    return h > 0 ? `${h}h ${m}m` : `${m}m`;
  };

  if (loading) {
    return <div className="aprev-loading"><div className="admin-spinner" /><p>Loading course preview...</p></div>;
  }
  if (!course) {
    return <div className="aprev-empty"><p>Course not found.</p></div>;
  }

  const lessons = course.lessons || [];
  const quizzes = course.quizzes || [];
  const totalDuration = lessons.reduce((s, l) => s + (l.duration || 0), 0);
  const thumbUrl = course.thumbnailUrl ? `http://localhost:8080${course.thumbnailUrl}` : null;

  return (
    <div className="aprev-root">
      <div className="aprev-banner-outer">
        <button className="aprev-banner-back" onClick={onBack}>
          <FiArrowLeft size={14} /> Back to Courses
        </button>
        <button
          className="ebp-comments-trigger"
          onClick={() => setShowComments(true)}
          style={{ top: "30px", right: "30px" }}
        >
          <FiMessageCircle size={16} />
          <span>Discussion</span>
        </button>
        <div className="aprev-banner-panoramic" style={thumbUrl ? { backgroundImage: `url(${thumbUrl})` } : {}} />
      </div>

      <div className="aprev-layout">
        <header className="aprev-header">
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 12 }}>
            <h1 className="aprev-title" style={{ marginBottom: 0 }}>{course.title}</h1>
            <button
              className="cd-edit-toggle"
              onClick={() => setShowEditForm(true)}
              title="Edit course"
            >
              <FiEdit3 size={16} />
            </button>
          </div>
          <div style={{ height: 16 }} />
          <div className="aprev-meta">
            <div className="aprev-meta-item">
              <div className="aprev-meta-icon"><FiLayers size={18} /></div>
              <div className="aprev-meta-info"><span className="aprev-meta-lbl">Level</span><span className="aprev-meta-val">{levelLabel[course.level] || course.level}</span></div>
            </div>
            <div className="aprev-meta-item">
              <div className="aprev-meta-icon"><FiUsers size={18} /></div>
              <div className="aprev-meta-info"><span className="aprev-meta-lbl">Students</span><span className="aprev-meta-val">{enrollmentCount} Enrolled</span></div>
            </div>
          </div>
        </header>

        <div className="aprev-main">
          <div className="aprev-content">
            {!analyticsOpen ? (
              <>
                <section className="aprev-section">
                  <h3 className="aprev-section-title">About This Course</h3>
                  {course.description ? (
                    <p className="aprev-description">{course.description}</p>
                  ) : (
                    <p className="aprev-description" style={{ color: "#999", fontStyle: "italic" }}>
                      No description provided. Click the edit icon to add one.
                    </p>
                  )}
                  <p className="aprev-description" style={{ marginTop: 10 }}>
                    Category: <strong>{categoryName || "—"}</strong>
                  </p>
                </section>
                <div className="aprev-stats">
                  <div className="aprev-stat-card"><FiClock size={16} /><div><span className="aprev-stat-val">{formatMin(totalDuration)}</span><span className="aprev-stat-lbl">Duration</span></div></div>
                  <div className="aprev-stat-card"><FiPlay size={16} /><div><span className="aprev-stat-val">{lessons.length}</span><span className="aprev-stat-lbl">Lessons</span></div></div>
                  <div className="aprev-stat-card"><FiHelpCircle size={16} /><div><span className="aprev-stat-val">{quizzes.length}</span><span className="aprev-stat-lbl">Quizzes</span></div></div>
                </div>
                <section className="aprev-section">
                  <h3 className="aprev-section-title">Lessons</h3>
                  <div className="aprev-curriculum">
                    {lessons.map((lesson, idx) => {
                      const isActive = activeLesson?.lessonId === lesson.lessonId;
                      return (
                        <div key={lesson.lessonId || idx} className="aprev-lesson-group">
                          <div
                            className={`aprev-lesson-row ${isActive ? "active" : ""}`}
                            onClick={() => setActiveLesson(isActive ? null : lesson)}
                            style={{ cursor: "pointer" }}
                          >
                            <div className="aprev-lesson-idx">{idx + 1}</div>
                            <div className="aprev-lesson-info">
                              <span className="aprev-lesson-title">{lesson.title}</span>
                              <span className="aprev-lesson-meta">
                                <FiVideo size={12} /> {lesson.duration || 0}m
                              </span>
                            </div>
                            <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                              <div className="aprev-lesson-tag">{isActive ? "Watching" : "Click to Watch"}</div>
                              {isActive ? <FiChevronUp size={18} /> : <FiChevronDown size={18} />}
                            </div>
                          </div>
                          {isActive && (
                            <div className="aprev-inline-player">
                              {lesson.mediaUrl ? (
                                <video
                                  src={`http://localhost:8080${lesson.mediaUrl}`}
                                  controls
                                  autoPlay
                                  className="aprev-inline-video"
                                />
                              ) : (
                                <div className="aprev-video-placeholder">No video source found</div>
                              )}
                            </div>
                          )}
                        </div>
                      );
                    })}
                    {quizzes.map((quiz, idx) => (
                      <div key={quiz.quizId || idx} className="aprev-lesson-row quiz">
                        <div className="aprev-lesson-idx"><FiFileText size={14} /></div>
                        <div className="aprev-lesson-info">
                          <span className="aprev-lesson-title">{quiz.title}</span>
                          <span className="aprev-lesson-meta">{quiz.questions?.length || 0} Questions</span>
                        </div>
                        <div className="aprev-lesson-tag quiz">Knowledge Check</div>
                      </div>
                    ))}
                  </div>
                </section>
              </>
            ) : progressTarget ? (
              <section className="aprev-section">
                <h3 className="aprev-section-title">
                  {`${progressData?.studentUsername || progressTarget.studentName}'s progress for ${progressData?.courseTitle || course.title}`}
                </h3>
                {progressLoading ? (
                  <p className="aprev-description">Loading progress...</p>
                ) : !progressData ? (
                  <p className="aprev-description">Unable to load progress.</p>
                ) : (
                  <>
                    <div className="aprev-stats">
                      <div className="aprev-stat-card"><FiBarChart2 size={16} /><div><span className="aprev-stat-val">{Math.round(progressData.courseProgress?.completionPercent || 0)}%</span><span className="aprev-stat-lbl">Global Progress</span></div></div>
                      <div className="aprev-stat-card"><FiPlay size={16} /><div><span className="aprev-stat-val">{progressData.courseProgress?.completedLessons || 0}/{progressData.courseProgress?.totalLessons || 0}</span><span className="aprev-stat-lbl">Completed Lessons</span></div></div>
                      <div className="aprev-stat-card"><FiClock size={16} /><div><span className="aprev-stat-val">{fmtDate(progressData.courseProgress?.lastUpdated)}</span><span className="aprev-stat-lbl">Last Updated</span></div></div>
                    </div>
                    <div className="ip-table-wrap" style={{ marginTop: 16 }}>
                      <table className="ip-table">
                        <thead>
                          <tr><th>Lesson</th><th>Progress</th><th>Last Updated</th></tr>
                        </thead>
                        <tbody>
                          {(progressData.lessonProgress || []).map((lp) => (
                            <tr key={lp.lessonId}>
                              <td>{lp.lessonTitle || "Lesson"}</td>
                              <td>{Math.round(lp.completionPercent || 0)}%</td>
                              <td>{fmtDate(lp.lastUpdated)}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                    <button
                      className="aprev-banner-back"
                      style={{ position: "static", marginTop: 16, color: "#333", borderColor: "#ddd", background: "#fff" }}
                      onClick={() => { setProgressTarget(null); setProgressData(null); }}
                    >
                      Back to Enrollments
                    </button>
                  </>
                )}
              </section>
            ) : (
              <section className="aprev-section">
                {/* ── Analytics tabs ── */}
                <div className="cd-tabs" style={{ marginBottom: 16 }}>
                  <button
                    className={`cd-tab ${analyticsTab === "enrollments" ? "active" : ""}`}
                    onClick={() => setAnalyticsTab("enrollments")}
                  >
                    <FiUsers size={13} style={{ marginRight: 5 }} />Enrollments
                    <span className="cd-tab-badge">{courseRows.length}</span>
                  </button>
                  <button
                    className={`cd-tab ${analyticsTab === "quizzes" ? "active" : ""}`}
                    onClick={() => setAnalyticsTab("quizzes")}
                  >
                    <FiHelpCircle size={13} style={{ marginRight: 5 }} />Quiz Results
                    <span className="cd-tab-badge">{quizAttempts.length}</span>
                  </button>
                </div>

                {/* ── Enrollments tab ── */}
                {analyticsTab === "enrollments" && (
                  <>
                    <h3 className="aprev-section-title">All Enrollments</h3>
                    {courseRows.length === 0 ? (
                      <p className="aprev-description">No enrollments for this course yet.</p>
                    ) : (
                      <div className="ip-table-wrap">
                        <table className="ip-table">
                          <thead>
                            <tr><th>Student</th><th>Date Enrolled</th><th>Progress</th></tr>
                          </thead>
                          <tbody>
                            {courseRows.map((r) => (
                              <tr key={r.enrollmentId}>
                                <td>{r.studentName || "—"}</td>
                                <td>{fmtDate(r.enrolledAt)}</td>
                                <td>
                                  <button className="aprev-progress-btn" onClick={() => openProgress(r)}>
                                    Show Progress
                                  </button>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    )}
                  </>
                )}

                {/* ── Quiz Results tab ── */}
                {analyticsTab === "quizzes" && (
                  <>
                    <h3 className="aprev-section-title">Quiz Performance</h3>

                    {/* Quiz filter chips */}
                    {quizzes.length > 0 && (
                      <div style={{ display: "flex", gap: 8, flexWrap: "wrap", marginBottom: 16 }}>
                        <button
                          className={`cd-tier-chip ${selectedQuizId === null ? "active" : ""}`}
                          onClick={() => setSelectedQuizId(null)}
                        >
                          All Quizzes
                        </button>
                        {quizzes.map((q) => (
                          <button
                            key={q.quizId}
                            className={`cd-tier-chip ${selectedQuizId === q.quizId ? "active" : ""}`}
                            onClick={() => setSelectedQuizId(q.quizId)}
                          >
                            {q.title}
                          </button>
                        ))}
                      </div>
                    )}

                    {quizAttemptsLoading ? (
                      <p className="aprev-description">Loading quiz results...</p>
                    ) : quizAttempts.length === 0 ? (
                      <p className="aprev-description">No quiz attempts yet.</p>
                    ) : (() => {
                      const filtered = selectedQuizId
                        ? quizAttempts.filter((a) => a.quizId === selectedQuizId)
                        : quizAttempts;
                      const quizMap = Object.fromEntries(quizzes.map((q) => [q.quizId, q]));

                      return (
                        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                          {filtered.map((attempt) => {
                            const quiz = quizMap[attempt.quizId];
                            const isExpanded = expandedAttempt === attempt.id;
                            const scoreColor = attempt.score >= 80 ? "#2e7d32" : attempt.score >= 50 ? "#e65100" : "#c62828";

                            return (
                              <div key={attempt.id} style={{ border: "1.5px solid #e8e4d8", borderRadius: 10, overflow: "hidden" }}>
                                {/* Attempt header row */}
                                <div
                                  style={{ display: "flex", alignItems: "center", gap: 12, padding: "12px 16px", cursor: "pointer", background: "#fdfcf9" }}
                                  onClick={() => setExpandedAttempt(isExpanded ? null : attempt.id)}
                                >
                                  <FiAward size={16} color={scoreColor} style={{ flexShrink: 0 }} />
                                  <div style={{ flex: 1, minWidth: 0 }}>
                                    <div style={{ fontWeight: 600, fontSize: 14, color: "#1a1a1a" }}>
                                      {attempt.studentUsername || attempt.studentId}
                                    </div>
                                    <div style={{ fontSize: 12, color: "#888", marginTop: 2 }}>
                                      {quiz?.title || "Quiz"} · {fmtDate(attempt.takenAt)}
                                    </div>
                                  </div>
                                  <div style={{ display: "flex", alignItems: "center", gap: 10, flexShrink: 0 }}>
                                    <span style={{ fontWeight: 700, fontSize: 16, color: scoreColor }}>{attempt.score}%</span>
                                    <span style={{ fontSize: 12, color: "#888" }}>{attempt.correctCount}/{attempt.totalQuestions} correct</span>
                                    {isExpanded ? <FiChevronUp size={16} color="#888" /> : <FiChevronDown size={16} color="#888" />}
                                  </div>
                                </div>

                                {/* Expanded: per-question breakdown */}
                                {isExpanded && quiz && (
                                  <div style={{ padding: "0 16px 16px", background: "#fff", borderTop: "1px solid #f0ede5" }}>
                                    {([...(quiz.questions || [])]).map((q, qIdx) => {
                                      const wasCorrect = attempt.questionResults?.[q.questionId];
                                      const chosenIndices = attempt.answers?.[q.questionId] || [];

                                      return (
                                        <div key={q.questionId} style={{ marginTop: 14, paddingTop: 14, borderTop: qIdx > 0 ? "1px solid #f0ede5" : "none" }}>
                                          <div style={{ display: "flex", gap: 8, alignItems: "flex-start", marginBottom: 8 }}>
                                            {wasCorrect
                                              ? <FiCheckCircle size={15} color="#2e7d32" style={{ marginTop: 2, flexShrink: 0 }} />
                                              : <FiXCircle size={15} color="#c62828" style={{ marginTop: 2, flexShrink: 0 }} />
                                            }
                                            <span style={{ fontSize: 13, fontWeight: 500, color: "#1a1a1a" }}>
                                              Q{qIdx + 1}: {q.text}
                                            </span>
                                          </div>
                                          <div style={{ paddingLeft: 24, display: "flex", flexDirection: "column", gap: 5 }}>
                                            {(q.options || []).map((opt, oIdx) => {
                                              const isChosen = chosenIndices.includes(oIdx);
                                              const isCorrectOpt = opt.isCorrect;
                                              let bg = "transparent", color = "#555", border = "1px solid #e8e4d8";
                                              if (isCorrectOpt) { bg = "#e8f5e9"; color = "#2e7d32"; border = "1px solid #a5d6a7"; }
                                              if (isChosen && !isCorrectOpt) { bg = "#ffebee"; color = "#c62828"; border = "1px solid #ef9a9a"; }

                                              return (
                                                <div key={oIdx} style={{ display: "flex", alignItems: "center", gap: 8, padding: "5px 10px", borderRadius: 6, background: bg, border, fontSize: 13, color }}>
                                                  <span style={{ fontSize: 11 }}>{isChosen ? "●" : "○"}</span>
                                                  <span style={{ flex: 1 }}>{opt.text}</span>
                                                  {isCorrectOpt && <span style={{ fontSize: 11, fontWeight: 600, color: "#2e7d32" }}>✓ Correct</span>}
                                                  {isChosen && !isCorrectOpt && <span style={{ fontSize: 11, fontWeight: 600, color: "#c62828" }}>✗ Wrong</span>}
                                                </div>
                                              );
                                            })}
                                          </div>
                                        </div>
                                      );
                                    })}
                                  </div>
                                )}
                              </div>
                            );
                          })}
                        </div>
                      );
                    })()}
                  </>
                )}
              </section>
            )}
          </div>

          <aside className="aprev-sidebar">
            <div className="aprev-status-card">
              <div className="aprev-status-header">
                <span className="aprev-status-price">{course.isFree ? "Free" : `$${course.price?.toFixed(2)}`}</span>
                <span className="aprev-status-label">{enrollmentCount} enrollments</span>
              </div>
              <button
                className="aprev-analytics-btn"
                onClick={() => setAnalyticsOpen((v) => !v)}
                style={{
                  width: '100%',
                  height: '52px',
                  fontSize: '16px',
                  fontWeight: '700',
                  background: 'linear-gradient(135deg, #D4AF37 0%, #B8860B 100%)',
                  color: '#fff',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '10px',
                  border: 'none',
                  borderRadius: '12px',
                  boxShadow: '0 4px 15px rgba(212, 175, 55, 0.3)',
                  transition: 'all 0.3s ease',
                  cursor: 'pointer',
                }}
              >
                <FiBarChart2 size={20} />
                {analyticsOpen ? "Back to Details" : "View Analytics"}
              </button>
            </div>
          </aside>
        </div>
      </div>
      {showEditForm && (
        <CourseDetails
          course={course}
          instructor={instructor}
          onClose={() => setShowEditForm(false)}
          onSaved={(updated) => {
            setCourse(updated);
            setShowEditForm(false);
          }}
        />
      )}
      {showComments && (
        <CourseComments
          courseId={courseId}
          onClose={() => setShowComments(false)}
          onAuthorClick={(author) => {
            if (author?.authorRole === "STUDENT" && author?.authorId) {
              onStudentProfile?.(author.authorId);
              setShowComments(false);
            }
          }}
        />
      )}
    </div>
  );
}
