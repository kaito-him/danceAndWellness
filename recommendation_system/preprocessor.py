"""
Data preprocessing module - handles data cleaning and feature engineering
"""
import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler, LabelEncoder, OneHotEncoder
from sklearn.impute import SimpleImputer
import joblib
from config import Config


class DataPreprocessor:
    """Handles all data preprocessing and feature engineering"""
    
    def __init__(self):
        self.scaler = StandardScaler()
        self.level_encoder = LabelEncoder()
        self.category_encoder = None
        self.imputer = SimpleImputer(strategy='mean')
        
    def preprocess_student_data(self, students_df, enrollments_df, lesson_progress_df):
        """
        Preprocess student data and create feature vectors
        
        Args:
            students_df: DataFrame with student information
            enrollments_df: DataFrame with enrollment data
            lesson_progress_df: DataFrame with lesson progress
            
        Returns:
            DataFrame with student feature vectors
        """
        # Handle missing values in student preferences
        students_df['preferred_category1'] = students_df['preferred_category1'].fillna('UNKNOWN')
        students_df['preferred_category2'] = students_df['preferred_category2'].fillna('UNKNOWN')
        students_df['preferred_category3'] = students_df['preferred_category3'].fillna('UNKNOWN')
        students_df['preferred_level'] = students_df['preferred_level'].fillna('BEGINNER')
        
        # Calculate student performance metrics
        student_features = self._calculate_student_metrics(
            students_df, enrollments_df, lesson_progress_df
        )
        
        # Encode categorical features
        student_features = self._encode_student_features(student_features)
        
        return student_features
    
    def _calculate_student_metrics(self, students_df, enrollments_df, lesson_progress_df):
        """
        Calculate performance and engagement metrics for each student
        """
        # Check if enrollments_df has required columns
        if enrollments_df.empty or 'student_id' not in enrollments_df.columns:
            # Return students with default metrics
            students_df['avg_progress'] = 0
            students_df['max_progress'] = 0
            students_df['min_progress'] = 0
            students_df['std_progress'] = 0
            students_df['total_enrollments'] = 0
            students_df['completed_courses'] = 0
            students_df['lessons_completed'] = 0
            students_df['total_lessons'] = 0
            students_df['lesson_completion_rate'] = 0
            students_df['engagement_score'] = 0.5
            return students_df
        
        # Ensure progress column exists
        if 'progress' not in enrollments_df.columns:
            enrollments_df['progress'] = 0
        
        # Average progress across all enrollments
        avg_progress = enrollments_df.groupby('student_id')['progress'].agg([
            ('avg_progress', 'mean'),
            ('max_progress', 'max'),
            ('min_progress', 'min'),
            ('std_progress', 'std')
        ]).reset_index()
        
        # Fill NaN std with 0 (students with only one course)
        avg_progress['std_progress'] = avg_progress['std_progress'].fillna(0)
        
        # Count enrollments and completions
        enrollment_counts = enrollments_df.groupby('student_id').agg({
            'course_id': 'count',
            'progress': lambda x: (x >= 90).sum()  # Completed courses
        }).rename(columns={'course_id': 'total_enrollments', 'progress': 'completed_courses'}).reset_index()
        
        # Calculate lesson completion rate
        lesson_completion = lesson_progress_df.groupby('student_id')['completed'].agg([
            ('lessons_completed', 'sum'),
            ('total_lessons', 'count')
        ]).reset_index()
        lesson_completion['lesson_completion_rate'] = (
            lesson_completion['lessons_completed'] / lesson_completion['total_lessons']
        ).fillna(0)
        
        # Calculate engagement score (time-based)
        if 'last_position' in lesson_progress_df.columns and 'duration' in lesson_progress_df.columns:
            engagement = lesson_progress_df.groupby('student_id').apply(
                lambda x: (x['last_position'].sum() / x['duration'].sum()) if x['duration'].sum() > 0 else 0
            ).reset_index(name='engagement_score')
        else:
            engagement = pd.DataFrame({
                'student_id': students_df['student_id'],
                'engagement_score': 0.5
            })
        
        # Merge all metrics
        student_features = students_df.copy()
        student_features = student_features.merge(avg_progress, on='student_id', how='left')
        student_features = student_features.merge(enrollment_counts, on='student_id', how='left')
        student_features = student_features.merge(lesson_completion, on='student_id', how='left')
        student_features = student_features.merge(engagement, on='student_id', how='left')
        
        # Fill missing values for new students
        numeric_cols = ['avg_progress', 'max_progress', 'min_progress', 'std_progress',
                       'total_enrollments', 'completed_courses', 'lessons_completed',
                       'total_lessons', 'lesson_completion_rate', 'engagement_score']
        
        for col in numeric_cols:
            if col in student_features.columns:
                student_features[col] = student_features[col].fillna(0)
        
        return student_features
    
    def _encode_student_features(self, student_features):
        """
        Encode categorical features for students
        """
        # Encode preferred level
        if 'preferred_level' in student_features.columns:
            level_mapping = {'BEGINNER': 1, 'INTERMEDIATE': 2, 'ADVANCED': 3, 'UNKNOWN': 0}
            student_features['preferred_level_encoded'] = student_features['preferred_level'].map(level_mapping)
        
        # One-hot encode preferred categories
        category_cols = ['preferred_category1', 'preferred_category2', 'preferred_category3']
        for col in category_cols:
            if col in student_features.columns:
                # Create dummy variables
                dummies = pd.get_dummies(student_features[col], prefix=col)
                student_features = pd.concat([student_features, dummies], axis=1)
        
        return student_features
    
    def preprocess_course_data(self, courses_df, enrollments_df):
        """
        Preprocess course data and create feature vectors
        
        Args:
            courses_df: DataFrame with course information
            enrollments_df: DataFrame with enrollment data
            
        Returns:
            DataFrame with course feature vectors
        """
        # Handle empty dataframe
        if courses_df.empty:
            print("Warning: No courses to preprocess")
            return courses_df
        
        # Ensure required columns exist
        if 'category_name' not in courses_df.columns:
            courses_df['category_name'] = 'UNKNOWN'
        if 'level' not in courses_df.columns:
            courses_df['level'] = 'BEGINNER'
        if 'price' not in courses_df.columns:
            courses_df['price'] = 0
        if 'lesson_count' not in courses_df.columns:
            courses_df['lesson_count'] = 0
        if 'enrollment_count' not in courses_df.columns:
            courses_df['enrollment_count'] = 0
        if 'avg_progress' not in courses_df.columns:
            courses_df['avg_progress'] = 0
        
        # Handle missing values
        courses_df['category_name'] = courses_df['category_name'].fillna('UNKNOWN')
        courses_df['level'] = courses_df['level'].fillna('BEGINNER')
        courses_df['price'] = courses_df['price'].fillna(0)
        courses_df['lesson_count'] = courses_df['lesson_count'].fillna(0)
        courses_df['enrollment_count'] = courses_df['enrollment_count'].fillna(0)
        courses_df['avg_progress'] = courses_df['avg_progress'].fillna(0)
        
        # Calculate course popularity score
        courses_df['popularity_score'] = self._calculate_popularity_score(courses_df)
        
        # Calculate course difficulty score based on average progress
        courses_df['difficulty_score'] = self._calculate_difficulty_score(courses_df)
        
        # Encode categorical features
        courses_df = self._encode_course_features(courses_df)
        
        return courses_df
    
    def _calculate_popularity_score(self, courses_df):
        """
        Calculate popularity score based on enrollments and completion rate
        """
        # Normalize enrollment count
        max_enrollments = courses_df['enrollment_count'].max()
        if max_enrollments > 0:
            normalized_enrollments = courses_df['enrollment_count'] / max_enrollments
        else:
            normalized_enrollments = 0
        
        # Combine with average progress (completion indicator)
        popularity = (normalized_enrollments * 0.7 + courses_df['avg_progress'] / 100 * 0.3)
        return popularity
    
    def _calculate_difficulty_score(self, courses_df):
        """
        Calculate difficulty score (inverse of average progress)
        Lower progress = harder course
        """
        # Inverse relationship: lower avg_progress = higher difficulty
        difficulty = 1 - (courses_df['avg_progress'] / 100)
        return difficulty.fillna(0.5)  # Default to medium difficulty
    
    def _encode_course_features(self, courses_df):
        """
        Encode categorical features for courses
        """
        # Encode level
        level_mapping = {'BEGINNER': 1, 'INTERMEDIATE': 2, 'ADVANCED': 3}
        courses_df['level_encoded'] = courses_df['level'].map(level_mapping).fillna(1)
        
        # One-hot encode category
        category_dummies = pd.get_dummies(courses_df['category_name'], prefix='category')
        courses_df = pd.concat([courses_df, category_dummies], axis=1)
        
        # Encode price (free vs paid)
        courses_df['is_paid'] = (~courses_df['is_free']).astype(int)
        
        return courses_df
    
    def normalize_features(self, features_df, feature_columns):
        """
        Normalize numerical features using StandardScaler
        
        Args:
            features_df: DataFrame with features
            feature_columns: List of column names to normalize
            
        Returns:
            DataFrame with normalized features
        """
        df_copy = features_df.copy()
        
        # Only normalize columns that exist
        cols_to_normalize = [col for col in feature_columns if col in df_copy.columns]
        
        if cols_to_normalize:
            df_copy[cols_to_normalize] = self.scaler.fit_transform(df_copy[cols_to_normalize])
        
        return df_copy
    
    def save_preprocessors(self):
        """Save fitted preprocessors for later use"""
        import os
        os.makedirs(Config.MODEL_PATH, exist_ok=True)
        
        joblib.dump(self.scaler, Config.SCALER_PATH)
        print(f"Preprocessors saved to {Config.MODEL_PATH}")
    
    def load_preprocessors(self):
        """Load previously fitted preprocessors"""
        try:
            self.scaler = joblib.load(Config.SCALER_PATH)
            print("Preprocessors loaded successfully")
        except FileNotFoundError:
            print("No saved preprocessors found. Using new instances.")
