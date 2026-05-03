import React, { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import api from "./services/api";
import "../styles/ForgotPassword.css";

// step: "request" | "verify" | "reset" | "done"
export default function ForgotPassword({ onClose }) {
  const navigate = useNavigate();
  const [step, setStep] = useState("request");

  // request step
  const [usernameOrEmail, setUsernameOrEmail] = useState("");

  // verify step
  const [code, setCode] = useState(["", "", "", "", "", ""]);
  const [timeLeft, setTimeLeft] = useState(60);
  const [timerActive, setTimerActive] = useState(false);
  const inputRefs = useRef([]);

  // reset step
  const [userId, setUserId] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showNew, setShowNew] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [fieldErrors, setFieldErrors] = useState({});

  // countdown timer
  useEffect(() => {
    if (!timerActive) return;
    if (timeLeft <= 0) { setTimerActive(false); return; }
    const t = setTimeout(() => setTimeLeft((s) => s - 1), 1000);
    return () => clearTimeout(t);
  }, [timerActive, timeLeft]);

  // ── Step 1: request code ────────────────────────────────────────────────
  const handleRequest = async (e) => {
    e.preventDefault();
    setError("");
    if (!usernameOrEmail.trim()) {
      setError("Please enter your username or email.");
      return;
    }
    setLoading(true);
    try {
      await api.post("/auth/forgot-password/request", { usernameOrEmail: usernameOrEmail.trim() });
      setTimeLeft(60);
      setTimerActive(true);
      setStep("verify");
    } catch (err) {
      setError(err?.response?.data || "No account found with that username or email.");
    } finally {
      setLoading(false);
    }
  };

  // ── Step 2: verify code ─────────────────────────────────────────────────
  const handleCodeInput = (idx, val) => {
    if (!/^\d?$/.test(val)) return;
    const next = [...code];
    next[idx] = val;
    setCode(next);
    setError("");
    if (val && idx < 5) inputRefs.current[idx + 1]?.focus();
  };

  const handleCodeKeyDown = (idx, e) => {
    if (e.key === "Backspace" && !code[idx] && idx > 0) {
      inputRefs.current[idx - 1]?.focus();
    }
  };

  const handlePaste = (e) => {
    const pasted = e.clipboardData.getData("text").replace(/\D/g, "").slice(0, 6);
    if (pasted.length === 6) {
      setCode(pasted.split(""));
      inputRefs.current[5]?.focus();
    }
  };

  const handleVerify = async (e) => {
    e.preventDefault();
    const fullCode = code.join("");
    if (fullCode.length < 6) { setError("Please enter the full 6-digit code."); return; }
    if (timeLeft <= 0) { setError("Code has expired. Please request a new one."); return; }
    setLoading(true);
    setError("");
    try {
      const res = await api.post("/auth/forgot-password/verify", {
        usernameOrEmail: usernameOrEmail.trim(),
        code: fullCode,
      });
      setUserId(res.data.userId);
      setStep("reset");
    } catch (err) {
      const status = err?.response?.status;
      if (status === 410) {
        setError("Code has expired. Please request a new one.");
        setTimerActive(false);
      } else {
        setError(err?.response?.data || "Incorrect code. Please try again.");
      }
    } finally {
      setLoading(false);
    }
  };

  const handleResend = async () => {
    setError("");
    setCode(["", "", "", "", "", ""]);
    setLoading(true);
    try {
      await api.post("/auth/forgot-password/request", { usernameOrEmail: usernameOrEmail.trim() });
      setTimeLeft(60);
      setTimerActive(true);
    } catch (err) {
      setError(err?.response?.data || "Failed to resend code.");
    } finally {
      setLoading(false);
    }
  };

  // ── Step 3: reset password ──────────────────────────────────────────────
  const validatePassword = (pw) => {
    const errs = {};
    if (pw.length < 8) errs.length = "At least 8 characters";
    if (!/[A-Z]/.test(pw)) errs.upper = "At least 1 uppercase letter";
    if (!/[a-z]/.test(pw)) errs.lower = "At least 1 lowercase letter";
    if (!/\d/.test(pw)) errs.number = "At least 1 number";
    if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?]/.test(pw)) errs.special = "At least 1 special character";
    return errs;
  };

  const handleReset = async (e) => {
    e.preventDefault();
    setError("");
    const errs = validatePassword(newPassword);
    if (Object.keys(errs).length > 0) { setFieldErrors(errs); return; }
    if (newPassword !== confirmPassword) { setError("Passwords do not match."); return; }
    setLoading(true);
    try {
      await api.post("/auth/forgot-password/reset", { userId, newPassword, confirmPassword });
      setStep("done");
    } catch (err) {
      setError(err?.response?.data || "Failed to reset password. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const pwChecks = [
    { key: "length",  label: "At least 8 characters" },
    { key: "upper",   label: "1 uppercase letter" },
    { key: "lower",   label: "1 lowercase letter" },
    { key: "number",  label: "1 number" },
    { key: "special", label: "1 special character" },
  ];
  const currentErrors = newPassword ? validatePassword(newPassword) : {};

  return (
    <div className="fp-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="fp-card">
        <div className="fp-accent" />

        <button className="fp-close" onClick={onClose} aria-label="Close">✕</button>

        {/* ── Step 1: Request ── */}
        {step === "request" && (
          <>
            <div className="fp-header">
              <h2 className="fp-title">Forgot Password?</h2>
              <p className="fp-sub">Enter your username or email and we'll send you a reset code.</p>
            </div>
            <form onSubmit={handleRequest} className="fp-form">
              <div className="fp-field">
                <label>Username or Email</label>
                <input
                  type="text"
                  placeholder="e.g. john_doe or john@example.com"
                  value={usernameOrEmail}
                  onChange={(e) => { setUsernameOrEmail(e.target.value); setError(""); }}
                  autoFocus
                />
              </div>
              {error && <div className="fp-error">{error}</div>}
              <button type="submit" className="fp-btn" disabled={loading}>
                {loading ? "Sending…" : "Send Reset Code"}
              </button>
            </form>
          </>
        )}

        {/* ── Step 2: Verify ── */}
        {step === "verify" && (
          <>
            <div className="fp-header">
              <h2 className="fp-title">Enter Verification Code</h2>
              <p className="fp-sub">
                We sent a 6-digit code to your registered email.
                {timeLeft > 0
                  ? <> It expires in <span className="fp-timer">{timeLeft}s</span>.</>
                  : <span className="fp-expired"> Code expired.</span>
                }
              </p>
            </div>
            <form onSubmit={handleVerify} className="fp-form">
              <div className="fp-code-row" onPaste={handlePaste}>
                {code.map((digit, idx) => (
                  <input
                    key={idx}
                    ref={(el) => (inputRefs.current[idx] = el)}
                    className={`fp-code-input ${error ? "error" : ""}`}
                    type="text"
                    inputMode="numeric"
                    maxLength={1}
                    value={digit}
                    onChange={(e) => handleCodeInput(idx, e.target.value)}
                    onKeyDown={(e) => handleCodeKeyDown(idx, e)}
                    autoFocus={idx === 0}
                  />
                ))}
              </div>
              {error && <div className="fp-error">{error}</div>}
              <button type="submit" className="fp-btn" disabled={loading || timeLeft <= 0}>
                {loading ? "Verifying…" : "Verify Code"}
              </button>
              <button
                type="button"
                className="fp-link-btn"
                onClick={handleResend}
                disabled={loading || timeLeft > 0}
              >
                {timeLeft > 0 ? `Resend in ${timeLeft}s` : "Resend Code"}
              </button>
            </form>
          </>
        )}

        {/* ── Step 3: Reset ── */}
        {step === "reset" && (
          <>
            <div className="fp-header">
              <h2 className="fp-title">Set New Password</h2>
              <p className="fp-sub">Choose a strong password for your account.</p>
            </div>
            <form onSubmit={handleReset} className="fp-form">
              <div className="fp-field">
                <label>New Password</label>
                <div className="fp-pw-wrap">
                  <input
                    type={showNew ? "text" : "password"}
                    placeholder="New password"
                    value={newPassword}
                    onChange={(e) => { setNewPassword(e.target.value); setFieldErrors({}); setError(""); }}
                  />
                  <button type="button" className="fp-eye" onClick={() => setShowNew((v) => !v)}>
                    {showNew ? "🙈" : "👁"}
                  </button>
                </div>
              </div>

              {/* Password strength checklist */}
              {newPassword && (
                <ul className="fp-checklist">
                  {pwChecks.map(({ key, label }) => (
                    <li key={key} className={!currentErrors[key] ? "pass" : "fail"}>
                      <span>{!currentErrors[key] ? "✓" : "✗"}</span> {label}
                    </li>
                  ))}
                </ul>
              )}

              <div className="fp-field">
                <label>Confirm Password</label>
                <div className="fp-pw-wrap">
                  <input
                    type={showConfirm ? "text" : "password"}
                    placeholder="Confirm password"
                    value={confirmPassword}
                    onChange={(e) => { setConfirmPassword(e.target.value); setError(""); }}
                  />
                  <button type="button" className="fp-eye" onClick={() => setShowConfirm((v) => !v)}>
                    {showConfirm ? "🙈" : "👁"}
                  </button>
                </div>
                {confirmPassword && newPassword !== confirmPassword && (
                  <span className="fp-match-err">Passwords do not match</span>
                )}
              </div>

              {error && <div className="fp-error">{error}</div>}
              <button
                type="submit"
                className="fp-btn"
                disabled={loading || Object.keys(currentErrors).length > 0 || newPassword !== confirmPassword}
              >
                {loading ? "Saving…" : "Reset Password"}
              </button>
            </form>
          </>
        )}

        {/* ── Step 4: Done ── */}
        {step === "done" && (
          <div className="fp-done">
            <div className="fp-done-icon">✓</div>
            <h2 className="fp-title">Password Updated Successfully</h2>
            <p className="fp-sub">Your password has been changed. You can now sign in with your new password.</p>
            <button
              className="fp-btn"
              onClick={() => { onClose(); navigate("/login"); }}
            >
              Go to Login
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
