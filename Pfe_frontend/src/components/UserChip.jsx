import React from "react";
import "../styles/UserChip.css";

export default function UserChip({ user, onProfileClick }) {
  if (!user) return null;

  const { username, role, photo } = user;
  const initials = username ? username.slice(0, 2).toUpperCase() : "??";
  
  // Construct photo URL if photo exists and is not an empty string
  const photoUrl = (photo && photo.trim() !== "") ? `http://localhost:8080/api/files/${photo}` : null;

  return (
    <div className="uc-container" onClick={onProfileClick} title="Manage Profile">
      <div className="uc-avatar">
        {photoUrl ? (
          <img src={photoUrl} alt={username} className="uc-img" />
        ) : (
          <span className="uc-initials">{initials}</span>
        )}
      </div>
      <div className="uc-info">
        <p className="uc-name">{username}</p>
        <p className="uc-role">{role}</p>
      </div>
    </div>
  );
}
