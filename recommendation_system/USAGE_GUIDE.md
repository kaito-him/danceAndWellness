# Course Recommendation System - Usage Guide

## Quick Start

### 1. Setup

```bash
# Navigate to recommendation system directory
cd recommendation_system

# Install dependencies
pip install -r requirements.txt

# Configure database
cp .env.example .env
# Edit .env with your database credentials
```

### 2. Train Initial Model

```bash
python main.py train
```

This will:
- Connect to your database
- Load student, course, and enrollment data
- Preprocess and engineer features
- Train the recommendation model
- Save the model to `models/` directory

### 3. Test Recommendations

```bash
# Test for a specific student
python main.py test --student-id 1 --top-n 10

# Find similar courses
python main.py similar --course-id 5 --top-n 5

# Evaluate model performance
python main.py evaluate
```

### 4. Start API Server

```bash
python api.py
```

The API will be available at `http://localhost:5000`

## Integration with Your Application

### Frontend Integration (React)

Add this service to your frontend:

```javascript
// src/services/recommendationService.js
import axios from 'axios';

const RECOMMENDATION_API = 'http://localhost:8080/api/recommendations';

export const getRecommendations = async (studentId, topN = 10) => {
  try {
    const response = await axios.get(
      `${RECOMMENDATION_API}/student/${studentId}?topN=${topN}`,
      {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      }
    );
    return response.data;
  } catch (error) {
    console.error('Error fetching recommendations:', error);
    return [];
  }
};

export const getSimilarCourses = async (courseId, topN = 5) => {
  try {
    const response = await axios.get(
      `${RECOMMENDATION_API}/similar/${courseId}?topN=${topN}`
    );
    return response.data;
  } catch (error) {
    console.error('Error fetching similar courses:', error);
    return [];
  }
};
```

### Use in Student Dashboard

```javascript
// In StudentDashboard.jsx
import { getRecommendations } from '../services/recommendationService';

const RecommendedCourses = () => {
  const [recommendations, setRecommendations] = useState([]);
  const [loading, setLoading] = useState(true);
  const studentId = user?.userId;

  useEffect(() => {
    const fetchRecommendations = async () => {
      if (studentId) {
        setLoading(true);
        const recs = await getRecommendations(studentId, 6);
        setRecommendations(recs);
        setLoading(false);
      }
    };

    fetchRecommendations();
  }, [studentId]);

  if (loading) return <div>Loading recommendations...</div>;

  return (
    <div className="recommended-courses">
      <h2>Recommended for You</h2>
      <div className="course-grid">
        {recommendations.map(rec => (
          <CourseCard 
            key={rec.courseId}
            course={rec}
            badge="Recommended"
            score={rec.recommendationScore}
          />
        ))}
      </div>
    </div>
  );
};
```

### Backend Integration (Spring Boot)

The Java integration is already created. Add to your existing services:

```java
// In CourseService.java
@Autowired
private RecommendationService recommendationService;

public void publishCourse(Long courseId) {
    // ... existing publish logic ...
    
    // Trigger recommendation refresh
    recommendationService.refreshRecommendations();
}

// In EnrollmentService.java
public void enrollStudent(Long studentId, Long courseId) {
    // ... existing enrollment logic ...
    
    // Trigger recommendation refresh
    recommendationService.refreshRecommendations();
}
```

## When to Refresh Recommendations

The system should be refreshed when data changes:

### 1. Course Events
```java
@EventListener
public void onCoursePublished(CoursePublishedEvent event) {
    recommendationService.refreshRecommendations();
}

@EventListener
public void onCourseArchived(CourseArchivedEvent event) {
    recommendationService.refreshRecommendations();
}
```

### 2. Enrollment Events
```java
@EventListener
public void onStudentEnrolled(EnrollmentEvent event) {
    recommendationService.refreshRecommendations();
}

@EventListener
public void onStudentUnenrolled(UnenrollmentEvent event) {
    recommendationService.refreshRecommendations();
}
```

### 3. Progress Events
```java
@EventListener
public void onLessonCompleted(LessonCompletedEvent event) {
    // Refresh less frequently for lesson completions
    // Consider batching or scheduling
    recommendationService.refreshRecommendations();
}
```

### 4. Scheduled Refresh
```java
@Scheduled(cron = "0 0 2 * * ?") // Every day at 2 AM
public void scheduledRefresh() {
    log.info("Running scheduled recommendation refresh");
    recommendationService.refreshRecommendations();
}
```

## API Endpoints

### Get Recommendations
```bash
GET /api/recommendations/student/{studentId}?topN=10
```

Response:
```json
[
  {
    "courseId": 5,
    "title": "Advanced Ballet Techniques",
    "category": "BALLET",
    "level": "ADVANCED",
    "price": 49.99,
    "isFree": false,
    "recommendationScore": 0.8542,
    "popularityScore": 0.7234,
    "lessonCount": 15
  }
]
```

### Get Similar Courses
```bash
GET /api/recommendations/similar/{courseId}?topN=5
```

### Refresh System
```bash
POST /api/recommendations/refresh
```

### Health Check
```bash
GET /api/recommendations/health
```

### Get Statistics
```bash
GET /api/recommendations/stats
```

## Performance Optimization

### 1. Caching Recommendations

Cache recommendations for a short period:

```java
@Cacheable(value = "recommendations", key = "#studentId")
public List<CourseRecommendation> getRecommendations(Long studentId, Integer topN) {
    // ... existing code ...
}

@CacheEvict(value = "recommendations", allEntries = true)
public void refreshRecommendations() {
    // ... existing code ...
}
```

### 2. Async Refresh

The refresh is already async. For heavy load, consider:

```java
@Async
@Scheduled(fixedDelay = 3600000) // Every hour
public void periodicRefresh() {
    if (shouldRefresh()) {
        recommendationService.refreshRecommendations();
    }
}

private boolean shouldRefresh() {
    // Check if significant changes occurred
    return hasNewCourses() || hasSignificantEnrollments();
}
```

### 3. Batch Processing

For multiple students:

```java
List<Long> studentIds = Arrays.asList(1L, 2L, 3L, 4L, 5L);
Map<Long, List<CourseRecommendation>> batchRecs = 
    recommendationService.getBatchRecommendations(studentIds, 10);
```

## Monitoring

### Check System Health

```bash
curl http://localhost:8080/api/recommendations/health
```

### View Statistics

```bash
curl http://localhost:8080/api/recommendations/stats
```

### Evaluate Performance

```bash
python main.py evaluate
```

This generates a report with:
- Precision@K, Recall@K, Hit Rate
- Coverage and diversity metrics
- Cold start performance

## Troubleshooting

### Issue: No recommendations returned

**Possible causes:**
1. Student not found in database
2. No published courses available
3. All courses already enrolled

**Solution:**
```bash
# Check if student exists
python -c "from data_loader import DataLoader; dl = DataLoader(); print(dl.load_student_data())"

# Check available courses
python -c "from data_loader import DataLoader; dl = DataLoader(); print(len(dl.load_course_data()))"
```

### Issue: Low recommendation scores

**Possible causes:**
1. Insufficient training data
2. Poor feature matching
3. Need to adjust weights

**Solution:**
Edit `config.py`:
```python
# Adjust feature weights
WEIGHT_PROGRESS = 0.20      # Decrease if progress is unreliable
WEIGHT_PREFERENCES = 0.40   # Increase for preference-based
WEIGHT_DIFFICULTY = 0.20
WEIGHT_CATEGORY = 0.20
```

### Issue: Slow performance

**Possible causes:**
1. Large dataset
2. Frequent refreshes
3. No caching

**Solution:**
1. Increase similarity threshold:
```python
MIN_SIMILARITY_THRESHOLD = 0.2  # Higher = fewer candidates
```

2. Implement caching in Java backend
3. Schedule refreshes instead of real-time

### Issue: Python API not responding

**Check:**
```bash
# Test Python API directly
curl http://localhost:5000/health

# Check logs
tail -f logs/api.log

# Restart API
python api.py
```

## Advanced Usage

### Custom Feature Weights

Adjust weights based on your use case:

```python
# In config.py

# For performance-focused recommendations
WEIGHT_PROGRESS = 0.40
WEIGHT_PREFERENCES = 0.25
WEIGHT_DIFFICULTY = 0.20
WEIGHT_CATEGORY = 0.15

# For preference-focused recommendations
WEIGHT_PROGRESS = 0.15
WEIGHT_PREFERENCES = 0.50
WEIGHT_DIFFICULTY = 0.15
WEIGHT_CATEGORY = 0.20
```

### A/B Testing

Test different recommendation strategies:

```java
public List<CourseRecommendation> getRecommendationsWithStrategy(
        Long studentId, String strategy) {
    
    if ("performance".equals(strategy)) {
        // Use performance-weighted recommendations
        return getRecommendations(studentId, 10);
    } else if ("popular".equals(strategy)) {
        // Use popularity-based recommendations
        return getPopularCourses(10);
    } else {
        // Default hybrid approach
        return getRecommendations(studentId, 10);
    }
}
```

### Explainable Recommendations

Add explanations for why courses are recommended:

```python
def explain_recommendation(student_id, course_id):
    """Generate explanation for a recommendation"""
    student = students_df[students_df['student_id'] == student_id].iloc[0]
    course = courses_df[courses_df['course_id'] == course_id].iloc[0]
    
    reasons = []
    
    # Check category match
    if course['category_name'] in [student['preferred_category1'], 
                                    student['preferred_category2'],
                                    student['preferred_category3']]:
        reasons.append(f"Matches your interest in {course['category_name']}")
    
    # Check level match
    if course['level'] == student['preferred_level']:
        reasons.append(f"Matches your preferred difficulty level")
    
    # Check popularity
    if course['popularity_score'] > 0.7:
        reasons.append("Highly popular among students")
    
    return reasons
```

## Production Deployment

### Using Docker

```bash
# Build and run with Docker Compose
docker-compose up -d

# Check logs
docker-compose logs -f recommendation-api

# Stop
docker-compose down
```

### Environment Variables

Set in production:
```bash
export DB_HOST=your-db-host
export DB_NAME=your-db-name
export DB_USER=your-db-user
export DB_PASSWORD=your-db-password
export API_PORT=5000
```

### Scaling

For high traffic:
1. Run multiple API instances behind a load balancer
2. Use Redis for caching
3. Schedule batch refreshes during off-peak hours
4. Consider using a message queue for refresh triggers

## Best Practices

1. **Refresh Strategy**: Don't refresh on every single action. Batch updates or schedule periodic refreshes.

2. **Caching**: Cache recommendations for 1-6 hours depending on your update frequency.

3. **Monitoring**: Track recommendation click-through rates and enrollment conversions.

4. **Fallback**: Always have a fallback to popular courses if recommendations fail.

5. **Privacy**: Ensure student data is handled securely and in compliance with regulations.

6. **Testing**: Regularly evaluate recommendation quality using the evaluation metrics.

7. **Feedback Loop**: Collect user feedback on recommendations to improve the system.
