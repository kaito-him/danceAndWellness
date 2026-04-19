import React, { useState, useEffect } from "react";
import { useSearchParams } from "react-router-dom";
import {
  FiBookOpen,
  FiClock,
  FiGrid,
  FiMessageSquare,
  FiCreditCard,
  FiUser,
  FiLogOut,
  FiBell,
  FiMenu,
  FiCheckCircle,
  FiXCircle,
  FiPlus,
  FiRss,
} from "react-icons/fi";
import AddCourseForm   from "../Instructor/Addcourseform";
import CourseCard      from "../Instructor/CourseCard";
import CourseDetails   from "../Instructor/CourseDetails";
import NotificationBell from "../NotificationBell.jsx";
import InstructorProfile from "./InstructorProfile";
import InstructorPayment from "./Instructorpayment";
import LogoutModal     from "../LogoutModal";
import api             from "./../services/api";
import "../../styles/Instructordashboard.css";
import InstructorFeed from "../Instructor/Instructorfeed";
import UserChip from "../UserChip";
import logo from "../../assets/Dicone.png";

/* ─── sidebar items ──────────────────────────────────────────────── */
const NAV_ITEMS = [
  { key: "courses",  label: "My Courses",     Icon: FiGrid        },
  { key: "feed",     label: "Feed",           Icon: FiRss         },
  { key: "pending",  label: "Pending Review", Icon: FiClock       },
  { key: "messages", label: "Messages",       Icon: FiMessageSquare },
  { key: "payments", label: "Payments",       Icon: FiCreditCard  },
];

const VALID_SECTIONS = new Set([
  ...NAV_ITEMS.map((n) => n.key),
  "profile",
]);

export default function InstructorDashboard() {
  const [searchParams, setSearchParams] = useSearchParams();
  const initialSection = VALID_SECTIONS.has(searchParams.get("section"))
    ? searchParams.get("section")
    : "courses";

  const [modalOpen,     setModalOpen]     = useState(false);
  const [activeTab,     setActiveTab]     = useState(initialSection);
  const [courses,       setCourses]       = useState([]);
  const [editingCourse, setEditingCourse] = useState(null);
  const [toast,         setToast]         = useState(null);
  const [sidebarOpen,   setSidebarOpen]   = useState(true);
  const [notifOpen,     setNotifOpen]     = useState(false);
  const [showLogout,    setShowLogout]    = useState(false);
  const [user,          setUser]          = useState(null);

  useEffect(() => {
    api.get("/users/me")
      .then(res => setUser(res.data))
      .catch(err => console.error(err));
  }, []);

  const username = user?.username || localStorage.getItem("username") || "Instructor";

  // Keep URL in sync with active section
  useEffect(() => {
    const currentParams = new URLSearchParams(window.location.search);
    if (currentParams.get("section") !== activeTab) {
      currentParams.set("section", activeTab);
      setSearchParams(currentParams, { replace: true });
    }
  }, [activeTab, setSearchParams]);

  /* ── data fetching ─────────────────────────────────────────────── */
  const fetchPending = async () => {
    try {
      const res = await api.get("/courses/my-pending");
      setCourses(res.data);
    } catch (_) {
      showToast("error", "Failed to load courses.");
    }
  };

  useEffect(() => {
    const pendingId = localStorage.getItem("pendingCourseId");
    if (pendingId) {
      localStorage.removeItem("pendingCourseId");
    }
  }, []);

  useEffect(() => {
    if (activeTab === "pending") fetchPending();
  }, [activeTab]);

  /* ── helpers ───────────────────────────────────────────────────── */
  const showToast = (type, msg) => {
    setToast({ type, msg });
    setTimeout(() => setToast(null), 3500);
  };

  const handleDelete = async (courseId) => {
    if (!window.confirm("Delete this course? This cannot be undone.")) return;
    try {
      await api.delete(`/courses/${courseId}`);
      setCourses((prev) => prev.filter((c) => c.courseId !== courseId));
      showToast("success", "Course deleted.");
    } catch (_) {
      showToast("error", "Failed to delete course.");
    }
  };

  const handleSaved = (updated) => {
    setCourses((prev) =>
      prev.map((c) => (c.courseId === updated.courseId ? updated : c))
    );
    showToast("success", "Course updated.");
  };

  const handleCourseAdded = (type, msg) => {
    showToast(type, msg);
    if (type === "success" && activeTab === "pending") fetchPending();
  };

  const confirmLogout = () => {
    localStorage.clear();
    window.location.href = "/login";
  };

  /* ── section renderer ──────────────────────────────────────────── */
  const renderContent = () => {

    /* ── Manage Profile ─────────────────────────────────────────── */
    if (activeTab === "profile") {
      return <InstructorProfile />;
    }

    /* ── Feed ───────────────────────────────────────────────────── */
if (activeTab === "feed") return <InstructorFeed />;
    /* ── Messages ───────────────────────────────────────────────── */
    if (activeTab === "messages") {
      return (
        <div className="id-placeholder">
          <div className="id-placeholder-icon"><FiMessageSquare size={52} /></div>
          <h2>Messages</h2>
          <p>Student questions and conversations will appear here.</p>
        </div>
      );
    }

    /* ── Payments ───────────────────────────────────────────────── */
    if (activeTab === "payments") {
      return <InstructorPayment />;
    }

    /* ── Pending Review ─────────────────────────────────────────── */
    if (activeTab === "pending") {
      return (
        <>
          <div className="id-header">
            <div>
              <h1 className="id-heading">Pending Review</h1>
              <p className="id-subheading">Courses awaiting admin approval</p>
            </div>
            {courses.length > 0 && (
              <div className="id-stats">
                <div className="id-stat">
                  <span className="id-stat-num">{courses.length}</span>
                  <span className="id-stat-label">Awaiting Review</span>
                </div>
              </div>
            )}
          </div>

          {courses.length === 0 ? (
            <div className="id-empty">
              <div className="id-empty-icon"><FiCheckCircle size={48} /></div>
              <h2 className="id-empty-title">Nothing pending</h2>
              <p className="id-empty-sub">Courses you submit will appear here.</p>
            </div>
          ) : (
            <div className="id-grid">
              {courses.map((course) => (
                <CourseCard
                  key={course.courseId}
                  course={course}
                  onDelete={handleDelete}
                  onEdit={(c) => setEditingCourse(c)}
                />
              ))}
            </div>
          )}
        </>
      );
    }

    /* ── My Courses (default) ───────────────────────────────────── */
    return (
      <>
        <div className="id-header">
          <div>
            <h1 className="id-heading">My Courses</h1>
            <p className="id-subheading">Manage and publish your learning content</p>
          </div>
          <button className="id-btn-add" onClick={() => setModalOpen(true)}>
            <FiPlus size={16} strokeWidth={2.5} />
            Add Course
          </button>
        </div>

        {courses.length === 0 ? (
          <div className="id-empty">
            <div className="id-empty-icon">🎓</div>
            <h2 className="id-empty-title">No courses yet</h2>
            <p className="id-empty-sub">Create your first course and submit it for review.</p>
          </div>
        ) : (
          <div className="id-grid">
            {courses.map((course) => (
              <CourseCard
                key={course.courseId}
                course={course}
                onDelete={handleDelete}
                onEdit={(c) => setEditingCourse(c)}
              />
            ))}
          </div>
        )}
      </>
    );
  };

  /* ── render ────────────────────────────────────────────────────── */
  return (
    <div className="id-shell">

      {/* ── TOP NAV ─────────────────────────────────────────────── */}
      <header className="id-topnav">
        <div className="id-topnav-left">
          <button
            className="id-hamburger"
            onClick={() => setSidebarOpen((o) => !o)}
            aria-label="Toggle sidebar"
          >
            <FiMenu size={20} />
          </button>
          <div className="id-logo-flex" style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <img src={logo} alt="Logo" style={{ height: '42px', width: 'auto' }} />
            <span className="id-logo">Dance&amp;Wellness</span>
          </div>
        </div>

        <div className="id-topnav-right">
          {/* notification bell */}
          <div className="id-notif-wrapper">
            <button
              className="id-notif-btn"
              onClick={() => setNotifOpen((o) => !o)}
              aria-label="Notifications"
            >
              <FiBell size={17} />
              <span className="id-notif-badge">2</span>
            </button>

            {notifOpen && (
              <div className="id-notif-dropdown">
                <p className="id-notif-title">Notifications</p>
                <div className="id-notif-item">Your course was approved ✓</div>
                <div className="id-notif-item">New student enrolled in React 101</div>
              </div>
            )}
          </div>

          {/* user chip */}
          <UserChip 
            user={user} 
            onProfileClick={() => setActiveTab("profile")} 
          />
        </div>
      </header>

      <div className="id-layout">

        {/* ── SIDEBAR ───────────────────────────────────────────── */}
        <aside className={`id-sidebar ${sidebarOpen ? "open" : "closed"}`}>
          <nav className="id-sidenav">
            {NAV_ITEMS.map(({ key, label, Icon }) => (
              <button
                key={key}
                className={`id-sidenav-item ${activeTab === key ? "active" : ""}`}
                onClick={() => setActiveTab(key)}
                title={!sidebarOpen ? label : undefined}
              >
                <span className="id-sidenav-icon"><Icon size={17} /></span>
                <span className="id-sidenav-label">{label}</span>

                {/* badge on pending */}
                {key === "pending" && courses.length > 0 && (
                  <span className="id-sidenav-badge">{courses.length}</span>
                )}
              </button>
            ))}
          </nav>

          <div className="id-sidebar-footer">
            <button
              className={`id-sidenav-item ${activeTab === "profile" ? "active" : ""}`}
              onClick={() => setActiveTab("profile")}
              title={!sidebarOpen ? "Manage Profile" : undefined}
            >
              <span className="id-sidenav-icon"><FiUser size={17} /></span>
              <span className="id-sidenav-label">Manage Profile</span>
            </button>

            <button
              className="id-sidenav-item logout"
              onClick={() => setShowLogout(true)}
              title={!sidebarOpen ? "Log Out" : undefined}
            >
              <span className="id-sidenav-icon"><FiLogOut size={17} /></span>
              <span className="id-sidenav-label">Log Out</span>
            </button>
          </div>
        </aside>

        {/* ── MAIN ──────────────────────────────────────────────── */}
        <main
          className="id-main"
          onClick={() => notifOpen && setNotifOpen(false)}
        >
          {renderContent()}
        </main>
      </div>

      {/* ── modals / overlays ──────────────────────────────────── */}
      {modalOpen && (
        <AddCourseForm
          onClose={() => setModalOpen(false)}
          onSuccess={handleCourseAdded}
        />
      )}

      {editingCourse && (
        <CourseDetails
          course={editingCourse}
          onClose={() => setEditingCourse(null)}
          onSaved={handleSaved}
        />
      )}

      {showLogout && (
        <LogoutModal
          onConfirm={confirmLogout}
          onCancel={() => setShowLogout(false)}
        />
      )}

      {toast && (
        <div className={`id-toast ${toast.type}`}>
          {toast.type === "success"
            ? <FiCheckCircle size={15} />
            : <FiXCircle size={15} />}
          {toast.msg}
        </div>
      )}
    </div>
  );
}