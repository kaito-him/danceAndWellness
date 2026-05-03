import React, { useEffect, useState, useMemo } from "react";
import { useSearchParams } from "react-router-dom";
import api from "../services/api";
import {
  FiArrowLeft, FiLayers, FiClock, FiHelpCircle,
  FiPlay, FiChevronRight, FiBookmark,
  FiTrendingUp, FiVideo, FiFileText, FiUsers, FiMessageCircle, FiX,
  FiChevronDown, FiChevronUp, FiBarChart2
} from "react-icons/fi";
import CourseComments from "../Student/CourseComments";
import "../../styles/AdminCoursePreview.css";
import "../../styles/InstructorPayment.css";

export default function AdminCoursePreview({ courseId, onBack, onStudentProfile }) {
  const [course, setCourse] = useState(null);
  const [loading, setLoading] = useState(true);
  const [searchParams, setSearchParams] = useSearchParams();
  const [categoryName, setCategoryName] = useState("");
  const [enrollmentCount, setEnrollmentCount] = useState(0);
  const [showComments, setShowComments] = useState(false);
  const [activeLesson, setActiveLesson] = useState(null); // For "watching"
  const [analyticsOpen, setAnalyticsOpen] = useState(false);
  const [curriculumTab, setCurriculumTab] = useState("lessons"); // "lessons" | "quizzes"
  const [rows, setRows] = useState([]);
  const [progressTarget, setProgressTarget] = useState(null);
  const [progressData, setProgressData] = useState(null);
  const [progressLoading, setProgressLoading] = useState(false);

  useEffect(() => {
    const init = async () => {
      setLoading(true);
      try {
        const [courseRes, countRes] = await Promise.all([
          api.get(`/courses/${courseId}`),
          api.get(`/courses/${courseId}/enrollments/count`)
        ]);
        
        setCourse(courseRes.data);
        setEnrollmentCount(countRes.data);

        if (courseRes.data.categoryId) {
          try {
            const catRes = await api.get(`/categories/${courseRes.data.categoryId}`);
            setCategoryName(catRes.data.name);
          } catch {
            setCategoryName("Category");
          }
        }
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    init();
  }, [courseId]);

  useEffect(() => {
    if (!analyticsOpen) return;
    api.get(`/instructor/payments/course/${courseId}/enrollments`)
      .then((res) => setRows(Array.isArray(res.data) ? res.data : []))
      .catch(() => setRows([]));
  }, [analyticsOpen, courseId]);

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

  const fmtDate = (raw) => {
    if (!raw) return "—";
    const d = Array.isArray(raw)
      ? new Date(raw[0], raw[1] - 1, raw[2], raw[3] || 0, raw[4] || 0)
      : new Date(raw);
    return d.toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" });
  };

  const returnTo = searchParams.get("returnTo");
  const section  = searchParams.get("section");
  const getBackText = () => {
    if (returnTo === "students") return "Back to Student Profile";
    if (returnTo === "instructors") return "Back to Instructor Profile";
    if (section === "archived") return "Back to Archived";
    return "Back to Catalog";
  };

  const levelLabel = { BEGINNER: "Beginner", INTERMEDIATE: "Intermediate", ADVANCED: "Advanced" };
  const formatMin = (min) => {
    if (!min) return "0m";
    const h = Math.floor(min / 60), m = min % 60;
    return h > 0 ? `${h}h ${m}m` : `${m}m`;
  };

  if (loading) return (
    <div className="aprev-loading">
      <div className="admin-spinner" /><p>Loading course preview...</p>
    </div>
  );

  if (!course) return (
    <div className="aprev-empty">
      <p>Course not found.</p>
      <button className="aprev-back-btn" onClick={onBack}>
        <FiArrowLeft size={14} /> Back to Catalog
      </button>
    </div>
  );

  const lessons = course.lessons || [];
  const quizzes = course.quizzes || [];
  const totalDuration = lessons.reduce((s, l) => s + (l.duration || 0), 0);
  const thumbUrl = course.thumbnailUrl ? `http://localhost:8080${course.thumbnailUrl}` : null;

  return (
    <div className="aprev-root">
      {/* Banner */}
      <div className="aprev-banner-outer">
        <button className="aprev-banner-back" onClick={onBack}>
          <FiArrowLeft size={14} /> {getBackText()}
        </button>
        
        <button 
          className="ebp-comments-trigger" 
          onClick={() => setShowComments(true)}
          style={{ top: '30px', right: '30px' }}
        >
          <FiMessageCircle size={16} />
          <span>Discussion</span>
        </button>

        <div
          className="aprev-banner-panoramic"
          style={thumbUrl ? { backgroundImage: `url(${thumbUrl})` } : {}}
        />
      </div>

      <div className="aprev-layout">
        <header className="aprev-header">
          <div className="aprev-breadcrumbs">
            <span>Admin</span>
            <FiChevronRight size={12} className="aprev-sep" />
            <span>Courses</span>
            <FiChevronRight size={12} className="aprev-sep" />
            <span className="aprev-current">{course.title}</span>
          </div>

          <h1 className="aprev-title">{course.title}</h1>

          <div className="aprev-meta">
            <div 
              className="aprev-meta-item clickable" 
              onClick={(e) => {
                e.stopPropagation();
                e.preventDefault();
                if (course.instructor?.id) {
                  setSearchParams({ section: "instructors", instructorId: course.instructor.id });
                }
              }}
              title="View Instructor Details"
            >
              <div className="aprev-avatar">
                {course.instructor?.photo ? (
                  <img src={`http://localhost:8080/api/files/${course.instructor.photo}`} alt={course.instructor.username} />
                ) : (
                  course.instructor?.username?.charAt(0).toUpperCase() || "I"
                )}
              </div>
              <div className="aprev-meta-info">
                <span className="aprev-meta-lbl">Instructor</span>
                <span className="aprev-meta-val">{course.instructor?.username}</span>
              </div>
            </div>

            <div className="aprev-meta-item">
              <div className="aprev-meta-icon"><FiLayers size={18} /></div>
              <div className="aprev-meta-info">
                <span className="aprev-meta-lbl">Level</span>
                <span className="aprev-meta-val">{levelLabel[course.level] || course.level}</span>
              </div>
            </div>

            {categoryName && (
              <div
                className="aprev-meta-item clickable"
                onClick={() => setSearchParams({ section: "feed", category: categoryName })}
                title={`Browse all "${categoryName}" courses`}
              >
                <div className="aprev-meta-icon"><FiBookmark size={18} /></div>
                <div className="aprev-meta-info">
                  <span className="aprev-meta-lbl">Category</span>
                  <span className="aprev-meta-val" style={{ color: 'var(--ad-gold)' }}>{categoryName}</span>
                </div>
              </div>
            )}

            <div className="aprev-meta-item">
              <div className="aprev-meta-icon"><FiUsers size={18} /></div>
              <div className="aprev-meta-info">
                <span className="aprev-meta-lbl">Students</span>
                <span className="aprev-meta-val">{enrollmentCount} Enrolled</span>
              </div>
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
                      No description provided for this course.
                    </p>
                  )}
                </section>

                <div className="aprev-stats">
                  <div className="aprev-stat-card">
                    <FiClock size={16} />
                    <div>
                      <span className="aprev-stat-val">{formatMin(totalDuration)}</span>
                      <span className="aprev-stat-lbl">Duration</span>
                    </div>
                  </div>
                  <div className="aprev-stat-card">
                    <FiPlay size={16} />
                    <div>
                      <span className="aprev-stat-val">{lessons.length}</span>
                      <span className="aprev-stat-lbl">Lessons</span>
                    </div>
                  </div>
                  <div className="aprev-stat-card">
                    <FiHelpCircle size={16} />
                    <div>
                      <span className="aprev-stat-val">{quizzes.length}</span>
                      <span className="aprev-stat-lbl">Quizzes</span>
                    </div>
                  </div>
                </div>

                <section className="aprev-section">
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
                    <h3 className="aprev-section-title" style={{ margin: 0 }}>Curriculum Structure</h3>
                    <div className="aprev-curr-tabs">
                      <button
                        className={`aprev-curr-tab ${curriculumTab === "lessons" ? "active" : ""}`}
                        onClick={() => setCurriculumTab("lessons")}
                      >
                        <FiPlay size={13} /> Lessons
                        <span className="aprev-curr-badge">{lessons.length}</span>
                      </button>
                      <button
                        className={`aprev-curr-tab ${curriculumTab === "quizzes" ? "active" : ""}`}
                        onClick={() => setCurriculumTab("quizzes")}
                      >
                        <FiHelpCircle size={13} /> Quizzes
                        <span className="aprev-curr-badge">{quizzes.length}</span>
                      </button>
                    </div>
                  </div>

                  {curriculumTab === "lessons" && (
                    <div className="aprev-curriculum">
                      {lessons.length === 0 && (
                        <p className="aprev-description" style={{ color: "#999", fontStyle: "italic" }}>No lessons yet.</p>
                      )}
                      {lessons.map((lesson, idx) => {
                        const isActive = activeLesson?.lessonId === lesson.lessonId;
                        return (
                          <div key={lesson.lessonId} className="aprev-lesson-group">
                            <div
                              className={`aprev-lesson-row ${isActive ? 'active' : ''}`}
                              onClick={() => setActiveLesson(isActive ? null : lesson)}
                              style={{ cursor: 'pointer' }}
                            >
                              <div className="aprev-lesson-idx">{idx + 1}</div>
                              <div className="aprev-lesson-info">
                                <span className="aprev-lesson-title">{lesson.title}</span>
                                <span className="aprev-lesson-meta">
                                  <FiVideo size={12} /> {lesson.duration}m
                                </span>
                              </div>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
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
                    </div>
                  )}

                  {curriculumTab === "quizzes" && (
                    <div className="aprev-curriculum">
                      {quizzes.length === 0 && (
                        <p className="aprev-description" style={{ color: "#999", fontStyle: "italic" }}>No quizzes for this course.</p>
                      )}
                      {quizzes.map((quiz, qIdx) => (
                        <div key={quiz.quizId ?? qIdx} className="aprev-quiz-card">
                          <div className="aprev-quiz-header">
                            <div className="aprev-lesson-idx"><FiFileText size={14} /></div>
                            <div className="aprev-lesson-info">
                              <span className="aprev-lesson-title">{quiz.title}</span>
                              <span className="aprev-lesson-meta">{quiz.questions?.length || 0} Questions</span>
                            </div>
                            <div className="aprev-lesson-tag" style={{ background: '#fdf3f2', color: '#c0392b' }}>Knowledge Check</div>
                          </div>
                          <div className="aprev-quiz-questions">
                            {(quiz.questions || []).map((qst, qstIdx) => (
                              <div key={qst.questionId ?? qstIdx} className="aprev-quiz-question">
                                <p className="aprev-quiz-q-text">
                                  <span className="aprev-quiz-q-num">Q{qstIdx + 1}.</span> {qst.text}
                                </p>
                                <ul className="aprev-quiz-options">
                                  {(qst.options || []).map((opt, oIdx) => (
                                    <li
                                      key={opt.optionId ?? oIdx}
                                      className={`aprev-quiz-option ${opt.isCorrect ? "correct" : ""}`}
                                    >
                                      <span className="aprev-quiz-opt-marker">
                                        {opt.isCorrect ? (
                                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                                        ) : (
                                          <span style={{ width: 14, height: 14, display: 'inline-block', borderRadius: '50%', border: '1.5px solid #ccc' }} />
                                        )}
                                      </span>
                                      {opt.text}
                                    </li>
                                  ))}
                                </ul>
                              </div>
                            ))}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
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
                      <div className="aprev-stat-card">
                        <FiBarChart2 size={16} />
                        <div>
                          <span className="aprev-stat-val">{Math.round(progressData.courseProgress?.completionPercent || 0)}%</span>
                          <span className="aprev-stat-lbl">Global Progress</span>
                        </div>
                      </div>
                      <div className="aprev-stat-card">
                        <FiPlay size={16} />
                        <div>
                          <span className="aprev-stat-val">{progressData.courseProgress?.completedLessons || 0}/{progressData.courseProgress?.totalLessons || 0}</span>
                          <span className="aprev-stat-lbl">Completed Lessons</span>
                        </div>
                      </div>
                      <div className="aprev-stat-card">
                        <FiClock size={16} />
                        <div>
                          <span className="aprev-stat-val">{fmtDate(progressData.courseProgress?.lastUpdated)}</span>
                          <span className="aprev-stat-lbl">Last Updated</span>
                        </div>
                      </div>
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
                <h3 className="aprev-section-title">All Enrollments</h3>
                {rows.length === 0 ? (
                  <p className="aprev-description">No enrollments for this course yet.</p>
                ) : (
                  <div className="ip-table-wrap">
                    <table className="ip-table">
                      <thead>
                        <tr><th>Student</th><th>Date Enrolled</th><th>Type</th><th>Progress</th></tr>
                      </thead>
                      <tbody>
                        {rows.map((r) => (
                          <tr key={r.enrollmentId}>
                            <td>
                              <div 
                                style={{ 
                                  fontWeight: 600, 
                                  cursor: 'pointer', 
                                  color: 'var(--ad-gold-dark)',
                                  textDecoration: 'underline transparent'
                                }} 
                                onClick={() => onStudentProfile(r.studentId)}
                                className="student-name-link"
                              >
                                {r.studentName || "—"}
                              </div>
                              <div style={{ fontSize: 11, opacity: 0.7 }}>{r.studentEmail}</div>
                            </td>
                            <td>{fmtDate(r.enrolledAt)}</td>
                            <td>{r.enrollmentType}</td>
                            <td>
                              <button
                                className="aprev-progress-btn"
                                onClick={() => openProgress(r)}
                                style={{
                                  padding: '5px 12px',
                                  fontSize: '11px',
                                  borderRadius: '6px',
                                  border: '1px solid #ddd',
                                  background: '#fff',
                                  cursor: 'pointer'
                                }}
                              >
                                Show Progress
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </section>
            )}
          </div>

          <aside className="aprev-sidebar">
            <div className="aprev-status-card">
              <div className="aprev-status-header">
                <span className="aprev-status-price">
                  {course.isFree ? "Free Catalog" : `$${course.price?.toFixed(2)}`}
                </span>
                <span className="aprev-status-label">{enrollmentCount} total enrollments</span>
              </div>
              <div className="aprev-admin-controls" style={{ display: 'flex', justifyContent: 'center', padding: '10px 0' }}>
                <button 
                  className="ebp-enroll-cta" 
                  onClick={() => setAnalyticsOpen(!analyticsOpen)}
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
                    cursor: 'pointer'
                  }}
                >
                  <FiBarChart2 size={20} />
                  {analyticsOpen ? "Back to Details" : "View Course Analytics"}
                </button>
              </div>
              <div className="aprev-includes">
                <h4>Admin Insights:</h4>
                <ul className="aprev-includes-list-alt">
                  <li><FiUsers size={14} /> {enrollmentCount} active students</li>
                  <li><FiMessageCircle size={14} /> Review discussions</li>
                  <li><FiVideo size={14} /> Audit video content</li>
                </ul>
              </div>
            </div>
          </aside>
        </div>
      </div>

      {showComments && (
        <CourseComments
          courseId={courseId}
          onClose={() => setShowComments(false)}
        />
      )}
    </div>
  );
}
