"""
Test script to demonstrate the recommendation system
"""
import numpy as np
import pandas as pd
from recommendation_engine import RecommendationEngine
from evaluator import RecommendationEvaluator


def test_basic_recommendations():
    """Test basic recommendation functionality"""
    print("\n" + "=" * 70)
    print("TEST 1: Basic Recommendations")
    print("=" * 70)
    
    engine = RecommendationEngine()
    
    # Load or train model
    try:
        engine.load_model()
        print("✓ Model loaded from disk")
    except:
        print("Training new model...")
        engine.load_and_prepare_data()
        engine.save_model()
        print("✓ Model trained and saved")
    
    # Test with first 3 students
    test_students = engine.student_ids[:min(3, len(engine.student_ids))]
    
    for student_id in test_students:
        print(f"\n--- Student {student_id} ---")
        recommendations = engine.recommend_courses(student_id, top_n=5)
        
        if recommendations:
            print(f"Generated {len(recommendations)} recommendations:")
            for i, rec in enumerate(recommendations, 1):
                print(f"  {i}. {rec['title'][:40]:<40} | Score: {rec['recommendation_score']:.3f}")
        else:
            print("  No recommendations generated")
    
    print("\n✓ Test passed!")


def test_similar_courses():
    """Test similar course functionality"""
    print("\n" + "=" * 70)
    print("TEST 2: Similar Courses")
    print("=" * 70)
    
    engine = RecommendationEngine()
    
    try:
        engine.load_model()
    except:
        engine.load_and_prepare_data()
    
    # Test with first course
    if engine.course_ids:
        test_course_id = engine.course_ids[0]
        course_info = engine.courses_df[engine.courses_df['course_id'] == test_course_id].iloc[0]
        
        print(f"\nFinding courses similar to: {course_info['title']}")
        print(f"Category: {course_info['category_name']} | Level: {course_info['level']}")
        
        similar = engine.get_similar_courses(test_course_id, top_n=5)
        
        if similar:
            print(f"\nFound {len(similar)} similar courses:")
            for i, course in enumerate(similar, 1):
                print(f"  {i}. {course['title'][:40]:<40} | Similarity: {course['similarity_score']:.3f}")
        else:
            print("  No similar courses found")
    
    print("\n✓ Test passed!")


def test_evaluation_metrics():
    """Test evaluation functionality"""
    print("\n" + "=" * 70)
    print("TEST 3: Evaluation Metrics")
    print("=" * 70)
    
    engine = RecommendationEngine()
    
    try:
        engine.load_model()
    except:
        engine.load_and_prepare_data()
    
    evaluator = RecommendationEvaluator(engine)
    
    # Test with subset of students
    test_students = engine.student_ids[:min(20, len(engine.student_ids))]
    
    print(f"\nEvaluating with {len(test_students)} students...")
    
    # Accuracy metrics
    print("\n--- Accuracy Metrics ---")
    accuracy = evaluator.evaluate_recommendations(test_students, k=10)
    for metric, value in accuracy.items():
        print(f"  {metric}: {value:.4f}")
    
    # Diversity metrics
    print("\n--- Diversity Metrics ---")
    diversity = evaluator.evaluate_diversity(test_students[:10], k=10)
    print(f"  Unique courses: {diversity['unique_courses_recommended']}")
    print(f"  Diversity ratio: {diversity['diversity_ratio']:.4f}")
    print(f"  Category Gini: {diversity['category_gini']:.4f}")
    
    # Cold start
    print("\n--- Cold Start Performance ---")
    cold_start = evaluator.evaluate_cold_start(k=10)
    print(f"  New students: {cold_start.get('num_new_students', 0)}")
    print(f"  Recommendations generated: {cold_start.get('recommendations_generated', 0)}")
    print(f"  Avg score: {cold_start.get('avg_recommendation_score', 0):.4f}")
    
    print("\n✓ Test passed!")


def test_feature_vectors():
    """Test feature vector creation"""
    print("\n" + "=" * 70)
    print("TEST 4: Feature Vectors")
    print("=" * 70)
    
    engine = RecommendationEngine()
    
    try:
        engine.load_model()
    except:
        engine.load_and_prepare_data()
    
    print(f"\nStudent feature matrix shape: {engine.student_matrix.shape}")
    print(f"Course feature matrix shape: {engine.course_matrix.shape}")
    
    # Check for NaN values
    student_nans = np.isnan(engine.student_matrix).sum()
    course_nans = np.isnan(engine.course_matrix).sum()
    
    print(f"\nNaN values in student matrix: {student_nans}")
    print(f"NaN values in course matrix: {course_nans}")
    
    if student_nans == 0 and course_nans == 0:
        print("\n✓ No NaN values found!")
    else:
        print("\n✗ Warning: NaN values detected!")
    
    # Sample feature vector
    if len(engine.student_matrix) > 0:
        print(f"\nSample student feature vector (first 10 features):")
        print(engine.student_matrix[0][:10])
    
    if len(engine.course_matrix) > 0:
        print(f"\nSample course feature vector (first 10 features):")
        print(engine.course_matrix[0][:10])
    
    print("\n✓ Test passed!")


def test_refresh_mechanism():
    """Test recommendation refresh"""
    print("\n" + "=" * 70)
    print("TEST 5: Refresh Mechanism")
    print("=" * 70)
    
    engine = RecommendationEngine()
    
    try:
        engine.load_model()
        print("✓ Initial model loaded")
    except:
        engine.load_and_prepare_data()
        print("✓ Initial model trained")
    
    initial_update = engine.last_update
    print(f"Initial update time: {initial_update}")
    
    # Simulate refresh
    print("\nRefreshing recommendations...")
    engine.refresh_recommendations()
    
    new_update = engine.last_update
    print(f"New update time: {new_update}")
    
    if new_update > initial_update:
        print("\n✓ Refresh successful!")
    else:
        print("\n✗ Refresh may have failed")
    
    print("\n✓ Test passed!")


def run_all_tests():
    """Run all tests"""
    print("\n" + "=" * 70)
    print("RUNNING ALL TESTS")
    print("=" * 70)
    
    tests = [
        ("Basic Recommendations", test_basic_recommendations),
        ("Similar Courses", test_similar_courses),
        ("Evaluation Metrics", test_evaluation_metrics),
        ("Feature Vectors", test_feature_vectors),
        ("Refresh Mechanism", test_refresh_mechanism)
    ]
    
    passed = 0
    failed = 0
    
    for test_name, test_func in tests:
        try:
            test_func()
            passed += 1
        except Exception as e:
            print(f"\n✗ Test '{test_name}' failed: {str(e)}")
            failed += 1
    
    print("\n" + "=" * 70)
    print("TEST SUMMARY")
    print("=" * 70)
    print(f"Passed: {passed}/{len(tests)}")
    print(f"Failed: {failed}/{len(tests)}")
    
    if failed == 0:
        print("\n🎉 All tests passed!")
    else:
        print(f"\n⚠️  {failed} test(s) failed")


if __name__ == '__main__':
    import sys
    
    if len(sys.argv) > 1:
        test_name = sys.argv[1]
        
        tests = {
            'basic': test_basic_recommendations,
            'similar': test_similar_courses,
            'eval': test_evaluation_metrics,
            'features': test_feature_vectors,
            'refresh': test_refresh_mechanism,
            'all': run_all_tests
        }
        
        if test_name in tests:
            tests[test_name]()
        else:
            print(f"Unknown test: {test_name}")
            print(f"Available tests: {', '.join(tests.keys())}")
    else:
        run_all_tests()
