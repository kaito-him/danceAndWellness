import React, { useEffect, useState } from "react";
import api from "../../components/services/api";
import { useNavigate } from "react-router-dom";
import { FiArrowLeft, FiLayers, FiClock, FiHelpCircle, FiGrid, FiLock } from "react-icons/fi";
import "../../styles/Courses.css";

export default function EmbeddedCoursePage({ courseId, onBack, onBrowseLessons }) {
  const navigate  = useNavigate();
  const studentId = localStorage.getItem("userId");

  const [course,    setCourse]    = useState(null);
  const [loading,   setLoading]   = useState(true);
  const [enrolled,  setEnrolled]  = useState(false);
  const [enrolling, setEnrolling] = useState(false);
  const [openQuiz,  setOpenQuiz]  = useState(null);
  const [activeTab, setActiveTab] = useState("overview");

  // ── Fetch course + enrollment status ──────────────────────────────────
  useEffect(() => {
    setLoading(true);
    setActiveTab("overview");

    const init = async () => {
      try {
        const courseRes = await api.get(`/courses/${courseId}`);
        setCourse(courseRes.data);

        if (studentId) {
          const enrollRes = await api.get("/enrollment/is-enrolled", {
            params: { studentId, courseId },
          });
          setEnrolled(enrollRes.data.enrolled);
        }
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    init();
  }, [courseId, studentId]);

  // ── Free enroll ────────────────────────────────────────────────────────
  const handleFreeEnroll = async () => {
    if (enrolled) {
      onBrowseLessons(courseId);
      return;
    }
    try {
      setEnrolling(true);
      await api.post("/enrollment/free", null, {
        params: { studentId, courseId },
      });
      setEnrolled(true);
      onBrowseLessons(courseId);
    } catch (err) {
      console.error("Free enroll failed:", err);
    } finally {
      setEnrolling(false);
    }
  };

  // ── Main enroll / access handler ──────────────────────────────────────
  const handleEnroll = () => {
    if (!course) return;
    if (course.isFree) {
      handleFreeEnroll();
    } else if (enrolled) {
      onBrowseLessons(courseId);
    } else {
      navigate(`/checkout/${courseId}`);
    }
  };

  // ── Helpers ───────────────────────────────────────────────────────────
  const levelLabel = {
    BEGINNER:     "Beginner",
    INTERMEDIATE: "Intermediate",
    ADVANCED:     "Advanced",
  };

  const formatMin = (min) => {
    if (!min) return "—";
    const h = Math.floor(min / 60), m = min % 60;
    return h > 0 ? `${h}h ${m}m` : `${m}m`;
  };

  const enrollBtnLabel = () => {
    if (!course)       return "Loading…";
    if (enrolling)     return "Enrolling…";
    if (enrolled)      return "Go to Lessons";
    if (course.isFree) return "Enroll for Free";
    return `Enroll — $${course.price?.toFixed(2)}`;
  };

  const priceLabel = () => {
    if (!course) return null;
    if (enrolled) return (
      <p className="detail-price" style={{ color: "#4caf50" }}>Enrolled ✓</p>
    );
    if (course.isFree) return (
      <p className="detail-price free">Free</p>      // never shows $0.00
    );
    return <p className="detail-price">${course.price?.toFixed(2)}</p>;
  };

  // ── Loading ────────────────────────────────────────────────────────────
  if (loading) return (
    <div className="courses-loading" style={{ minHeight: "60vh" }}>
      <div className="courses-spinner" /><p>Loading course…</p>
    </div>
  );

  if (!course) return (
    <div className="courses-empty" style={{ minHeight: "60vh" }}>
      <p>Course not found.</p>
      <button
        className="detail-back-btn"
        style={{ background: "var(--clr-gold)", border: "none", color: "#fff" }}
        onClick={onBack}
      >
        ← Back to Courses
      </button>
    </div>
  );

  const lessons       = course.lessons ? [...course.lessons] : [];
  const quizzes       = course.quizzes ? [...course.quizzes] : [];
  const totalDuration = lessons.reduce((s, l) => s + (l.duration || 0), 0);

  return (
    <div style={{ display: "flex", flexDirection: "column" }}>

      {/* ── HERO ── */}
      <section className="detail-hero" style={{ minHeight: 360 }}>
        <div
          className="detail-hero-bg"
          style={course.thumbnailUrl
            ? { backgroundImage: `url(http://localhost:8080${course.thumbnailUrl})` }
            : {}}
        />
        <div className="detail-hero-overlay" />

        <div className="detail-hero-content">
          <button className="detail-back-btn" onClick={onBack}>
            <FiArrowLeft size={14} /> Back to Courses
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
              <p className="detail-meta-label">Duration</p>
              <p className="detail-meta-value">{formatMin(totalDuration)}</p>
            </div>
          </div>

          {/* ── Enroll Card ── */}
          <div className="detail-enroll-card">
            {priceLabel()}
            <button
              className="detail-enroll-btn"
              onClick={handleEnroll}
              disabled={enrolling}
            >
              {!enrolled && !course.isFree && (
                <FiLock size={13} style={{ marginRight: 6 }} />
              )}
              {enrollBtnLabel()}
            </button>
            <p className="detail-enroll-note">
              {course.isFree
                ? "Free forever · No credit card needed"
                : "Full lifetime access · All devices"}
            </p>
          </div>
        </div>
      </section>

      {/* ── TABS ── */}
      <main className="detail-main" style={{ maxWidth: "100%", padding: "0 40px 60px" }}>
        <div className="detail-tabs" style={{ top: 64 }}>

          <button
            className={`detail-tab ${activeTab === "overview" ? "active" : ""}`}
            onClick={() => setActiveTab("overview")}
          >
            <FiGrid size={15} /> Overview
          </button>

          <button
            className={`detail-tab ${activeTab === "lessons" ? "active" : ""}`}
            onClick={() => {
              if (enrolled) {
                onBrowseLessons(courseId);
              } else if (course.isFree) {
                handleFreeEnroll();
              } else {
                navigate(`/checkout/${courseId}`);
              }
            }}
          >
            {!enrolled && !course.isFree && (
              <FiLock size={13} style={{ marginRight: 4 }} />
            )}
            <FiLayers size={15} /> Lessons ({lessons.length})
          </button>

          <button
            className={`detail-tab ${activeTab === "quizzes" ? "active" : ""}`}
            onClick={() => setActiveTab("quizzes")}
          >
            <FiHelpCircle size={15} /> Quizzes ({quizzes.length})
          </button>
        </div>

        {/* ── OVERVIEW ── */}
        {activeTab === "overview" && (
          <div className="detail-section detail-overview">
            <div className="detail-overview-grid">
              {[
                { icon: <FiLayers size={20} />,     label: "Total Lessons", value: lessons.length },
                { icon: <FiClock size={20} />,      label: "Duration",      value: formatMin(totalDuration) },
                { icon: <FiHelpCircle size={20} />, label: "Quizzes",       value: quizzes.length },
                {
                  icon: <span style={{ fontSize: 18 }}>🎯</span>,
                  label: "Level",
                  value: levelLabel[course.level] || course.level,
                },
              ].map((item, i) => (
                <div key={i} className="detail-overview-card">
                  <div className="detail-ov-icon">{item.icon}</div>
                  <p className="detail-ov-label">{item.label}</p>
                  <p className="detail-ov-value">{item.value}</p>
                </div>
              ))}
            </div>

            <div className="detail-overview-info">
              <h3>About This Course</h3>
              <p>
                Explore <strong>{course.title}</strong> — a{" "}
                {levelLabel[course.level]?.toLowerCase()} level{" "}
                {course.category?.toLowerCase()} course taught by{" "}
                <strong>{course.instructor?.username || "a certified instructor"}</strong>.
                Dive into {lessons.length} structured lesson{lessons.length !== 1 ? "s" : ""} and
                test your knowledge with {quizzes.length} interactive quiz
                {quizzes.length !== 1 ? "zes" : ""}.
              </p>

              <button
                className="detail-enroll-btn"
                style={{ marginBottom: 20, display: "inline-flex", alignItems: "center", gap: 8 }}
                onClick={handleEnroll}
                disabled={enrolling}
              >
                {enrolled ? (
                  <><FiLayers size={14} /> Browse All Lessons</>
                ) : course.isFree ? (
                  <><FiLayers size={14} /> {enrolling ? "Enrolling…" : "Enroll for Free"}</>
                ) : (
                  <><FiLock size={14} /> Enroll — ${course.price?.toFixed(2)}</>
                )}
              </button>

              <div className="detail-overview-tags">
                <span>{course.category}</span>
                <span>{levelLabel[course.level]}</span>
                <span>{course.isFree ? "Free" : "Premium"}</span>
                {course.status && <span>{course.status}</span>}
                {enrolled && (
                  <span style={{ background: "#4caf50", color: "#fff", borderColor: "#4caf50" }}>
                    Enrolled
                  </span>
                )}
              </div>
            </div>
          </div>
        )}

        {/* ── QUIZZES ── */}
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
                          <FiHelpCircle size={16} />
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
                                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none"
                                    stroke="currentColor" strokeWidth="2.5">
                                    <path d="M20 6L9 17l-5-5"/>
                                  </svg>
                                  Correct answer
                                </>
                              ) : (
                                <>
                                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none"
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
      </main>
    </div>
  );
}