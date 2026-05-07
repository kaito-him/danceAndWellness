# Course Recommendation System - Technical Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Dance & Wellness Platform                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐         ┌──────────────┐                      │
│  │   Frontend   │────────▶│   Backend    │                      │
│  │   (React)    │         │  (Spring)    │                      │
│  └──────────────┘         └──────┬───────┘                      │
│                                   │                               │
│                                   │ REST API                      │
│                                   ▼                               │
│                          ┌─────────────────┐                     │
│                          │  Recommendation │                     │
│                          │     Service     │                     │
│                          │    (Java)       │                     │
│                          └────────┬────────┘                     │
│                                   │                               │
│                                   │ HTTP                          │
│                                   ▼                               │
│                          ┌─────────────────┐                     │
│                          │   Python API    │                     │
│                          │    (Flask)      │                     │
│                          └────────┬────────┘                     │
│                                   │                               │
│                    ┌──────────────┼──────────────┐              │
│                    ▼              ▼              ▼               │
│            ┌──────────┐   ┌──────────┐   ┌──────────┐          │
│            │   Data   │   │  Feature │   │   Model  │          │
│            │  Loader  │   │ Engineer │   │  Engine  │          │
│            └────┬─────┘   └──────────┘   └──────────┘          │
│                 │                                                 │
│                 ▼                                                 │
│         ┌──────────────┐                                         │
│         │  PostgreSQL  │                                         │
│         │   Database   │                                         │
│         └──────────────┘                                         │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Training Phase

```
Database → Data Loader → Preprocessor → Feature Engineer → Model Training → Save Model
```

1. **Data Loader** extracts:
   - Student profiles (preferences, level)
   - Course catalog (category, level, price)
   - Enrollments (progress, completion)
   - Lesson progress (completion rate)

2. **Preprocessor** handles:
   - Missing value imputation
   - Categorical encoding (level, category)
   - Feature normalization
   - Performance metric calculation

3. **Feature Engineer** creates:
   - Student feature vectors (performance + preferences)
   - Course feature vectors (attributes + popularity)
   - Combined representations

4. **Model Training**:
   - KNN model for collaborative filtering
   - Cosine similarity for content-based filtering
   - Hybrid score combination

### 2. Recommendation Phase

```
Student ID → Load Model → Calculate Similarities → Filter & Rank → Return Top-N
```

1. **Load student profile** from feature matrix
2. **Calculate content similarity** with all courses
3. **Calculate collaborative scores** from similar students
4. **Combine scores** (70% content + 30% collaborative)
5. **Filter** enrolled courses
6. **Rank** by combined score
7. **Return** top N recommendations

### 3. Refresh Phase

```
Trigger Event → Reload Data → Retrain Model → Update Cache → Notify Complete
```

Triggered by:
- New course published
- Course archived
- Student enrollment/unenrollment
- Lesson completion
- Scheduled refresh

## Feature Engineering Details

### Student Feature Vector (Dimensions: ~30-50)

**Performance Features (25% weight)**:
- `avg_progress`: Average progress across all enrollments (0-1)
- `max_progress`: Highest progress achieved (0-1)
- `lesson_completion_rate`: Ratio of completed lessons (0-1)
- `engagement_score`: Time spent / total duration (0-1)
- `completion_ratio`: Completed courses / total enrollments (0-1)

**Preference Features (35% weight)**:
- `preferred_level_encoded`: Difficulty preference (0-1)
- `preferred_category_vector`: One-hot encoded categories (weighted 1.0, 0.7, 0.4)
- `total_enrollments_normalized`: Engagement indicator (0-1)

**Example**:
```python
[
  0.75,  # avg_progress
  0.90,  # max_progress
  0.80,  # lesson_completion_rate
  0.65,  # engagement_score
  0.60,  # completion_ratio
  0.67,  # preferred_level (INTERMEDIATE = 2/3)
  1.0, 0.0, 0.7, 0.0, 0.4, 0.0,  # category preferences
  0.50   # total_enrollments_normalized
]
```

### Course Feature Vector (Dimensions: ~20-30)

**Difficulty Features (20% weight)**:
- `level_encoded`: Course difficulty (0-1)
- `difficulty_score`: Inverse of avg progress (0-1)

**Category Features (20% weight)**:
- `category_vector`: One-hot encoded category

**Quality Features (35% weight)**:
- `popularity_score`: Enrollment-based popularity (0-1)
- `lesson_count_normalized`: Content richness (0-1)

**Price Feature (5% weight)**:
- `is_free`: Binary indicator

**Example**:
```python
[
  0.67,  # level_encoded (INTERMEDIATE)
  0.45,  # difficulty_score
  0.0, 1.0, 0.0, 0.0, 0.0,  # category (BALLET)
  0.82,  # popularity_score
  0.75,  # lesson_count_normalized
  0.0    # is_free (paid course)
]
```

## Algorithms

### 1. Content-Based Filtering (Cosine Similarity)

```python
similarity = cosine_similarity(student_vector, course_vector)
```

**Advantages**:
- Works for new courses (no cold start)
- Personalized to student preferences
- Explainable recommendations

**Formula**:
```
similarity(A, B) = (A · B) / (||A|| × ||B||)
```

### 2. Collaborative Filtering (KNN)

```python
# Find 5 most similar students
neighbors = knn_model.kneighbors(student_vector)

# Aggregate their course preferences
for neighbor in neighbors:
    courses = get_enrolled_courses(neighbor)
    scores[courses] += similarity_weight * progress_weight
```

**Advantages**:
- Discovers unexpected patterns
- Leverages wisdom of the crowd
- Improves with more data

### 3. Hybrid Approach

```python
final_score = (0.7 * content_score) + (0.3 * collaborative_score)
```

**Advantages**:
- Combines strengths of both approaches
- Balances personalization and discovery
- Robust to data sparsity

## Evaluation Metrics

### Accuracy Metrics

**Precision@K**:
```
Precision@K = (Relevant courses in top K) / K
```
Measures: How many recommended courses are actually relevant?

**Recall@K**:
```
Recall@K = (Relevant courses in top K) / (Total relevant courses)
```
Measures: How many relevant courses did we find?

**Hit Rate@K**:
```
Hit Rate@K = 1 if any course in top K is relevant, else 0
```
Measures: Did we recommend at least one relevant course?

### Diversity Metrics

**Coverage**:
```
Coverage = (Unique courses recommended) / (Total courses)
```
Measures: What percentage of catalog gets recommended?

**Gini Coefficient**:
```
Gini = (2 * Σ(i * x_i)) / (n * Σx_i) - (n+1)/n
```
Measures: How evenly distributed are recommendations across categories?
- 0 = perfect equality (good diversity)
- 1 = perfect inequality (poor diversity)

### Cold Start Performance

Evaluates recommendations for new students with ≤2 enrollments.

**Metrics**:
- Recommendation generation rate
- Average recommendation score
- Reliance on popular courses

## Configuration Parameters

### Feature Weights (config.py)

```python
WEIGHT_PROGRESS = 0.25      # Academic performance importance
WEIGHT_PREFERENCES = 0.35   # Student interests importance
WEIGHT_DIFFICULTY = 0.20    # Difficulty matching importance
WEIGHT_CATEGORY = 0.20      # Category matching importance
```

**Tuning Guidelines**:
- Increase `WEIGHT_PROGRESS` if student performance is reliable
- Increase `WEIGHT_PREFERENCES` for preference-driven recommendations
- Increase `WEIGHT_DIFFICULTY` to match student skill level closely
- Increase `WEIGHT_CATEGORY` for category-focused recommendations

### Recommendation Parameters

```python
TOP_N_RECOMMENDATIONS = 10           # Number of recommendations to return
MIN_SIMILARITY_THRESHOLD = 0.1       # Minimum score to recommend
```

### Hybrid Weights

```python
CONTENT_WEIGHT = 0.7        # Content-based filtering weight
COLLABORATIVE_WEIGHT = 0.3  # Collaborative filtering weight
```

## Performance Characteristics

### Time Complexity

**Training**:
- Data loading: O(n) where n = total records
- Feature engineering: O(s + c) where s = students, c = courses
- KNN training: O(s²) for similarity matrix
- **Total**: O(s² + c)

**Recommendation**:
- Content similarity: O(c) for one student
- Collaborative filtering: O(k × c) where k = neighbors
- **Total**: O(c) per student

### Space Complexity

- Student matrix: O(s × f) where f = feature dimensions
- Course matrix: O(c × f)
- KNN model: O(s²) for distance matrix
- **Total**: O(s² + (s+c)×f)

### Scalability

**Current capacity** (single instance):
- Students: 10,000+
- Courses: 1,000+
- Recommendations: <100ms per student

**Scaling strategies**:
1. Horizontal scaling: Multiple API instances
2. Caching: Redis for frequent requests
3. Batch processing: Pre-compute for all students
4. Approximate methods: LSH for large datasets

## Integration Points

### 1. Database Schema Requirements

**Required tables**:
- `student`: user_id, preferred_category1-3, preferred_level
- `course`: course_id, title, category_id, level, price, is_free, status
- `enrollment`: student_id, course_id, progress
- `lesson`: lesson_id, course_id, duration
- `lesson_progress`: student_id, lesson_id, completed, last_position
- `category`: id, name

### 2. API Endpoints

**Python API** (Flask):
- `GET /recommend/<student_id>`: Get recommendations
- `GET /similar-courses/<course_id>`: Get similar courses
- `POST /refresh`: Trigger model refresh
- `GET /health`: Health check
- `GET /stats`: System statistics

**Java API** (Spring Boot):
- `GET /api/recommendations/student/{id}`: Get recommendations
- `GET /api/recommendations/similar/{id}`: Get similar courses
- `POST /api/recommendations/refresh`: Trigger refresh
- `GET /api/recommendations/health`: Health check

### 3. Event Triggers

Refresh recommendations on:
- `CoursePublishedEvent`
- `CourseArchivedEvent`
- `EnrollmentEvent`
- `UnenrollmentEvent`
- `LessonCompletedEvent`
- Scheduled (daily at 2 AM)

## Deployment Options

### Option 1: Standalone Python Service

```bash
python api.py
```

**Pros**: Simple, independent
**Cons**: Manual management

### Option 2: Docker Container

```bash
docker-compose up -d
```

**Pros**: Isolated, reproducible
**Cons**: Requires Docker

### Option 3: Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: recommendation-api
spec:
  replicas: 3
  ...
```

**Pros**: Scalable, resilient
**Cons**: Complex setup

## Monitoring & Maintenance

### Health Checks

```bash
# Python API
curl http://localhost:5000/health

# Java API
curl http://localhost:8080/api/recommendations/health
```

### Performance Monitoring

Track:
- Response time (target: <100ms)
- Recommendation quality (precision, recall)
- Coverage (% of catalog recommended)
- Diversity (Gini coefficient)
- Cold start performance

### Maintenance Tasks

**Daily**:
- Check API health
- Monitor error logs

**Weekly**:
- Review recommendation quality metrics
- Check for data anomalies

**Monthly**:
- Evaluate model performance
- Tune hyperparameters if needed
- Review and update feature weights

**Quarterly**:
- Full model retraining
- A/B test new algorithms
- Update documentation

## Future Enhancements

### Short-term (1-3 months)
- [ ] Add explanation generation
- [ ] Implement A/B testing framework
- [ ] Add Redis caching layer
- [ ] Create admin dashboard

### Medium-term (3-6 months)
- [ ] Deep learning models (Neural CF)
- [ ] Real-time streaming updates
- [ ] Multi-objective optimization
- [ ] Social recommendations

### Long-term (6-12 months)
- [ ] Reinforcement learning (MAB)
- [ ] Context-aware recommendations
- [ ] Cross-platform recommendations
- [ ] Federated learning for privacy

## References

- **Cosine Similarity**: Salton & McGill (1983)
- **Collaborative Filtering**: Goldberg et al. (1992)
- **Hybrid Recommenders**: Burke (2002)
- **Evaluation Metrics**: Herlocker et al. (2004)
- **Cold Start Problem**: Schein et al. (2002)

## Support

For issues or questions:
1. Check the README.md
2. Review USAGE_GUIDE.md
3. Run test_system.py
4. Check logs in logs/
5. Contact the ML team
