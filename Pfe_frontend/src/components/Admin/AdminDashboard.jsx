import React, { useState, useEffect, useCallback } from "react";
import { useSearchParams } from "react-router-dom";
import {
  FiBookOpen,
  FiClock,
  FiFileText,
  FiStar,
  FiSlash,
  FiBarChart2,
  FiTrendingUp,
  FiRadio,
  FiCreditCard,
  FiUser,
  FiLogOut,
  FiBell,
  FiMenu,
  FiCheckCircle,
  FiXCircle,
  FiAward,
  FiGrid,
  FiUsers,
  FiDollarSign,
} from "react-icons/fi";
import AdminCourseCard from "./Admincoursecard";
import AdminCourseDetail from "./Admincoursedetail";
import InstructorApplications from "./InstructorApplications";
import AdminBadges from "./Adminbadges";
import AdminCategories from "./AdminCategories";
import AdminInstructors from "./AdminInstructors";
import AdminStudents from "./Adminstudents";
import BannedAccount from "./BannedAccount";           // ← NEW
import api from "./../services/api";
import "../../styles/AdminDashboard.css";
import AdminProfile from "./AdminProfile";
import LogoutModal from "../LogoutModal";
import UserChip from "../UserChip";
import logo from "../../assets/Dicone.png";
import AdminPayment from "./AdminPayment";

const NAV_ITEMS = [
  { key: "feed",         label: "Published Courses",       Icon: FiBookOpen    },
  { key: "pending",      label: "Pending Course Review",   Icon: FiClock       },
  { key: "applications", label: "Instructor Applications", Icon: FiFileText    },
  { key: "payments",     label: "Platform Payments",       Icon: FiDollarSign  },
  { key: "instructors",  label: "Manage Instructors",      Icon: FiUsers       },
  { key: "students",     label: "Students",                Icon: FiUsers       },
  { key: "banned",       label: "Banned Accounts",         Icon: FiSlash       },
  { key: "stats-overall",label: "Overall Statistics",      Icon: FiBarChart2   },
  { key: "stats-today",  label: "Today's Statistics",      Icon: FiTrendingUp  },
  { key: "live",         label: "Live Sessions",           Icon: FiRadio       },
  { key: "badges",       label: "Badges",                  Icon: FiAward       },
  { key: "categories",   label: "Categories",              Icon: FiGrid        },
];

const VALID_SECTIONS = new Set([
  ...NAV_ITEMS.map((n) => n.key),
  "profile",
]);

export default function AdminDashboard() {
  const [searchParams, setSearchParams] = useSearchParams();
  const initialSection = VALID_SECTIONS.has(searchParams.get("section"))
    ? searchParams.get("section")
    : "feed";

  const [courses, setCourses]           = useState([]);
  const [loading, setLoading]           = useState(true);
  const [showLogout, setShowLogout]     = useState(false);
  const [selectedCourse, setSelectedCourse] = useState(null);
  const [toast, setToast]               = useState(null);
  const [activeSection, setActiveSection]   = useState(initialSection);
  const [sidebarOpen, setSidebarOpen]   = useState(true);
  const [notifOpen, setNotifOpen]       = useState(false);
  const [adminUser, setAdminUser]       = useState(null);

  useEffect(() => {
    const fetchMe = async () => {
      try {
        const res = await api.get("/users/me");
        setAdminUser(res.data);
      } catch (err) {
        console.error("Failed to fetch admin user", err);
      }
    };
    fetchMe();
  }, []);

  // Keep URL in sync with active section
  useEffect(() => {
    const currentParams = new URLSearchParams(window.location.search);
    if (currentParams.get("section") !== activeSection) {
      setSearchParams({ section: activeSection });
    }
  }, [activeSection, setSearchParams]);

  const raw = localStorage.getItem("username");
  const username = adminUser?.username || (raw && raw !== "null" && raw !== "undefined" ? raw : "Admin");
  const photoUrl = adminUser?.photo ? `http://localhost:8080/api/files/${adminUser.photo}` : null;

  const fetchPending = async () => {
    setLoading(true);
    try {
      const res = await api.get("/courses/pending");
      setCourses(res.data);
    } catch (_) {
      showToast("error", "Failed to load courses.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const pendingId = localStorage.getItem("pendingCourseId");
    if (pendingId) localStorage.removeItem("pendingCourseId");
  }, []);

  useEffect(() => {
    if (activeSection === "pending") fetchPending();
  }, [activeSection]);

  const showToast = (type, msg) => {
    setToast({ type, msg });
    setTimeout(() => setToast(null), 3500);
  };

  const removeCourse = (courseId) =>
    setCourses((prev) => prev.filter((c) => c.courseId !== courseId));

  const handleApprove = async (courseId) => {
    try {
      await api.patch(`/courses/${courseId}/approve`);
      removeCourse(courseId);
      showToast("success", "Course approved and published!");
    } catch (_) {
      showToast("error", "Failed to approve course.");
    }
  };

  const handleArchive = async (courseId) => {
    try {
      await api.patch(`/courses/${courseId}/archive`);
      removeCourse(courseId);
      showToast("success", "Course archived.");
    } catch (_) {
      showToast("error", "Failed to archive course.");
    }
  };

  const confirmLogout = () => {
    localStorage.clear();
    window.location.href = "/login";
  };

  const renderContent = () => {

    if (activeSection === "profile") return <AdminProfile onUpdate={(data) => setAdminUser(prev => ({ ...prev, ...data }))} />;
    if (activeSection === "applications") return <InstructorApplications />;
    if (activeSection === "badges") return <AdminBadges />;
    if (activeSection === "categories") return <AdminCategories />;
    if (activeSection === "payments") return <AdminPayment />;

    // ── Instructors ────────────────────────────────────────────────────────
    if (activeSection === "instructors") return <AdminInstructors />;

    // ── Students ────────────────────────────────────────────────────────
    if (activeSection === "students") return <AdminStudents />;

    // ── Banned Accounts ─────────────────────────────────────────────────
    if (activeSection === "banned") return <BannedAccount />;

    // ── Pending course review ──────────────────────────────────────────────
    if (activeSection === "pending") {
      return (
        <div className="admin-page">
          <div className="admin-header">
            <div>
              <h1 className="admin-heading">Pending Approvals</h1>
              <p className="admin-subheading">Review submitted courses before publishing</p>
            </div>
            <div className="admin-stats">
              <div className="admin-stat">
                <span className="admin-stat-num">{courses.length}</span>
                <span className="admin-stat-label">Awaiting Review</span>
              </div>
            </div>
          </div>

          {loading ? (
            <div className="admin-loading">
              <div className="admin-spinner" />
              <p>Loading courses…</p>
            </div>
          ) : courses.length === 0 ? (
            <div className="admin-empty">
              <div className="admin-empty-icon"><FiCheckCircle size={48} /></div>
              <h2 className="admin-empty-title">All caught up!</h2>
              <p className="admin-empty-sub">No courses waiting for review.</p>
            </div>
          ) : (
            <div className="admin-grid">
              {courses.map((course) => (
                <AdminCourseCard
                  key={course.courseId}
                  course={course}
                  onApprove={handleApprove}
                  onArchive={handleArchive}
                  onViewDetails={(c) => setSelectedCourse(c)}
                />
              ))}
            </div>
          )}
        </div>
      );
    }

    // ── Feed ──────────────────────────────────────────────────────────────
    if (activeSection === "feed") {
      return (
        <div className="admin-placeholder">
          <div className="admin-placeholder-icon"><FiBookOpen size={52} /></div>
          <h2>Published Courses</h2>
          <p>All live courses will appear here.</p>
        </div>
      );
    }

    // ── Catch-all placeholder ──────────────────────────────────────────────
    const item = NAV_ITEMS.find((n) => n.key === activeSection);
    return (
      <div className="admin-placeholder">
        <div className="admin-placeholder-icon">
          {item?.Icon && <item.Icon size={52} />}
        </div>
        <h2>{item?.label}</h2>
        <p>This section is coming soon.</p>
      </div>
    );
  };

  return (
    <div className="admin-shell">

      {/* ── TOP NAV ── */}
      <header className="admin-topnav">
        <div className="admin-topnav-left">
          <button
            className="admin-hamburger"
            onClick={() => setSidebarOpen((o) => !o)}
            aria-label="Toggle sidebar"
          >
            <FiMenu size={20} />
          </button>
          <div className="admin-logo-flex" style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <img src={logo} alt="Logo" style={{ height: '42px', width: 'auto' }} />
            <span className="admin-logo">Dance&amp;Wellness</span>
          </div>
        </div>

        <div className="admin-topnav-right">
          <div className="admin-notif-wrapper">
            <button
              className="admin-notif-btn"
              onClick={() => setNotifOpen((o) => !o)}
              aria-label="Notifications"
            >
              <FiBell size={17} />
              <span className="admin-notif-badge">3</span>
            </button>
            {notifOpen && (
              <div className="admin-notif-dropdown">
                <p className="admin-notif-title">Notifications</p>
                <div className="admin-notif-item">New instructor application received</div>
                <div className="admin-notif-item">Course "React Mastery" pending review</div>
                <div className="admin-notif-item">Payment issue reported by user #42</div>
              </div>
            )}
          </div>

          <UserChip 
            user={adminUser} 
            onProfileClick={() => setActiveSection("profile")} 
          />
        </div>
      </header>

      <div className="admin-layout">

        {/* ── SIDEBAR ── */}
        <aside className={`admin-sidebar ${sidebarOpen ? "open" : "closed"}`}>
          <nav className="admin-sidenav">
            {NAV_ITEMS.map(({ key, label, Icon }) => (
              <button
                key={key}
                className={`admin-sidenav-item ${activeSection === key ? "active" : ""}`}
                onClick={() => setActiveSection(key)}
                title={!sidebarOpen ? label : undefined}
              >
                <span className="admin-sidenav-icon"><Icon size={17} /></span>
                <span className="admin-sidenav-label">{label}</span>
              </button>
            ))}
          </nav>

          <div className="admin-sidebar-footer">
            <button
              className={`admin-sidenav-item ${activeSection === "profile" ? "active" : ""}`}
              onClick={() => setActiveSection("profile")}
              title={!sidebarOpen ? "Manage Profile" : undefined}
            >
              <span className="admin-sidenav-icon"><FiUser size={17} /></span>
              <span className="admin-sidenav-label">Manage Profile</span>
            </button>
            <button
              className="admin-sidenav-item logout"
              onClick={() => setShowLogout(true)}
              title={!sidebarOpen ? "Log Out" : undefined}
            >
              <span className="admin-sidenav-icon"><FiLogOut size={17} /></span>
              <span className="admin-sidenav-label">Log Out</span>
            </button>
          </div>
        </aside>

        {/* ── MAIN CONTENT ── */}
        <main
          className="admin-main"
          onClick={() => notifOpen && setNotifOpen(false)}
        >
          {renderContent()}
        </main>
      </div>

      {/* ── Course detail modal ── */}
      {selectedCourse && (
        <AdminCourseDetail
          course={selectedCourse}
          onClose={() => setSelectedCourse(null)}
          onApprove={handleApprove}
          onArchive={handleArchive}
        />
      )}

      {/* ── Toast ── */}
      {toast && (
        <div className={`admin-toast ${toast.type}`}>
          {toast.type === "success"
            ? <FiCheckCircle size={15} />
            : <FiXCircle size={15} />}
          {toast.msg}
        </div>
      )}

      {/* ── Logout modal ── */}
      {showLogout && (
        <LogoutModal
          onConfirm={confirmLogout}
          onCancel={() => setShowLogout(false)}
        />
      )}
    </div>
  );
}