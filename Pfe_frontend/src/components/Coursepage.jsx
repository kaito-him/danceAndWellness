import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import api from "./services/api";           // ← use api, NOT axios
import "../styles/Courses.css";

const CoursePage = () => {
  const { courseId } = useParams();
  const navigate     = useNavigate();

  const token     = localStorage.getItem("token");
  const studentId = localStorage.getItem("userId");

  const [course,    setCourse]    = useState(null);
  const [loading,   setLoading]   = useState(true);
  const [enrolled,  setEnrolled]  = useState(false);
  const [openQuiz,  setOpenQuiz]  = useState(null);
  const [activeTab, setActiveTab] = useState("overview");

  useEffect(() => {
    const init = async () => {
      try {
        // Course is public — always fetch it
        const courseRes = await api.get(`/courses/${courseId}`);
        setCourse(courseRes.data);

        // Enrollment check only makes sense when logged in
        if (token && studentId) {
          const enrollRes = await api.get("/payment/is-enrolled", {
            params: { studentId, courseId },
          });
          setEnrolled(enrollRes.data.enrolled);
        }
      } catch (err) {
        console.error("Failed to load course:", err);
      } finally {
        setLoading(false);
      }
    };
    init();
  }, [courseId, token, studentId]);

  // ── Enroll handler ────────────────────────────────────────────────────
  const handleEnroll = () => {
    if (!course) return;

    // Not logged in → send to login
    if (!token) {
      localStorage.setItem("pendingCourseId", courseId);
      navigate("/login", { state: { from: "/student" } });
      return;
    }

    if (course.isFree || enrolled) {
      navigate("/student");          // go to dashboard, lessons accessible there
    } else {
      navigate(`/checkout/${courseId}`);
    }
  };

  // ── Helpers ───────────────────────────────────────────────────────────
  const levelLabel = {
    BEGINNER: "Beginner",
    INTERMEDIATE: "Intermediate",
    ADVANCED: "Advanced",
  };

  const formatMin = (min) => {
    if (!min) return "—";
    const h = Math.floor(min / 60), m = min % 60;
    return h > 0 ? `${h}h ${m}m` : `${m}m`;
  };

  if (loading) return (
    <div className="courses-root">
      <div className="courses-loading" style={{ minHeight: "100vh" }}>
        <div className="courses-spinner" />
        <p>Loading course…</p>
      </div>
    </div>
  );

  if (!course) return (
    <div className="courses-root">
      <div className="courses-empty" style={{ minHeight: "100vh" }}>
        Course not found.
        <button className="detail-back-btn" onClick={() => navigate("/courses")}>
          ← Back to Courses
        </button>
      </div>
    </div>
  );

  const lessons       = course.lessons ? [...course.lessons] : [];
  const quizzes       = course.quizzes ? [...course.quizzes] : [];
  const totalDuration = lessons.reduce((sum, l) => sum + (l.duration || 0), 0);

  const enrollBtnLabel = () => {
    if (!token)         return "Sign In to Enroll";
    if (course.isFree)  return "Start Learning — Free";
    if (enrolled)       return "Go to Lessons";
    return `Enroll — $${course.price?.toFixed(2)}`;
  };

  const priceLabel = () => {
    if (course.isFree) return <p className="detail-price free">Free</p>;
    if (enrolled)      return <p className="detail-price" style={{ color: "#4caf50" }}>Enrolled ✓</p>;
    return <p className="detail-price">${course.price?.toFixed(2)}</p>;
  };

  const handleLessonsTab = () => {
    if (!token) {
      localStorage.setItem("pendingCourseId", courseId);
      navigate("/login", { state: { from: "/student" } });
      return;
    }
    if (course.isFree || enrolled) navigate("/student");
    else navigate(`/checkout/${courseId}`);
  };

  return (
    <div className="courses-root">

      {/* ── Hero ── */}
      <section className="detail-hero">
        <div
          className="detail-hero-bg"
          style={course.thumbnailUrl
            ? { backgroundImage: `url(http://localhost:8080${course.thumbnailUrl})` }
            : {}}
        />
        <div className="detail-hero-overlay" />

        <div className="detail-hero-content">
          <button className="detail-back-btn" onClick={() => navigate("/courses")}>
            ← Back to Courses
          </button>

          <div className="detail-badges">
            <span className="detail-badge-cat">{course.category}</span>
            <span className="detail-badge-level">
              {levelLabel[course.level] || course.level}
            </span>
          </div>

          <h1 className="detail-title">{course.title}</h1>

          <div className="detail-meta">
            <div className="detail-instructor">
              <div className="detail-avatar">
                {course.instructor?.username?.charAt(0).toUpperCase() || "?"}
              </div>
              <div>
                <p className="detail-meta-label">Instructor</p>
                <p className="detail-meta-value">
                  {course.instructor?.username || "Unknown"}
                </p>
              </div>
            </div>
            <div className="detail-stat">
              <p className="detail-meta-label">Lessons</p>
              <p className="detail-meta-value">{lessons.length}</p>
            </div>
            <div className="detail-stat">
              <p className="detail-meta-label">Quizzes</p>
              <p className="detail-meta-value">{quizzes.length}</p>
            </div>
            <div className="detail-stat">
              <p className="detail-meta-label">Total Duration</p>
              <p className="detail-meta-value">{formatMin(totalDuration)}</p>
            </div>
          </div>

          {/* ── Enroll Card ── */}
          <div className="detail-enroll-card">
            {priceLabel()}
            <button className="detail-enroll-btn" onClick={handleEnroll}>
              {enrollBtnLabel()}
            </button>
            <p className="detail-enroll-note">
              {token ? "Full lifetime access · All devices" : "Sign in to get started"}
            </p>
          </div>
        </div>
      </section>

      {/* ── Content ── */}
      <main className="detail-main">
        <div className="detail-tabs">
          <button
            className={`detail-tab ${activeTab === "lessons" ? "active" : ""}`}
            onClick={handleLessonsTab}
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" strokeWidth="2">
              <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
            </svg>
            Lessons ({lessons.length})
          </button>

          <button
            className={`detail-tab ${activeTab === "quizzes" ? "active" : ""}`}
            onClick={() => setActiveTab("quizzes")}
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" strokeWidth="2">
              <circle cx="12" cy="12" r="10"/>
              <path d="M9.09 9a3 3 0 015.83 1c0 2-3 3-3 3M12 17h.01"/>
            </svg>
            Quizzes ({quizzes.length})
          </button>

          <button
            className={`detail-tab ${activeTab === "overview" ? "active" : ""}`}
            onClick={() => setActiveTab("overview")}
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" strokeWidth="2">
              <rect x="3" y="3" width="18" height="18" rx="2"/>
              <path d="M3 9h18M9 21V9"/>
            </svg>
            Overview
          </button>
        </div>

        {/* ── QUIZZES TAB ── */}
        {activeTab === "quizzes" && (
          <div className="detail-section">
            {quizzes.length === 0 ? (
              <div className="detail-empty">No quizzes added yet.</div>
            ) : (
              <ul className="detail-quiz-list">
                {quizzes.map((quiz) => (
                  <li key={quiz.quizId} className="detail-quiz-item">
                    <button
                      className={`detail-lesson-header ${openQuiz === quiz.quizId ? "open" : ""}`}
                      onClick={() =>
                        setOpenQuiz(openQuiz === quiz.quizId ? null : quiz.quizId)
                      }
                    >
                      <div className="detail-lesson-left">
                        <span className="detail-quiz-icon">
                          <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
                            stroke="currentColor" strokeWidth="2">
                            <circle cx="12" cy="12" r="10"/>
                            <path d="M9.09 9a3 3 0 015.83 1c0 2-3 3-3 3M12 17h.01"/>
                          </svg>
                        </span>
                        <span className="detail-lesson-title">{quiz.title}</span>
                      </div>
                      <div className="detail-lesson-right">
                        <span className="detail-lesson-dur">
                          {quiz.questions?.length ?? 0} questions
                        </span>
                        <svg className="detail-chevron" width="16" height="16"
                          viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                          <path d="M6 9l6 6 6-6"/>
                        </svg>
                      </div>
                    </button>

                    {openQuiz === quiz.quizId && (
                      <div className="detail-quiz-body">
                        {quiz.questions?.map((q, qi) => (
                          <div key={q.questionId} className="detail-question">
                            <div className="detail-q-header">
                              <span className="detail-q-num">Q{qi + 1}</span>
                              <p className="detail-q-text">{q.text}</p>
                            </div>
                            <div className={`detail-q-answer ${q.isCorrect ? "correct" : "incorrect"}`}>
                              {q.isCorrect ? (
                                <>
                                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                    stroke="currentColor" strokeWidth="2.5">
                                    <path d="M20 6L9 17l-5-5"/>
                                  </svg>
                                  Correct answer
                                </>
                              ) : (
                                <>
                                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                    stroke="currentColor" strokeWidth="2.5">
                                    <path d="M18 6L6 18M6 6l12 12"/>
                                  </svg>
                                  Incorrect
                                </>
                              )}
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </li>
                ))}
              </ul>
            )}
          </div>
        )}

        {/* ── OVERVIEW TAB ── */}
        {activeTab === "overview" && (
          <div className="detail-section detail-overview">
            <div className="detail-overview-grid">
              <div className="detail-overview-card">
                <div className="detail-ov-icon">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" strokeWidth="1.8">
                    <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                  </svg>
                </div>
                <p className="detail-ov-label">Total Lessons</p>
                <p className="detail-ov-value">{lessons.length}</p>
              </div>
              <div className="detail-overview-card">
                <div className="detail-ov-icon">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" strokeWidth="1.8">
                    <circle cx="12" cy="12" r="10"/>
                    <path d="M12 6v6l4 2"/>
                  </svg>
                </div>
                <p className="detail-ov-label">Total Duration</p>
                <p className="detail-ov-value">{formatMin(totalDuration)}</p>
              </div>
              <div className="detail-overview-card">
                <div className="detail-ov-icon">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" strokeWidth="1.8">
                    <circle cx="12" cy="12" r="10"/>
                    <path d="M9.09 9a3 3 0 015.83 1c0 2-3 3-3 3M12 17h.01"/>
                  </svg>
                </div>
                <p className="detail-ov-label">Quizzes</p>
                <p className="detail-ov-value">{quizzes.length}</p>
              </div>
              <div className="detail-overview-card">
                <div className="detail-ov-icon">
                  <svg width="22" height="22" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" strokeWidth="1.8">
                    <path d="M22 12h-4l-3 9L9 3l-3 9H2"/>
                  </svg>
                </div>
                <p className="detail-ov-label">Level</p>
                <p className="detail-ov-value">{levelLabel[course.level] || course.level}</p>
              </div>
            </div>

            <div className="detail-overview-info">
              <h3>About This Course</h3>
              <p>
                Explore <strong>{course.title}</strong> — a{" "}
                {levelLabel[course.level]?.toLowerCase()} level{" "}
                {course.category?.toLowerCase()} course taught by{" "}
                <strong>{course.instructor?.username || "a certified instructor"}</strong>.
                Dive into {lessons.length} structured lesson{lessons.length !== 1 ? "s" : ""} and
                test your knowledge with {quizzes.length} interactive quiz{quizzes.length !== 1 ? "zes" : ""}.
              </p>

              <button
                className="detail-enroll-btn"
                style={{ marginBottom: 20 }}
                onClick={handleEnroll}
              >
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none"
                  stroke="currentColor" strokeWidth="2.5" style={{ marginRight: 6 }}>
                  <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
                </svg>
                {!token
                  ? "Sign In to Access Lessons"
                  : enrolled || course.isFree
                  ? "Browse All Lessons"
                  : `Enroll — $${course.price?.toFixed(2)}`}
              </button>

              <div className="detail-overview-tags">
                <span>{course.category}</span>
                <span>{levelLabel[course.level]}</span>
                <span>{course.isFree ? "Free" : "Premium"}</span>
                <span>{course.status}</span>
                {enrolled && (
                  <span style={{ background: "#4caf50", color: "#fff" }}>Enrolled</span>
                )}
              </div>
            </div>
          </div>
        )}
      </main>

      <footer className="courses-footer">
        <span className="courses-logo-sm">Dance &amp; Wellness</span>
        <p>© {new Date().getFullYear()} Dance &amp; Wellness Platform. All rights reserved.</p>
      </footer>
    </div>
  );
};

export default CoursePage;