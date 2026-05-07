# Course Recommendation System

A machine learning-based course recommendation system for the Dance & Wellness platform using Python and scikit-learn.

## Features

- **Hybrid Recommendation Approach**:
  - Content-based filtering (cosine similarity)
  - Collaborative filtering (KNN-based)
  - Popularity-based boosting

- **Personalized Recommendations** based on:
  - Academic performance (progress per course)
  - Student preferences (interests, preferred topics, difficulty level)
  - Enrollment history
  - Lesson completion rates

- **Real-time Updates**: Automatically refreshes when:
  - New courses are published
  - Courses are archived
  - Students enroll/unenroll
  - Students watch lessons

- **Comprehensive Evaluation**:
  - Precision@K, Recall@K, Hit Rate
  - Diversity metrics
  - Cold start performance

## Architecture

```
recommendation_system/
├── config.py              # Configuration and parameters
├── data_loader.py         # Database data extraction
├── preprocessor.py        # Data preprocessing and cleaning
├── feature_engineer.py    # Feature vector creation
├── recommendation_engine.py  # Core recommendation logic
├── evaluator.py           # Evaluation metrics
├── api.py                 # Flask REST API
├── main.py                # CLI interface
├── requirements.txt       # Python dependencies
└── models/                # Saved models (created on first run)
```

## Installation

### 1. Install Dependencies

```bash
cd recommendation_system
pip install -r requirements.txt
```

### 2. Configure Database

Copy `.env.example` to `.env` and update with your database credentials:

```bash
cp .env.example .env
```

Edit `.env`:
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=dance_wellness
DB_USER=postgres
DB_PASSWORD=your_password
```

### 3. Train the Model

```bash
python main.py train
```

This will:
- Load data from the database
- Preprocess and engineer features
- Train the recommendation model
- Save the model to `models/`

## Usage

### Command Line Interface

#### Train Model
```bash
python main.py train
```

#### Test Recommendations for a Student
```bash
python main.py test --student-id 1 --top-n 10
```

#### Evaluate Model Performance
```bash
python main.py evaluate
```

#### Refresh Model with Latest Data
```bash
python main.py refresh
```

#### Find Similar Courses
```bash
python main.py similar --course-id 5 --top-n 5
```

### REST API

#### Start the API Server
```bash
python api.py
```

The API will run on `http://localhost:5000`

#### API Endpoints

**Get Recommendations for a Student**
```bash
GET /recommend/<student_id>?top_n=10
```

Response:
```json
{
  "student_id": 1,
  "recommendations": [
    {
      "course_id": 5,
      "title": "Advanced Ballet Techniques",
      "category": "BALLET",
      "level": "ADVANCED",
      "price": 49.99,
      "is_free": false,
      "recommendation_score": 0.8542,
      "popularity_score": 0.7234,
      "lesson_count": 15
    }
  ],
  "count": 10
}
```

**Get Similar Courses**
```bash
GET /similar-courses/<course_id>?top_n=5
```

**Refresh Recommendations**
```bash
POST /refresh
```

**Evaluate System**
```bash
GET /evaluate
```

**Get System Statistics**
```bash
GET /stats
```

**Health Check**
```bash
GET /health
```

## Integration with Java Backend

### Option 1: REST API Integration

Add a service in your Spring Boot backend to call the Python API:

```java
@Service
public class RecommendationService {
    
    private final RestTemplate restTemplate;
    private final String recommendationApiUrl = "http://localhost:5000";
    
    public List<CourseRecommendation> getRecommendations(Long studentId, int topN) {
        String url = String.format("%s/recommend/%d?top_n=%d", 
            recommendationApiUrl, studentId, topN);
        
        RecommendationResponse response = restTemplate.getForObject(
            url, RecommendationResponse.class);
        
        return response.getRecommendations();
    }
    
    public void refreshRecommendations() {
        String url = recommendationApiUrl + "/refresh";
        restTemplate.postForObject(url, null, Void.class);
    }
}
```

### Option 2: Scheduled Refresh

Add a scheduled task to refresh recommendations periodically:

```java
@Scheduled(cron = "0 0 2 * * ?") // Every day at 2 AM
public void refreshRecommendations() {
    recommendationService.refreshRecommendations();
}
```

### Option 3: Event-Driven Refresh

Trigger refresh on specific events:

```java
@EventListener
public void onCoursePublished(CoursePublishedEvent event) {
    recommendationService.refreshRecommendations();
}

@EventListener
public void onStudentEnrolled(EnrollmentEvent event) {
    recommendationService.refreshRecommendations();
}
```

## How It Works

### 1. Data Preprocessing

- **Handle Missing Values**: Fill missing preferences with defaults
- **Encode Categorical Features**: 
  - Level: BEGINNER=1, INTERMEDIATE=2, ADVANCED=3
  - Categories: One-hot encoding
- **Normalize Numerical Features**: StandardScaler for progress, engagement scores

### 2. Feature Engineering

**Student Feature Vector**:
- Performance metrics (25% weight):
  - Average progress across courses
  - Lesson completion rate
  - Engagement score
  - Completion ratio

- Preference features (35% weight):
  - Preferred categories (weighted: 1st=1.0, 2nd=0.7, 3rd=0.4)
  - Preferred difficulty level
  - Total enrollments

**Course Feature Vector**:
- Difficulty features (20% weight):
  - Level encoding
  - Difficulty score (based on avg progress)

- Category features (20% weight):
  - One-hot encoded category

- Quality features:
  - Popularity score
  - Lesson count
  - Price (free vs paid)

### 3. Recommendation Algorithm

**Hybrid Approach** (Content-based + Collaborative):

1. **Content-based Similarity** (70% weight):
   - Calculate cosine similarity between student and course vectors
   - Matches student preferences with course characteristics

2. **Collaborative Filtering** (30% weight):
   - Find similar students using KNN
   - Recommend courses that similar students enrolled in
   - Weight by similarity and progress

3. **Filtering**:
   - Exclude already enrolled courses
   - Apply minimum similarity threshold
   - Rank by combined score

### 4. Evaluation Metrics

- **Precision@K**: Proportion of recommended courses that are relevant
- **Recall@K**: Proportion of relevant courses that are recommended
- **Hit Rate@K**: Whether at least one recommendation is relevant
- **Coverage**: Percentage of courses that get recommended
- **Diversity**: Distribution across categories (Gini coefficient)
- **Cold Start**: Performance for new students

## Configuration

Edit `config.py` to adjust:

```python
# Recommendation parameters
TOP_N_RECOMMENDATIONS = 10
MIN_SIMILARITY_THRESHOLD = 0.1

# Feature weights
WEIGHT_PROGRESS = 0.25      # Academic performance
WEIGHT_PREFERENCES = 0.35   # Student interests
WEIGHT_DIFFICULTY = 0.20    # Difficulty matching
WEIGHT_CATEGORY = 0.20      # Category matching
```

## Performance Optimization

### Caching
The system caches feature matrices and only recomputes when data changes.

### Batch Processing
Use the `/batch-recommend` endpoint for multiple students:

```bash
POST /batch-recommend
{
  "student_ids": [1, 2, 3, 4, 5],
  "top_n": 10
}
```

### Model Persistence
Models are saved to disk and loaded on startup for fast initialization.

## Monitoring

Check system health:
```bash
curl http://localhost:5000/health
```

Get statistics:
```bash
curl http://localhost:5000/stats
```

## Troubleshooting

### Issue: No recommendations returned
- Check if student exists in database
- Verify courses are published
- Check minimum similarity threshold in config

### Issue: Poor recommendation quality
- Increase training data (more enrollments)
- Adjust feature weights in config
- Run evaluation to identify issues

### Issue: Slow performance
- Use batch endpoint for multiple students
- Increase MIN_SIMILARITY_THRESHOLD to reduce candidates
- Consider caching recommendations

## Future Enhancements

- [ ] Deep learning models (Neural Collaborative Filtering)
- [ ] Real-time streaming updates
- [ ] A/B testing framework
- [ ] Explainable recommendations
- [ ] Multi-armed bandit for exploration/exploitation
- [ ] Session-based recommendations
- [ ] Social recommendations (friends' courses)

## License

MIT License
