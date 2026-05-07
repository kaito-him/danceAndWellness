"""
Recommendation engine - core recommendation logic using similarity-based approach
"""
import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.neighbors import NearestNeighbors
from sklearn.ensemble import RandomForestClassifier
import joblib
from datetime import datetime
from config import Config
from data_loader import DataLoader
from preprocessor import DataPreprocessor
from feature_engineer import FeatureEngineer


class RecommendationEngine:
    """
    Main recommendation engine using hybrid approach:
    1. Content-based filtering (cosine similarity)
    2. Collaborative filtering (user-based)
    3. Popularity-based boosting
    """
    
    def __init__(self):
        self.data_loader = DataLoader()
        self.preprocessor = DataPreprocessor()
        self.feature_engineer = FeatureEngineer()
        
        # Cached data
        self.students_df = None
        self.courses_df = None
        self.enrollments_df = None
        self.lesson_progress_df = None
        self.categories = None
        
        # Feature matrices
        self.student_matrix = None
        self.course_matrix = None
        self.student_ids = None
        self.course_ids = None
        
        # Models
        self.knn_model = None
        
        # Last update timestamp
        self.last_update = None
    
    def load_and_prepare_data(self):
        """
        Load all data from database and prepare feature matrices
        """
        print("Loading data from database...")
        
        # Load raw data
        self.students_df = self.data_loader.load_student_data()
        self.courses_df = self.data_loader.load_course_data()
        self.enrollments_df = self.data_loader.load_enrollment_data()
        self.lesson_progress_df = self.data_loader.load_lesson_progress()
        categories_df = self.data_loader.load_categories()
        self.categories = categories_df['name'].tolist() if not categories_df.empty else ['UNKNOWN']
        
        print(f"Loaded {len(self.students_df)} students, {len(self.courses_df)} courses")
        
        # Check if we have minimum data
        if len(self.students_df) == 0:
            print("\n⚠️  ERROR: No students found in database!")
            print("Please ensure your MongoDB database has student data.")
            print("Database: pfe_db, Collection: student")
            return False
        
        if len(self.courses_df) == 0:
            print("\n⚠️  ERROR: No published courses found in database!")
            print("Please ensure your MongoDB database has published courses.")
            print("Database: pfe_db, Collection: course (with status='PUBLISHED')")
            return False
        
        # Preprocess data
        print("Preprocessing data...")
        self.students_df = self.preprocessor.preprocess_student_data(
            self.students_df, self.enrollments_df, self.lesson_progress_df
        )
        self.courses_df = self.preprocessor.preprocess_course_data(
            self.courses_df, self.enrollments_df
        )
        
        # Create feature matrices
        print("Creating feature matrices...")
        self.student_matrix, self.course_matrix, self.student_ids, self.course_ids = \
            self.feature_engineer.create_student_course_matrix(
                self.students_df, self.courses_df, self.categories
            )

        # Sanitize: replace NaN/inf with 0
        self.student_matrix = np.nan_to_num(self.student_matrix, nan=0.0, posinf=1.0, neginf=0.0)
        self.course_matrix  = np.nan_to_num(self.course_matrix,  nan=0.0, posinf=1.0, neginf=0.0)
        
        # Train KNN model for collaborative filtering
        print("Training KNN model...")
        self._train_knn_model()
        
        self.last_update = datetime.now()
        print(f"Data preparation complete at {self.last_update}")
        return True
    
    def _train_knn_model(self):
        """
        Train KNN model for finding similar students
        """
        if self.student_matrix is not None and len(self.student_matrix) > 0:
            # Replace any NaN/inf values before fitting
            import numpy as np
            self.student_matrix = np.nan_to_num(self.student_matrix, nan=0.0, posinf=1.0, neginf=0.0)

            n_neighbors = min(5, len(self.student_matrix) - 1)
            if n_neighbors > 0:
                self.knn_model = NearestNeighbors(
                    n_neighbors=n_neighbors,
                    metric='cosine',
                    algorithm='brute'
                )
                self.knn_model.fit(self.student_matrix)
    
    def recommend_courses(self, student_id, top_n=None):
        """
        Generate course recommendations for a student
        """
        if top_n is None:
            top_n = Config.TOP_N_RECOMMENDATIONS
        
        # Check if data needs refresh
        if self.student_matrix is None or self.course_matrix is None:
            print("No model loaded, loading data...")
            self.load_and_prepare_data()
        
        # Get student index
        try:
            student_idx = self.student_ids.index(student_id)
        except ValueError:
            print(f"Student {student_id} not found in student_ids.")
            print(f"Available student IDs: {self.student_ids}")
            return self._get_popular_courses(top_n)
        
        # Get student feature vector
        student_vector = self.student_matrix[student_idx].reshape(1, -1)
        
        # Check dimension compatibility — reload if mismatch
        if student_vector.shape[1] != self.course_matrix.shape[1]:
            print(f"Dimension mismatch (student:{student_vector.shape[1]} vs course:{self.course_matrix.shape[1]}), reloading...")
            self.load_and_prepare_data()
            student_idx = self.student_ids.index(student_id)
            student_vector = self.student_matrix[student_idx].reshape(1, -1)
        
        # Calculate scores
        content_scores = self._calculate_content_similarity(student_vector)
        collab_scores  = self._calculate_collaborative_scores(student_idx)
        hybrid_scores  = self._combine_scores(content_scores, collab_scores)
        
        # Filter out already enrolled courses
        enrolled_courses = self.data_loader.get_student_enrolled_courses(student_id)
        
        print(f"\n[DEBUG] student_idx      : {student_idx}")
        print(f"[DEBUG] enrolled_courses  : {enrolled_courses}")
        print(f"[DEBUG] total courses     : {len(self.course_ids)}")
        print(f"[DEBUG] score range       : min={hybrid_scores.min():.4f}  max={hybrid_scores.max():.4f}")
        print(f"[DEBUG] threshold         : {Config.MIN_SIMILARITY_THRESHOLD}")
        above = [(self.course_ids[i], round(float(hybrid_scores[i]), 4))
                 for i in range(len(self.course_ids))
                 if hybrid_scores[i] >= Config.MIN_SIMILARITY_THRESHOLD
                 and self.course_ids[i] not in enrolled_courses]
        print(f"[DEBUG] courses above threshold (not enrolled): {len(above)}")
        for cid, sc in above[:5]:
            print(f"         course_id={cid}  score={sc}")
        
        # Build recommendations list
        recommendations = []
        for course_idx, score in enumerate(hybrid_scores):
            course_id = self.course_ids[course_idx]
            if course_id in enrolled_courses:
                continue
            if score < Config.MIN_SIMILARITY_THRESHOLD:
                continue
            course_info = self.courses_df[self.courses_df['course_id'] == course_id]
            if course_info.empty:
                continue
            course_info = course_info.iloc[0]
            recommendations.append({
                'course_id': course_id,
                'title': course_info['title'],
                'category': course_info.get('category_name', 'Unknown'),
                'level': course_info.get('level', 'BEGINNER'),
                'price': float(course_info['price']) if not course_info.get('is_free', True) else 0,
                'is_free': bool(course_info.get('is_free', True)),
                'thumbnail_url': course_info.get('thumbnailUrl') or course_info.get('thumbnail_url') or None,
                'instructor_name': course_info.get('instructor_username') or course_info.get('instructor_name') or None,
                'recommendation_score': float(score),
                'popularity_score': float(course_info.get('popularity_score', 0)),
                'lesson_count': int(course_info.get('lesson_count', 0))
            })
        
        recommendations.sort(key=lambda x: x['recommendation_score'], reverse=True)
        return recommendations[:top_n]
    
    def _calculate_content_similarity(self, student_vector):
        """
        Calculate content-based similarity between student and all courses
        """
        # Cosine similarity between student vector and all course vectors
        similarities = cosine_similarity(student_vector, self.course_matrix)[0]
        return similarities
    
    def _calculate_collaborative_scores(self, student_idx):
        """
        Calculate collaborative filtering scores based on similar students
        """
        if self.knn_model is None or len(self.student_matrix) < 2:
            return np.zeros(len(self.course_ids))
        
        # Guard: enrollments_df must be a valid non-empty DataFrame with required columns
        if (self.enrollments_df is None or
                not isinstance(self.enrollments_df, pd.DataFrame) or
                self.enrollments_df.empty or
                'student_id' not in self.enrollments_df.columns or
                'course_id' not in self.enrollments_df.columns):
            return np.zeros(len(self.course_ids))
        
        # Find similar students
        distances, indices = self.knn_model.kneighbors(
            self.student_matrix[student_idx].reshape(1, -1)
        )
        
        collab_scores = np.zeros(len(self.course_ids))
        
        for idx, distance in zip(indices[0], distances[0]):
            if idx == student_idx:
                continue
            
            similar_student_id = self.student_ids[idx]
            similar_student_courses = self.enrollments_df[
                self.enrollments_df['student_id'] == similar_student_id
            ]
            
            similarity_weight = 1 - distance if distance < 1 else 0
            
            for _, enrollment in similar_student_courses.iterrows():
                course_id = enrollment['course_id']
                if course_id in self.course_ids:
                    course_idx = self.course_ids.index(course_id)
                    progress = enrollment.get('progress', 0) or 0
                    progress_weight = progress / 100
                    collab_scores[course_idx] += similarity_weight * progress_weight
        
        if collab_scores.max() > 0:
            collab_scores = collab_scores / collab_scores.max()
        
        return collab_scores
    
    def _combine_scores(self, content_scores, collab_scores, content_weight=0.7, collab_weight=0.3):
        """
        Combine content-based and collaborative filtering scores
        """
        # Weighted combination
        hybrid_scores = (content_weight * content_scores) + (collab_weight * collab_scores)
        
        # Apply popularity boost for new students (with few enrollments)
        # This is already incorporated in the feature vectors
        
        return hybrid_scores
    
    def _get_popular_courses(self, top_n):
        """
        Return most popular courses (fallback for new students)
        """
        popular_courses = self.courses_df.nlargest(top_n, 'popularity_score')
        
        recommendations = []
        for _, course in popular_courses.iterrows():
            recommendations.append({
                'course_id': course['course_id'],
                'title': course['title'],
                'category': course['category_name'],
                'level': course['level'],
                'price': float(course['price']) if not course['is_free'] else 0,
                'is_free': bool(course['is_free']),
                'recommendation_score': float(course['popularity_score']),
                'popularity_score': float(course['popularity_score']),
                'lesson_count': int(course['lesson_count'])
            })
        
        return recommendations
    
    def refresh_recommendations(self):
        """
        Refresh the recommendation system (call when courses change or student actions occur)
        """
        print("Refreshing recommendation system...")
        self.load_and_prepare_data()
        print("Refresh complete!")
    
    def get_similar_courses(self, course_id, top_n=5):
        """
        Find courses similar to a given course
        
        Args:
            course_id: Course identifier
            top_n: Number of similar courses to return
            
        Returns:
            List of similar courses
        """
        try:
            course_idx = self.course_ids.index(course_id)
        except ValueError:
            return []
        
        course_vector = self.course_matrix[course_idx].reshape(1, -1)
        
        # Calculate similarity with all other courses
        similarities = cosine_similarity(course_vector, self.course_matrix)[0]
        
        # Get top N similar courses (excluding the course itself)
        similar_indices = np.argsort(similarities)[::-1][1:top_n+1]
        
        similar_courses = []
        for idx in similar_indices:
            similar_course_id = self.course_ids[idx]
            course_info = self.courses_df[self.courses_df['course_id'] == similar_course_id].iloc[0]
            
            similar_courses.append({
                'course_id': similar_course_id,
                'title': course_info['title'],
                'category': course_info['category_name'],
                'level': course_info['level'],
                'similarity_score': float(similarities[idx])
            })
        
        return similar_courses
    
    def save_model(self, path=None):
        """Save the trained model and all required data"""
        if path is None:
            path = Config.MODEL_PATH
        
        import os
        os.makedirs(path, exist_ok=True)
        
        model_data = {
            'student_matrix': self.student_matrix,
            'course_matrix': self.course_matrix,
            'student_ids': self.student_ids,
            'course_ids': self.course_ids,
            'knn_model': self.knn_model,
            'last_update': self.last_update,
            # Save dataframes needed at inference time
            'courses_df': self.courses_df,
            'enrollments_df': self.enrollments_df,
            'categories': self.categories,
        }
        
        joblib.dump(model_data, f"{path}/recommendation_model.pkl")
        self.preprocessor.save_preprocessors()
        print(f"Model saved to {path}")
    
    def load_model(self, path=None):
        """Load a previously trained model"""
        if path is None:
            path = Config.MODEL_PATH
        
        try:
            model_data = joblib.load(f"{path}/recommendation_model.pkl")
            self.student_matrix = model_data['student_matrix']
            self.course_matrix = model_data['course_matrix']
            self.student_ids = model_data['student_ids']
            self.course_ids = model_data['course_ids']
            self.knn_model = model_data['knn_model']
            self.last_update = model_data['last_update']
            # Restore dataframes
            self.courses_df = model_data.get('courses_df')
            self.enrollments_df = model_data.get('enrollments_df', pd.DataFrame())
            self.categories = model_data.get('categories', [])
            
            self.preprocessor.load_preprocessors()
            print(f"Model loaded from {path}")
            print(f"Last update: {self.last_update}")
        except FileNotFoundError:
            print("No saved model found. Please train a new model.")
