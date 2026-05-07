"""
Configuration file for the recommendation system
"""
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # Database configuration (MongoDB)
    MONGO_URI = os.getenv('MONGO_URI', 'mongodb://localhost:27017/pfe_db')
    
    # Recommendation parameters
    TOP_N_RECOMMENDATIONS = 10
    MIN_SIMILARITY_THRESHOLD = 0.0  # 0 = return all non-enrolled courses ranked by score
    
    # Feature weights
    WEIGHT_PROGRESS = 0.25
    WEIGHT_PREFERENCES = 0.35
    WEIGHT_DIFFICULTY = 0.20
    WEIGHT_CATEGORY = 0.20
    
    # Model paths
    MODEL_PATH = 'models/'
    SCALER_PATH = 'models/scaler.pkl'
    ENCODER_PATH = 'models/encoder.pkl'
    
    # API configuration
    API_HOST = '0.0.0.0'
    API_PORT = 5000
