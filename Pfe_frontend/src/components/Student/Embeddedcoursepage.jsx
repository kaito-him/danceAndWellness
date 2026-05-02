import React, { useEffect, useState } from "react";
import api from "../../components/services/api";
import { useNavigate, Link } from "react-router-dom";
import {
  FiArrowLeft, FiLayers, FiClock, FiHelpCircle,
  FiCheckCircle, FiTrash2, FiPlay, FiChevronRight, FiShield, FiCheck, FiBookmark,
  FiTrendingUp, FiUserCheck
} from "react-icons/fi";
import "../../styles/Courses.css";
import { FiMessageCircle } from "react-icons/fi"; // already have react-icons
import CourseComments from "./CourseComments";


/* ── REUSABLE ACTION MODAL (Logout Style) ── */
const ActionModal = ({ title, message, icon: Icon, confirmText, onConfirm, onCancel, loading }) => {
  useEffect(() => {
    const handler = (e) => { if (e.key === "Escape") onCancel(); };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [onCancel]);

  return (
    <div className="lm-backdrop" onClick={onCancel} style={{ zIndex: 3000 }}>
      <div className="lm-card" onClick={(e) => e.stopPropagation()}>
        <div className="lm-icon-ring">
          <Icon className="lm-icon" size={24} strokeWidth={1.8} />
        </div>
        <h2 className="lm-title">{title}</h2>
        <p className="lm-message">{message}</p>
        <div className="lm-actions">
          <button className="lm-btn-cancel" onClick={onCancel}>No, stay</button>
          <button className="lm-btn-confirm" onClick={onConfirm} disabled={loading}>
            {loading ? "Processing..." : confirmText}
          </button>
        </div>
      </div>
    </div>
  );
};

export default function EmbeddedCoursePage({ courseId, onBack, onBrowseLessons }) {
  const navigate = useNavigate();
  const studentId = localStorage.getItem("userId");

  const [course, setCourse] = useState(null);
  const [loading, setLoading] = useState(true);
  const [enrolled, setEnrolled] = useState(false);
  const [enrolling, setEnrolling] = useState(false);
  const [cancelling, setCancelling] = useState(false);
  const [modalType, setModalType] = useState(null); // 'enroll' or 'cancel'
  const [categoryName, setCategoryName] = useState("");
  const [showComments, setShowComments] = useState(false);
  const [courseProgress, setCourseProgress] = useState(0);
  const [completedLessonsCount, setCompletedLessonsCount] = useState(0);

  useEffect(() => {
    setLoading(true);
    const init = async () => {
      try {
        const courseRes = await api.get(`/courses/${courseId}`);
        setCourse(courseRes.data);

        // Set category name from categoryId
        const courseData = courseRes.data;
        if (courseData.categoryId) {
          // Fetch category by ID
          try {
            const catRes = await api.get(`/categories/${courseData.categoryId}`);
            setCategoryName(catRes.data.name);
          } catch {
            // If fetch fails, show the ID as fallback
            setCategoryName(courseData.categoryId);
          }
        }

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

  /* ── Fetch course progress when enrolled ── */
  useEffect(() => {
    if (!enrolled || !studentId || !courseId) return;
    api.get("/progress/course", { params: { studentId, courseId } })
      .then(res => {
        setCourseProgress(res.data.courseCompletionPercent ?? 0);
        setCompletedLessonsCount(res.data.completedLessons ?? 0);
      })
      .catch(() => { });
  }, [enrolled, studentId, courseId]);

  const handleFreeEnroll = async () => {
    try {
      setEnrolling(true);
      await api.post("/enrollment/free", null, { params: { studentId, courseId } });
      setEnrolled(true);
      setModalType(null);
      // Optional: auto-navigate to lessons or stay
      // onBrowseLessons(courseId); 
    } catch (err) {
      console.error("Free enroll failed:", err);
    } finally {
      setEnrolling(false);
    }
  };

  const handleCancelEnrollment = async () => {
    try {
      setCancelling(true);
      await api.delete("/enrollment/cancel-free", { params: { studentId, courseId } });
      setEnrolled(false);
      setModalType(null);
    } catch (err) {
      console.error("Cancel failed:", err);
    } finally {
      setCancelling(false);
    }
  };

  const handleMainCTA = () => {
    if (!course) return;
    if (enrolled) onBrowseLessons(courseId);
    else if (course.isFree) setModalType('enroll');
    else navigate(`/checkout/${courseId}`);
  };

  const userRole = localStorage.getItem("userRole");
  const [showSwitchModal, setShowSwitchModal] = useState(false);

  useEffect(() => {
    if (userRole === "INSTRUCTOR") {
      setShowSwitchModal(true);
    }
  }, [userRole]);

  const handleSwitchToStudent = () => {
    localStorage.clear();
    window.location.href = "/signup/student";
  };

  const levelLabel = { BEGINNER: "Beginner", INTERMEDIATE: "Intermediate", ADVANCED: "Advanced" };
  const formatMin = (min) => {
    if (!min) return "—";
    const h = Math.floor(min / 60), m = min % 60;
    return h > 0 ? `${h}h ${m}m` : `${m}m`;
  };

  if (loading) return (
    <div className="courses-loading" style={{ minHeight: "60vh" }}>
      <div className="sd-spinner" /><p>Perfecting the scene...</p>
    </div>
  );

  if (!course) return (
    <div className="courses-empty" style={{ minHeight: "60vh" }}>
      <p>Course not found.</p>
      <button className="cps-back-minimal" onClick={onBack}>
        <FiArrowLeft size={14} /> Back to Dashboard
      </button>
    </div>
  );

  const lessons = course.lessons ? [...course.lessons] : [];
  const quizzes = course.quizzes ? [...course.quizzes] : [];
  const totalDuration = lessons.reduce((s, l) => s + (l.duration || 0), 0);
  const thumbUrl = course.thumbnailUrl ? `http://localhost:8080${course.thumbnailUrl}` : null;

  return (
    <div className="ebp-root">

      <div className="ebp-banner-outer">
        <button className="ebp-banner-back-alt" onClick={onBack}>
          <FiArrowLeft size={14} /> Back to Courses
        </button>

        {/* Comments trigger — sits in the top-right of the banner */}
        <button
          className="ebp-comments-trigger"
          onClick={() => setShowComments(true)}
          title="Open course discussion"
        >
          <FiMessageCircle size={16} />
          <span>Discussion</span>
        </button>

        <div
          className="ebp-banner-panoramic"
          style={thumbUrl ? { backgroundImage: `url(${thumbUrl})` } : {}}
        />
      </div>

      <div className="ebp-layout-alt">
        <header className="ebp-header-editorial">
          <div className="ebp-breadcrumbs-alt">
            <Link to="/student/home">Home</Link>
            <FiChevronRight size={12} className="ebp-crumb-sep" />
            <span className="ebp-crumb-link">Categories</span>
            <FiChevronRight size={12} className="ebp-crumb-sep" />
            <span className="ebp-crumb-current">{categoryName}</span>
          </div>

          <h1 className="ebp-page-title">{course.title}</h1>

          <div className="ebp-meta-grid">
            <div
              className="ebp-meta-item"
              style={{ cursor: 'pointer' }}
              onClick={() => {
                if (course.instructor?.id) {
                  navigate(`/student/instructor/${course.instructor.id}`);
                }
              }}
              title="View Instructor Profile"
            >
              <div className="ebp-meta-avatar">
                {course.instructor?.photo ? (
                  <img src={`http://localhost:8080/api/files/${course.instructor.photo}`} alt={course.instructor.username} />
                ) : (
                  course.instructor?.username?.charAt(0).toUpperCase() || "I"
                )}
              </div>
              <div className="ebp-meta-info">
                <span className="ebp-meta-label">Instructor</span>
                <span className="ebp-meta-value ebp-instructor-link">{course.instructor?.username || "Instructor"}</span>
              </div>
            </div>

            <div className="ebp-meta-item">
              <div className="ebp-meta-icon"><FiLayers size={18} /></div>
              <div className="ebp-meta-info">
                <span className="ebp-meta-label">Course Level</span>
                <span className="ebp-meta-value">{levelLabel[course.level] || course.level}</span>
              </div>
            </div>

            <div className="ebp-meta-item">
              <div className="ebp-meta-icon"><FiBookmark size={18} /></div>
              <div className="ebp-meta-info">
                <span className="ebp-meta-label">Category</span>
                <span className="ebp-meta-value">{categoryName}</span>
              </div>
            </div>
          </div>
        </header>

        {/* ── LEFT: CONTENT ── */}
        <div className="ebp-main-alt">
          <div className="ebp-divider-alt" />

          {/* Overview / Description */}
          <section className="ebp-overview-section">
            <h3 className="ebp-section-title">About This Course</h3>
            {course.description ? (
              <p className="ebp-description-alt">{course.description}</p>
            ) : (
              <p className="ebp-description-alt" style={{ color: "#999", fontStyle: "italic" }}>
                No description provided for this course.
              </p>
            )}
          </section>

          {/* Stats Grid */}
          <div className="ebp-stats-grid-alt">
            <div className="ebp-stat-card-alt">
              <div className="ebp-stat-icon-outer"><FiClock size={16} /></div>
              <div className="ebp-stat-content">
                <span className="ebp-stat-val">{formatMin(totalDuration)}</span>
                <span className="ebp-stat-lbl">Total Duration</span>
              </div>
            </div>
            <div className="ebp-stat-card-alt">
              <div className="ebp-stat-icon-outer"><FiPlay size={16} /></div>
              <div className="ebp-stat-content">
                <span className="ebp-stat-val">{lessons.length}</span>
                <span className="ebp-stat-lbl">Video Lessons</span>
              </div>
            </div>
            <div className="ebp-stat-card-alt">
              <div className="ebp-stat-icon-outer"><FiHelpCircle size={16} /></div>
              <div className="ebp-stat-content">
                <span className="ebp-stat-val">{quizzes.length}</span>
                <span className="ebp-stat-lbl">Interactive Quizzes</span>
              </div>
            </div>
          </div>

          {/* Progress Bar (only when enrolled and has progress) */}
          {enrolled && courseProgress > 0 && (
            <div className="ebp-course-progress-section">
              <div className="ebp-course-progress-header">
                <FiTrendingUp size={16} className="ebp-progress-icon" />
                <span className="ebp-progress-title">Your Progress</span>
                <span className="ebp-progress-pct">{courseProgress}%</span>
              </div>
              <div className="ebp-course-progress-track">
                <div
                  className="ebp-course-progress-fill"
                  style={{ width: `${courseProgress}%` }}
                />
              </div>
              <p className="ebp-course-progress-sub">
                {completedLessonsCount} of {lessons.length} lessons completed
              </p>
            </div>
          )}
        </div>

        {/* ── RIGHT: SIDEBAR ── */}
        <aside className="ebp-sidebar-alt">
          <div className="ebp-pricing-card">
            <div className="ebp-price-header">
              <span className="ebp-price-amount">
                {enrolled ? "Accessed" : course.isFree ? "" : `$${course.price?.toFixed(2)}`}
              </span>
              <p className="ebp-price-label">
                {enrolled ? "Currently Enrolled" : course.isFree ? "" : "One-time payment"}
              </p>
            </div>

            <button
              className={`ebp-enroll-cta ${enrolled ? "enrolled" : ""}`}
              onClick={handleMainCTA}
            >
              {enrolled ? "Go to Lessons" : course.isFree ? "Enroll for Free" : "Enroll Now"}
            </button>

            {!course.isFree && (
              <div className="ebp-guarantee-alt warning">
                <FiShield size={14} />
                <span>Note: Enrollment cannot be cancelled after joining.</span>
              </div>
            )}

            <div className="ebp-includes-alt">
              <h4 className="ebp-includes-h4">This course includes:</h4>
              <ul className="ebp-includes-list">
                <li><FiCheck size={16} /> <span>Full lifetime access</span></li>
                <li><FiCheck size={16} /> <span>Access on mobile and desktop</span></li>
                <li><FiCheck size={16} /> <span>Downloadable resources</span></li>
                <li><FiCheck size={16} /> <span>Certificate of completion</span></li>
              </ul>
            </div>

            {/* Cancel (Free only) */}
            {enrolled && course.isFree && (
              <div className="ebp-cancel-alt">
                <button className="ebp-cancel-btn-alt" onClick={() => setModalType('cancel')}>
                  Cancel enrollment
                </button>
              </div>
            )}
          </div>
        </aside>
      </div>

      {/* ── MODALS ── */}
      {modalType === 'enroll' && (
        <ActionModal
          title="Enroll Now"
          message={`Are you sure you want to enroll in ${course.title}? It's free!`}
          icon={FiCheckCircle}
          confirmText="Yes, enroll"
          onConfirm={handleFreeEnroll}
          onCancel={() => setModalType(null)}
          loading={enrolling}
        />
      )}

      {modalType === 'cancel' && (
        <ActionModal
          title="Cancel Enrollment"
          message="Are you sure you want to unenroll from this course?"
          icon={FiTrash2}
          confirmText="Yes, unenroll"
          onConfirm={handleCancelEnrollment}
          onCancel={() => setModalType(null)}
          loading={cancelling}
        />
      )}

      {showComments && (
        <CourseComments
          courseId={courseId}
          onClose={() => setShowComments(false)}
        />
      )}

      {/* Switch to Student Modal */}
      {showSwitchModal && (
        <div className="lm-backdrop" onClick={onBack}>
          <div className="lm-card" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '400px' }}>
            <div className="lm-icon-ring" style={{ color: '#b89c4d', marginBottom: '16px', borderColor: '#b89c4d' }}>
              <FiUserCheck size={24} />
            </div>
            <h2 className="lm-title">Switch to Student View</h2>
            <p className="lm-message" style={{ lineHeight: '1.6' }}>
              To view, enroll, or interact with courses as a student, you must use a student account.
              <br /><br />
              Would you like to log out and switch to the student registration?
            </p>
            <div className="lm-actions">
              <button className="lm-btn-cancel" onClick={onBack}>No, go back</button>
              <button
                className="lm-btn-confirm"
                onClick={handleSwitchToStudent}
                style={{ background: '#b89c4d' }}
              >
                Switch to Student
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}