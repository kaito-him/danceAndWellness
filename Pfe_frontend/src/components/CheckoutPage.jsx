import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import api from "../components/services/api";
import { loadStripe } from "@stripe/stripe-js";
import {
  Elements,
  CardElement,
  useStripe,
  useElements,
} from "@stripe/react-stripe-js";
import "../styles/Checkout.css";

const stripePromise = loadStripe("pk_test_51TGJhq2MqsLK6y9qBnzzNiWdAro6RG6NdHEsX20MCSK6nboy9EosYgWb8z5iJ6YKiST0pEDhCkseemcHPoxvbD7K00i2IewEre");

// ── Navigate helpers — always land inside the dashboard ──────────────────────
const returnToCourse = (courseId, navigate) => {
  localStorage.setItem("pendingCourseId", courseId);
  navigate("/student");
};

const openLessons = (courseId, navigate) => {
  localStorage.setItem("pendingCourseDirect", courseId);
  navigate("/student");
};

// ── Checkout form ─────────────────────────────────────────────────────────────
function CheckoutForm({ course, clientSecret, paymentIntentId, studentId, onSuccess }) {
  const stripe = useStripe();
  const elements = useElements();

  const [processing, setProcessing] = useState(false);
  const [cardError, setCardError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!stripe || !elements) return;

    setProcessing(true);
    setCardError(null);

    // Card data goes directly to Stripe — never touches your server
    const { error, paymentIntent } = await stripe.confirmCardPayment(clientSecret, {
      payment_method: { card: elements.getElement(CardElement) },
    });

    if (error) {
      setCardError(error.message);
      setProcessing(false);
      return;
    }

    if (paymentIntent.status === "succeeded") {
      // Tell backend to save the enrollment
      await api.post("/enrollment/confirm", {
        paymentIntentId,
        courseId: course.courseId,
        studentId,
      });
      onSuccess();
    }
  };

  return (
    <form className="checkout-form" onSubmit={handleSubmit}>

      {/* ── Course summary ── */}
      <div className="checkout-summary">
        <img
          className="checkout-thumb"
          src={
            course.thumbnailUrl
              ? `http://localhost:8080${course.thumbnailUrl}`
              : "/placeholder.png"
          }
          alt={course.title}
        />
        <div className="checkout-summary-info">
          <p className="checkout-course-cat">{course.category}</p>
          <h2 className="checkout-course-title">{course.title}</h2>
          <p className="checkout-course-instructor">
            by {course.instructor?.username || "Instructor"}
          </p>
        </div>
        <p className="checkout-price">${course.price?.toFixed(2)}</p>
      </div>

      <div className="checkout-divider" />

      {/* ── Stripe CardElement ── */}
      <label className="checkout-label">Card details</label>
      <div className="checkout-card-wrap">
        <CardElement
          options={{
            style: {
              base: {
                fontSize: "16px",
                color: "#1a1a2e",
                fontFamily: "'Inter', sans-serif",
                "::placeholder": { color: "#aaa" },
              },
              invalid: { color: "#e55353" },
            },
          }}
        />
      </div>

      {cardError && (
        <p className="checkout-error">{cardError}</p>
      )}

      <button
        className="checkout-pay-btn"
        type="submit"
        disabled={!stripe || processing}
      >
        {processing
          ? <span className="checkout-spinner" />
          : <>Pay ${course.price?.toFixed(2)}</>
        }
      </button>

      <p className="checkout-secure-note">
        🔒 Secured by Stripe · Your card info never touches our servers
      </p>
    </form>
  );
}

// ── Page wrapper ──────────────────────────────────────────────────────────────
export default function CheckoutPage() {
  const { courseId } = useParams();
  const navigate = useNavigate();
  const userRole = localStorage.getItem("userRole");

  useEffect(() => {
    if (userRole === "INSTRUCTOR") {
      // Redirect to student dashboard which will show the switch modal for this course
      returnToCourse(courseId, navigate);
    }
  }, [userRole, courseId, navigate]);

  const studentId = localStorage.getItem("userId") || "demo-student-id";

  const [course, setCourse] = useState(null);
  const [clientSecret, setClientSecret] = useState(null);
  const [paymentIntentId, setPaymentIntentId] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [paid, setPaid] = useState(false);

  useEffect(() => {
    const init = async () => {
      try {
        // 1. Load course
        const { data: courseData } = await api.get(`/courses/${courseId}`);
        setCourse(courseData);

        // 2. Free course — skip checkout entirely, go to lessons
        if (courseData.isFree) {
          openLessons(courseId, navigate);
          return;
        }

        // 3. Paid course — create Stripe PaymentIntent
        const { data: intentData } = await api.post("/enrollment/create-intent", {
          courseId,
          studentId,
        });
        setClientSecret(intentData.clientSecret);
        setPaymentIntentId(intentData.paymentIntentId);

      } catch (err) {
        const msg =
          err.response?.data?.message ||
          err.response?.data ||
          err.message ||
          "Unexpected error";

        // Already paid — jump straight to lessons
        if (typeof msg === "string" && msg.toLowerCase().includes("already enrolled")) {
          openLessons(courseId, navigate);
          return;
        }

        setError(typeof msg === "string" ? msg : "An error occurred. Please try again.");
      } finally {
        setLoading(false);
      }
    };

    init();
  }, [courseId, studentId, navigate]);

  // After successful payment show success screen, then open lessons in dashboard
  const handleSuccess = () => {
    setPaid(true);
    setTimeout(() => openLessons(courseId, navigate), 2500);
  };

  // ── Loading ──
  if (loading) return (
    <div className="checkout-root">
      <div className="checkout-center">
        <div className="checkout-spinner-lg" />
        <p>Preparing checkout…</p>
      </div>
    </div>
  );

  // ── Error ──
  if (error) return (
    <div className="checkout-root">
      <div className="checkout-center">
        <div className="checkout-success-icon"
          style={{ background: "#e55353", marginBottom: 16 }}>✕
        </div>
        <p style={{ fontWeight: 700, fontSize: "1.1rem", color: "#1a1a2e", marginBottom: 6 }}>
          Something went wrong
        </p>
        <p className="checkout-error" style={{ fontSize: 15, marginBottom: 24 }}>
          {error}
        </p>
        <div style={{ display: "flex", gap: 12, flexWrap: "wrap", justifyContent: "center" }}>
          <button
            className="checkout-pay-btn"
            style={{ width: "auto", padding: "12px 24px" }}
            onClick={() => returnToCourse(courseId, navigate)}
          >
            ← Back to Course
          </button>
          <button
            className="checkout-back-btn"
            style={{ border: "1.5px solid #ddd", padding: "12px 24px", borderRadius: 10 }}
            onClick={() => window.location.reload()}
          >
            ↺ Try Again
          </button>
        </div>
      </div>
    </div>
  );

  // ── Success ──
  if (paid) return (
    <div className="checkout-root">
      <div className="checkout-center checkout-success-box">
        <div className="checkout-success-icon">✓</div>
        <h2>Payment Successful!</h2>
        <p>You're enrolled in <strong>{course?.title}</strong>.</p>
        <p className="checkout-redirect-note">Redirecting to your lessons…</p>
      </div>
    </div>
  );

  // ── Checkout form ──
  return (
    <div className="checkout-root">
      <div className="checkout-card">

        {/* Back → returns to embedded course detail inside dashboard */}
        <button
          className="checkout-back-btn"
          onClick={() => returnToCourse(courseId, navigate)}
        >
          ← Back to Course
        </button>

        <h1 className="checkout-heading">Complete Enrollment</h1>

        {clientSecret && course && (
          <Elements stripe={stripePromise} options={{ clientSecret }}>
            <CheckoutForm
              course={course}
              clientSecret={clientSecret}
              paymentIntentId={paymentIntentId}
              studentId={studentId}
              onSuccess={handleSuccess}
            />
          </Elements>
        )}
      </div>
    </div>
  );
}