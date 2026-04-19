import { useState, useMemo, useEffect } from "react";
import axios from "axios";
import {
  FiHome, FiBookOpen, FiCalendar, FiAward,
  FiMessageSquare, FiCreditCard, FiSettings,
  FiHelpCircle, FiLogOut, FiBell, FiSearch, FiX,
  FiLayers, FiClock, FiChevronRight,
} from "react-icons/fi";
import useCurrentUser from "../services/useCurrentUser";
import LogoutModal from "../LogoutModal";
import EmbeddedCoursePage from "./Embeddedcoursepage";
import EmbeddedLessonCardsPage from "./EmbeddedLessonCardsPage";
import EmbeddedLessonPlayerPage from "./EmbeddedLessonPlayerPage";
import "../../styles/StudentDashboard.css";
import UserChip from "../UserChip";
import logo from "../../assets/Dicone.png";

/* ── Constants ─────────────────────────────────────────────── */
const LEVELS    = ["All Levels", "BEGINNER", "INTERMEDIATE", "ADVANCED"];
const SORT_OPTS = ["Most Popular", "Highest Rated", "Price: Low to High", "Price: High to Low"];

const LEVEL_META = {
  BEGINNER:     { label: "Beginner",     color: "#3a7d44" },
  INTERMEDIATE: { label: "Intermediate", color: "#b89c4d" },
  ADVANCED:     { label: "Advanced",     color: "#9b3a3a" },
};

const NAV_ITEMS = [
  { key: "home",         Icon: FiHome,          label: "Home"                   },
  { key: "my-courses",   Icon: FiBookOpen,      label: "My Courses"             },
  { key: "sessions",     Icon: FiCalendar,      label: "Planned Sessions"       },
  { key: "certificates", Icon: FiAward,         label: "Certificates"           },
  { key: "messages",     Icon: FiMessageSquare, label: "Messages / Chat"        },
  { key: "account",      Icon: FiCreditCard,    label: "Account & Subscription" },
  { key: "settings",     Icon: FiSettings,      label: "Settings & Profile"     },
  { key: "help",         Icon: FiHelpCircle,    label: "Help & Support"         },
];


const HOME     = ()                        => ({ type: "home" });
const COURSE   = (courseId)                => ({ type: "course",  courseId });
const LESSONS  = (courseId)                => ({ type: "lessons", courseId });
const PLAYER   = (courseId, lessonId)      => ({ type: "player",  courseId, lessonId });

/* ══════════════════════════════════════════════
   COURSE CARD
══════════════════════════════════════════════ */
const CourseCard = ({ course, index, onSelect }) => {
  const meta = LEVEL_META[course.level] || LEVEL_META.BEGINNER;

  return (
    <article
      className="sd-card"
      style={{ animationDelay: `${index * 50}ms` }}
      onClick={() => onSelect(course.courseId)}
    >
      <div className="sd-card-thumb">
        {course.thumbnailUrl ? (
          <img
            src={`http://localhost:8080${course.thumbnailUrl}`}
            alt={course.title}
            style={{ width: "100%", height: "100%", objectFit: "cover" }}
          />
        ) : (
          <div className="sd-card-thumb-placeholder"><FiLayers size={36} /></div>
        )}
        <span className="sd-card-level" style={{ background: meta.color }}>{meta.label}</span>
        {course.isFree
          ? <span className="sd-card-price free">Free</span>
          : <span className="sd-card-price paid">${course.price?.toFixed(2)}</span>}
      </div>

      <div className="sd-card-body">
        <p className="sd-card-cat">{course.category}</p>
        <h3 className="sd-card-title">{course.title}</h3>
        <div className="sd-card-instructor">
          <div className="sd-card-instr-avatar">
            {course.instructor?.username?.charAt(0).toUpperCase() || "?"}
          </div>
          <span className="sd-card-instr-name">
            {course.instructor?.username || "Unknown Instructor"}
          </span>
        </div>
        <div className="sd-card-stats">
          <span className="sd-card-stat"><FiLayers size={12} /> {course.lessons?.length ?? 0} lessons</span>
          <span className="sd-card-stat"><FiClock size={12} /> {course.quizzes?.length ?? 0} quizzes</span>
        </div>
        <button className="sd-card-cta">
          {course.isFree ? "Enroll Free" : "View Course"} <FiChevronRight size={14} />
        </button>
      </div>
    </article>
  );
};

/* ══════════════════════════════════════════════
   HOME — catalog with search / filters
══════════════════════════════════════════════ */
const HomeContent = ({ username, onCourseSelect }) => {
  const [courses,  setCourses]  = useState([]);
  const [loading,  setLoading]  = useState(true);
  const [search,   setSearch]   = useState("");
  const [category, setCategory] = useState("ALL");
  const [level,    setLevel]    = useState("All Levels");
  const [sort,     setSort]     = useState("Most Popular");
  const [showFree, setShowFree] = useState(false);

  useEffect(() => {
    axios.get("http://localhost:8080/api/courses/published")
      .then(res  => { setCourses(res.data); setLoading(false); })
      .catch(err => { console.error(err); setLoading(false); });
  }, []);

  const categories = useMemo(
    () => ["ALL", ...new Set(courses.map(c => c.category).filter(Boolean))],
    [courses]
  );

  const filtered = useMemo(() => {
    let list = [...courses];
    if (search.trim())
      list = list.filter(c =>
        c.title.toLowerCase().includes(search.toLowerCase()) ||
        c.instructor?.username?.toLowerCase().includes(search.toLowerCase()));
    if (category !== "ALL")     list = list.filter(c => c.category === category);
    if (level !== "All Levels") list = list.filter(c => c.level === level);
    if (showFree)               list = list.filter(c => c.isFree);
    if (sort === "Price: Low to High") list.sort((a, b) => (a.price ?? 0) - (b.price ?? 0));
    if (sort === "Price: High to Low") list.sort((a, b) => (b.price ?? 0) - (a.price ?? 0));
    return list;
  }, [courses, search, category, level, sort, showFree]);

  const hasActive = search || category !== "ALL" || level !== "All Levels" || showFree;
  const clearAll  = () => { setSearch(""); setCategory("ALL"); setLevel("All Levels"); setShowFree(false); };

  return (
    <div className="sd-home">
      <div className="sd-welcome-block">
        <p className="sd-welcome-label">Good day 👋</p>
        <h1 className="sd-welcome-title">Welcome back, <span>{username}</span></h1>
        <p className="sd-welcome-sub">Explore our full catalog and continue your learning journey.</p>
      </div>

      <div className="sd-search-wrap">
        <span className="sd-search-icon"><FiSearch size={17} /></span>
        <input type="text" className="sd-search-input"
          placeholder="Search courses or instructors…"
          value={search} onChange={e => setSearch(e.target.value)} />
        {search && (
          <button className="sd-search-clear" onClick={() => setSearch("")}>
            <FiX size={15} />
          </button>
        )}
      </div>

      <div className="sd-filters">
        <div className="sd-pills-row">
          {categories.map(cat => (
            <button key={cat}
              className={`sd-pill ${category === cat ? "active" : ""}`}
              onClick={() => setCategory(cat)}>
              {cat === "ALL" ? "All" : cat}
            </button>
          ))}
        </div>
        <div className="sd-filter-divider" />
        <select className="sd-select" value={level} onChange={e => setLevel(e.target.value)}>
          {LEVELS.map(l => <option key={l} value={l}>{l}</option>)}
        </select>
        <select className="sd-select" value={sort} onChange={e => setSort(e.target.value)}>
          {SORT_OPTS.map(s => <option key={s} value={s}>{s}</option>)}
        </select>
        <button className={`sd-pill ${showFree ? "free-active" : ""}`}
          onClick={() => setShowFree(f => !f)}>
          Free Only
        </button>
        {hasActive && (
          <button className="sd-pill clear-btn" onClick={clearAll}>
            <FiX size={11} /> Clear
          </button>
        )}
        <span className="sd-result-count">
          {loading ? "—" : `${filtered.length} course${filtered.length !== 1 ? "s" : ""}`}
        </span>
      </div>

      {loading ? (
        <div className="sd-courses-loading">
          <div className="sd-spinner" /><p>Loading courses…</p>
        </div>
      ) : filtered.length === 0 ? (
        <div className="sd-empty">
          <div className="sd-empty-icon">🔍</div>
          <h2 className="sd-empty-title">No courses found</h2>
          <p className="sd-empty-sub">Try adjusting your filters or search terms.</p>
          {hasActive && <button className="sd-btn-clear" onClick={clearAll}>Clear Filters</button>}
        </div>
      ) : (
        <div className="sd-course-grid">
          {filtered.map((course, idx) => (
            <CourseCard key={course.courseId} course={course} index={idx} onSelect={onCourseSelect} />
          ))}
        </div>
      )}
    </div>
  );
};

/* ══════════════════════════════════════════════
   PLACEHOLDER
══════════════════════════════════════════════ */
const Placeholder = ({ Icon, title, sub }) => (
  <div className="sd-placeholder">
    <div className="sd-placeholder-icon"><Icon size={52} /></div>
    <h2 className="sd-placeholder-title">{title}</h2>
    <p className="sd-placeholder-sub">{sub || "This section is coming soon."}</p>
  </div>
);

/* ══════════════════════════════════════════════
   MAIN DASHBOARD
══════════════════════════════════════════════ */
export default function StudentDashboard() {
  const { user, loading }           = useCurrentUser();
  const [activeTab,  setActiveTab]  = useState("home");
  const [sideOpen,   setSide]       = useState(true);
  const [notifOpen,  setNotif]      = useState(false);
  const [showLogout, setShowLogout] = useState(false);

  /* ── Single view state drives everything inside the home tab ── */
  const [view, setView]   = useState(HOME());
  useEffect(() => {
  // "pendingCourseDirect" → skip course detail, go straight to lessons
  const pendingDirect = localStorage.getItem("pendingCourseDirect");
  if (pendingDirect) {
    localStorage.removeItem("pendingCourseDirect");
    setView(LESSONS(pendingDirect));
    return;
  }

  // "pendingCourseId" → open course detail page
  const pendingId = localStorage.getItem("pendingCourseId");
  if (pendingId) {
    localStorage.removeItem("pendingCourseId");
    setView(COURSE(pendingId));
  }
}, []);
  const username = user?.username || localStorage.getItem("username") || "Student";

  const confirmLogout = () => { localStorage.clear(); window.location.href = "/login"; };

  /* Scroll to top on every view change */
  useEffect(() => { window.scrollTo({ top: 0, behavior: "smooth" }); }, [view]);

  /* Switching any sidebar tab resets to catalog */
  const handleTabChange = (key) => {
    setActiveTab(key);
    if (key === "home") setView(HOME());
    else                setView(HOME());
  };

  /* ── View transitions ── */
  const goToCourse   = (courseId)           => setView(COURSE(courseId));
  const goToLessons  = (courseId)           => setView(LESSONS(courseId));
  const goToPlayer   = (courseId, lessonId) => setView(PLAYER(courseId, lessonId));

  /* ── Content renderer ── */
  const renderContent = () => {
    if (activeTab !== "home") {
      switch (activeTab) {
        case "my-courses":   return <Placeholder Icon={FiBookOpen}      title="My Courses"             sub="Your enrolled courses will appear here." />;
        case "sessions":     return <Placeholder Icon={FiCalendar}      title="Planned Sessions"       sub="Upcoming live sessions will appear here." />;
        case "certificates": return <Placeholder Icon={FiAward}         title="Certificates"           sub="Your earned certificates will appear here." />;
        case "messages":     return <Placeholder Icon={FiMessageSquare} title="Messages / Chat"        sub="Conversations with instructors will appear here." />;
        case "account":      return <Placeholder Icon={FiCreditCard}    title="Account & Subscription" sub="Manage your plan and billing here." />;
        case "settings":     return <Placeholder Icon={FiSettings}      title="Settings & Profile"     sub="Update your profile and preferences here." />;
        case "help":         return <Placeholder Icon={FiHelpCircle}    title="Help & Support"         sub="FAQs and support resources will appear here." />;
        default:             return null;
      }
    }

    /* Home tab — route by view type */
    switch (view.type) {

      case "course":
        return (
          <EmbeddedCoursePage
            courseId={view.courseId}
            onBack={() => setView(HOME())}
            onBrowseLessons={(cid) => goToLessons(cid)}
          />
        );

      case "lessons":
        return (
          <EmbeddedLessonCardsPage
            courseId={view.courseId}
            onBack={() => setView(COURSE(view.courseId))}
            onSelectLesson={(lid) => goToPlayer(view.courseId, lid)}
          />
        );

      case "player":
        return (
          <EmbeddedLessonPlayerPage
            courseId={view.courseId}
            lessonId={view.lessonId}
            onBack={() => setView(LESSONS(view.courseId))}
            onLessonChange={(lid) => setView(PLAYER(view.courseId, lid))}
          />
        );

      default:
        return <HomeContent username={username} onCourseSelect={goToCourse} />;
    }
  };

  if (loading) return (
    <div className="sd-loading-screen">
      <div className="sd-spinner" /> Loading your dashboard…
    </div>
  );

  return (
    <div className="sd-root">

      {/* ── TOP NAV ── */}
      <header className="sd-topnav">
        <div className="sd-topnav-left">
          <button className="sd-hamburger" onClick={() => setSide(o => !o)} aria-label="Toggle sidebar">
            <span /><span /><span />
          </button>
          <div className="sd-logo-flex" style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <img src={logo} alt="Logo" style={{ height: '42px', width: 'auto' }} />
            <span className="sd-logo">Dance &amp; Wellness</span>
          </div>
        </div>

        <div className="sd-topnav-right">
          <div style={{ position: "relative" }}>
            <button className="sd-notif-btn" onClick={() => setNotif(o => !o)} aria-label="Notifications">
              <FiBell size={17} />
              <span className="sd-notif-badge">2</span>
            </button>
            {notifOpen && (
              <div className="sd-notif-dropdown">
                <p className="sd-notif-title">Notifications</p>
                {["New lesson added to Yoga Flow", "Your certificate is ready 🎉"].map((n, i) => (
                  <div key={i} className="sd-notif-item">{n}</div>
                ))}
              </div>
            )}
          </div>

          <UserChip 
            user={user} 
            onProfileClick={() => handleTabChange("settings")} 
          />
        </div>
      </header>

      <div className="sd-layout">

        {/* ── SIDEBAR ── */}
        <aside className={`sd-sidebar ${sideOpen ? "" : "collapsed"}`}>
          <nav className="sd-nav">
            <p className="sd-nav-section-title">Menu</p>
            {NAV_ITEMS.map(({ key, Icon, label }) => (
              <button
                key={key}
                className={`sd-nav-item ${activeTab === key ? "active" : ""}`}
                onClick={() => handleTabChange(key)}
                title={!sideOpen ? label : undefined}
              >
                <span className="sd-nav-icon"><Icon size={17} /></span>
                <span className="sd-nav-label">{label}</span>
              </button>
            ))}
          </nav>
          <div className="sd-sidebar-footer">
            <div className="sd-sidebar-divider" />
            <button className="sd-nav-item logout"
              onClick={() => setShowLogout(true)}
              title={!sideOpen ? "Log Out" : undefined}>
              <span className="sd-nav-icon"><FiLogOut size={17} /></span>
              <span className="sd-nav-label">Log Out</span>
            </button>
          </div>
        </aside>

        {/* ── MAIN ── */}
        <main className="sd-main" onClick={() => notifOpen && setNotif(false)}>
          {renderContent()}
        </main>
      </div>

      {showLogout && (
        <LogoutModal onConfirm={confirmLogout} onCancel={() => setShowLogout(false)} />
      )}
    </div>
  );
}