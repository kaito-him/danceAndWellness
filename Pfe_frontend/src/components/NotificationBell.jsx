import React, { useState, useEffect, useRef } from "react";
import api from "../components/services/api";
import "../styles/NotificationBell.css";

export default function NotificationBell() {
  const [open,          setOpen]          = useState(false);
  const [notifications, setNotifications] = useState([]);
  const [unread,        setUnread]        = useState(0);
  const dropdownRef = useRef(null);

  const fetchNotifications = async () => {
    try {
      const res = await api.get("/notifications");
      setNotifications(res.data);
      setUnread(res.data.filter((n) => !n.read).length);
    } catch (_) {}
  };

  // Poll every 30 s so instructors get notified without needing to refresh
  useEffect(() => {
    fetchNotifications();
    const interval = setInterval(fetchNotifications, 30000);
    return () => clearInterval(interval);
  }, []);

  // Close dropdown on outside click
  useEffect(() => {
    const handler = (e) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target))
        setOpen(false);
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const handleOpen = async () => {
    setOpen((o) => !o);
    if (!open && unread > 0) {
      try {
        await api.patch("/notifications/read-all");
        setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
        setUnread(0);
      } catch (_) {}
    }
  };

  const formatTime = (dt) => {
    const d = new Date(dt);
    return d.toLocaleDateString("en-GB", { day: "2-digit", month: "short" }) +
      " · " + d.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });
  };

  return (
    <div className="nb-wrap" ref={dropdownRef}>

      {/* Bell button */}
      <button className="nb-btn" onClick={handleOpen} aria-label="Notifications">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
          stroke="currentColor" strokeWidth="2" strokeLinecap="round">
          <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
          <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
        </svg>
        {unread > 0 && (
          <span className="nb-badge">{unread > 9 ? "9+" : unread}</span>
        )}
      </button>

      {/* Dropdown */}
      {open && (
        <div className="nb-dropdown">
          <div className="nb-dropdown-head">
            <span className="nb-dropdown-title">Notifications</span>
            {notifications.length > 0 && (
              <span className="nb-dropdown-count">{notifications.length}</span>
            )}
          </div>

          <div className="nb-list">
            {notifications.length === 0 ? (
              <div className="nb-empty">No notifications yet</div>
            ) : (
              notifications.map((n) => (
                <div key={n.id} className={`nb-item ${n.read ? "" : "nb-item-unread"}`}>
                  <span className={`nb-dot ${n.type === "COURSE_APPROVED" ? "nb-dot-green" : "nb-dot-red"}`} />
                  <div className="nb-item-body">
                    <p className="nb-item-msg">{n.message}</p>
                    <p className="nb-item-time">{formatTime(n.createdAt)}</p>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}