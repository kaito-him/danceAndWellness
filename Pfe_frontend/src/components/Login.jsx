import React, { useState } from "react";
import { useNavigate, useLocation } from "react-router-dom"; // ← add useLocation
import api from "../components/services/api";
import "../styles/Login.css";
import Navbar from "../components/Navbar";

const Login = () => {
  const navigate  = useNavigate();
  const location  = useLocation(); // ← new
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [loading,  setLoading]  = useState(false);
  const [error,    setError]    = useState("");

  // Where to send the user after login — course page or role dashboard
  const redirectTo = location.state?.from || null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const res  = await api.post("/auth/login", { username, password });
      const data = res.data;

      if (data.success) {
        localStorage.setItem("token",    data.token);
        localStorage.setItem("role",     data.role);
        localStorage.setItem("userId",   data.userId);
        localStorage.setItem("username", data.username);

        // If the user was trying to reach a specific page, go there first
        if (redirectTo) {
          navigate(redirectTo);
          return;
        }

        if (data.role === "ADMIN")      navigate("/admin");
        if (data.role === "INSTRUCTOR") navigate("/instructor");
        if (data.role === "STUDENT")    navigate("/student");
      } else {
        setError("Incorrect username or password. Please try again.");
      }
    } catch (err) {
      const status  = err?.response?.status;
      const message = err?.response?.data?.message;

      if (status === 400) {
        setError("Username and password are required.");
      } else if (status === 401) {
        setError("Incorrect username or password. Please try again.");
      } else if (status === 403 && message === "INACTIVE") {
        setError("Your account has been banned. Please contact support.");
      } else if (status === 403 && message === "PENDING") {
        setError("Your account is waiting for review. We will notify you as soon as we can.");
      } else {
        setError("An internal error occurred. Please try again later.");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-page">
      <Navbar />
      <div className="login-container">
        <div className="login-card">
          <div className="card-accent" />
          <div className="login-header">
            <h2 className="login-title">Welcome Back</h2>
            {/* Show a contextual hint when redirected from a course */}
            <p className="login-subtitle">
              {redirectTo
                ? "Sign in to continue to your course"
                : "Sign in to continue your journey"}
            </p>
          </div>

          <form onSubmit={handleSubmit} className="login-form">
            <div className="input-group">
              <label htmlFor="username">Username</label>
              <input
                id="username"
                type="text"
                placeholder="Enter your username"
                value={username}
                onChange={(e) => { setUsername(e.target.value); setError(""); }}
                className={error ? "input-error" : ""}
                required
              />
            </div>

            <div className="input-group">
              <label htmlFor="password">Password</label>
              <input
                id="password"
                type="password"
                placeholder="Enter your password"
                value={password}
                onChange={(e) => { setPassword(e.target.value); setError(""); }}
                className={error ? "input-error" : ""}
                required
              />
            </div>

            {error && (
              <div className="error-banner" role="alert">
                <span className="error-icon">!</span>
                {error}
              </div>
            )}

            <div className="forgot-row">
              <a href="#" className="forgot-link">Forgot password?</a>
            </div>

            <button type="submit" className="login-button" disabled={loading}>
              {loading ? "Signing in…" : "Sign In"}
            </button>
          </form>

          <p className="signup-prompt">
            Don't have an account?{" "}
            <a href="/signup" className="signup-link">Get started free</a>
          </p>
        </div>
      </div>
    </div>
  );
};

export default Login;