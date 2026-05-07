"""
Feature engineering module - creates combined feature representations
"""
import pandas as pd
import numpy as np
from config import Config


class FeatureEngineer:
    """Creates feature vectors for students and courses"""
    
    def __init__(self):
        self.student_feature_names = []
        self.course_feature_names = []
    
    def create_student_feature_vector(self, student_row, all_categories):
        """
        Create a comprehensive feature vector for a student.
        Falls back to a uniform non-zero vector when the student has no data,
        so cosine similarity still produces meaningful scores.
        """
        features = []

        # ── Performance features (5) ──────────────────────────────────────
        performance_features = [
            (student_row.get('avg_progress', 0) or 0) / 100,
            (student_row.get('max_progress', 0) or 0) / 100,
            (student_row.get('lesson_completion_rate', 0) or 0),
            (student_row.get('engagement_score', 0) or 0),
            (student_row.get('completed_courses', 0) or 0) /
                max((student_row.get('total_enrollments', 0) or 0), 1),
        ]
        features.extend([f * Config.WEIGHT_PROGRESS for f in performance_features])

        # ── Preferred level (1) ───────────────────────────────────────────
        preferred_level = (student_row.get('preferred_level_encoded', 1) or 1) / 3
        features.append(preferred_level * Config.WEIGHT_DIFFICULTY)

        # ── Category preferences (N) ──────────────────────────────────────
        category_vector = self._encode_category_preferences(student_row, all_categories)
        features.extend([c * Config.WEIGHT_PREFERENCES for c in category_vector])

        # ── Engagement count (1) ──────────────────────────────────────────
        total_enroll = min((student_row.get('total_enrollments', 0) or 0) / 10, 1)
        features.append(total_enroll * Config.WEIGHT_PREFERENCES)

        vec = np.array(features, dtype=float)

        # ── Cold-start fallback ───────────────────────────────────────────
        # If the entire vector is zero (new student, no prefs, no history)
        # replace it with a uniform vector so cosine similarity is non-zero.
        if vec.sum() == 0:
            vec = np.ones(len(vec)) * 0.1

        return vec
    
    def _encode_category_preferences(self, student_row, all_categories):
        """
        Encode student's preferred categories as a vector
        """
        category_vector = np.zeros(len(all_categories))
        
        # Weight: 1st preference = 1.0, 2nd = 0.7, 3rd = 0.4
        weights = [1.0, 0.7, 0.4]
        
        for i, pref_col in enumerate(['preferred_category1', 'preferred_category2', 'preferred_category3']):
            pref_cat = student_row.get(pref_col, 'UNKNOWN')
            if pref_cat in all_categories:
                idx = all_categories.index(pref_cat)
                category_vector[idx] = max(category_vector[idx], weights[i])
        
        return category_vector
    
    def create_course_feature_vector(self, course_row, all_categories):
        """
        Create a comprehensive feature vector for a course
        
        Args:
            course_row: Series containing course data
            all_categories: List of all possible categories
            
        Returns:
            numpy array with course features (same dimensions as student vector)
        """
        features = []
        
        # Difficulty features (weighted by WEIGHT_DIFFICULTY) - 2 features
        level_encoded = course_row.get('level_encoded', 1) / 3  # Normalize to 0-1
        difficulty_score = course_row.get('difficulty_score', 0.5)
        features.extend([
            level_encoded * Config.WEIGHT_DIFFICULTY,
            difficulty_score * Config.WEIGHT_DIFFICULTY
        ])
        
        # Category features (weighted by WEIGHT_CATEGORY) - N features (same as student)
        category_name = course_row.get('category_name', 'UNKNOWN')
        category_vector = np.zeros(len(all_categories))
        if category_name in all_categories:
            idx = all_categories.index(category_name)
            category_vector[idx] = 1.0
        features.extend([c * Config.WEIGHT_CATEGORY for c in category_vector])
        
        # Popularity and quality features - 4 features (to match student's 5 performance + 1 engagement)
        popularity = course_row.get('popularity_score', 0)
        lesson_count_normalized = min(course_row.get('lesson_count', 0) / 20, 1)
        enrollment_count_normalized = min(course_row.get('enrollment_count', 0) / 50, 1)
        avg_progress_normalized = course_row.get('avg_progress', 0) / 100
        
        features.extend([
            popularity * Config.WEIGHT_PREFERENCES,
            lesson_count_normalized * Config.WEIGHT_PREFERENCES,
            enrollment_count_normalized * Config.WEIGHT_PREFERENCES,
            avg_progress_normalized * Config.WEIGHT_PREFERENCES
        ])
        
        # Price feature - 1 feature
        is_free = 1 if course_row.get('is_free', False) else 0
        features.append(is_free * 0.1)  # Small weight for free courses
        
        vec = np.array(features, dtype=float)
        # Ensure course vector is never all-zeros
        if vec.sum() == 0:
            vec = np.ones(len(vec)) * 0.1
        return vec
    
    def create_student_course_matrix(self, students_df, courses_df, all_categories):
        """
        Create feature matrices for all students and courses
        
        Args:
            students_df: DataFrame with student data
            courses_df: DataFrame with course data
            all_categories: List of all categories
            
        Returns:
            Tuple of (student_matrix, course_matrix, student_ids, course_ids)
        """
        # Create student feature matrix
        student_features = []
        student_ids = []
        
        for idx, student in students_df.iterrows():
            feature_vector = self.create_student_feature_vector(student, all_categories)
            student_features.append(feature_vector)
            student_ids.append(student['student_id'])
        
        student_matrix = np.array(student_features)
        
        # Create course feature matrix
        course_features = []
        course_ids = []
        
        for idx, course in courses_df.iterrows():
            feature_vector = self.create_course_feature_vector(course, all_categories)
            course_features.append(feature_vector)
            course_ids.append(course['course_id'])
        
        course_matrix = np.array(course_features)
        
        return student_matrix, course_matrix, student_ids, course_ids
    
    def calculate_interaction_features(self, student_id, course_id, enrollments_df):
        """
        Calculate features based on student-course interactions
        
        Args:
            student_id: Student identifier
            course_id: Course identifier
            enrollments_df: DataFrame with enrollment history
            
        Returns:
            Dictionary with interaction features
        """
        # Check if student has enrolled in this course
        enrollment = enrollments_df[
            (enrollments_df['student_id'] == student_id) & 
            (enrollments_df['course_id'] == course_id)
        ]
        
        if not enrollment.empty:
            return {
                'is_enrolled': 1,
                'current_progress': enrollment.iloc[0]['progress'] / 100,
                'has_started': 1 if enrollment.iloc[0]['progress'] > 0 else 0
            }
        else:
            return {
                'is_enrolled': 0,
                'current_progress': 0,
                'has_started': 0
            }
    
    def get_similar_courses_features(self, course_id, courses_df, enrollments_df):
        """
        Get features from similar courses (same category, similar level)
        """
        target_course = courses_df[courses_df['course_id'] == course_id]
        
        if target_course.empty:
            return {}
        
        target_category = target_course.iloc[0]['category_name']
        target_level = target_course.iloc[0]['level']
        
        # Find similar courses
        similar_courses = courses_df[
            (courses_df['category_name'] == target_category) &
            (courses_df['level'] == target_level) &
            (courses_df['course_id'] != course_id)
        ]
        
        if similar_courses.empty:
            return {
                'similar_courses_count': 0,
                'similar_courses_avg_popularity': 0
            }
        
        return {
            'similar_courses_count': len(similar_courses),
            'similar_courses_avg_popularity': similar_courses['popularity_score'].mean()
        }
