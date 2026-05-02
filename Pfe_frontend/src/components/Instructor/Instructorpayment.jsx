import React, { useEffect, useState, useCallback } from "react";
import {
  FiCreditCard, FiCheckCircle, FiAlertCircle, FiRefreshCw,
  FiExternalLink, FiSearch, FiDollarSign, FiUsers, FiBookOpen, FiTrendingUp
} from "react-icons/fi";
import api from "../services/api";
import "../../styles/InstructorPayment.css";

// ─── helpers ────────────────────────────────────────────────────────────────
const fmt = (cents) =>
  cents != null && cents > 0
    ? `$${(cents / 100).toFixed(2)}`
    : null;

const fmtDate = (raw) => {
  if (!raw) return "—";
  const d = Array.isArray(raw)
    ? new Date(raw[0], raw[1] - 1, raw[2])
    : new Date(raw);
  return d.toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" });
};

const initials = (name) =>
  name ? name.split(" ").map((w) => w[0]).join("").toUpperCase().slice(0, 2) : "?";

// ─── component ───────────────────────────────────────────────────────────────
export default function InstructorPayment({ instructorId: propInstructorId, onStudentClick, onCourseClick }) {
  const [instructorId, setInstructorId] = useState(propInstructorId || null);
  const [instructorAppliedAt, setInstructorAppliedAt] = useState(null);
  const [status, setStatus]       = useState(null);   // Stripe account status
  const [enrollments, setEnrollments] = useState([]);
  const [loading, setLoading]     = useState(true);
  const [onboarding, setOnboarding] = useState(false);
  const [search, setSearch]       = useState("");
  const [selectedMonth, setSelectedMonth] = useState("ALL");
  const [toast, setToast]         = useState(null);

  // ── data fetch ─────────────────────────────────────────────────────────────
  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      let activeId = instructorId;

      if (!activeId) {
        const userId = localStorage.getItem("userId");
        if (!userId) throw new Error("No user ID");
        const instRes = await api.get(`/instructors/by-user/${userId}`);
        activeId = instRes.data.id;
        setInstructorId(activeId);
        setInstructorAppliedAt(instRes.data.appliedAt || null);
      }

      if (!activeId) return;

      const [statusRes, enrollRes] = await Promise.all([
        api.get(`/instructor/payments/${activeId}/status`),
        api.get(`/instructor/payments/${activeId}/enrollments`),
      ]);
      setStatus(statusRes.data);
      const all = Array.isArray(enrollRes.data) ? enrollRes.data : [];
      setEnrollments(all.filter((e) => e.enrollmentType === "PAID"));
    } catch {
      showToast("Failed to load payment data.", "error");
    } finally {
      setLoading(false);
    }
  }, [instructorId]);

  useEffect(() => {
    loadData();

    // If returning from Stripe onboarding
    const params = new URLSearchParams(window.location.search);
    if (params.get("onboarding") === "complete") {
      showToast("Stripe account connected successfully! ✓", "success");
      window.history.replaceState({}, "", window.location.pathname);
    } else if (params.get("onboarding") === "refresh") {
      showToast("Onboarding session expired. Please try again.", "error");
      window.history.replaceState({}, "", window.location.pathname);
    }
  }, [loadData]);

  // ── Stripe onboard ─────────────────────────────────────────────────────────
  const handleConnectStripe = async () => {
    setOnboarding(true);
    try {
      const res = await api.post(`/instructor/payments/${instructorId}/onboard`);
      const data = res.data;
      if (data.url) {
        window.location.href = data.url;
      } else {
        showToast("Could not generate onboarding link.", "error");
        setOnboarding(false);
      }
    } catch {
      showToast("Request failed. Check connection.", "error");
      setOnboarding(false);
    }
  };

  // ── toast helper ───────────────────────────────────────────────────────────
  const showToast = (msg, type = "success") => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 4000);
  };

  // ── derived stats ──────────────────────────────────────────────────────────
  const paidRows     = enrollments;
  const totalRevenue = paidRows.reduce((s, e) => s + (e.instructorShareCents || 0), 0);
  const totalGross   = paidRows.reduce((s, e) => s + (e.amountPaidCents || 0), 0);

  const monthLabel = (d) =>
    d.toLocaleDateString("en-US", { month: "long", year: "numeric" });

  const monthKey = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;

  const monthlyRevenue = (() => {
    const map = new Map();
    paidRows.forEach((e) => {
      if (!e.enrolledAt) return;
      const dt = Array.isArray(e.enrolledAt)
        ? new Date(e.enrolledAt[0], e.enrolledAt[1] - 1, e.enrolledAt[2])
        : new Date(e.enrolledAt);
      const k = monthKey(dt);
      const label = monthLabel(dt);
      const prev = map.get(k) || { key: k, label, revenueCents: 0, count: 0 };
      prev.revenueCents += (e.instructorShareCents || 0);
      prev.count += 1;
      map.set(k, prev);
    });

    const arr = Array.from(map.values()).sort((a, b) => (a.key > b.key ? -1 : 1));

    if (instructorAppliedAt) {
      const start = new Date(instructorAppliedAt);
      if (!Number.isNaN(start.getTime())) {
        const cursor = new Date(start.getFullYear(), start.getMonth(), 1);
        const end = new Date();
        const pad = [];
        while (cursor <= end) {
          const k = monthKey(cursor);
          const found = map.get(k);
          pad.push(found || { key: k, label: monthLabel(cursor), revenueCents: 0, count: 0 });
          cursor.setMonth(cursor.getMonth() + 1);
        }
        return pad.sort((a, b) => (a.key > b.key ? -1 : 1));
      }
    }
    return arr;
  })();

  // ── filter logic ───────────────────────────────────────────────────────────
  const filtered = paidRows.filter((e) => {
    const q = search.toLowerCase();
    const matchesSearch =
      !q ||
      (e.studentName  || "").toLowerCase().includes(q) ||
      (e.courseTitle  || "").toLowerCase().includes(q) ||
      (e.studentEmail || "").toLowerCase().includes(q);
    if (selectedMonth === "ALL") return matchesSearch;
    if (!e.enrolledAt) return false;
    const dt = Array.isArray(e.enrolledAt)
      ? new Date(e.enrolledAt[0], e.enrolledAt[1] - 1, e.enrolledAt[2])
      : new Date(e.enrolledAt);
    return monthKey(dt) === selectedMonth && matchesSearch;
  });

  // ── stripe status helpers ──────────────────────────────────────────────────
  const hasAccount      = status?.hasAccount;
  const chargesEnabled  = status?.chargesEnabled;
  const detailsSubmitted = status?.detailsSubmitted;

  const stripeBadge = () => {
    if (!hasAccount)       return { cls: "none",      label: "Not Connected" };
    if (chargesEnabled)    return { cls: "connected",  label: "Connected & Active" };
    if (detailsSubmitted)  return { cls: "pending",    label: "Under Review" };
    return                        { cls: "pending",    label: "Setup Incomplete" };
  };
  const badge = stripeBadge();

  // ═══════════════════════════════════════════════════════════════════════════
  // RENDER
  // ═══════════════════════════════════════════════════════════════════════════
  if (loading) {
    return (
      <div className="ip-page">
        <div className="ip-loading">
          <div className="ip-spinner" />
          <span>Loading payments…</span>
        </div>
      </div>
    );
  }

  return (
    <div className="ip-page">

      {/* ── Page header ── */}
      <div className="ip-header">
        <div className="ip-header-left">
          <h1>Payments & Earnings</h1>
          <p>Manage your Stripe payout account and track student enrollments</p>
        </div>
        <button
          className="ip-btn-stripe secondary"
          onClick={loadData}
          title="Refresh"
        >
          <FiRefreshCw size={14} />
          Refresh
        </button>
      </div>

      {/* ── Stats row ── */}
      <div className="ip-stats">
        <div className="ip-stat-card">
          <div className="ip-stat-label">Your Earnings (80%)</div>
          <div className="ip-stat-value green">{fmt(totalRevenue) || "$0.00"}</div>
          <div className="ip-stat-sub">from {paidRows.length} paid enrollment{paidRows.length !== 1 ? "s" : ""}</div>
        </div>
        <div className="ip-stat-card">
          <div className="ip-stat-label">Total Course Revenue</div>
          <div className="ip-stat-value">{fmt(totalGross) || "$0.00"}</div>
          <div className="ip-stat-sub">gross before platform fee</div>
        </div>
        <div className="ip-stat-card">
          <div className="ip-stat-label">Total Enrollments</div>
          <div className="ip-stat-value blue">{enrollments.length}</div>
          <div className="ip-stat-sub">{paidRows.length} paid transactions</div>
        </div>
        <div className="ip-stat-card">
          <div className="ip-stat-label">Platform Fee</div>
          <div className="ip-stat-value">20%</div>
          <div className="ip-stat-sub">you keep 80% of each sale</div>
        </div>
      </div>

      {/* ── Stripe Connect card ── */}
      <div className="ip-stripe-card">
        <div className="ip-stripe-header">
          <div>
            <div className="ip-stripe-title">
              <div className="ip-stripe-icon">
                <FiCreditCard size={22} color="var(--ip-gold)" />
              </div>
              <h2>Stripe Payout Account</h2>
            </div>
            <p className="ip-stripe-desc">
              Connect a Stripe Express account to receive your earnings directly.
              You keep <strong>80%</strong> of every paid enrollment — the platform
              retains a 20% service fee. Payouts are processed automatically by Stripe.
            </p>
          </div>

          {/* Status badge */}
          <div style={{ flexShrink: 0 }}>
            <span className={`ip-status-badge ${badge.cls}`}>
              <span className="ip-status-dot" />
              {badge.label}
            </span>
          </div>
        </div>

        {/* Info chips */}
        {hasAccount && (
          <div className="ip-stripe-info-row">
            <div className={`ip-info-chip ${chargesEnabled ? "ok" : "warn"}`}>
              {chargesEnabled ? <FiCheckCircle size={13} /> : <FiAlertCircle size={13} />}
              Charges {chargesEnabled ? "Enabled" : "Disabled"}
            </div>
            <div className={`ip-info-chip ${status?.payoutsEnabled ? "ok" : "warn"}`}>
              {status?.payoutsEnabled ? <FiCheckCircle size={13} /> : <FiAlertCircle size={13} />}
              Payouts {status?.payoutsEnabled ? "Enabled" : "Disabled"}
            </div>
            <div className={`ip-info-chip ${detailsSubmitted ? "ok" : "warn"}`}>
              {detailsSubmitted ? <FiCheckCircle size={13} /> : <FiAlertCircle size={13} />}
              Details {detailsSubmitted ? "Submitted" : "Incomplete"}
            </div>
          </div>
        )}

        {/* CTA button */}
        {!chargesEnabled ? (
          <button
            className="ip-btn-stripe"
            onClick={handleConnectStripe}
            disabled={onboarding}
          >
            {onboarding ? (
              <><span className="ip-spinner" style={{ width: 16, height: 16, borderWidth: 2, margin: 0 }} /> Redirecting…</>
            ) : (
              <><FiExternalLink size={15} /> {hasAccount ? "Complete Setup on Stripe" : "Connect Stripe Account"}</>
            )}
          </button>
        ) : (
          <button
            className="ip-btn-stripe secondary"
            onClick={handleConnectStripe}
            disabled={onboarding}
          >
            <FiExternalLink size={14} /> Manage Stripe Dashboard
          </button>
        )}
      </div>

      <div className="acf-price-tiers" style={{ marginBottom: 10 }}>
        <button
          type="button"
          className={`acf-tier-chip ${selectedMonth === "ALL" ? "active" : ""}`}
          onClick={() => setSelectedMonth("ALL")}
        >
          All Months
        </button>
        {monthlyRevenue.map((m) => (
          <button
            key={m.key}
            type="button"
            className={`acf-tier-chip ${selectedMonth === m.key ? "active" : ""}`}
            onClick={() => setSelectedMonth(m.key)}
            title={`${m.count} transaction(s)`}
          >
            {m.label}: {fmt(m.revenueCents) || "$0.00"}
          </button>
        ))}
      </div>

      {/* Filter toolbar */}
      <div className="ip-toolbar">
        <div className="ip-search">
          <FiSearch size={15} color="var(--ip-muted)" />
          <input
            placeholder="Search student or course…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <div className="ip-filter-select" style={{ display: "flex", alignItems: "center" }}>
          Paid only
        </div>
      </div>

      {/* Table */}
      {filtered.length === 0 ? (
        <div className="ip-empty">
          <div className="ip-empty-icon">📋</div>
          <div className="ip-empty-title">No enrollments found</div>
          <p className="ip-empty-sub">
            {enrollments.length === 0
              ? "Students who enroll in your courses will appear here."
              : "Try adjusting your search or filter."}
          </p>
        </div>
      ) : (
        <div className="ip-table-wrap">
          <table className="ip-table">
            <thead>
              <tr>
                <th>Student</th>
                <th>Course</th>
                <th>Course Fee</th>
                <th>Your Share (80%)</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((row) => (
                <tr key={row.enrollmentId}>

                  {/* Student */}
                  <td>
                    <div className="ip-student-cell">
                      <button
                        type="button"
                        className="ip-student-avatar"
                        style={{ border: "none", cursor: "pointer" }}
                        onClick={() => onStudentClick?.(row.studentId)}
                        title="Open student profile"
                      >
                        {initials(row.studentName)}
                      </button>
                      <div>
                        <button
                          type="button"
                          className="ip-student-name"
                          style={{ border: "none", background: "none", padding: 0, cursor: "pointer" }}
                          onClick={() => onStudentClick?.(row.studentId)}
                          title="Open student profile"
                        >
                          {row.studentName || "—"}
                        </button>
                        <div className="ip-student-email">{row.studentEmail || ""}</div>
                      </div>
                    </div>
                  </td>

                  {/* Course */}
                  <td>
                    <button
                      type="button"
                      className="ip-course-title"
                      style={{ border: "none", background: "none", padding: 0, cursor: "pointer" }}
                      onClick={() => onCourseClick?.(row.courseId)}
                      title={row.courseTitle}
                    >
                      {row.courseTitle || "—"}
                    </button>
                  </td>

                  {/* Course fee */}
                  <td>
                    {row.amountPaidCents > 0
                      ? <span className="ip-amount-total">{fmt(row.amountPaidCents)}</span>
                      : <span className="ip-amount-free">—</span>}
                  </td>

                  {/* Your share */}
                  <td>
                    {row.instructorShareCents > 0
                      ? <span className="ip-amount-share">{fmt(row.instructorShareCents)}</span>
                      : <span className="ip-amount-free">—</span>}
                  </td>

                  {/* Date */}
                  <td>
                    <span className="ip-date-cell">{fmtDate(row.enrolledAt)}</span>
                  </td>

                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Toast */}
      {toast && (
        <div className={`ip-toast ${toast.type}`}>
          {toast.type === "success"
            ? <FiCheckCircle size={16} />
            : <FiAlertCircle size={16} />}
          {toast.msg}
        </div>
      )}
    </div>
  );
}