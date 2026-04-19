import React from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import "../styles/Navbar.css";

const Navbar = ({ instructorsRef }) => {
  const { pathname } = useLocation();
  const navigate = useNavigate();

  const handleInstructorsClick = (e) => {
    e.preventDefault();
    const doScroll = () =>
      instructorsRef?.current?.scrollIntoView({ behavior: "smooth", block: "start" });

    if (pathname !== "/") {
      navigate("/");
      // Wait for route + paint before scrolling
      setTimeout(doScroll, 200);
    } else {
      doScroll();
    }
  };

  const NAV_LINKS = [
    { label: "Home",    to: "/" },
    { label: "Courses", to: "/courses" },
    { label: "About",   to: "/about" },
  ];

  return (
    <header className="navbar">
      <Link to="/" className="logo">Dance &amp; Wellness</Link>
      <nav className="nav-links">
        {NAV_LINKS.map(({ label, to }) => (
          <Link
            key={label}
            to={to}
            className={`nav-link ${pathname === to ? "active" : ""}`}
          >
            {label}
          </Link>
        ))}
        <a href="#instructors" className="nav-link" onClick={handleInstructorsClick}>
          Instructors
        </a>
      </nav>
      <Link to="/login" className="signin-btn">Sign In</Link>
    </header>
  );
};

export default Navbar;