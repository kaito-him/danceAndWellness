"""
Script to check MongoDB database contents
"""
from pymongo import MongoClient
from config import Config
import pandas as pd

def check_database():
    """Check what data exists in MongoDB"""
    print("=" * 70)
    print("CHECKING MONGODB DATABASE")
    print("=" * 70)
    print(f"\nConnecting to: {Config.MONGO_URI}")
    
    try:
        client = MongoClient(Config.MONGO_URI, serverSelectionTimeoutMS=5000)
        db = client.get_default_database()
        
        # Test connection
        client.server_info()
        print("✓ Connected successfully!\n")
        
        # List all collections
        collections = db.list_collection_names()
        print(f"Collections found: {len(collections)}")
        print(f"  {', '.join(collections)}\n")
        
        # Check each relevant collection
        print("-" * 70)
        print("COLLECTION DETAILS")
        print("-" * 70)
        
        # Students
        student_count = 0
        for coll_name in ['students', 'student', 'Students']:
            try:
                count = db[coll_name].count_documents({})
                if count > 0:
                    student_count = count
                    print(f"\n📚 STUDENTS: {student_count} total (in '{coll_name}')")
                    sample = db[coll_name].find_one()
                    print(f"   Sample fields: {list(sample.keys())}")
                    
                    # Check for preferences
                    with_prefs = db[coll_name].count_documents({
                        "$or": [
                            {"preferred_category1": {"$exists": True}},
                            {"preferredCategory1": {"$exists": True}}
                        ]
                    })
                    print(f"   With preferences: {with_prefs}")
                    break
            except:
                continue
        
        if student_count == 0:
            print(f"\n📚 STUDENTS: 0 total")
        
        # Courses
        course_count = 0
        published_count = 0
        for coll_name in ['Courses', 'courses', 'course', 'Course']:
            try:
                count = db[coll_name].count_documents({})
                if count > 0:
                    course_count = count
                    published_count = db[coll_name].count_documents({"status": "PUBLISHED"})
                    print(f"\n📖 COURSES: {course_count} total, {published_count} published (in '{coll_name}')")
                    sample = db[coll_name].find_one()
                    print(f"   Sample fields: {list(sample.keys())}")
                    
                    # Count by status
                    statuses = db[coll_name].distinct("status")
                    print(f"   Statuses: {statuses}")
                    for status in statuses:
                        status_count = db[coll_name].count_documents({"status": status})
                        print(f"     - {status}: {status_count}")
                    break
            except:
                continue
        
        if course_count == 0:
            print(f"\n📖 COURSES: 0 total")
        
        # Categories
        category_count = 0
        for coll_name in ['categories', 'category', 'Categories']:
            try:
                count = db[coll_name].count_documents({})
                if count > 0:
                    category_count = count
                    print(f"\n🏷️  CATEGORIES: {category_count} total (in '{coll_name}')")
                    categories = list(db[coll_name].find())
                    print(f"   Categories: {[c.get('name', 'N/A') for c in categories]}")
                    break
            except:
                continue
        
        if category_count == 0:
            print(f"\n🏷️  CATEGORIES: 0 total")
        
        # Enrollments
        enrollment_count = 0
        for coll_name in ['enrollments', 'enrollment', 'Enrollments']:
            try:
                count = db[coll_name].count_documents({})
                if count > 0:
                    enrollment_count = count
                    print(f"\n✅ ENROLLMENTS: {enrollment_count} total (in '{coll_name}')")
                    sample = db[coll_name].find_one()
                    print(f"   Sample fields: {list(sample.keys())}")
                    
                    # Average progress
                    pipeline = [{"$group": {"_id": None, "avg_progress": {"$avg": "$progress"}}}]
                    result = list(db[coll_name].aggregate(pipeline))
                    if result and result[0].get('avg_progress'):
                        print(f"   Average progress: {result[0]['avg_progress']:.1f}%")
                    break
            except:
                continue
        
        if enrollment_count == 0:
            print(f"\n✅ ENROLLMENTS: 0 total")
        
        # Lessons
        lesson_count = 0
        for coll_name in ['lessons', 'lesson', 'Lessons']:
            try:
                count = db[coll_name].count_documents({})
                if count > 0:
                    lesson_count = count
                    print(f"\n📝 LESSONS: {lesson_count} total (in '{coll_name}')")
                    sample = db[coll_name].find_one()
                    print(f"   Sample fields: {list(sample.keys())}")
                    break
            except:
                continue
        
        if lesson_count == 0:
            print(f"\n📝 LESSONS: 0 total")
        
        # Lesson Progress
        progress_count = 0
        for coll_name in ['lesson_progress', 'lessonProgress', 'LessonProgress']:
            try:
                count = db[coll_name].count_documents({})
                if count > 0:
                    progress_count = count
                    print(f"\n📊 LESSON PROGRESS: {progress_count} total (in '{coll_name}')")
                    sample = db[coll_name].find_one()
                    print(f"   Sample fields: {list(sample.keys())}")
                    
                    completed = db[coll_name].count_documents({"completed": True})
                    print(f"   Completed: {completed}")
                    break
            except:
                continue
        
        if progress_count == 0:
            print(f"\n📊 LESSON PROGRESS: 0 total")
        
        print("\n" + "=" * 70)
        print("RECOMMENDATION SYSTEM READINESS")
        print("=" * 70)
        
        ready = True
        issues = []
        
        if student_count == 0:
            ready = False
            issues.append("❌ No students found")
        else:
            print(f"✓ Students: {student_count}")
        
        if published_count == 0:
            ready = False
            issues.append("❌ No published courses found")
        else:
            print(f"✓ Published courses: {published_count}")
        
        if category_count == 0:
            issues.append("⚠️  No categories (will use 'UNKNOWN')")
        else:
            print(f"✓ Categories: {category_count}")
        
        if enrollment_count == 0:
            issues.append("⚠️  No enrollments (recommendations will be basic)")
        else:
            print(f"✓ Enrollments: {enrollment_count}")
        
        print()
        if ready:
            print("🎉 Database is ready for training!")
            print("\nRun: python main.py train")
        else:
            print("❌ Database is NOT ready for training")
            print("\nIssues:")
            for issue in issues:
                print(f"  {issue}")
            
            print("\nTo fix:")
            print("1. Start your Spring Boot backend")
            print("2. Create some students and courses through the application")
            print("3. Have students enroll in courses")
            print("4. Then run: python main.py train")
        
        client.close()
        
    except Exception as e:
        print(f"❌ Error connecting to MongoDB: {e}")
        print("\nMake sure:")
        print("1. MongoDB is running")
        print("2. Connection string is correct in .env file")
        print(f"   Current: {Config.MONGO_URI}")

if __name__ == '__main__':
    check_database()
