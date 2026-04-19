import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import Navbar from "./Navbar";
import api from "../components/services/api";
import "../styles/StudentSignup.css";

const StudentSignup = () => {
  const navigate = useNavigate();

  const [form, setForm] = useState({
    username: "",
    email: "",
    password: "",
    confirmPassword: "",
  });

  const [showPw, setShowPw]         = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [errors, setErrors]         = useState({});
  const [loading, setLoading]       = useState(false);

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
    setErrors({ ...errors, [e.target.name]: "" });
  };

  const validate = () => {
    const newErrors = {};
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;

    if (!form.username.trim())
      newErrors.username = "Username is required.";
    if (!form.email.trim())
      newErrors.email = "Email is required.";
    if (!passwordRegex.test(form.password))
      newErrors.password =
        "Min. 8 characters with uppercase, lowercase, and a number.";
    if (form.password !== form.confirmPassword)
      newErrors.confirmPassword = "Passwords do not match.";

    return newErrors;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const validationErrors = validate();
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }

    setLoading(true);
    try {
      await api.post("/auth/register/student", {
        username: form.username,
        email:    form.email,
        password: form.password,
      });
      navigate("/student");
    } catch (err) {
      const msg = err.response?.data || "Something went wrong.";
      if (msg.toLowerCase().includes("username"))
        setErrors({ username: msg });
      else if (msg.toLowerCase().includes("email"))
        setErrors({ email: msg });
      else
        setErrors({ general: msg });
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Navbar />
      <div className="signup-page">
        {/* Decorative background grain */}
        <div className="signup-bg-grain" />

        <div className="signup-container">
          <Link to="/signup" className="back-btn">← Back to role selection</Link>

          <div className="signup-card">
            {/* Header */}
            <div className="signup-header">
              <span className="signup-eyebrow">New Account</span>
              <h2>Start your <em>journey</em></h2>
              <p className="signup-subtitle">
                Join thousands of students learning dance and wellness.
              </p>
            </div>

            <form onSubmit={handleSubmit} noValidate>

              {/* Username */}
              <div className="input-group">
                <label htmlFor="username">Username</label>
                <input
                  id="username"
                  name="username"
                  placeholder="your_handle"
                  value={form.username}
                  onChange={handleChange}
                  autoComplete="username"
                />
                {errors.username && <span className="input-error">{errors.username}</span>}
              </div>

              {/* Email */}
              <div className="input-group">
                <label htmlFor="email">Email</label>
                <input
                  id="email"
                  name="email"
                  type="email"
                  placeholder="you@example.com"
                  value={form.email}
                  onChange={handleChange}
                  autoComplete="email"
                />
                {errors.email && <span className="input-error">{errors.email}</span>}
              </div>

              {/* Password */}
              <div className="input-group">
                <label htmlFor="password">Password</label>
                <div className="password-field">
                  <input
                    id="password"
                    name="password"
                    type={showPw ? "text" : "password"}
                    placeholder="Min. 8 characters"
                    value={form.password}
                    onChange={handleChange}
                    autoComplete="new-password"
                  />
                  <button type="button" className="pw-toggle" onClick={() => setShowPw(v => !v)}>
                    {showPw ? "Hide" : "Show"}
                  </button>
                </div>
                {errors.password && <span className="input-error">{errors.password}</span>}
              </div>

              {/* Confirm Password */}
              <div className="input-group">
                <label htmlFor="confirmPassword">Confirm Password</label>
                <div className="password-field">
                  <input
                    id="confirmPassword"
                    name="confirmPassword"
                    type={showConfirm ? "text" : "password"}
                    placeholder="Repeat password"
                    value={form.confirmPassword}
                    onChange={handleChange}
                    autoComplete="new-password"
                  />
                  <button type="button" className="pw-toggle" onClick={() => setShowConfirm(v => !v)}>
                    {showConfirm ? "Hide" : "Show"}
                  </button>
                </div>
                {errors.confirmPassword && <span className="input-error">{errors.confirmPassword}</span>}
              </div>

              {errors.general && (
                <div className="server-error-banner">⚠ {errors.general}</div>
              )}

              <button type="submit" className="submit-btn" disabled={loading}>
                {loading ? "Creating account…" : "Create Account"}
              </button>
            </form>
          </div>

          <p className="form-foot">
            Want to teach instead?{" "}
            <Link to="/signup/instructor">Apply as Instructor</Link>
          </p>
        </div>
      </div>
    </>
  );
};

export default StudentSignup; 