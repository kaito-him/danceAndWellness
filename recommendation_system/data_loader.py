"""
Data loader module - fetches data from MongoDB
"""
import pandas as pd
import numpy as np
from pymongo import MongoClient
from config import Config


class DataLoader:
    """Handles data extraction from MongoDB"""
    
    def __init__(self):
        self.client = MongoClient(Config.MONGO_URI)
        self.db = self.client.get_default_database()
    
    def load_student_data(self):
        """
        Load student data including preferences from user_profiles.
        Returns: DataFrame with student features
        """
        students = None
        for collection_name in ['students', 'student', 'Students']:
            try:
                students = list(self.db[collection_name].find({"isBanned": {"$ne": True}}))
                if students:
                    print(f"Found {len(students)} students in '{collection_name}' collection")
                    break
            except:
                continue

        if not students:
            print("Warning: No students found in database")
            return pd.DataFrame(columns=['student_id', 'username', 'preferred_category1',
                                         'preferred_category2', 'preferred_category3', 'preferred_level'])

        df = pd.DataFrame(students)

        # student_id = Student._id (used throughout the engine)
        if '_id' in df.columns:
            df['student_id'] = df['_id'].astype(str)
        elif 'userId' in df.columns:
            df['student_id'] = df['userId'].astype(str)

        # Keep userId for enrollment resolution
        if 'userId' in df.columns:
            df['userId'] = df['userId'].astype(str)
        else:
            df['userId'] = df['student_id']

        # ── Pull preferences from user_profiles ───────────────────────────
        # user_profiles.studentId actually stores the User's userId, not Student._id
        try:
            user_ids = df['userId'].tolist()
            profiles = list(self.db['user_profiles'].find(
                {"studentId": {"$in": user_ids}}
            ))
            print(f"Found {len(profiles)} user_profiles for {len(user_ids)} students")
            if profiles:
                profiles_df = pd.DataFrame(profiles)
                # Join key: profile.studentId == student.userId
                profiles_df['userId'] = profiles_df['studentId'].astype(str)

                def extract_pref(prefs, idx):
                    if not isinstance(prefs, list) or len(prefs) <= idx:
                        return None
                    p = prefs[idx]
                    if isinstance(p, dict):
                        return p.get('name') or p.get('categoryName') or str(p.get('_id', ''))
                    return str(p)

                profiles_df['preferred_category1'] = profiles_df['preferences'].apply(
                    lambda p: extract_pref(p, 0))
                profiles_df['preferred_category2'] = profiles_df['preferences'].apply(
                    lambda p: extract_pref(p, 1))
                profiles_df['preferred_category3'] = profiles_df['preferences'].apply(
                    lambda p: extract_pref(p, 2))
                profiles_df['preferred_level'] = profiles_df['skillLevel'].apply(
                    lambda s: str(s) if s else None)

                # Merge on userId (common key between student doc and user_profile)
                df = df.merge(
                    profiles_df[['userId', 'preferred_category1', 'preferred_category2',
                                 'preferred_category3', 'preferred_level']],
                    on='userId', how='left'
                )
                matched = df['preferred_category1'].notna().sum()
                print(f"  -> {matched}/{len(df)} students have preference data")
        except Exception as e:
            print(f"   Note: Could not load user_profiles: {e}")

        # Handle username field
        if 'username' not in df.columns:
            if 'name' in df.columns:
                df['username'] = df['name']
            elif 'email' in df.columns:
                df['username'] = df['email']
            else:
                df['username'] = df['student_id']

        # Ensure required columns exist
        for col in ['preferred_category1', 'preferred_category2', 'preferred_category3', 'preferred_level']:
            if col not in df.columns:
                df[col] = None

        required_cols = ['student_id', 'username', 'preferred_category1',
                         'preferred_category2', 'preferred_category3', 'preferred_level']
        for col in required_cols:
            if col not in df.columns:
                df[col] = None

        return df[required_cols]
    
    def load_enrollment_data(self):
        """
        Load enrollment data with progress information
        Returns: DataFrame with enrollment details
        """
        # Try different collection names
        enrollments = None
        for collection_name in ['enrollments', 'enrollment', 'Enrollments']:
            try:
                enrollments = list(self.db[collection_name].find())
                if enrollments:
                    print(f"Found {len(enrollments)} enrollments in '{collection_name}' collection")
                    break
            except:
                continue
        
        if not enrollments:
            print("Warning: No enrollments found in database")
            return pd.DataFrame(columns=['student_id', 'course_id', 'progress', 'enrolled_at'])
        
        df = pd.DataFrame(enrollments)
        
        # Convert IDs to strings
        if 'studentId' in df.columns:
            # Enrollments store studentId = userId.
            # The engine uses Student._id as student_id, so map userId → Student._id.
            df['user_id_raw'] = df['studentId'].astype(str)
            df['student_id'] = df['user_id_raw']  # default: keep as userId

            # Build userId → Student._id mapping
            try:
                from bson import ObjectId
                user_ids = df['user_id_raw'].unique().tolist()
                student_docs = []
                for col in ['students', 'student', 'Students']:
                    student_docs = list(self.db[col].find(
                        {"userId": {"$in": user_ids}},
                        {"_id": 1, "userId": 1}
                    ))
                    if student_docs:
                        break
                if student_docs:
                    uid_to_sid = {str(d['userId']): str(d['_id']) for d in student_docs}
                    df['student_id'] = df['user_id_raw'].map(uid_to_sid).fillna(df['user_id_raw'])
            except Exception as e:
                print(f"   Note: Could not map userId→studentId: {e}")
        elif 'student_id' not in df.columns and '_id' in df.columns:
            df['student_id'] = df['_id'].astype(str)
            
        if 'courseId' in df.columns:
            df['course_id'] = df['courseId'].astype(str)
        elif 'course_id' not in df.columns and 'course' in df.columns:
            df['course_id'] = df['course'].astype(str)
        
        # Ensure progress column exists
        if 'progress' not in df.columns:
            df['progress'] = 0
            print("   Note: 'progress' field not found, using default value 0")
        
        # Ensure enrolled_at exists
        if 'enrolledAt' in df.columns:
            df['enrolled_at'] = df['enrolledAt']
        elif 'enrolled_at' not in df.columns:
            df['enrolled_at'] = None
        
        # Get course details
        course_ids = df['course_id'].dropna().unique().tolist()
        from bson import ObjectId
        object_ids = []
        for cid in course_ids:
            try:
                object_ids.append(ObjectId(cid))
            except Exception:
                object_ids.append(cid)
        courses = list(self.db['Courses'].find({"_id": {"$in": object_ids}, "status": "PUBLISHED"}))
        if not courses:
            # fallback collection names
            for col in ['courses', 'course', 'Course']:
                courses = list(self.db[col].find({"_id": {"$in": object_ids}, "status": "PUBLISHED"}))
                if courses:
                    break
        courses_df = pd.DataFrame(courses)
        
        if not courses_df.empty:
            if '_id' in courses_df.columns:
                courses_df['course_id'] = courses_df['_id'].astype(str)
            
            # Merge course details
            df = df.merge(courses_df[['course_id', 'title', 'categoryId', 'level', 'price', 'isFree']], 
                         on='course_id', how='left')
            
            # Rename columns
            df = df.rename(columns={'categoryId': 'category_id', 'isFree': 'is_free'})
        
        return df
    
    def load_lesson_progress(self):
        """
        Load detailed lesson progress for each student
        Returns: DataFrame with lesson completion data
        """
        # Try different collection names
        lesson_progress = None
        for collection_name in ['lesson_progress', 'lessonProgress', 'LessonProgress']:
            try:
                lesson_progress = list(self.db[collection_name].find())
                if lesson_progress:
                    print(f"Found {len(lesson_progress)} lesson progress records in '{collection_name}' collection")
                    break
            except:
                continue
        
        if not lesson_progress:
            print("Warning: No lesson progress found in database")
            return pd.DataFrame(columns=['student_id', 'lesson_id', 'completed', 'last_position'])
        
        df = pd.DataFrame(lesson_progress)
        
        # Convert IDs
        if 'studentId' in df.columns:
            df['student_id'] = df['studentId'].astype(str)
        if 'lessonId' in df.columns:
            df['lesson_id'] = df['lessonId'].astype(str)
        
        # Ensure required columns
        if 'completed' not in df.columns:
            df['completed'] = False
        if 'lastPosition' in df.columns:
            df['last_position'] = df['lastPosition']
        elif 'last_position' not in df.columns:
            df['last_position'] = 0
        
        # Get lesson details to find course_id
        lesson_ids = df['lesson_id'].unique()
        lessons = list(self.db.lesson.find({"_id": {"$in": list(lesson_ids)}}))
        lessons_df = pd.DataFrame(lessons)
        
        if not lessons_df.empty:
            if '_id' in lessons_df.columns:
                lessons_df['lesson_id'] = lessons_df['_id'].astype(str)
            if 'courseId' in lessons_df.columns:
                lessons_df['course_id'] = lessons_df['courseId'].astype(str)
            
            # Merge lesson details
            df = df.merge(lessons_df[['lesson_id', 'course_id', 'duration']], 
                         on='lesson_id', how='left')
        
        return df
    
    def load_course_data(self):
        """
        Load all published courses
        Returns: DataFrame with course features
        """
        # Try different collection names
        courses = None
        for collection_name in ['Courses', 'courses', 'course', 'Course']:
            try:
                courses = list(self.db[collection_name].find({"status": "PUBLISHED"}))
                if courses:
                    print(f"Found {len(courses)} published courses in '{collection_name}' collection")
                    break
            except:
                continue
        
        if not courses:
            print("Warning: No published courses found in database")
            return pd.DataFrame(columns=['course_id', 'title', 'description', 'category_id', 
                                        'level', 'price', 'is_free', 'created_at'])
        
        df = pd.DataFrame(courses)
        
        # Convert IDs
        if '_id' in df.columns:
            df['course_id'] = df['_id'].astype(str)
        if 'categoryId' in df.columns:
            df['category_id'] = df['categoryId'].astype(str)
        if 'isFree' in df.columns:
            df['is_free'] = df['isFree']
        if 'createdAt' in df.columns:
            df['created_at'] = df['createdAt']

        # Preserve display fields needed by the recommendation response
        if 'thumbnailUrl' in df.columns:
            df['thumbnail_url'] = df['thumbnailUrl']
        else:
            df['thumbnail_url'] = None

        # Extract instructor username from the embedded instructor object
        def extract_instructor_name(instr):
            if isinstance(instr, dict):
                return instr.get('username') or instr.get('name') or None
            return None

        if 'instructor' in df.columns:
            df['instructor_name'] = df['instructor'].apply(extract_instructor_name)
        else:
            df['instructor_name'] = None
        
        # Get category names
        category_ids = df['category_id'].dropna().unique().tolist()

        # Try different collection names for categories
        categories = None
        categories_df = None
        for collection_name in ['categories', 'category', 'Categories']:
            try:
                # category_ids are plain strings; MongoDB _id may be ObjectId — try both
                from bson import ObjectId
                object_ids = []
                for cid in category_ids:
                    try:
                        object_ids.append(ObjectId(cid))
                    except Exception:
                        object_ids.append(cid)
                categories = list(self.db[collection_name].find(
                    {"_id": {"$in": object_ids}}
                ))
                if categories:
                    categories_df = pd.DataFrame(categories)
                    break
            except Exception:
                continue
        
        if categories_df is not None and not categories_df.empty:
            if '_id' in categories_df.columns:
                categories_df['category_id'] = categories_df['_id'].astype(str)
            df = df.merge(categories_df[['category_id', 'name']], on='category_id', how='left')
            df = df.rename(columns={'name': 'category_name'})
        else:
            df['category_name'] = 'Uncategorized'
        
        # Count lessons - try different collection names
        all_lessons = None
        for collection_name in ['lessons', 'lesson', 'Lessons']:
            try:
                all_lessons = list(self.db[collection_name].find())
                if all_lessons:
                    break
            except:
                continue
        
        if all_lessons:
            lessons_df = pd.DataFrame(all_lessons)
            if 'courseId' in lessons_df.columns:
                lessons_df['course_id'] = lessons_df['courseId'].astype(str)
                lesson_counts = lessons_df.groupby('course_id').size().reset_index(name='lesson_count')
                df = df.merge(lesson_counts, on='course_id', how='left')
        
        if 'lesson_count' not in df.columns:
            df['lesson_count'] = 0
        
        # Count enrollments and calculate average progress
        # Try different collection names
        enrollments = None
        for collection_name in ['enrollments', 'enrollment', 'Enrollments']:
            try:
                enrollments = list(self.db[collection_name].find())
                if enrollments:
                    break
            except:
                continue
        
        if enrollments:
            enrollments_df = pd.DataFrame(enrollments)
            
            # Ensure required columns exist
            if 'courseId' in enrollments_df.columns:
                enrollments_df['course_id'] = enrollments_df['courseId'].astype(str)
            elif 'course_id' not in enrollments_df.columns:
                enrollments_df['course_id'] = None
            
            if 'studentId' not in enrollments_df.columns:
                enrollments_df['studentId'] = None
            
            if 'progress' not in enrollments_df.columns:
                enrollments_df['progress'] = 0
            
            # Only aggregate if we have valid data
            if 'course_id' in enrollments_df.columns and enrollments_df['course_id'].notna().any():
                enrollment_stats = enrollments_df.groupby('course_id').agg({
                    'studentId': 'count',
                    'progress': 'mean'
                }).reset_index()
                enrollment_stats.columns = ['course_id', 'enrollment_count', 'avg_progress']
                
                df = df.merge(enrollment_stats, on='course_id', how='left')
        
        if 'enrollment_count' not in df.columns:
            df['enrollment_count'] = 0
        if 'avg_progress' not in df.columns:
            df['avg_progress'] = 0
        
        return df
    
    def load_categories(self):
        """
        Load all categories
        Returns: DataFrame with category information
        """
        # Try different collection names
        categories = None
        for collection_name in ['categories', 'category', 'Categories']:
            try:
                categories = list(self.db[collection_name].find())
                if categories:
                    print(f"Found {len(categories)} categories in '{collection_name}' collection")
                    break
            except:
                continue
        
        if not categories:
            print("Warning: No categories found in database")
            return pd.DataFrame(columns=['id', 'name'])
        
        df = pd.DataFrame(categories)
        
        if '_id' in df.columns:
            df['id'] = df['_id'].astype(str)
        
        return df[['id', 'name']]
    
    def get_student_completed_courses(self, student_id):
        """
        Get courses completed by a specific student (progress >= 90%).
        student_id here is the Student document's _id (MongoDB ObjectId string).
        Enrollments store studentId = userId, so we resolve userId first.
        """
        # Resolve userId from student document
        user_id = self._resolve_user_id(student_id)

        for collection_name in ['enrollments', 'enrollment', 'Enrollments']:
            try:
                enrollments = list(self.db[collection_name].find({
                    "studentId": user_id,
                    "progress": {"$gte": 90}
                }))
                if enrollments:
                    return [str(e.get('courseId')) for e in enrollments if 'courseId' in e]
            except:
                continue
        return []

    def get_student_enrolled_courses(self, student_id):
        """
        Get all courses a student is enrolled in.
        student_id here is the Student document's _id (MongoDB ObjectId string).
        Enrollments store studentId = userId, so we resolve userId first.
        """
        user_id = self._resolve_user_id(student_id)

        for collection_name in ['enrollments', 'enrollment', 'Enrollments']:
            try:
                enrollments = list(self.db[collection_name].find({"studentId": user_id}))
                # Return results even if empty list (student exists but not enrolled)
                return [str(e.get('courseId')) for e in enrollments if 'courseId' in e]
            except:
                continue
        return []

    def _resolve_user_id(self, student_id):
        """
        Given a Student document _id string, return the corresponding userId.
        Falls back to student_id itself if not found (handles cases where
        student_id is already a userId).
        """
        try:
            from bson import ObjectId
            for collection_name in ['students', 'student', 'Students']:
                try:
                    doc = self.db[collection_name].find_one({"_id": ObjectId(student_id)})
                    if doc and 'userId' in doc:
                        return str(doc['userId'])
                except Exception:
                    pass
        except Exception:
            pass
        # Fallback: assume student_id is already a userId
        return student_id
    
    def close(self):
        """Close database connection"""
        self.client.close()
