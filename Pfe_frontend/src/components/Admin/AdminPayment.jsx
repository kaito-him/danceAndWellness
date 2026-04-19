import React, { useState, useEffect } from "react";
import { 
  FiDollarSign, FiTrendingUp, FiCalendar, FiArrowRight, 
  FiActivity, FiTarget, FiHash 
} from "react-icons/fi";
import api from "./../services/api";
import "../../styles/AdminPayment.css";

export default function AdminPayment() {
  const [summary, setSummary] = useState(null);
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const [sumRes, transRes] = await Promise.all([
          api.get("/admin/payments/summary"),
          api.get("/admin/payments/transactions")
        ]);
        setSummary(sumRes.data);
        setTransactions(transRes.data);
      } catch (err) {
        console.error("Failed to fetch payment data", err);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  const formatCurrency = (cents) => {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD"
    }).format(cents / 100);
  };

  const formatDate = (isoString) => {
    return new Date(isoString).toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit"
    });
  };

  const handleInstructorClick = (e, instructorId) => {
    e.preventDefault();
    // Redirect logic as requested by user
    window.location.href = `/admin?section=instructors&instructorId=${instructorId}`;
  };

  const handleStudentClick = (e, studentId) => {
    e.preventDefault();
    window.location.href = `/admin?section=students&studentId=${studentId}`;
  };

  if (loading) {
    return (
      <div className="ap-loading">
        <div className="admin-spinner" />
        <p>Loading financial data…</p>
      </div>
    );
  }

  return (
    <div className="ap-page">
      <header className="ap-header">
        <h1 className="ap-heading">Platform Revenue</h1>
        <p className="ap-subheading">Track earnings and commissions from course enrollments</p>
      </header>

      {/* Stats Cards */}
      <div className="ap-stats-grid">
        <div className="ap-stat-card">
          <div className="ap-stat-icon" style={{ background: 'rgba(34, 120, 60, 0.1)', color: '#22783c' }}>
            <FiTrendingUp size={28} />
          </div>
          <div className="ap-stat-info">
            <span className="ap-stat-label">Total Platform Revenue</span>
            <span className="ap-stat-value">{formatCurrency(summary?.totalPlatformRevenueCents || 0)}</span>
          </div>
        </div>

        <div className="ap-stat-card">
          <div className="ap-stat-icon" style={{ background: 'rgba(184, 156, 77, 0.1)', color: '#b89c4d' }}>
            <FiCalendar size={28} />
          </div>
          <div className="ap-stat-info">
            <span className="ap-stat-label">Today's Revenue (20%)</span>
            <span className="ap-stat-value">{formatCurrency(summary?.todayPlatformRevenueCents || 0)}</span>
          </div>
        </div>

        <div className="ap-stat-card">
          <div className="ap-stat-icon" style={{ background: 'rgba(56, 178, 172, 0.1)', color: '#38b2ac' }}>
            <FiActivity size={28} />
          </div>
          <div className="ap-stat-info">
            <span className="ap-stat-label">Total Transactions</span>
            <span className="ap-stat-value">{summary?.totalTransactionsCount || 0}</span>
          </div>
        </div>
      </div>

      {/* Transactions Table */}
      <div className="ap-table-wrap">
        <div className="ap-table-header">
          <h2 className="ap-table-title">Recent Transactions</h2>
          <div className="ap-table-badge" style={{ fontSize: '12px', background: '#f7f5f0', padding: '4px 12px', borderRadius: '12px', color: '#9a9284', fontWeight: '600' }}>
            Live Updates
          </div>
        </div>
        
        <div style={{ overflowX: 'auto' }}>
          <table className="ap-table">
            <thead>
              <tr>
                <th>Student</th>
                <th>Course</th>
                <th>Instructor</th>
                <th>Total Paid</th>
                <th>Platform Fee (20%)</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {transactions.length > 0 ? (
                transactions.map((t) => (
                  <tr key={t.id}>
                    <td>
                      <a 
                        href="#" 
                        className="ap-instructor-link" // reusing the same style class
                        onClick={(e) => handleStudentClick(e, t.studentId)}
                      >
                        {t.studentName}
                      </a>
                    </td>
                    <td>{t.courseTitle}</td>
                    <td>
                      <a 
                        href="#" 
                        className="ap-instructor-link"
                        onClick={(e) => handleInstructorClick(e, t.instructorId)}
                      >
                        {t.instructorName}
                      </a>
                    </td>
                    <td className="ap-amount-main">{formatCurrency(t.totalAmountCents)}</td>
                    <td className="ap-amount-fee">+{formatCurrency(t.platformFeeCents)}</td>
                    <td className="ap-date">{formatDate(t.enrolledAt)}</td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="6" className="ap-empty">No paid transactions found yet.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
