import { useState, useMemo, useEffect, useRef } from "react";
import { Routes, Route, Navigate, useParams, useNavigate, useLocation, useSearchParams } from "react-router-dom";
import axios from "axios";
import {
  FiHome, FiBookOpen, FiCalendar, FiAward,
  FiMessageSquare, FiCreditCard, FiSettings,
  FiHelpCircle, FiLogOut, FiSearch, FiX,
  FiLayers, FiClock, FiChevronRight, FiChevronLeft, FiStar,
  FiRefreshCw,
} from "react-icons/fi";
import useCurrentUser from "../services/useCurrentUser";
import LogoutModal from "../LogoutModal";
import NotificationBell from "../NotificationBell";
import EmbeddedCoursePage from "./Embeddedcoursepage";
import EmbeddedLessonCardsPage from "./Embeddedlessoncardspage";
import EmbeddedLessonPlayerPage from "./Embeddedlessonplayerpage";
import EmbeddedInstructorsPage from "./EmbeddedInstructorsPage";
import EmbeddedInstructorDetailPage from "./EmbeddedInstructorDetailPage";
import CourseCard from "./CourseCard";
import MyCoursesPage from "./MyCoursesPage";
import MySubscriptionPage from "./MySubscriptionPage";
import StudentBadgesPage from "./StudentBadgesPage";
import StudentProfilePage from "./StudentProfilePage";
import StudentHelpPage from "./StudentHelpPage";

import "../../styles/StudentDashboard.css";
import "../../styles/StudentInstructors.css";
import "../../styles/InstructorFeed.css";
import UserChip from "../UserChip";
import logo from "../../assets/Dicone.png";
import bgImage from "../../assets/dance-wellness-bg.svg";
import StudentMessagesPage from "./StudentMessagesPage"
import "../../styles/Messages.css";
import { FiUsers } from "react-icons/fi";

/* ── Constants ─────────────────────────────────────────────── */
const LEVELS = ["All Levels", "BEGINNER", "INTERMEDIATE", "ADVANCED"];
const SORT_OPTS = ["Most Popular", "Highest Rated", "Price: Low to High", "Price: High to Low"];

const LEVEL_META = {
  BEGINNER: { label: "Beginner", color: "#3a7d44" },
  INTERMEDIATE: { label: "Intermediate", color: "#b89c4d" },
  ADVANCED: { label: "Advanced", color: "#9b3a3a" },
};

const NAV_ITEMS = [
  { key: "home", Icon: FiHome, label: "Home" },
  { key: "instructors", Icon: FiUsers, label: "Instructors" },
  { key: "my-courses", Icon: FiBookOpen, label: "My Courses" },
  { key: "account", Icon: FiCreditCard, label: "My Subscription" },
  { key: "messages", Icon: FiMessageSquare, label: "Messages / Chat" },
  { key: "badges", Icon: FiAward, label: "Badges" },
  { key: "settings", Icon: FiSettings, label: "Settings & Profile" },
  { key: "help", Icon: FiHelpCircle, label: "Help & Support" },
];



/* ══════════════════════════════════════════════
   RECOMMENDED FOR YOU SECTION
 ══════════════════════════════════════════════ */
const RecommendedSection = ({ onCourseSelect, studentId }) => {
  const [recCourses, setRecCourses] = useState([]);
  const [cats, setCats] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState(false);
  
  // Scroll state for arrows
  const scrollRef = useRef(null);
  const [canScrollLeft, setCanScrollLeft] = useState(false);
  const [canScrollRight, setCanScrollRight] = useState(false);

  const updateScrollButtons = () => {
    if (!scrollRef.current) return;
    const { scrollLeft, scrollWidth, clientWidth } = scrollRef.current;
    setCanScrollLeft(scrollLeft > 0);
    setCanScrollRight(scrollLeft < scrollWidth - clientWidth - 1);
  };

  const scroll = (direction) => {
    if (!scrollRef.current) return;
    const scrollAmount = 280; // card width + gap
    scrollRef.current.scrollBy({
      left: direction === "left" ? -scrollAmount : scrollAmount,
      behavior: "smooth",
    });
  };

  useEffect(() => {
    const el = scrollRef.current;
    if (!el) return;
    updateScrollButtons();
    el.addEventListener("scroll", updateScrollButtons);
    window.addEventListener("resize", updateScrollButtons);
    return () => {
      el.removeEventListener("scroll", updateScrollButtons);
      window.removeEventListener("resize", updateScrollButtons);
    };
  }, [recCourses]); // re-run when courses load

  const fetchRecs = async (forceRefresh = false) => {
    if (!studentId) { setLoading(false); return; }
    try {
      if (forceRefresh) {
        setRefreshing(true);
        await axios.post("http://localhost:5000/refresh").catch(() => {});
      }

      // 1. Get recommended course IDs from AI
      const aiRes = await axios.get(`http://localhost:5000/recommend/${studentId}?top_n=5`);
      const recommendations = aiRes.data?.recommendations || [];
      if (recommendations.length === 0) {
        setRecCourses([]);
        setLoading(false);
        setRefreshing(false);
        return;
      }

      // 2. Fetch full course objects + categories from Spring (same as all-courses)
      const [catsRes, ...courseResponses] = await Promise.all([
        axios.get("http://localhost:8080/api/categories"),
        ...recommendations.map(r =>
          axios.get(`http://localhost:8080/api/courses/${r.course_id}`).catch(() => null)
        ),
      ]);

      const catMap = {};
      catsRes.data.forEach(c => { catMap[c.id] = c.name; });
      setCats(catsRes.data);

      const enriched = courseResponses
        .map((res) => {
          if (!res) return null;
          const course = res.data;
          return {
            ...course,
            category: catMap[course.categoryId] || course.categoryId || "Uncategorized",
          };
        })
        .filter(Boolean);

      setRecCourses(enriched);
      setError(false);
    } catch {
      setError(true);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    // Reset state immediately when user changes so stale data never shows
    setRecCourses([]);
    setLoading(true);
    setError(false);
    fetchRecs();
  }, [studentId]);

  if (!loading && (error || recCourses.length === 0)) return null;

  return (
    <div className="sd-rec-section">
      <div className="sd-rec-header">
        <div className="sd-rec-title-wrap">
          <span className="sd-rec-badge"><FiStar size={11} /> AI Picks</span>
          <h2 className="sd-rec-title">Recommended for You</h2>
          <p className="sd-rec-sub">Courses picked by our AI based on your interests and activity</p>
        </div>
        <button
          className="sd-rec-refresh-btn"
          onClick={() => fetchRecs(true)}
          disabled={refreshing}
          title="Retrain & refresh recommendations"
        >
          <FiRefreshCw size={13} className={refreshing ? "sd-rec-spin" : ""} />
          {refreshing ? "Updating…" : "Refresh"}
        </button>
      </div>

      {loading ? (
        <div className="sd-course-grid">
          {Array.from({ length: 4 }).map((_, i) => <CourseCardSkeleton key={i} index={i} />)}
        </div>
      ) : (
        <div className="sd-rec-row-wrapper">
          {canScrollLeft && (
            <button
              className="sd-rec-scroll-btn sd-rec-scroll-left"
              onClick={() => scroll("left")}
              aria-label="Scroll left"
            >
              <FiChevronLeft size={20} />
            </button>
          )}
          <div className="sd-rec-row" ref={scrollRef}>
            {recCourses.map((course, idx) => (
              <div className="sd-rec-row-item" key={course.courseId}>
                <div className="sd-rec-card-wrap">
                  <CourseCard
                    course={{ ...course, title: course.title?.length > 50 ? course.title.slice(0, 50) + "…" : course.title }}
                    index={idx}
                    onSelect={onCourseSelect}
                    cats={cats}
                  />
                </div>
              </div>
            ))}
          </div>
          {canScrollRight && (
            <button
              className="sd-rec-scroll-btn sd-rec-scroll-right"
              onClick={() => scroll("right")}
              aria-label="Scroll right"
            >
              <FiChevronRight size={20} />
            </button>
          )}
        </div>
      )}
    </div>
  );
};

/* ══════════════════════════════════════════════
   HOME — catalog with URL-synced search / filters
 ══════════════════════════════════════════════ */

// Skeleton loader for course cards
const CourseCardSkeleton = ({ index }) => (
  <article className="sd-card-skeleton" style={{ animationDelay: `${index * 50}ms` }}>
    <div className="sd-skeleton-thumb"></div>
    <div className="sd-skeleton-body">
      <div className="sd-skeleton-line sd-cat-line"></div>
      <div className="sd-skeleton-line sd-title-line-1"></div>
      <div className="sd-skeleton-line sd-title-line-2"></div>
      <div className="sd-skeleton-instructor">
        <div className="sd-skeleton-avatar"></div>
        <div className="sd-skeleton-line sd-name-line"></div>
      </div>
      <div className="sd-skeleton-stats">
        <div className="sd-skeleton-line sd-stat-line"></div>
        <div className="sd-skeleton-line sd-stat-line"></div>
      </div>
      <div className="sd-skeleton-line sd-cta-line"></div>
    </div>
  </article>
);
const HomeContent = ({ username, onCourseSelect, studentId }) => {
  const [searchParams, setSearchParams] = useSearchParams();
  const [courses, setCourses] = useState([]);
  const [cats, setCats] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterLoading, setFilterLoading] = useState(false);

  // Filters from URL — persisted across page refresh
  const search = searchParams.get("q") || "";
  const category = searchParams.get("category") || "ALL";
  const level = searchParams.get("level") || "ALL";
  const sort = searchParams.get("sort") || "Most Popular";
  const showFree = searchParams.get("free") === "1";

  // Local input state — only syncs to URL on submit (like instructor feed)
  const [inputValue, setInputValue] = useState(search);

  // Keep input in sync if URL changes (back button)
  useEffect(() => { setInputValue(search); }, [search]);

  const updateParam = (key, value, defaultVal = "ALL") => {
    const next = new URLSearchParams(searchParams);
    if (!value || value === defaultVal) next.delete(key);
    else next.set(key, value);
    setSearchParams(next, { replace: true });
  };

  const handleSearchSubmit = (e) => {
    if (e) e.preventDefault();
    const next = new URLSearchParams(searchParams);
    if (inputValue.trim()) next.set("q", inputValue.trim());
    else next.delete("q");
    setSearchParams(next, { replace: true });
  };

  const handleClearSearch = () => {
    setInputValue("");
    const next = new URLSearchParams(searchParams);
    next.delete("q");
    setSearchParams(next, { replace: true });
  };

  // Fetch courses + categories from DB
  useEffect(() => {
    setLoading(true);
    Promise.all([
      axios.get("http://localhost:8080/api/courses/published"),
      axios.get("http://localhost:8080/api/categories"),
    ]).then(([coursesRes, catsRes]) => {
      const catMap = {};
      catsRes.data.forEach(cat => { catMap[cat.id] = cat.name; });
      const enriched = coursesRes.data.map(course => ({
        ...course,
        category: catMap[course.categoryId] || course.categoryId || "Uncategorized",
      }));
      setCourses(enriched);
      setCats(Array.isArray(catsRes.data) ? catsRes.data : []);
      setTimeout(() => setLoading(false), 800);
    }).catch(err => {
      console.error(err);
      setTimeout(() => setLoading(false), 800);
    });
  }, []);

  // Show skeleton briefly whenever filters/search change (after initial load)
  useEffect(() => {
    if (loading) return; // don't double-trigger during initial load
    setFilterLoading(true);
    const t = setTimeout(() => setFilterLoading(false), 400);
    return () => clearTimeout(t);
  }, [search, category, level, sort, showFree]); // eslint-disable-line react-hooks/exhaustive-deps

  const filtered = useMemo(() => {
    let list = [...courses];
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(c =>
        c.title?.toLowerCase().includes(q) ||
        c.instructor?.username?.toLowerCase().includes(q));
    }
    if (category !== "ALL") list = list.filter(c => c.category === category);
    if (level !== "ALL") list = list.filter(c => c.level === level);
    if (showFree) list = list.filter(c => c.isFree);
    if (sort === "Price: Low to High") list.sort((a, b) => (a.price ?? 0) - (b.price ?? 0));
    if (sort === "Price: High to Low") list.sort((a, b) => (b.price ?? 0) - (a.price ?? 0));
    return list;
  }, [courses, search, category, level, sort, showFree]);

  const hasActive = search || category !== "ALL" || level !== "ALL" || showFree;
  const clearAll = () => { setInputValue(""); setSearchParams({}, { replace: true }); };

  return (
    <div className="sd-home">
      <div className="sd-welcome-block">
        <h1 className="sd-welcome-title">Welcome back, <span>{username}</span></h1>
        <p className="sd-welcome-sub">Explore our full catalog and continue your learning journey.</p>
      </div>

      {/* ── Filter bar — moved to top ── */}
      <div className="if-filter-bar">
        <form className="if-search-wrap" onSubmit={handleSearchSubmit}>
          <button type="submit" className="if-search-submit-btn">
            <FiSearch className="if-search-icon" />
          </button>
          <input
            type="text"
            placeholder="Search courses or instructors…"
            className="if-search-input"
            value={inputValue}
            onChange={e => setInputValue(e.target.value)}
          />
          {inputValue && (
            <button type="button" className="if-search-clear-btn" onClick={handleClearSearch}>
              <FiX />
            </button>
          )}
        </form>

        <div className="if-select-group">
          <div className="if-select-wrap">
            <select
              className="if-select"
              value={category}
              onChange={e => updateParam("category", e.target.value)}
            >
              <option value="ALL">All Categories</option>
              {cats.map(c => <option key={c.id} value={c.name}>{c.name}</option>)}
            </select>
          </div>

          <div className="if-select-wrap">
            <select
              className="if-select"
              value={level}
              onChange={e => updateParam("level", e.target.value)}
            >
              <option value="ALL">All Levels</option>
              <option value="BEGINNER">Beginner</option>
              <option value="INTERMEDIATE">Intermediate</option>
              <option value="ADVANCED">Advanced</option>
            </select>
          </div>

          <div className="if-select-wrap">
            <select
              className="if-select"
              value={sort}
              onChange={e => updateParam("sort", e.target.value, "Most Popular")}
            >
              {SORT_OPTS.map(s => <option key={s} value={s}>{s}</option>)}
            </select>
          </div>

          <button
            className={`sd-pill ${showFree ? "free-active" : ""}`}
            style={{ whiteSpace: "nowrap" }}
            onClick={() => {
              const next = new URLSearchParams(searchParams);
              showFree ? next.delete("free") : next.set("free", "1");
              setSearchParams(next, { replace: true });
            }}
          >
            Free Only
          </button>

          {hasActive && (
            <button className="sd-pill clear-btn" onClick={clearAll}>
              <FiX size={11} /> Clear
            </button>
          )}
        </div>

        <div className="if-results-count">
          {loading || filterLoading ? "—" : `${filtered.length} course${filtered.length !== 1 ? "s" : ""}`}
        </div>
      </div>

      {/* ── AI Recommendations — only show when no filters are active ── */}
      {!hasActive && <RecommendedSection onCourseSelect={onCourseSelect} studentId={studentId} />}

      {/* ── All Courses heading ── */}
      <div className="sd-section-heading">
        <h2 className="sd-section-title">{hasActive ? "Search Results" : "All Courses"}</h2>
      </div>

      {loading || filterLoading ? (
        <div className="sd-course-grid">
          {Array.from({ length: 8 }).map((_, idx) => (
            <CourseCardSkeleton key={idx} index={idx} />
          ))}
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

/* ── Route Wrappers to extract params ── */
const CourseWrapper = ({ navigate }) => {
  const { courseId } = useParams();
  return (
    <EmbeddedCoursePage
      courseId={courseId}
      onBack={() => navigate("/student/home")}
      onBrowseLessons={(cid) => navigate(`/student/course/${cid}/lessons`)}
    />
  );
};

const LessonsWrapper = ({ navigate }) => {
  const { courseId } = useParams();
  return (
    <EmbeddedLessonCardsPage
      courseId={courseId}
      onBack={() => navigate(`/student/course/${courseId}`)}
      onSelectLesson={(lid) => navigate(`/student/course/${courseId}/lesson/${lid}`)}
    />
  );
};

const PlayerWrapper = ({ navigate }) => {
  const { courseId, lessonId } = useParams();
  return (
    <EmbeddedLessonPlayerPage
      courseId={courseId}
      lessonId={lessonId}
      onBack={() => navigate(`/student/course/${courseId}/lessons`)}
      onLessonChange={(lid) => navigate(`/student/course/${courseId}/lesson/${lid}`)}
    />
  );
};

const InstructorDetailWrapper = ({ navigate }) => {
  const { instructorId } = useParams();
  return (
    <EmbeddedInstructorDetailPage
      instructorId={instructorId}
      onBack={() => navigate("/student/instructors")}
      onCourseSelect={(cid) => navigate(`/student/course/${cid}`)}
    />
  );
};

/* ══════════════════════════════════════════════
   MAIN DASHBOARD
 ══════════════════════════════════════════════ */
export default function StudentDashboard() {
  const { user, loading } = useCurrentUser();
  const navigate = useNavigate();
  const location = useLocation();
  const [sideOpen, setSide] = useState(false);
  const [showLogout, setShowLogout] = useState(false);
  const [showWelcome, setShowWelcome] = useState(false);

  useEffect(() => {
    // Check if we just signed up
    if (location.state?.showWelcomeModal) {
      setShowWelcome(true);
      // Clear the state so it doesn't re-trigger on refresh
      window.history.replaceState({}, document.title);
    }
  }, [location.state]);

  // Derive active tab from URL (e.g., /student/home -> home)
  const currentPath = location.pathname.replace("/student/", "");
  const activeTab = useMemo(() => {
    if (currentPath.startsWith("course")) return "home";
    const segment = currentPath.split("/")[0];
    return segment || "home";
  }, [currentPath]);

  useEffect(() => {
    const pendingDirect = localStorage.getItem("pendingCourseDirect");
    if (pendingDirect) {
      localStorage.removeItem("pendingCourseDirect");
      navigate(`/student/course/${pendingDirect}/lessons`, { replace: true });
      return;
    }
    const pendingId = localStorage.getItem("pendingCourseId");
    if (pendingId) {
      localStorage.removeItem("pendingCourseId");
      navigate(`/student/course/${pendingId}`, { replace: true });
    }
  }, [navigate]);

  const username = user?.username || localStorage.getItem("username") || "Student";
  const confirmLogout = () => { localStorage.clear(); window.location.href = "/login"; };

  useEffect(() => { window.scrollTo({ top: 0, behavior: "smooth" }); }, [location.pathname]);

  const handleTabChange = (key) => navigate(`/student/${key}`);

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
          <NotificationBell
            onNotificationClick={(n) => {
              if (n.courseId) navigate(`/student/course/${n.courseId}`);
            }}
          />

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
        <main className="sd-main" style={{
          backgroundImage: `linear-gradient(rgba(247,245,240,0.55), rgba(247,245,240,0.55)), url(${bgImage})`,
          backgroundSize: 'cover',
          backgroundPosition: 'center',
          backgroundAttachment: 'fixed',
        }}>
          <Routes>
            <Route index element={<Navigate to="/student/home" replace />} />
            <Route path="home" element={<HomeContent username={username} studentId={user?.userId} onCourseSelect={(id) => navigate(`/student/course/${id}`)} />} />

            <Route path="course/:courseId" element={<CourseWrapper navigate={navigate} />} />
            <Route path="course/:courseId/lessons" element={<LessonsWrapper navigate={navigate} />} />
            <Route path="course/:courseId/lesson/:lessonId" element={<PlayerWrapper navigate={navigate} />} />

            <Route path="instructors" element={<EmbeddedInstructorsPage onInstructorSelect={(id) => navigate(`/student/instructor/${id}`)} />} />
            <Route path="instructor/:instructorId" element={<InstructorDetailWrapper navigate={navigate} />} />

            <Route path="my-courses" element={<MyCoursesPage onCourseSelect={(id) => navigate(`/student/course/${id}`)} />} />
            <Route path="sessions" element={<Placeholder Icon={FiCalendar} title="Planned Sessions" sub="Upcoming live sessions will appear here." />} />
            <Route path="badges" element={<StudentBadgesPage />} />
            <Route path="messages" element={<StudentMessagesPage />} />
            <Route path="account" element={<MySubscriptionPage onCourseSelect={(id) => navigate(`/student/course/${id}`)} />} />
            <Route path="settings" element={<StudentProfilePage />} />
            <Route path="help" element={<StudentHelpPage />} />

            <Route path="*" element={<Navigate to="/student/home" replace />} />
          </Routes>
        </main>
      </div>

      {showLogout && (
        <LogoutModal onConfirm={confirmLogout} onCancel={() => setShowLogout(false)} />
      )}

      {showWelcome && (
        <div className="sd-welcome-modal-overlay">
          <div className="sd-welcome-modal">
            <button className="sd-welcome-close" onClick={() => setShowWelcome(false)}>
              <FiX size={20} />
            </button>
            <div className="sd-welcome-icon">✨</div>
            <h2>Welcome aboard, {username}!</h2>
            <p>Your account has been created successfully.</p>
            <p className="sd-welcome-sub">
              Feel free to complete your profile now, or start exploring courses right away.
            </p>
            <div className="sd-welcome-actions">
              <button className="sd-btn-primary" onClick={() => {
                setShowWelcome(false);
                navigate("/student/settings");
              }}>
                Complete Profile
              </button>
              <button className="sd-btn-secondary" onClick={() => setShowWelcome(false)}>
                Maybe Later
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}