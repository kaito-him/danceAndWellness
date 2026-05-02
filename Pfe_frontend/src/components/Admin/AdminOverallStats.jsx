import React, { useState, useEffect } from "react";
import {
  FiUsers,
  FiUserCheck,
  FiBookOpen,
  FiDollarSign,
  FiPieChart,
  FiActivity,
  FiUserPlus,
  FiShieldOff,
  FiGrid,
  FiArrowUpRight,
  FiLayers
} from "react-icons/fi";
import api from "./../services/api";
import "../../styles/AdminOverallStats.css";

export default function AdminOverallStats() {
  const [stats, setStats] = useState(null);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAllCats, setShowAllCats] = useState(false);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [statsRes, catsRes] = await Promise.all([
        api.get("/statistics/overall"),
        api.get("/categories")
      ]);
      setStats(statsRes.data);
      setCategories(catsRes.data);
    } catch (err) {
      console.error("Failed to load statistics data", err);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="aos-loading">
        <div className="admin-spinner" />
        <span>Calculating statistics...</span>
      </div>
    );
  }

  if (!stats) {
    return (
      <div className="aos-error">
        <FiActivity size={48} />
        <p>No statistics data available.</p>
      </div>
    );
  }

  const revenue = (stats.totalRevenueCents / 100).toLocaleString("en-US", {
    style: "currency",
    currency: "USD",
  });

  // Merge categories with course counts
  const mergedCats = categories.map(cat => ({
    name: cat.name,
    count: stats.coursesByCategory[cat.name] || 0
  })).sort((a, b) => b.count - a.count);

  const visibleCats = showAllCats ? mergedCats : mergedCats.slice(0, 3);

  return (
    <div className="aos-page">
      <div className="aos-header">
        <div>
          <h1 className="aos-title">Overall Statistics</h1>
          <p className="aos-subtitle">Platform-wide overview and performance metrics</p>
        </div>
        <button className="aos-refresh-btn" onClick={() => { setLoading(true); loadData(); }}>
          <FiActivity size={14} /> Refresh Data
        </button>
      </div>

      {/* ── Main KPIs ── */}
      <div className="aos-hero-grid">
        <StatCard 
          icon={FiDollarSign} 
          label="Total Platform Revenue" 
          value={revenue} 
          trend="+12% this month" 
          color="gold"
        />
        <StatCard 
          icon={FiUsers} 
          label="Total Students" 
          value={stats.totalStudents} 
          trend={`${stats.activeAccounts} active`} 
          color="blue"
        />
        <StatCard 
          icon={FiUserCheck} 
          label="Total Instructors" 
          value={stats.totalInstructors} 
          trend={`${stats.pendingInstructorApplications} pending`} 
          color="green"
        />
        <StatCard 
          icon={FiBookOpen} 
          label="Total Courses" 
          value={stats.totalCourses} 
          trend={`${stats.publishedCourses} published`} 
          color="purple"
        />
      </div>

      <div className="aos-main-layout">
        {/* ── Left Column: Distributions ── */}
        <div className="aos-left-col">
          {/* Courses by Category */}
          <div className="aos-section-card">
            <div className="aos-sec-header" style={{ justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <FiGrid />
                <h3>Courses by Category</h3>
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
              {visibleCats.length > 0 ? (
                visibleCats.map(({ name, count }) => (
                  <div key={name} className="aos-cat-item">
                    <div className="aos-cat-info">
                      <span className="aos-cat-name">{name}</span>
                      <span className="aos-cat-val">{count}</span>
                    </div>
                    <div className="aos-progress-bg">
                      <div 
                        className="aos-progress-fill" 
                        style={{ width: `${stats.publishedCourses > 0 ? (count / stats.publishedCourses) * 100 : 0}%` }} 
                      />
                    </div>
                  </div>
                ))
              ) : (
                <p className="aos-empty-text">No category data available.</p>
              )}
            </div>
          </div>

          {/* Enrollment Split */}
          <div className="aos-section-card">
            <div className="aos-sec-header">
              <FiPieChart />
              <h3>Enrollment Distribution</h3>
            </div>
            <div className="aos-split-stats">
              <div className="aos-split-item">
                <div className="aos-split-label">Paid Enrollments</div>
                <div className="aos-split-value">{stats.paidEnrollments}</div>
                <div className="aos-split-perc">{Math.round((stats.paidEnrollments / stats.totalEnrollments) * 100 || 0)}%</div>
              </div>
              <div className="aos-split-sep" />
              <div className="aos-split-item">
                <div className="aos-split-label">Free Enrollments</div>
                <div className="aos-split-value">{stats.freeEnrollments}</div>
                <div className="aos-split-perc">{Math.round((stats.freeEnrollments / stats.totalEnrollments) * 100 || 0)}%</div>
              </div>
            </div>
            <div className="aos-stacked-bar">
               <div 
                 className="aos-bar-segment paid" 
                 style={{ width: `${(stats.paidEnrollments / stats.totalEnrollments) * 100}%` }} 
               />
               <div 
                 className="aos-bar-segment free" 
                 style={{ width: `${(stats.freeEnrollments / stats.totalEnrollments) * 100}%` }} 
               />
            </div>
          </div>
        </div>

        {/* ── Right Column: Status Summary ── */}
        <div className="aos-right-col">
          {/* User Account Status */}
          <div className="aos-section-card">
            <div className="aos-sec-header">
              <FiUserPlus />
              <h3>User Health</h3>
            </div>
            <div className="aos-status-rows">
              <StatusRow label="Active Accounts" val={stats.activeAccounts} icon={FiUserCheck} color="#22783c" />
              <StatusRow label="Banned Accounts" val={stats.bannedAccounts} icon={FiShieldOff} color="#e53e3e" />
              <StatusRow label="Pending Instructors" val={stats.pendingInstructorApplications} icon={FiActivity} color="#b89c4d" />
            </div>
          </div>

          {/* Course Inventory */}
          <div className="aos-section-card">
            <div className="aos-sec-header">
              <FiLayers />
              <h3>Course Inventory</h3>
            </div>
            <div className="aos-inventory">
               <div className="aos-inv-item">
                  <span className="aos-inv-dot pub" />
                  <span className="aos-inv-label">Published</span>
                  <span className="aos-inv-val">{stats.publishedCourses}</span>
               </div>
               <div className="aos-inv-item">
                  <span className="aos-inv-dot draft" />
                  <span className="aos-inv-label">Drafts</span>
                  <span className="aos-inv-val">{stats.draftCourses}</span>
               </div>
               <div className="aos-inv-item">
                  <span className="aos-inv-dot arch" />
                  <span className="aos-inv-label">Archived</span>
                  <span className="aos-inv-val">{stats.archivedCourses}</span>
               </div>
            </div>
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

function StatusRow({ label, val, icon: Icon, color }) {
  return (
    <div className="aos-status-row">
      <div className="aos-status-icon" style={{ background: `${color}15`, color }}>
        <Icon size={16} />
      </div>
      <div className="aos-status-info">
        <span className="aos-status-label">{label}</span>
        <span className="aos-status-val">{val}</span>
      </div>
    </div>
  );
}
