"""
Main script to train and test the recommendation system
"""
import argparse
from recommendation_engine import RecommendationEngine
from evaluator import RecommendationEvaluator
from config import Config


def train_model():
    """Train the recommendation model"""
    print("=" * 60)
    print("TRAINING RECOMMENDATION MODEL")
    print("=" * 60)
    
    # Initialize engine
    engine = RecommendationEngine()
    
    # Load and prepare data
    success = engine.load_and_prepare_data()
    
    if not success:
        print("\n❌ Training failed: Insufficient data in database")
        print("\nTo fix this:")
        print("1. Make sure MongoDB is running: mongodb://localhost:27017")
        print("2. Ensure database 'pfe_db' exists")
        print("3. Add students to 'student' collection")
        print("4. Add courses with status='PUBLISHED' to 'course' collection")
        print("5. Optionally add enrollments and lesson progress for better recommendations")
        return
    
    # Save model
    engine.save_model()
    
    print("\n✓ Model training complete!")
    print(f"  - Students: {len(engine.student_ids)}")
    print(f"  - Courses: {len(engine.course_ids)}")
    print(f"  - Model saved to: {Config.MODEL_PATH}")


def test_recommendations(student_id, top_n=10):
    """Test recommendations for a specific student"""
    print("=" * 60)
    print(f"TESTING RECOMMENDATIONS FOR STUDENT {student_id}")
    print("=" * 60)
    
    # Load engine
    engine = RecommendationEngine()
    
    try:
        engine.load_model()
    except:
        print("No saved model found. Training new model...")
        engine.load_and_prepare_data()
        engine.save_model()
    
    # Get recommendations
    recommendations = engine.recommend_courses(student_id, top_n=top_n)
    
    print(f"\nTop {top_n} Recommendations:")
    print("-" * 60)
    
    if not recommendations:
        print("No recommendations found for this student.")
        return
    
    for i, rec in enumerate(recommendations, 1):
        print(f"\n{i}. {rec['title']}")
        print(f"   Category: {rec['category']} | Level: {rec['level']}")
        price_str = 'FREE' if rec['is_free'] else f"${rec['price']:.2f}"
        print(f"   Price: {price_str}")
        print(f"   Score: {rec['recommendation_score']:.4f}")
        print(f"   Popularity: {rec['popularity_score']:.4f}")
        print(f"   Lessons: {rec['lesson_count']}")


def evaluate_model():
    """Evaluate the recommendation model"""
    print("=" * 60)
    print("EVALUATING RECOMMENDATION MODEL")
    print("=" * 60)
    
    # Load engine
    engine = RecommendationEngine()
    
    try:
        engine.load_model()
    except:
        print("No saved model found. Training new model...")
        engine.load_and_prepare_data()
        engine.save_model()
    
    # Create evaluator
    evaluator = RecommendationEvaluator(engine)
    
    # Generate full evaluation report
    evaluator.generate_evaluation_report()


def refresh_model():
    """Refresh the recommendation model with latest data"""
    print("=" * 60)
    print("REFRESHING RECOMMENDATION MODEL")
    print("=" * 60)
    
    engine = RecommendationEngine()
    
    # Load existing model if available
    try:
        engine.load_model()
        print("Loaded existing model")
    except:
        print("No existing model found")
    
    # Refresh with latest data
    engine.refresh_recommendations()
    
    # Save updated model
    engine.save_model()
    
    print("\n✓ Model refresh complete!")


def find_similar_courses(course_id, top_n=5):
    """Find courses similar to a given course"""
    print("=" * 60)
    print(f"FINDING SIMILAR COURSES TO COURSE {course_id}")
    print("=" * 60)
    
    # Load engine
    engine = RecommendationEngine()
    
    try:
        engine.load_model()
    except:
        print("No saved model found. Training new model...")
        engine.load_and_prepare_data()
        engine.save_model()
    
    # Get similar courses
    similar_courses = engine.get_similar_courses(course_id, top_n=top_n)
    
    print(f"\nTop {top_n} Similar Courses:")
    print("-" * 60)
    
    if not similar_courses:
        print("No similar courses found.")
        return
    
    for i, course in enumerate(similar_courses, 1):
        print(f"\n{i}. {course['title']}")
        print(f"   Category: {course['category']} | Level: {course['level']}")
        print(f"   Similarity: {course['similarity_score']:.4f}")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='Course Recommendation System')
    parser.add_argument('command', choices=['train', 'test', 'evaluate', 'refresh', 'similar'],
                       help='Command to execute')
    parser.add_argument('--student-id', type=str, help='Student ID for testing (MongoDB ObjectId string)')
    parser.add_argument('--course-id', type=str, help='Course ID for finding similar courses (MongoDB ObjectId string)')
    parser.add_argument('--top-n', type=int, default=10, help='Number of recommendations')
    
    args = parser.parse_args()
    
    if args.command == 'train':
        train_model()
    
    elif args.command == 'test':
        if not args.student_id:
            print("Error: --student-id is required for testing")
            return
        test_recommendations(args.student_id, args.top_n)
    
    elif args.command == 'evaluate':
        evaluate_model()
    
    elif args.command == 'refresh':
        refresh_model()
    
    elif args.command == 'similar':
        if not args.course_id:
            print("Error: --course-id is required for finding similar courses")
            return
        find_similar_courses(args.course_id, args.top_n)


if __name__ == '__main__':
    main()
