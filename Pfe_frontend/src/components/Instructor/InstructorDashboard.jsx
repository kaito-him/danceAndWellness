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
  FiMenu,
  FiCheckCircle,
  FiXCircle,
  FiPlus,
  FiRss,
  FiEdit3,
  FiArchive,
} from "react-icons/fi";
import AddCourseForm from "../Instructor/Addcourseform";
import CourseCard from "../Instructor/CourseCard";
import InstructorCoursePreview from "../Instructor/InstructorCoursePreview";
import InstructorStudentProfile from "../Instructor/InstructorStudentProfile";
import CourseDetails from "../Instructor/CourseDetails";
import NotificationBell from "../NotificationBell.jsx";
import InstructorProfile from "./InstructorProfile";
import InstructorPayment from "./Instructorpayment";
import InstructorMessagesPage from "./InstructorMessagesPage";
import LogoutModal from "../LogoutModal";
import RoleWarningModal from "./RoleWarningModal";
import api from "./../services/api";
import "../../styles/Instructordashboard.css";
import InstructorFeed from "../Instructor/Instructorfeed";
import UserChip from "../UserChip";
import logo from "../../assets/Dicone.png";
import "../../styles/Messages.css";

/* ─── sidebar items ──────────────────────────────────────────────── */
const NAV_ITEMS = [
  { key: "courses", label: "My Courses", Icon: FiGrid },
  { key: "feed", label: "Feed", Icon: FiRss },
  { key: "drafts", label: "Drafts", Icon: FiEdit3 },
  { key: "archive", label: "Archive", Icon: FiArchive },
  { key: "messages", label: "Messages", Icon: FiMessageSquare },
  { key: "payments", label: "Payments", Icon: FiCreditCard },
];

const VALID_SECTIONS = new Set([
  ...NAV_ITEMS.map((n) => n.key),
  "profile",
  "course-preview",
  "student-profile",
]);

export default function InstructorDashboard() {
  const [searchParams, setSearchParams] = useSearchParams();
  const initialSection = VALID_SECTIONS.has(searchParams.get("section"))
    ? searchParams.get("section")
    : "courses";
  const initialCourseId = searchParams.get("courseId");

  const [modalOpen, setModalOpen] = useState(false);
  const [activeTab, setActiveTab] = useState(initialSection);
  const [courses, setCourses] = useState([]);
  const [editingCourse, setEditingCourse] = useState(
    initialSection === "course-preview" && initialCourseId ? { courseId: initialCourseId } : null
  );
  const [editingDraftCourse, setEditingDraftCourse] = useState(null);
  const [confirmPublishCourse, setConfirmPublishCourse] = useState(null);
  const [confirmArchiveCourse, setConfirmArchiveCourse] = useState(null);
  const [confirmUnarchiveCourse, setConfirmUnarchiveCourse] = useState(null);
  const [confirmDeleteCourse, setConfirmDeleteCourse] = useState(null);
  const [toast, setToast] = useState(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [showLogout, setShowLogout] = useState(false);
  const [user, setUser] = useState(null);
  const [instructor, setInstructor] = useState(null);
  const [selectedStudentUserId, setSelectedStudentUserId] = useState(searchParams.get("studentUserId"));
  const [studentProfileSource, setStudentProfileSource] = useState("course");
  const [openCommentsToken, setOpenCommentsToken] = useState(0);
  const [showRoleWarning, setShowRoleWarning] = useState(searchParams.get("showRoleWarning") === "true");

  useEffect(() => {
    api.get("/users/me")
      .then(res => {
        setUser(res.data);
        // Also fetch instructor details by userId
        return api.get(`/instructors/by-user/${res.data.userId}`);
      })
      .then(res => {
        setInstructor(res.data);
        // Merge instructor photo into user object for UserChip
        if (res.data?.photo) {
          setUser(prev => ({ ...prev, photo: res.data.photo }));
        }
      })
      .catch(err => console.error(err));
  }, []);

  const username = user?.username || localStorage.getItem("username") || "Instructor";

  // Keep URL in sync with active section
  useEffect(() => {
    const currentParams = new URLSearchParams(window.location.search);
    if (currentParams.get("section") !== activeTab) {
      currentParams.set("section", activeTab);
    }
    if (activeTab === "course-preview" && editingCourse?.courseId) {
      currentParams.set("courseId", editingCourse.courseId);
    } else {
      currentParams.delete("courseId");
    }
    if (activeTab === "student-profile" && selectedStudentUserId) {
      currentParams.set("studentUserId", selectedStudentUserId);
    } else {
      currentParams.delete("studentUserId");
    }
    setSearchParams(currentParams, { replace: true });
  }, [activeTab, editingCourse, selectedStudentUserId, setSearchParams]);

  const [draftCount, setDraftCount] = useState(0);
  const [archiveCount, setArchiveCount] = useState(0);

  /* ── data fetching ─────────────────────────────────────────────── */
  const fetchCourses = async () => {
    try {
      const res = await api.get("/courses/my-published");
      setCourses(res.data);
    } catch (_) {
      showToast("error", "Failed to load courses.");
    }
  };

  const fetchDrafts = async () => {
    try {
      const res = await api.get("/courses/my-drafts");
      setCourses(res.data);
      setDraftCount(res.data.length);
    } catch (_) {
      showToast("error", "Failed to load drafts.");
    }
  };

  const fetchArchived = async () => {
    try {
      const res = await api.get("/courses/my-archived");
      setCourses(res.data);
      setArchiveCount(res.data.length);
    } catch (_) {
      showToast("error", "Failed to load archived courses.");
    }
  };

  const refreshCounts = async () => {
    try {
      const [d, a] = await Promise.all([
        api.get("/courses/my-drafts"),
        api.get("/courses/my-archived")
      ]);
      setDraftCount(d.data.length);
      setArchiveCount(a.data.length);
    } catch (err) {
      console.error("Failed to fetch counts", err);
    }
  };

  // Fetch all counts on mount for sidebar badges
  useEffect(() => {
    refreshCounts();
  }, []);

  useEffect(() => {
    if (activeTab === "drafts") {
      fetchDrafts();
    } else if (activeTab === "archive") {
      fetchArchived();
    } else if (activeTab === "courses") {
      fetchCourses();
    }
  }, [activeTab]);

  /* ── helpers ───────────────────────────────────────────────────── */
  const showToast = (type, msg) => {
    setToast({ type, msg });
    setTimeout(() => setToast(null), 3500);
  };

  const handleDelete = async (courseOrId) => {
    const courseId = typeof courseOrId === "string" ? courseOrId : courseOrId?.courseId;
    if (!courseId) return;
    try {
      await api.delete(`/courses/${courseId}`);
      setCourses((prev) => prev.filter((c) => c.courseId !== courseId));
      showToast("success", "Course deleted.");
      refreshCounts();
      // Refresh the course list
      if (activeTab === "courses") fetchCourses();
      else if (activeTab === "drafts") fetchDrafts();
      else if (activeTab === "archive") fetchArchived();
    } catch (_) {
      showToast("error", "Failed to delete course.");
    }
  };

  const handleArchive = async (courseId) => {
    try {
      await api.patch(`/courses/${courseId}/archive-instructor`);
      setCourses((prev) => prev.filter((c) => c.courseId !== courseId));
      showToast("success", "Course archived.");
      refreshCounts();
      if (activeTab === "courses") fetchCourses();
      else if (activeTab === "archive") fetchArchived();
    } catch (err) {
      showToast("error", err?.response?.data || "Failed to archive course.");
    }
  };

  const handleUnarchive = async (courseId) => {
    try {
      await api.patch(`/courses/${courseId}/unarchive`);
      setCourses((prev) => prev.filter((c) => c.courseId !== courseId));
      showToast("success", "Course moved back to published.");
      refreshCounts();
      if (activeTab === "archive") fetchArchived();
      else if (activeTab === "courses") fetchCourses();
    } catch (err) {
      showToast("error", err?.response?.data || "Failed to unarchive course.");
    }
  };

  const handlePublishDraft = async (courseId) => {
    try {
      const res = await api.patch(`/courses/${courseId}/publish`);
      showToast("success", "Course published successfully!");
      refreshCounts();
      if (activeTab === "drafts") fetchDrafts();
      else if (activeTab === "courses") fetchCourses();
    } catch (err) {
      showToast("error", err?.response?.data || "Failed to publish draft.");
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
    if (type === "success") {
      refreshCounts();
      if (activeTab === "courses") fetchCourses();
      else if (activeTab === "drafts") fetchDrafts();
    }
  };

  const confirmLogout = () => {
    localStorage.clear();
    window.location.href = "/login";
  };

  const handleSwitchAccount = () => {
    // Close the modal and navigate to role selection or signup
    setShowRoleWarning(false);
    window.location.href = "/signup";
  };

  const handleCancelRoleWarning = () => {
    // Close the modal and stay on instructor dashboard
    setShowRoleWarning(false);
    // Remove the showRoleWarning param from URL
    const currentParams = new URLSearchParams(window.location.search);
    currentParams.delete("showRoleWarning");
    currentParams.delete("courseId");
    setSearchParams(currentParams, { replace: true });
    // Reset to courses view
    setEditingCourse(null);
    setActiveTab("courses");
  };

  /* ── section renderer ──────────────────────────────────────────── */
  const renderContent = () => {

    /* ── Manage Profile ─────────────────────────────────────────── */
    if (activeTab === "profile") {
      return <InstructorProfile />;
    }

    if (activeTab === "course-preview" && editingCourse?.courseId) {
      return (
        <InstructorCoursePreview
          courseId={editingCourse.courseId}
          instructorId={instructor?.id}
          instructor={instructor}
          openCommentsOnLoadToken={openCommentsToken}
          onStudentProfile={(studentUserId) => {
            setSelectedStudentUserId(studentUserId);
            setStudentProfileSource("course");
            setActiveTab("student-profile");
          }}
          onBack={() => { setEditingCourse(null); setActiveTab("courses"); }}
        />
      );
    }

    if (activeTab === "student-profile" && selectedStudentUserId) {
      return (
        <InstructorStudentProfile
          studentUserId={selectedStudentUserId}
          instructor={instructor}
          onCourseSelect={(courseId) => {
            setEditingCourse({ courseId });
            setActiveTab("course-preview");
          }}
          onBack={() => setActiveTab(studentProfileSource === "payments" ? "payments" : "course-preview")}
          backLabel={studentProfileSource === "payments" ? "Back to Payments" : "Back to Course"}
        />
      );
    }

    /* ── Feed ───────────────────────────────────────────────────── */
    if (activeTab === "feed") return <InstructorFeed />;
    /* ── Messages ───────────────────────────────────────────────── */
    if (activeTab === "messages") {
      return <InstructorMessagesPage currentUserId={user?.userId} />;
    }

    /* ── Payments ───────────────────────────────────────────────── */
    if (activeTab === "payments") {
      return (
        <InstructorPayment
          onStudentClick={(studentUserId) => {
            setSelectedStudentUserId(studentUserId);
            setStudentProfileSource("payments");
            setActiveTab("student-profile");
          }}
          onCourseClick={(courseId) => {
            setEditingCourse({ courseId });
            setActiveTab("course-preview");
          }}
        />
      );
    }

    /* ── Drafts ────────────────────────────────────────────────── */
    if (activeTab === "drafts") {
      return (
        <>
          <div className="id-header">
            <div>
              <h1 className="id-heading">Drafts</h1>
              <p className="id-subheading">Courses saved as drafts — edit, delete, or publish when ready</p>
            </div>
            {courses.length > 0 && (
              <div className="id-stats">
                <div className="id-stat">
                  <span className="id-stat-num">{courses.length}</span>
                  <span className="id-stat-label">Draft Courses</span>
                </div>
              </div>
            )}
          </div>

          {courses.length === 0 ? (
            <div className="id-empty">
              <div className="id-empty-icon"><FiBookOpen size={48} /></div>
              <h2 className="id-empty-title">No drafts</h2>
              <p className="id-empty-sub">Use “Save Draft” when creating a course.</p>
            </div>
          ) : (
            <div className="id-grid">
              {courses.map((course) => (
                <CourseCard
                  key={course.courseId}
                  course={course}
                  onDelete={(c) => setConfirmDeleteCourse(c)}
                  onEdit={(c) => setEditingDraftCourse(c)}
                  onPublish={() => setConfirmPublishCourse(course)}
                  publishLabel="Publish"
                />
              ))}
            </div>
          )}
        </>
      );
    }

    /* ── Archive ───────────────────────────────────────────────── */
    if (activeTab === "archive") {
      return (
        <>
          <div className="id-header">
            <div>
              <h1 className="id-heading">Archive</h1>
              <p className="id-subheading">Manage archived courses: unarchive or delete permanently</p>
            </div>
            {courses.length > 0 && (
              <div className="id-stats">
                <div className="id-stat">
                  <span className="id-stat-num">{courses.length}</span>
                  <span className="id-stat-label">Archived Courses</span>
                </div>
              </div>
            )}
          </div>

          {courses.length === 0 ? (
            <div className="id-empty">
              <div className="id-empty-icon"><FiArchive size={48} /></div>
              <h2 className="id-empty-title">No archived courses</h2>
              <p className="id-empty-sub">Archived free courses will appear here.</p>
            </div>
          ) : (
            <div className="id-grid">
              {courses.map((course) => (
                <CourseCard
                  key={course.courseId}
                  course={course}
                  onDelete={(c) => setConfirmDeleteCourse(c)}
                  onEdit={(c) => { setEditingCourse(c); setActiveTab("course-preview"); }}
                  onPublish={() => setConfirmUnarchiveCourse(course)}
                  publishLabel="Unarchive"
                  deleteLabel="Delete Permanently"
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
                onDelete={course.isFree ? (c) => setConfirmArchiveCourse(c) : null}
                onEdit={(c) => { setEditingCourse(c); setActiveTab("course-preview"); }}
                deleteLabel="Archive"
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
          <NotificationBell
            onNotificationClick={(n) => {
              if (!n?.courseId) return;
              setEditingCourse({ courseId: n.courseId });
              setActiveTab("course-preview");
              if (n.openComments || n.type === "COURSE_COMMENT") {
                setOpenCommentsToken((v) => v + 1);
              }
            }}
          />

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

                {/* badges */}
                {key === "drafts" && draftCount > 0 && (
                  <span className="id-sidenav-badge">{draftCount}</span>
                )}
                {key === "archive" && archiveCount > 0 && (
                  <span className="id-sidenav-badge">{archiveCount}</span>
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
          className={`id-main ${activeTab === "messages" ? "id-main-no-padding" : ""}`}
        >
          {renderContent()}
        </main>
      </div>

      {/* ── modals / overlays ──────────────────────────────────── */}
      {modalOpen && (
        <AddCourseForm
          onClose={() => setModalOpen(false)}
          onSuccess={handleCourseAdded}
          instructor={instructor}
        />
      )}

      {showLogout && (
        <LogoutModal
          onConfirm={confirmLogout}
          onCancel={() => setShowLogout(false)}
        />
      )}

      {showRoleWarning && (
        <RoleWarningModal
          onSwitchAccount={handleSwitchAccount}
          onCancel={handleCancelRoleWarning}
        />
      )}

      {editingDraftCourse && (
        <CourseDetails
          course={editingDraftCourse}
          instructor={instructor}
          onClose={() => setEditingDraftCourse(null)}
          onSaved={(updated) => {
            setCourses((prev) => prev.map((c) => (c.courseId === updated.courseId ? updated : c)));
            setEditingDraftCourse(null);
            showToast("success", "Draft updated.");
          }}
        />
      )}

      {confirmPublishCourse && (
        <div className="lm-backdrop" onClick={() => setConfirmPublishCourse(null)}>
          <div className="lm-card" onClick={(e) => e.stopPropagation()}>
            <h2 className="lm-title">Publish Draft</h2>
            <p className="lm-message">
              Publish this draft now? Your course will be published immediately and available to students.
            </p>
            <div className="lm-actions">
              <button className="lm-btn-cancel" onClick={() => setConfirmPublishCourse(null)}>Cancel</button>
              <button
                className="lm-btn-confirm"
                onClick={() => {
                  handlePublishDraft(confirmPublishCourse.courseId);
                  setConfirmPublishCourse(null);
                }}
              >
                Confirm Publish
              </button>
            </div>
          </div>
        </div>
      )}

      {confirmArchiveCourse && (
        <div className="lm-backdrop" onClick={() => setConfirmArchiveCourse(null)}>
          <div className="lm-card" onClick={(e) => e.stopPropagation()}>
            <h2 className="lm-title">Archive Course</h2>
            <p className="lm-message">
              Archive "{confirmArchiveCourse.title}"? You can restore it later from the Archive section.
            </p>
            <div className="lm-actions">
              <button className="lm-btn-cancel" onClick={() => setConfirmArchiveCourse(null)}>Cancel</button>
              <button
                className="lm-btn-confirm"
                onClick={() => {
                  handleArchive(confirmArchiveCourse.courseId);
                  setConfirmArchiveCourse(null);
                }}
              >
                Confirm Archive
              </button>
            </div>
          </div>
        </div>
      )}

      {confirmUnarchiveCourse && (
        <div className="lm-backdrop" onClick={() => setConfirmUnarchiveCourse(null)}>
          <div className="lm-card" onClick={(e) => e.stopPropagation()}>
            <h2 className="lm-title">Unarchive Course</h2>
            <p className="lm-message">
              Move "{confirmUnarchiveCourse.title}" back to published courses?
            </p>
            <div className="lm-actions">
              <button className="lm-btn-cancel" onClick={() => setConfirmUnarchiveCourse(null)}>Cancel</button>
              <button
                className="lm-btn-confirm"
                onClick={() => {
                  handleUnarchive(confirmUnarchiveCourse.courseId);
                  setConfirmUnarchiveCourse(null);
                }}
              >
                Confirm Unarchive
              </button>
            </div>
          </div>
        </div>
      )}

      {confirmDeleteCourse && (
        <div className="lm-backdrop" onClick={() => setConfirmDeleteCourse(null)}>
          <div className="lm-card" onClick={(e) => e.stopPropagation()}>
            <h2 className="lm-title">Delete Permanently</h2>
            <p className="lm-message">
              Permanently delete "{confirmDeleteCourse.title}"? This cannot be undone.
            </p>
            <div className="lm-actions">
              <button className="lm-btn-cancel" onClick={() => setConfirmDeleteCourse(null)}>Cancel</button>
              <button
                className="lm-btn-confirm"
                onClick={() => {
                  handleDelete(confirmDeleteCourse.courseId);
                  setConfirmDeleteCourse(null);
                }}
              >
                Confirm Delete
              </button>
            </div>
          </div>
        </div>
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