import React, { useState, useEffect, useCallback, useMemo, useRef } from "react";
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
  FiMenu,
  FiCheckCircle,
  FiXCircle,
  FiAward,
  FiGrid,
  FiUsers,
  FiDollarSign,
  FiLayers,
  FiSearch,
  FiArchive,
  FiX,
  FiMoreVertical,
  FiRefreshCw,
  FiCalendar,
  FiAlertCircle,
} from "react-icons/fi";
import AdminCourseDetail from "./Admincoursedetail";
import InstructorApplications from "./InstructorApplications";
import AdminBadges from "./Adminbadges";
import AdminCategories from "./AdminCategories";
import AdminInstructors from "./AdminInstructors";
import AdminStudents from "./Adminstudents";
import BannedAccount from "./BannedAccount";
import api from "./../services/api";
import "../../styles/AdminDashboard.css";
import "../../styles/Courses.css"; // Reuse catalog styles
import AdminProfile from "./AdminProfile";
import LogoutModal from "../LogoutModal";
import UserChip from "../UserChip";
import logo from "../../assets/Dicone.png";
import AdminPayment from "./AdminPayment";
import AdminCoursePreview from "./AdminCoursePreview";
import AdminCatalogCard from "./AdminCatalogCard";
import AdminOverallStats from "./AdminOverallStats";
import AdminTodayStats from "./AdminTodayStats";
import NotificationBell from "../NotificationBell";

/* ── Skeleton Loader ─────────────────────────────────────────── */
const CourseCardSkeleton = ({ index }) => (
  <div className="course-card-skeleton" style={{ animationDelay: `${index * 80}ms` }}>
    <div className="skeleton-thumb" />
    <div className="skeleton-body">
      <div className="skeleton-line cat" />
      <div className="skeleton-line title" />
      <div className="skeleton-line title-half" />
      <div className="skeleton-instructor">
        <div className="skeleton-avatar" />
        <div className="skeleton-line name" />
      </div>
      <div className="skeleton-stats">
        <div className="skeleton-line stat" />
        <div className="skeleton-line stat" />
      </div>
      <div className="skeleton-btn" />
    </div>
  </div>
);

const AdminPublishedCourses = ({ onArchive, onPreview }) => {
  const [courses, setCourses] = useState([]);
  const [cats, setCats] = useState([]);
  const [loading, setLoading] = useState(true);

  const [searchParams, setSearchParams] = useSearchParams();

  // Search & Filter State (synced with URL)
  const [searchInput, setSearchInput] = useState(searchParams.get("q") || "");
  const activeQuery = searchParams.get("q") || "";
  const filterCat = searchParams.get("category") || "ALL";
  const filterLevel = searchParams.get("level") || "ALL";

  // Archive Confirm State
  const [courseToArchive, setCourseToArchive] = useState(null);
  const [showArchiveModal, setShowArchiveModal] = useState(false);
  const [archiveMessage, setArchiveMessage] = useState("");

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const [cRes, catRes] = await Promise.all([
        api.get("/courses/published"),
        api.get("/categories")
      ]);
      setCourses(cRes.data);
      setCats(catRes.data);
    } catch (err) {
      console.error(err);
    } finally {
      setTimeout(() => setLoading(false), 800);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const filtered = useMemo(() => {
    let list = [...courses];
    if (filterCat !== "ALL") list = list.filter(c => c.category === filterCat);
    if (filterLevel !== "ALL") list = list.filter(c => c.level === filterLevel);
    if (activeQuery) {
      const q = activeQuery.toLowerCase();
      list = list.filter(c =>
        c.title?.toLowerCase().includes(q) ||
        c.instructor?.username?.toLowerCase().includes(q)
      );
    }
    return list;
  }, [courses, filterCat, filterLevel, activeQuery]);

  const updateParams = (updates) => {
    const newParams = new URLSearchParams(searchParams);
    Object.entries(updates).forEach(([key, val]) => {
      if (val === "ALL" || val === "") newParams.delete(key);
      else newParams.set(key, val);
    });
    setSearchParams(newParams);
  };

  const handleSearch = () => {
    setLoading(true);
    updateParams({ q: searchInput });
    setTimeout(() => setLoading(false), 600);
  };

  const handleFilterChange = (key, val) => {
    setLoading(true);
    updateParams({ [key]: val });
    setTimeout(() => setLoading(false), 600);
  };

  const handleClear = () => {
    setLoading(true);
    setSearchInput("");
    setSearchParams({ section: "feed" }); // Reset everything but section
    setTimeout(() => setLoading(false), 600);
  };

  const initiateArchive = (e, course) => {
    e.stopPropagation();
    setCourseToArchive(course);
    setShowArchiveModal(true);
  };

  const confirmArchive = async () => {
    if (!courseToArchive) return;
    if (!archiveMessage.trim()) {
      alert("Please provide a reason for archiving this course.");
      return;
    }
    await onArchive(courseToArchive.courseId, archiveMessage);
    setShowArchiveModal(false);
    setCourseToArchive(null);
    setArchiveMessage("");
    fetchData();
  };

  const levelColor = (level) =>
    ({ BEGINNER: "#27ae60", INTERMEDIATE: "#b89c4d", ADVANCED: "#c0392b" }[level] || "#b89c4d");

  return (
    <div className="admin-page">
      <div className="admin-header">
        <div>
          <h1 className="admin-heading">Published Catalog</h1>
          <p className="admin-subheading">View and manage all live courses on the platform</p>
        </div>
        <div className="admin-stats">
          <div className="admin-stat">
            <span className="admin-stat-num">{courses.length}</span>
            <span className="admin-stat-label">Live Courses</span>
          </div>
        </div>
      </div>

      <div className="courses-search-bar" style={{ margin: '0 0 40px', maxWidth: 'none', display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
        <div className="courses-search-input-wrapper" style={{ flex: '1', minWidth: '300px' }}>
          <FiSearch className="search-icon" />
          <input
            type="text"
            placeholder="Search by title or instructor…"
            className="courses-input"
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
          />
          <div style={{ display: 'flex', gap: '8px', marginLeft: '10px' }}>
            <button className="courses-search-btn" onClick={handleSearch} style={{ padding: '8px 20px' }}>Search</button>
            <button
              className="courses-empty-reset"
              onClick={handleClear}
              style={{ margin: 0, padding: '8px 16px', background: 'transparent' }}
            >
              Clear
            </button>
          </div>
        </div>

        <div className="courses-select-group" style={{ marginLeft: 'auto', width: 'auto' }}>
          <select className="courses-select" value={filterCat} onChange={(e) => handleFilterChange("category", e.target.value)}>
            <option value="ALL">All Categories</option>
            {cats.map(c => <option key={c.id} value={c.name}>{c.name}</option>)}
          </select>
          <select className="courses-select" value={filterLevel} onChange={(e) => handleFilterChange("level", e.target.value)}>
            <option value="ALL">All Levels</option>
            <option value="BEGINNER">Beginner</option>
            <option value="INTERMEDIATE">Intermediate</option>
            <option value="ADVANCED">Advanced</option>
          </select>
        </div>
      </div>

      {loading ? (
        <div className="courses-grid">
          {Array.from({ length: 8 }).map((_, idx) => <CourseCardSkeleton key={idx} index={idx} />)}
        </div>
      ) : filtered.length === 0 ? (
        <div className="courses-empty">
          <div className="courses-empty-icon"><FiSearch size={40} /></div>
          <h2 className="courses-empty-title">No courses found</h2>
          <p className="courses-empty-sub">We couldn't find any published courses matching your filters.</p>
          <button className="courses-empty-reset" onClick={handleClear}>Reset Filters</button>
        </div>
      ) : (
        <div className="courses-grid">
          {filtered.map((course, idx) => (
            <AdminCatalogCard
              key={course.courseId}
              course={course}
              onArchive={initiateArchive}
              onPreview={onPreview}
            />
          ))}
        </div>
      )}

      {/* Archive Modal */}
      {showArchiveModal && (
        <div className="cat-overlay" onClick={() => setShowArchiveModal(false)}>
          <div className="cat-modal confirm" onClick={(e) => e.stopPropagation()}>
            <div className="cat-modal-header">
              <h2>Archive Course</h2>
              <button className="cat-modal-close" onClick={() => setShowArchiveModal(false)}>
                <FiX size={18} />
              </button>
            </div>
            <div className="cat-modal-body">
              <p>Are you sure you want to archive <strong>{courseToArchive?.title}</strong>?</p>
              <span>This will remove the course from the public catalog and place it in the archive.</span>

              <div style={{ marginTop: '20px' }}>
                <label style={{ display: 'block', fontSize: '13.5px', fontWeight: '700', color: 'var(--sd-text)', marginBottom: '8px', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                  Archiving Reason <span style={{ color: '#c0392b' }}>*</span>
                </label>
                <textarea
                  className="courses-input"
                  style={{ width: '100%', minHeight: '100px', padding: '12px', fontSize: '14px', borderRadius: '12px', border: '1.5px solid var(--sd-border)', background: 'var(--sd-surface2)', outline: 'none', resize: 'vertical' }}
                  placeholder="Explain to the instructor why this course is being archived..."
                  value={archiveMessage}
                  onChange={(e) => setArchiveMessage(e.target.value)}
                />
              </div>
            </div>
            <div className="cat-modal-footer">
              <button className="cat-btn-cancel" onClick={() => setShowArchiveModal(false)}>
                Cancel
              </button>
              <button
                className="cat-btn-delete"
                onClick={confirmArchive}
                style={{ background: '#b89c4d', color: '#fff', border: 'none' }}
              >
                Yes, Archive it
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

/* ── Admin Archived Courses ──────────────────────────────────── */
const AdminArchivedCourses = ({ onUnarchive, onPreview }) => {
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openMenuId, setOpenMenuId] = useState(null);
  const [confirmCourse, setConfirmCourse] = useState(null);
  const menuRef = useRef(null);

  const [searchParams, setSearchParams] = useSearchParams();
  const [searchInput, setSearchInput] = useState(searchParams.get("q") || "");
  const activeQuery = searchParams.get("q") || "";

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get("/courses/admin-archived");
      setCourses(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setTimeout(() => setLoading(false), 600);
    }
  }, []);

  useEffect(() => { fetchData(); }, [fetchData]);

  const handleSearch = () => {
    setLoading(true);
    setSearchParams((prev) => {
      const next = new URLSearchParams(prev);
      if (searchInput.trim()) next.set("q", searchInput.trim());
      else next.delete("q");
      return next;
    }, { replace: true });
    setTimeout(() => setLoading(false), 500);
  };

  const handleClear = () => {
    setLoading(true);
    setSearchInput("");
    setSearchParams((prev) => {
      const next = new URLSearchParams(prev);
      next.delete("q");
      return next;
    }, { replace: true });
    setTimeout(() => setLoading(false), 500);
  };

  const filtered = useMemo(() => {
    let list = [...courses];
    if (activeQuery) {
      const q = activeQuery.toLowerCase();
      list = list.filter(c => 
        c.title?.toLowerCase().includes(q) || 
        c.instructor?.username?.toLowerCase().includes(q)
      );
    }
    return list;
  }, [courses, activeQuery]);

  // Close menu on outside click
  useEffect(() => {
    const handler = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) setOpenMenuId(null);
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const fmtDate = (raw) => {
    if (!raw) return "—";
    const d = Array.isArray(raw)
      ? new Date(raw[0], raw[1] - 1, raw[2])
      : new Date(raw);
    return d.toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" });
  };

  const BASE = "http://localhost:8080";
  const toSrc = (url) => url ? (url.startsWith("/api") ? `${BASE}${url}` : url) : null;
  const levelColor = (l) => ({ BEGINNER: "#27ae60", INTERMEDIATE: "#b89c4d", ADVANCED: "#c0392b" }[l] || "#b89c4d");
  const levelLabel = (l) => ({ BEGINNER: "Beginner", INTERMEDIATE: "Intermediate", ADVANCED: "Advanced" }[l] || l);

  const handleUnarchive = async () => {
    if (!confirmCourse) return;
    await onUnarchive(confirmCourse.courseId);
    setConfirmCourse(null);
    fetchData();
  };

  return (
    <div className="admin-page">
      <div className="admin-header">
        <div>
          <h1 className="admin-heading">Archived Courses</h1>
          <p className="admin-subheading">Courses you have archived — review the reason and restore if needed</p>
        </div>
        <div className="admin-stats">
          <div className="admin-stat">
            <span className="admin-stat-num">{courses.length}</span>
            <span className="admin-stat-label">Archived</span>
          </div>
        </div>
      </div>
      
      <div className="courses-search-bar" style={{ margin: '0 0 40px', maxWidth: 'none', display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
        <div className="courses-search-input-wrapper" style={{ flex: '1', minWidth: '300px' }}>
          <FiSearch className="search-icon" />
          <input
            type="text"
            placeholder="Search archived courses…"
            className="courses-input"
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
          />
          <div style={{ display: 'flex', gap: '8px', marginLeft: '10px' }}>
            <button className="courses-search-btn" onClick={handleSearch} style={{ padding: '8px 20px' }}>Search</button>
            <button
              className="courses-empty-reset"
              onClick={handleClear}
              style={{ margin: 0, padding: '8px 16px', background: 'transparent' }}
            >
              Clear
            </button>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="courses-grid">
          {Array.from({ length: 6 }).map((_, i) => <CourseCardSkeleton key={i} index={i} />)}
        </div>
      ) : filtered.length === 0 ? (
        <div className="admin-empty">
          <div className="admin-empty-icon"><FiArchive size={48} /></div>
          <h2 className="admin-empty-title">
            {activeQuery ? "No matching courses" : "No archived courses"}
          </h2>
          <p className="admin-empty-sub">
            {activeQuery 
              ? `We couldn't find any archived courses matching "${activeQuery}".`
              : "Courses you archive from the catalog will appear here."
            }
          </p>
          {activeQuery && (
            <button className="courses-empty-reset" onClick={handleClear} style={{ marginTop: '16px' }}>
              Clear Search
            </button>
          )}
        </div>
      ) : (
        <div className="aac-grid">
          {filtered.map((course) => {
            const thumb = toSrc(course.thumbnailUrl);
            const isMenuOpen = openMenuId === course.courseId;
            return (
              <div 
                key={course.courseId} 
                className="aac-card"
                style={{ cursor: 'pointer' }}
                onClick={() => onPreview(course.courseId)}
              >
                {/* Thumbnail */}
                <div className="aac-thumb">
                  {thumb
                    ? <img src={thumb} alt={course.title} />
                    : <div className="aac-thumb-empty"><FiArchive size={28} /></div>
                  }
                  {/* Three-dot menu */}
                  <div className="aac-menu-wrap" ref={isMenuOpen ? menuRef : null}>
                    <button
                      className="aac-dots-btn"
                      onClick={(e) => { e.stopPropagation(); setOpenMenuId(isMenuOpen ? null : course.courseId); }}
                      title="Options"
                    >
                      <FiMoreVertical size={16} />
                    </button>
                    {isMenuOpen && (
                      <div className="aac-dropdown">
                        <button
                          className="aac-dropdown-item"
                          onClick={(e) => { e.stopPropagation(); setOpenMenuId(null); setConfirmCourse(course); }}
                        >
                          <FiRefreshCw size={13} />
                          Unarchive Course
                        </button>
                      </div>
                    )}
                  </div>
                </div>

                {/* Body */}
                <div className="aac-body">
                  <div className="aac-tags">
                    <span className="aac-tag-level" style={{ background: levelColor(course.level) }}>
                      {levelLabel(course.level)}
                    </span>
                    <span className={`aac-tag-price ${course.isFree ? "free" : "paid"}`}>
                      {course.isFree ? "Free" : `$${course.price}`}
                    </span>
                  </div>
                  <h3 className="aac-title">{course.title}</h3>
                  <p className="aac-instructor">
                    {course.instructor?.photo
                      ? <img src={`${BASE}/api/files/${course.instructor.photo}`} alt="" className="aac-instr-avatar" />
                      : <span className="aac-instr-initials">{course.instructor?.username?.charAt(0).toUpperCase() || "I"}</span>
                    }
                    {course.instructor?.username || "Unknown Instructor"}
                  </p>

                  {/* Archive metadata */}
                  <div className="aac-meta-block">
                    <div className="aac-meta-row">
                      <FiCalendar size={13} className="aac-meta-icon" />
                      <span className="aac-meta-label">Archived on</span>
                      <span className="aac-meta-value">{fmtDate(course.archivedAt)}</span>
                    </div>
                    <div className="aac-meta-row reason">
                      <FiAlertCircle size={13} className="aac-meta-icon" />
                      <span className="aac-meta-label">Reason</span>
                    </div>
                    <p className="aac-reason-text">
                      {course.archiveReason || <em style={{ color: "#aaa" }}>No reason provided</em>}
                    </p>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Confirm unarchive modal */}
      {confirmCourse && (
        <div className="lm-backdrop" onClick={() => setConfirmCourse(null)}>
          <div className="lm-card" onClick={(e) => e.stopPropagation()}>
            <div className="lm-icon-ring" style={{ background: "rgba(39,174,96,0.1)", borderColor: "rgba(39,174,96,0.3)" }}>
              <FiRefreshCw size={22} style={{ color: "#27ae60" }} />
            </div>
            <h2 className="lm-title">Unarchive Course</h2>
            <p className="lm-message">
              Restore <strong>"{confirmCourse.title}"</strong> to the published catalog?
              The instructor will be notified.
            </p>
            <div className="lm-actions">
              <button className="lm-btn-cancel" onClick={() => setConfirmCourse(null)}>Cancel</button>
              <button
                className="lm-btn-confirm"
                style={{ background: "#27ae60", borderColor: "#27ae60" }}
                onClick={handleUnarchive}
              >
                Yes, Restore
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

const NAV_ITEMS = [
  { key: "feed", label: "Published Courses", Icon: FiBookOpen },
  { key: "archived", label: "Archived Courses", Icon: FiArchive },
  { key: "applications", label: "Instructor Applications", Icon: FiFileText },
  { key: "payments", label: "Platform Payments", Icon: FiDollarSign },
  { key: "instructors", label: "Manage Instructors", Icon: FiUsers },
  { key: "students", label: "Students", Icon: FiUsers },
  { key: "banned", label: "Banned Accounts", Icon: FiSlash },
  { key: "stats-overall", label: "Overall Statistics", Icon: FiBarChart2 },
  { key: "stats-today", label: "Today's Statistics", Icon: FiTrendingUp },
  { key: "badges", label: "Badges", Icon: FiAward },
  { key: "categories", label: "Categories", Icon: FiGrid },
];

const VALID_SECTIONS = new Set([
  ...NAV_ITEMS.map((n) => n.key),
  "profile",
  "course-preview",
]);

export default function AdminDashboard() {
  const [searchParams, setSearchParams] = useSearchParams();
  const initialSection = VALID_SECTIONS.has(searchParams.get("section"))
    ? searchParams.get("section")
    : "feed";
  const initialCourseId = searchParams.get("courseId");

  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showLogout, setShowLogout] = useState(false);
  const [selectedCourse, setSelectedCourse] = useState(null);
  const [previewCourseId, setPreviewCourseId] = useState(
    initialSection === "course-preview" && initialCourseId ? initialCourseId : null
  );
  const [toast, setToast] = useState(null);
  const [activeSection, setActiveSection] = useState(initialSection);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [adminUser, setAdminUser] = useState(null);

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

  // Reset preview when switching sections
  useEffect(() => {
    setPreviewCourseId(null);
  }, [activeSection]);

  // Sync activeSection FROM URL (handles navigation from children and sidebar)
  useEffect(() => {
    const section = searchParams.get("section");
    const courseId = searchParams.get("courseId");
    
    if (section && VALID_SECTIONS.has(section)) {
      if (section !== activeSection) {
        setActiveSection(section);
        setPreviewCourseId(null);
      }
      // Handle course-preview section with courseId
      if (section === "course-preview" && courseId) {
        setPreviewCourseId(courseId);
      }
    } else {
      // Default to feed if no valid section
      setActiveSection("feed");
    }
  }, [searchParams, activeSection]);

  const handleSectionChange = (newSection) => {
    // This will trigger the useEffect above via URL change
    setSearchParams({ section: newSection });
  };

  const raw = localStorage.getItem("username");
  const username = adminUser?.username || (raw && raw !== "null" && raw !== "undefined" ? raw : "Admin");
  const photoUrl = adminUser?.photo ? `http://localhost:8080/api/files/${adminUser.photo}` : null;

  useEffect(() => {
    const pendingId = localStorage.getItem("pendingCourseId");
    if (pendingId) localStorage.removeItem("pendingCourseId");
  }, []);

  const showToast = (type, msg) => {
    setToast({ type, msg });
    setTimeout(() => setToast(null), 3500);
  };

  const removeCourse = (courseId) =>
    setCourses((prev) => prev.filter((c) => c.courseId !== courseId));

  const handleArchive = async (courseId, message) => {
    try {
      await api.patch(`/courses/${courseId}/archive`, { message });
      removeCourse(courseId);
      showToast("success", "Course archived.");
    } catch (_) {
      showToast("error", "Failed to archive course.");
    }
  };

  const handleUnarchiveByAdmin = async (courseId) => {
    try {
      await api.patch(`/courses/${courseId}/unarchive-admin`);
      showToast("success", "Course restored and instructor notified.");
    } catch (err) {
      showToast("error", err?.response?.data || "Failed to unarchive course.");
    }
  };

  const confirmLogout = () => {
    localStorage.clear();
    window.location.href = "/login";
  };

  const renderContent = () => {
    // Handle course-preview section
    if (activeSection === "course-preview" && previewCourseId) {
      return (
        <AdminCoursePreview
          courseId={previewCourseId}
          onBack={() => {
            const returnTo = searchParams.get("returnTo");
            const returnId = searchParams.get("returnId");
            if (returnTo && returnId) {
              setPreviewCourseId(null);
              setActiveSection(returnTo);
              const params = { section: returnTo };
              if (returnTo === "students") params.studentId = returnId;
              if (returnTo === "instructors") params.instructorId = returnId;
              setSearchParams(params);
            } else {
              setPreviewCourseId(null);
              setActiveSection("feed");
              setSearchParams({ section: "feed" });
            }
          }}
          onStudentProfile={(id) => {
            setPreviewCourseId(null);
            setSearchParams({ section: "students", studentId: id, fromCourseId: previewCourseId });
          }}
        />
      );
    }
    
    if (previewCourseId) {
      return (
        <AdminCoursePreview
          courseId={previewCourseId}
          onBack={() => {
            const returnTo = searchParams.get("returnTo");
            const returnId = searchParams.get("returnId");
            if (returnTo && returnId) {
              setPreviewCourseId(null);
              setActiveSection(returnTo);
              const params = { section: returnTo };
              if (returnTo === "students") params.studentId = returnId;
              if (returnTo === "instructors") params.instructorId = returnId;
              setSearchParams(params);
            } else {
              setPreviewCourseId(null);
            }
          }}
          onStudentProfile={(id) => {
            setPreviewCourseId(null);
            setSearchParams({ section: "students", studentId: id, fromCourseId: previewCourseId });
          }}
        />
      );
    }

    if (activeSection === "profile") return <AdminProfile onUpdate={(data) => setAdminUser(prev => ({ ...prev, ...data }))} />;
    if (activeSection === "applications") return <InstructorApplications />;
    if (activeSection === "badges") return <AdminBadges />;
    if (activeSection === "categories") return <AdminCategories />;
    if (activeSection === "payments") return <AdminPayment />;

    // ── Instructors ────────────────────────────────────────────────────────
    if (activeSection === "instructors") {
      return (
        <AdminInstructors 
          onCourseClick={(courseId, instructorId) => {
            setPreviewCourseId(courseId);
            setActiveSection("course-preview");
            setSearchParams({ 
              section: "course-preview", 
              courseId, 
              returnTo: "instructors", 
              returnId: instructorId 
            });
          }}
        />
      );
    }

    // ── Students ────────────────────────────────────────────────────────
    if (activeSection === "students") {
      return (
        <AdminStudents 
          onCourseClick={(courseId, studentId) => {
            setPreviewCourseId(courseId);
            setActiveSection("course-preview");
            setSearchParams({ 
              section: "course-preview", 
              courseId, 
              returnTo: "students", 
              returnId: studentId 
            });
          }}
        />
      );
    }

    // ── Banned Accounts ─────────────────────────────────────────────────
    if (activeSection === "banned") return <BannedAccount />;

    // ── Archived Courses (Admin) ──────────────────────────────────
    if (activeSection === "archived") {
      return (
        <AdminArchivedCourses 
          onUnarchive={handleUnarchiveByAdmin} 
          onPreview={(id) => setPreviewCourseId(id)}
        />
      );
    }

    // ── Feed (Published Courses) ──────────────────────────────────────────
    if (activeSection === "feed") {
      return (
        <AdminPublishedCourses
          onArchive={handleArchive}
          onPreview={(id) => setPreviewCourseId(id)}
        />
      );
    }

    // ── Overall Statistics ────────────────────────────────────────────────
    if (activeSection === "stats-overall") return <AdminOverallStats />;
    if (activeSection === "stats-today") return <AdminTodayStats />;

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
          <NotificationBell
            onNotificationClick={(n) => {
              if (n.type === "NEW_INSTRUCTOR_APPLICATION") {
                handleSectionChange("applications");
              } else if (n.courseId) {
                setPreviewCourseId(n.courseId);
                setActiveSection("course-preview");
                setSearchParams({ section: "course-preview", courseId: n.courseId });
              }
            }}
          />

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
                onClick={() => handleSectionChange(key)}
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
              onClick={() => handleSectionChange("profile")}
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
        >
          {renderContent()}
        </main>
      </div>

      {/* ── Course detail modal ── */}
      {selectedCourse && (
        <AdminCourseDetail
          course={selectedCourse}
          onClose={() => setSelectedCourse(null)}
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