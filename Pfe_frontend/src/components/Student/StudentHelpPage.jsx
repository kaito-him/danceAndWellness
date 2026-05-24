import { useState, useMemo } from "react";
import {
  FiHelpCircle, FiChevronDown, FiSearch, FiX,
  FiMail, FiBook, FiPlayCircle, FiCreditCard,
  FiUser, FiMessageSquare, FiAward, FiShield,
} from "react-icons/fi";
import "../../styles/StudentHelp.css";

/* ── FAQ data ──────────────────────────────────────────────── */
const FAQ_CATEGORIES = [
  {
    key: "getting-started",
    label: "Getting Started",
    icon: FiBook,
    faqs: [
      {
        q: "How do I create my student account?",
        a: "Click \"Sign Up\" on the homepage, select \"Student\" as your role, fill in your name, email address, and a strong password, then confirm your email. Once verified you are taken directly to your dashboard.",
      },
      {
        q: "How do I log in to the platform?",
        a: "Go to dance&wellness.com and click \"Log In\" at the top right. Enter the email and password you used to sign up. If you have forgotten your password, click \"Forgot Password?\" to receive a reset link by email.",
      },
      {
        q: "Is there a mobile app available?",
        a: "Yes! Dance & Wellness has a companion mobile app for Android and iOS. You can log in with the same credentials and access all your courses on the go.",
      },
      {
        q: "How do I complete my student profile?",
        a: "Navigate to Settings & Profile from the left sidebar. You can upload a profile photo, update your display name, bio, and any other personal details. A complete profile helps instructors and peers recognise you.",
      },
    ],
  },
  {
    key: "courses",
    label: "Courses & Lessons",
    icon: FiPlayCircle,
    faqs: [
      {
        q: "How do I browse and find courses?",
        a: "Your home screen shows the full course catalog. Use the search bar to look for a title or instructor name, then narrow results by category, level (Beginner / Intermediate / Advanced), or price using the filter bar.",
      },
      {
        q: "How do I enroll in a course?",
        a: "Open the course detail page and click \"Enroll Now\". Free courses enroll you instantly. Paid courses will redirect you to a secure checkout powered by Stripe. After payment you get immediate access.",
      },
      {
        q: "Where can I find my enrolled courses?",
        a: "Click \"My Courses\" in the left sidebar. All courses you are enrolled in appear there, together with your overall progress for each one.",
      },
      {
        q: "Can I watch lessons on any device?",
        a: "Yes. Lessons are streamed in your browser and on the mobile app. Playback adapts automatically to your connection speed. Offline download is not currently supported.",
      },
      {
        q: "How do I resume a lesson I was watching?",
        a: "Open \"My Courses\", select the course, then click the lesson list. The platform remembers where you stopped and you can continue from that position.",
      },
      {
        q: "Are there quizzes or assessments?",
        a: "Some courses include quizzes at the end of lessons. Complete them to test your understanding and earn bonus XP points that contribute toward your badges.",
      },
    ],
  },
  {
    key: "payments",
    label: "Payments & Subscriptions",
    icon: FiCreditCard,
    faqs: [
      {
        q: "What payment methods are accepted?",
        a: "We accept all major credit and debit cards (Visa, Mastercard, American Express) via Stripe. Additional local payment options may be available depending on your region.",
      },
      {
        q: "Where can I view my purchase history?",
        a: "Go to \"My Subscription\" in the sidebar. You will see a list of all your transactions, including course names, amounts, and dates.",
      },
      {
        q: "Can I get a refund for a course?",
        a: "Refund requests are handled on a case-by-case basis. Please contact our support team at dance&wellness@gmail.com within 7 days of purchase and describe your situation. We will do our best to help.",
      },
      {
        q: "Are any courses free?",
        a: "Yes! Toggle the \"Free Only\" filter on the home screen to display all courses that are available at no cost. Some instructors offer free intro lessons within paid courses as well.",
      },
    ],
  },
  {
    key: "account",
    label: "Account & Profile",
    icon: FiUser,
    faqs: [
      {
        q: "How do I change my password?",
        a: "Go to Settings & Profile → Security section. Enter your current password, then your new password twice to confirm. Changes take effect immediately.",
      },
      {
        q: "How do I update my email address?",
        a: "In Settings & Profile, click on the email field to edit it. You will receive a verification link to your new address before the change is confirmed.",
      },
      {
        q: "Can I delete my account?",
        a: "Yes. Please email us at dance&wellness@gmail.com with the subject \"Account Deletion Request\". Note that deleting your account is permanent and removes all your progress and enrollments.",
      },
      {
        q: "My account seems to be suspended – what should I do?",
        a: "If you see a \"Banned Account\" message, your account was suspended by an administrator. Contact our support team at dance&wellness@gmail.com with details so we can review and resolve the situation.",
      },
    ],
  },
  {
    key: "messages",
    label: "Messages & Community",
    icon: FiMessageSquare,
    faqs: [
      {
        q: "How do I message an instructor?",
        a: "Open the Messages / Chat section from the sidebar and start a conversation with your instructor. You can ask questions about course material, request feedback, or discuss scheduling.",
      },
      {
        q: "Can I leave comments on a lesson?",
        a: "Yes. Open any lesson player and scroll to the Comments section at the bottom. You can leave a question or feedback and instructors or other students can reply.",
      },
    ],
  },
  {
    key: "badges",
    label: "Badges & Progress",
    icon: FiAward,
    faqs: [
      {
        q: "How do I earn badges?",
        a: "Badges are awarded automatically when you hit certain milestones: finishing your first lesson, completing a full course, scoring 100 % on a quiz, and more. Check the Badges section to see all available achievements and your progress toward each.",
      },
      {
        q: "What are XP points?",
        a: "XP (experience points) are earned every time you complete a lesson, pass a quiz, or reach a streak milestone. They are used to rank progress on the platform leaderboard and unlock special badges.",
      },
    ],
  },
  {
    key: "privacy",
    label: "Privacy & Security",
    icon: FiShield,
    faqs: [
      {
        q: "Is my personal data secure?",
        a: "Yes. We follow industry-standard security practices. Passwords are hashed, and payment information is never stored on our servers — it is handled entirely by Stripe's PCI-DSS compliant infrastructure.",
      },
      {
        q: "Who can see my profile information?",
        a: "Your name and profile photo are visible to instructors and other students in shared course areas. Your email, payment details, and private settings are never shared publicly.",
      },
    ],
  },
];

/* ─────────────────────────────────────────────────────────────
   COMPONENT
 ───────────────────────────────────────────────────────────── */
export default function StudentHelpPage() {
  const [search, setSearch] = useState("");
  const [openId, setOpenId] = useState(null); // "catKey-idx"

  const toggleFaq = (id) => setOpenId((prev) => (prev === id ? null : id));

  /* Flatten & filter FAQs by search query */
  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return FAQ_CATEGORIES;
    return FAQ_CATEGORIES.map((cat) => ({
      ...cat,
      faqs: cat.faqs.filter(
        (f) =>
          f.q.toLowerCase().includes(q) ||
          f.a.toLowerCase().includes(q)
      ),
    })).filter((cat) => cat.faqs.length > 0);
  }, [search]);

  const totalResults = filtered.reduce((acc, c) => acc + c.faqs.length, 0);

  return (
    <div className="help-page">

      {/* ── HERO ── */}
      <div className="help-hero">
        <div className="help-hero-badge">
          <FiHelpCircle size={12} />
          Help &amp; Support
        </div>
        <h1 className="help-hero-title">
          How can we <span>help you?</span>
        </h1>
        <p className="help-hero-sub">
          Find answers to common questions about using the Dance &amp; Wellness
          platform, or reach our team directly.
        </p>
      </div>

      {/* ── SEARCH ── */}
      <div className="help-search-wrap">
        <FiSearch size={16} className="help-search-icon" />
        <input
          id="help-search-input"
          type="text"
          className="help-search-input"
          placeholder="Search your question…"
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setOpenId(null);
          }}
        />
        {search && (
          <button
            className="help-search-clear"
            onClick={() => { setSearch(""); setOpenId(null); }}
            aria-label="Clear search"
          >
            <FiX size={14} />
          </button>
        )}
      </div>

      {/* ── FAQ SECTIONS ── */}
      <div className="help-faq-section" style={{ marginTop: search ? 0 : 44 }}>
        <div className="help-section-label">
          <div className="help-section-label-icon">
            <FiHelpCircle size={16} />
          </div>
          <h2>
            {search
              ? `${totalResults} result${totalResults !== 1 ? "s" : ""} for "${search}"`
              : "Frequently Asked Questions"}
          </h2>
        </div>

        {filtered.length === 0 ? (
          <div className="help-no-results">
            <span>🔍</span>
            No questions match <strong>"{search}"</strong>.<br />
            Try a different keyword or{" "}
            <a href="mailto:dance&wellness@gmail.com" style={{ color: "#b89c4d" }}>
              contact our team
            </a>.
          </div>
        ) : (
          filtered.map((cat) => (
            <div key={cat.key} style={{ marginBottom: 32 }}>
              {/* Category sub-header (only when showing all) */}
              {!search && (
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 8,
                    marginBottom: 12,
                    color: "#b89c4d",
                    fontSize: 12.5,
                    fontWeight: 600,
                    letterSpacing: "1.5px",
                    textTransform: "uppercase",
                  }}
                >
                  <cat.icon size={13} />
                  {cat.label}
                </div>
              )}

              <div className="help-faq-list">
                {cat.faqs.map((faq, idx) => {
                  const id = `${cat.key}-${idx}`;
                  const isOpen = openId === id;
                  return (
                    <div
                      key={id}
                      className={`help-faq-item ${isOpen ? "open" : ""}`}
                    >
                      <button
                        id={`faq-btn-${id}`}
                        className="help-faq-question"
                        onClick={() => toggleFaq(id)}
                        aria-expanded={isOpen}
                      >
                        <div className="help-faq-q-left">
                          <div className="help-faq-num">{idx + 1}</div>
                          <span className="help-faq-q-text">{faq.q}</span>
                        </div>
                        <FiChevronDown size={17} className="help-faq-chevron" />
                      </button>

                      <div className="help-faq-answer" aria-hidden={!isOpen}>
                        <div className="help-faq-answer-inner">{faq.a}</div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          ))
        )}
      </div>

      {/* ── CONTACT SUPPORT ── */}
      <div className="help-contact-section">
        <div className="help-section-label">
          <div className="help-section-label-icon">
            <FiMail size={16} />
          </div>
          <h2>Contact Support</h2>
        </div>

        <div className="help-contact-card">
          <div className="help-contact-icon-wrap">
            <FiMail size={30} />
          </div>
          <div className="help-contact-info">
            <h3>Still have a question?</h3>
            <p>
              Our support team is here to help. Send us an email and we will
              get back to you as soon as possible — usually within 24 hours on
              business days.
            </p>
            <a
              href="mailto:dance&wellness@gmail.com"
              className="help-contact-email-btn"
              id="help-contact-email-btn"
            >
              <FiMail size={15} />
              dance&amp;wellness@gmail.com
            </a>
            <div className="help-contact-response">
              <span className="help-contact-response-dot" />
              Typical response time: within 24 hours
            </div>
          </div>
        </div>
      </div>

    </div>
  );
}
