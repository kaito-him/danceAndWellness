import React, { useState, useEffect } from "react";
import {
  FiUsers,
  FiUserPlus,
  FiBookOpen,
  FiDollarSign,
  FiActivity,
  FiTrendingUp,
  FiCalendar,
  FiArrowUpRight,
  FiGrid,
  FiPieChart
} from "react-icons/fi";
import api from "./../services/api";
import "../../styles/AdminOverallStats.css"; // Reuse the same premium styles

export default function AdminTodayStats() {
  const [stats, setStats] = useState(null);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAllCats, setShowAllCats] = useState(false);

  const todayDate = new Date().toLocaleDateString("en-US", {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [statsRes, catsRes] = await Promise.all([
        api.get("/statistics/today"),
        api.get("/categories")
      ]);
      setStats(statsRes.data);
      setCategories(catsRes.data);
    } catch (err) {
      console.error("Failed to load today's statistics", err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="aos-loading">
        <div className="admin-spinner" />
        <span>Compiling today's activity...</span>
      </div>
    );
  }

  if (!stats) {
    return (
      <div className="aos-error">
        <FiActivity size={48} />
        <p>No activity recorded for today yet.</p>
      </div>
    );
  }

  const revenue = (stats.revenueTodayCents / 100).toLocaleString("en-US", {
    style: "currency",
    currency: "USD",
  });

  // Merge categories with today's enrollment counts
  const mergedCats = categories.map(cat => ({
    name: cat.name,
    count: stats.enrollmentsByCategoryToday[cat.name] || 0
  })).sort((a, b) => b.count - a.count);

  const visibleCats = showAllCats ? mergedCats : mergedCats.slice(0, 3);

  return (
    <div className="aos-page">
      <div className="aos-header">
        <div>
          <h1 className="aos-title">Today's Statistics</h1>
          <p className="aos-subtitle">Activity for {todayDate}</p>
        </div>
        <button className="aos-refresh-btn" onClick={() => { setLoading(true); loadData(); }}>
          <FiActivity size={14} /> Refresh
        </button>
      </div>

      {/* ── Today's KPIs ── */}
      <div className="aos-hero-grid">
        <StatCard 
          icon={FiDollarSign} 
          label="Today's Revenue" 
          value={revenue} 
          trend="Real-time" 
          color="gold"
        />
        <StatCard 
          icon={FiUserPlus} 
          label="New Students" 
          value={stats.newStudents} 
          trend="Joined Today" 
          color="blue"
        />
        <StatCard 
          icon={FiActivity} 
          label="New Enrollments" 
          value={stats.totalEnrollmentsToday} 
          trend={`${stats.paidEnrollmentsToday} paid`} 
          color="green"
        />
        <StatCard 
          icon={FiTrendingUp} 
          label="Instructor Apps" 
          value={stats.newInstructorApplications} 
          trend="Awaiting review" 
          color="purple"
        />
      </div>

      <div className="aos-main-layout">
        <div className="aos-left-col">
          {/* Enrollments by Category Today */}
          <div className="aos-section-card">
            <div className="aos-sec-header" style={{ justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <FiGrid />
                <h3>Enrollments by Category Today</h3>
              </div>
              {mergedCats.length > 3 && (
                <button 
                  className="aos-toggle-btn" 
                  onClick={() => setShowAllCats(!showAllCats)}
                >
                  {showAllCats ? "Show Less" : `See All (${mergedCats.length})`}
                </button>
              )}
            </div>
            <div className="aos-cat-list">
              {visibleCats.length > 0 && mergedCats.some(c => c.count > 0) ? (
                visibleCats.map(({ name, count }) => (
                  <div key={name} className="aos-cat-item">
                    <div className="aos-cat-info">
                      <span className="aos-cat-name">{name}</span>
                      <span className="aos-cat-val">{count}</span>
                    </div>
                    <div className="aos-progress-bg">
                      <div 
                        className="aos-progress-fill" 
                        style={{ width: `${stats.totalEnrollmentsToday > 0 ? (count / stats.totalEnrollmentsToday) * 100 : 0}%` }} 
                      />
                    </div>
                  </div>
                ))
              ) : (
                <div className="aos-empty-mini">
                  <FiCalendar size={24} />
                  <p>No enrollment activity per category for today.</p>
                </div>
              )}
            </div>
          </div>

          {/* New Courses Today */}
          <div className="aos-section-card">
            <div className="aos-sec-header">
              <FiBookOpen />
              <h3>Content Production</h3>
            </div>
            <div className="aos-status-row">
                <div className="aos-status-icon" style={{ background: 'rgba(184, 156, 77, 0.1)', color: '#b89c4d' }}>
                    <FiBookOpen size={16} />
                </div>
                <div className="aos-status-info">
                    <span className="aos-status-label">New Courses Created Today</span>
                    <span className="aos-status-val">{stats.newCourses}</span>
                </div>
            </div>
          </div>
        </div>

        <div className="aos-right-col">
          {/* Enrollment Type Split Today */}
          <div className="aos-section-card">
            <div className="aos-sec-header">
              <FiPieChart />
              <h3>Today's Split</h3>
            </div>
            <div className="aos-split-stats">
              <div className="aos-split-item">
                <div className="aos-split-label">Paid</div>
                <div className="aos-split-value">{stats.paidEnrollmentsToday}</div>
              </div>
              <div className="aos-split-sep" />
              <div className="aos-split-item">
                <div className="aos-split-label">Free</div>
                <div className="aos-split-value">{stats.freeEnrollmentsToday}</div>
              </div>
            </div>
            <div className="aos-stacked-bar">
               <div 
                 className="aos-bar-segment paid" 
                 style={{ width: `${stats.totalEnrollmentsToday > 0 ? (stats.paidEnrollmentsToday / stats.totalEnrollmentsToday) * 100 : 0}%` }} 
               />
               <div 
                 className="aos-bar-segment free" 
                 style={{ width: `${stats.totalEnrollmentsToday > 0 ? (stats.freeEnrollmentsToday / stats.totalEnrollmentsToday) * 100 : 0}%` }} 
               />
            </div>
            {stats.totalEnrollmentsToday === 0 && (
                <p style={{ textAlign: 'center', fontSize: '11px', color: '#999', marginTop: '12px' }}>
                    No enrollments recorded yet today.
                </p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function StatCard({ icon: Icon, label, value, trend, color }) {
  return (
    <div className={`aos-stat-card ${color}`}>
      <div className="aos-stat-icon">
        <Icon size={24} />
      </div>
      <div className="aos-stat-body">
        <p className="aos-stat-label">{label}</p>
        <h2 className="aos-stat-value">{value}</h2>
        <div className="aos-stat-footer">
          <FiArrowUpRight size={12} />
          <span>{trend}</span>
        </div>
      </div>
    </div>
  );
}
