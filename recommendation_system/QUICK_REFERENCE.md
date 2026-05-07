# Quick Reference Card

## Installation

```bash
cd recommendation_system
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your database credentials
```

## Common Commands

### Train Model
```bash
python main.py train
```

### Test Recommendations
```bash
python main.py test --student-id 1 --top-n 10
```

### Find Similar Courses
```bash
python main.py similar --course-id 5 --top-n 5
```

### Evaluate Model
```bash
python main.py evaluate
```

### Refresh Model
```bash
python main.py refresh
```

### Start API Server
```bash
python api.py
```

### Run Tests
```bash
python test_system.py all
```

## API Endpoints

### Python API (Port 5000)

```bash
# Get recommendations
curl http://localhost:5000/recommend/1?top_n=10

# Get similar courses
curl http://localhost:5000/similar-courses/5?top_n=5

# Refresh system
curl -X POST http://localhost:5000/refresh

# Health check
curl http://localhost:5000/health

# Get stats
curl http://localhost:5000/stats
```

### Java API (Port 8080)

```bash
# Get recommendations
curl http://localhost:8080/api/recommendations/student/1?topN=10

# Get similar courses
curl http://localhost:8080/api/recommendations/similar/5?topN=5

# Refresh system
curl -X POST http://localhost:8080/api/recommendations/refresh

# Health check
curl http://localhost:8080/api/recommendations/health
```

## Frontend Integration

```javascript
// Get recommendations
const recommendations = await axios.get(
  `/api/recommendations/student/${studentId}?topN=10`
);

// Get similar courses
const similar = await axios.get(
  `/api/recommendations/similar/${courseId}?topN=5`
);
```

## Configuration

### Feature Weights (config.py)
```python
WEIGHT_PROGRESS = 0.25      # Performance
WEIGHT_PREFERENCES = 0.35   # Interests
WEIGHT_DIFFICULTY = 0.20    # Level matching
WEIGHT_CATEGORY = 0.20      # Category matching
```

### Recommendation Parameters
```python
TOP_N_RECOMMENDATIONS = 10
MIN_SIMILARITY_THRESHOLD = 0.1
```

## Docker

```bash
# Build and run
docker-compose up -d

# View logs
docker-compose logs -f recommendation-api

# Stop
docker-compose down
```

## Troubleshooting

### No recommendations returned
```bash
# Check if model is loaded
curl http://localhost:5000/health

# Retrain model
python main.py train
```

### Slow performance
```python
# In config.py, increase threshold
MIN_SIMILARITY_THRESHOLD = 0.2
```

### API not responding
```bash
# Check if running
curl http://localhost:5000/health

# Restart
python api.py
```

## File Structure

```
recommendation_system/
├── config.py              # Configuration
├── data_loader.py         # Database access
├── preprocessor.py        # Data preprocessing
├── feature_engineer.py    # Feature creation
├── recommendation_engine.py  # Core logic
├── evaluator.py           # Evaluation
├── api.py                 # Flask API
├── main.py                # CLI
├── test_system.py         # Tests
├── requirements.txt       # Dependencies
├── models/                # Saved models
└── logs/                  # Log files
```

## Key Metrics

- **Precision@10**: Relevant courses in top 10
- **Recall@10**: Coverage of relevant courses
- **Hit Rate**: At least one relevant course
- **Coverage**: % of catalog recommended
- **Diversity**: Category distribution (Gini)

## When to Refresh

✅ **Always refresh on**:
- New course published
- Course archived

⚠️ **Batch or schedule**:
- Student enrollment
- Lesson completion

⏰ **Scheduled**:
- Daily at 2 AM (recommended)

## Performance Targets

- Response time: <100ms per student
- Training time: <5 minutes for 10K students
- Precision@10: >0.3
- Coverage: >0.5
- Diversity (Gini): <0.5

## Support Files

- **README.md**: Full documentation
- **USAGE_GUIDE.md**: Integration guide
- **SYSTEM_OVERVIEW.md**: Technical details
- **QUICK_REFERENCE.md**: This file
