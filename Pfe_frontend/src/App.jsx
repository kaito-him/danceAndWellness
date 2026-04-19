import { BrowserRouter, Routes, Route } from "react-router-dom";
import React, { useRef } from "react";
import HomePage from "../src/components/HomePage";
import Login from "../src/components/Login";
import AdminDashboard from "./components/Admin/AdminDashboard";
import InstructorDashboard from "../src/components/Instructor/InstructorDashboard";
import StudentDashboard from "../src/components/Student/StudentDashboard";
import ProtectedRoute from "../src/components/auth/ProtectedRoute";
import RoleSelection from "../src/components/RoleSelection";
import StudentSignup from "../src/components/StudentSignup";
import InstructorSignup from "../src/components/InstructorSignup";
import CoursePage from "./components/Coursepage";
import CoursesPage from "./components/Coursespage";
import LessonCardsPage from "./components/Lessoncardspage";
import LessonPlayerPage from "./components/Lessonplayerpage";
import CheckoutPage from "./components/CheckoutPage";

function App() {
  const instructorsRef = useRef(null);

  return (
    <BrowserRouter>
      <Routes>
        {/* ── Public ── */}
        <Route path="/" element={<HomePage instructorsRef={instructorsRef} />} />
        <Route path="/login" element={<Login />} />
        <Route path="/signup" element={<RoleSelection />} />
        <Route path="/signup/student" element={<StudentSignup />} />
        <Route path="/signup/instructor" element={<InstructorSignup />} />

        {/* ── Courses ── */}
        <Route path="/courses" element={<CoursesPage />} />
        <Route path="/courses/:courseId" element={<CoursePage />} />

        {/* ── Lessons ── */}
        <Route path="/courses/:courseId/lessons" element={<LessonCardsPage />} />
        <Route path="/courses/:courseId/lessons/:lessonId" element={<LessonPlayerPage />} />

        {/* ── Protected ── */}
        <Route path="/admin" element={<ProtectedRoute role="ADMIN"><AdminDashboard /></ProtectedRoute>} />
        <Route path="/instructor" element={<ProtectedRoute role="INSTRUCTOR"><InstructorDashboard /></ProtectedRoute>} />
        <Route path="/student" element={<ProtectedRoute role="STUDENT"><StudentDashboard /></ProtectedRoute>} />
        <Route path="/checkout/:courseId" element={<CheckoutPage />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;