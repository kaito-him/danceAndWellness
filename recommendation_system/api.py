"""
Flask API for the recommendation system
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
from recommendation_engine import RecommendationEngine
from evaluator import RecommendationEvaluator
from config import Config
import logging

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize recommendation engine
engine = RecommendationEngine()

# Load or train model on startup
try:
    logger.info("Loading recommendation model...")
    engine.load_model()
    logger.info("Model loaded successfully")
except:
    logger.info("No saved model found. Training new model...")
    engine.load_and_prepare_data()
    engine.save_model()
    logger.info("Model trained and saved")


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'last_update': str(engine.last_update) if engine.last_update else None,
        'num_students': len(engine.student_ids) if engine.student_ids else 0,
        'num_courses': len(engine.course_ids) if engine.course_ids else 0
    })


@app.route('/recommend/<string:student_id>', methods=['GET'])
def get_recommendations(student_id):
    """
    Get course recommendations for a student.
    Accepts either the Student._id or the User's userId — resolves automatically.
    """
    try:
        top_n = request.args.get('top_n', Config.TOP_N_RECOMMENDATIONS, type=int)

        # Resolve: if the passed ID is a userId, map it to the Student._id
        resolved_id = _resolve_student_id(student_id)
        logger.info(f"Recommendations for userId={student_id} → studentId={resolved_id}")

        recommendations = engine.recommend_courses(resolved_id, top_n=top_n)

        return jsonify({
            'student_id': student_id,
            'resolved_student_id': resolved_id,
            'recommendations': recommendations,
            'count': len(recommendations)
        })

    except Exception as e:
        logger.error(f"Error generating recommendations: {str(e)}")
        return jsonify({'error': str(e)}), 500


def _resolve_student_id(user_id_or_student_id):
    """
    Given either a userId or a Student._id, return the Student._id
    that exists in engine.student_ids.
    """
    # If it's already a known student_id, return it directly
    if engine.student_ids and user_id_or_student_id in engine.student_ids:
        return user_id_or_student_id

    # Otherwise treat it as a userId and look up the Student._id from DB
    try:
        dl = engine.data_loader
        for col in ['students', 'student', 'Students']:
            doc = dl.db[col].find_one({"userId": user_id_or_student_id}, {"_id": 1})
            if doc:
                return str(doc['_id'])
    except Exception as e:
        logger.warning(f"Could not resolve userId to studentId: {e}")

    # Fallback: return as-is
    return user_id_or_student_id


@app.route('/similar-courses/<string:course_id>', methods=['GET'])
def get_similar_courses(course_id):
    """
    Get courses similar to a given course

    Query params:
        - top_n: Number of similar courses (default: 5)
    """
    try:
        top_n = request.args.get('top_n', 5, type=int)

        logger.info(f"Finding similar courses for course {course_id}")
        similar_courses = engine.get_similar_courses(course_id, top_n=top_n)

        return jsonify({
            'course_id': course_id,
            'similar_courses': similar_courses,
            'count': len(similar_courses)
        })

    except Exception as e:
        logger.error(f"Error finding similar courses: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/refresh', methods=['POST'])
def refresh_recommendations():
    """
    Refresh the recommendation system with latest DB data and save the model.
    Call this when: new course published, student enrolls, lessons completed.
    """
    try:
        logger.info("Refreshing recommendation system...")
        engine.refresh_recommendations()
        engine.save_model()

        return jsonify({
            'status': 'success',
            'message': 'Recommendation system refreshed',
            'last_update': str(engine.last_update)
        })

    except Exception as e:
        logger.error(f"Error refreshing recommendations: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/evaluate', methods=['GET'])
def evaluate_system():
    """
    Evaluate recommendation system performance
    """
    try:
        logger.info("Evaluating recommendation system...")
        evaluator = RecommendationEvaluator(engine)
        
        # Run evaluations
        accuracy = evaluator.evaluate_recommendations(k=10)
        diversity = evaluator.evaluate_diversity(k=10)
        cold_start = evaluator.evaluate_cold_start(k=10)
        
        return jsonify({
            'accuracy_metrics': accuracy,
            'diversity_metrics': {
                'unique_courses': diversity['unique_courses_recommended'],
                'diversity_ratio': diversity['diversity_ratio'],
                'category_gini': diversity['category_gini'],
                'categories_covered': diversity['num_categories_covered']
            },
            'cold_start_metrics': cold_start
        })
    
    except Exception as e:
        logger.error(f"Error evaluating system: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/batch-recommend', methods=['POST'])
def batch_recommendations():
    """
    Get recommendations for multiple students at once
    
    Request body:
        {
            "student_ids": [1, 2, 3, ...],
            "top_n": 10
        }
    """
    try:
        data = request.get_json()
        student_ids = data.get('student_ids', [])
        top_n = data.get('top_n', Config.TOP_N_RECOMMENDATIONS)
        
        if not student_ids:
            return jsonify({'error': 'student_ids is required'}), 400
        
        logger.info(f"Generating batch recommendations for {len(student_ids)} students")
        
        results = {}
        for student_id in student_ids:
            recommendations = engine.recommend_courses(student_id, top_n=top_n)
            results[student_id] = recommendations
        
        return jsonify({
            'results': results,
            'count': len(results)
        })
    
    except Exception as e:
        logger.error(f"Error in batch recommendations: {str(e)}")
        return jsonify({'error': str(e)}), 500


@app.route('/stats', methods=['GET'])
def get_stats():
    """
    Get recommendation system statistics
    """
    try:
        stats = {
            'total_students': len(engine.student_ids) if engine.student_ids else 0,
            'total_courses': len(engine.course_ids) if engine.course_ids else 0,
            'total_enrollments': len(engine.enrollments_df) if engine.enrollments_df is not None else 0,
            'last_update': str(engine.last_update) if engine.last_update else None,
            'categories': engine.categories if engine.categories else [],
            'model_loaded': engine.student_matrix is not None
        }
        
        return jsonify(stats)
    
    except Exception as e:
        logger.error(f"Error getting stats: {str(e)}")
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    app.run(
        host=Config.API_HOST,
        port=Config.API_PORT,
        debug=True
    )
