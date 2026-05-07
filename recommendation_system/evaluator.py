"""
Evaluation module - measures recommendation quality
"""
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.metrics import precision_score, recall_score, f1_score, ndcg_score


class RecommendationEvaluator:
    """
    Evaluates recommendation system performance using various metrics
    """
    
    def __init__(self, recommendation_engine):
        self.engine = recommendation_engine
    
    def evaluate_recommendations(self, test_students=None, k=10):
        """
        Evaluate recommendation quality using multiple metrics
        
        Args:
            test_students: List of student IDs to test (None = all students)
            k: Number of recommendations to evaluate
            
        Returns:
            Dictionary with evaluation metrics
        """
        if test_students is None:
            test_students = self.engine.student_ids[:min(100, len(self.engine.student_ids))]
        
        metrics = {
            'precision_at_k': [],
            'recall_at_k': [],
            'hit_rate': [],
            'ndcg': [],
            'coverage': set()
        }
        
        for student_id in test_students:
            # Get recommendations
            recommendations = self.engine.recommend_courses(student_id, top_n=k)
            recommended_ids = [rec['course_id'] for rec in recommendations]
            
            # Get actual enrollments (ground truth)
            actual_enrollments = self.engine.data_loader.get_student_enrolled_courses(student_id)
            
            if not actual_enrollments:
                continue
            
            # Calculate metrics
            precision = self._calculate_precision_at_k(recommended_ids, actual_enrollments, k)
            recall = self._calculate_recall_at_k(recommended_ids, actual_enrollments, k)
            hit = self._calculate_hit_rate(recommended_ids, actual_enrollments)
            
            metrics['precision_at_k'].append(precision)
            metrics['recall_at_k'].append(recall)
            metrics['hit_rate'].append(hit)
            
            # Track coverage
            metrics['coverage'].update(recommended_ids)
        
        # Calculate average metrics
        results = {
            'precision@{}'.format(k): np.mean(metrics['precision_at_k']) if metrics['precision_at_k'] else 0,
            'recall@{}'.format(k): np.mean(metrics['recall_at_k']) if metrics['recall_at_k'] else 0,
            'hit_rate@{}'.format(k): np.mean(metrics['hit_rate']) if metrics['hit_rate'] else 0,
            'coverage': len(metrics['coverage']) / len(self.engine.course_ids) if self.engine.course_ids else 0,
            'num_students_evaluated': len(test_students)
        }
        
        return results
    
    def _calculate_precision_at_k(self, recommended, actual, k):
        """
        Precision@K: proportion of recommended items that are relevant
        """
        recommended_k = recommended[:k]
        relevant_recommended = len(set(recommended_k) & set(actual))
        return relevant_recommended / k if k > 0 else 0
    
    def _calculate_recall_at_k(self, recommended, actual, k):
        """
        Recall@K: proportion of relevant items that are recommended
        """
        recommended_k = recommended[:k]
        relevant_recommended = len(set(recommended_k) & set(actual))
        return relevant_recommended / len(actual) if actual else 0
    
    def _calculate_hit_rate(self, recommended, actual):
        """
        Hit Rate: whether at least one recommended item is relevant
        """
        return 1 if len(set(recommended) & set(actual)) > 0 else 0
    
    def evaluate_diversity(self, student_ids=None, k=10):
        """
        Evaluate diversity of recommendations across students
        
        Args:
            student_ids: List of student IDs to evaluate
            k: Number of recommendations per student
            
        Returns:
            Dictionary with diversity metrics
        """
        if student_ids is None:
            student_ids = self.engine.student_ids[:min(50, len(self.engine.student_ids))]
        
        all_recommendations = []
        category_distribution = {}
        level_distribution = {}
        
        for student_id in student_ids:
            recommendations = self.engine.recommend_courses(student_id, top_n=k)
            
            for rec in recommendations:
                all_recommendations.append(rec['course_id'])
                
                # Track category distribution
                category = rec['category']
                category_distribution[category] = category_distribution.get(category, 0) + 1
                
                # Track level distribution
                level = rec['level']
                level_distribution[level] = level_distribution.get(level, 0) + 1
        
        # Calculate diversity metrics
        unique_courses = len(set(all_recommendations))
        total_recommendations = len(all_recommendations)
        
        # Gini coefficient for category distribution
        category_gini = self._calculate_gini_coefficient(list(category_distribution.values()))
        
        return {
            'unique_courses_recommended': unique_courses,
            'total_recommendations': total_recommendations,
            'diversity_ratio': unique_courses / total_recommendations if total_recommendations > 0 else 0,
            'category_distribution': category_distribution,
            'level_distribution': level_distribution,
            'category_gini': category_gini,
            'num_categories_covered': len(category_distribution)
        }
    
    def _calculate_gini_coefficient(self, values):
        """
        Calculate Gini coefficient (0 = perfect equality, 1 = perfect inequality)
        Lower is better for diversity
        """
        if not values:
            return 0
        
        sorted_values = sorted(values)
        n = len(sorted_values)
        cumsum = np.cumsum(sorted_values)
        
        return (2 * np.sum((np.arange(1, n + 1)) * sorted_values)) / (n * cumsum[-1]) - (n + 1) / n
    
    def evaluate_cold_start(self, new_student_ids=None, k=10):
        """
        Evaluate performance for new students (cold start problem)
        
        Args:
            new_student_ids: List of new student IDs with few enrollments
            k: Number of recommendations
            
        Returns:
            Dictionary with cold start metrics
        """
        # Find students with 0-2 enrollments
        if new_student_ids is None:
            enrollment_counts = self.engine.enrollments_df.groupby('student_id').size()
            new_student_ids = enrollment_counts[enrollment_counts <= 2].index.tolist()
        
        if not new_student_ids:
            return {'message': 'No new students found for cold start evaluation'}
        
        cold_start_metrics = {
            'num_new_students': len(new_student_ids),
            'recommendations_generated': 0,
            'avg_recommendation_score': [],
            'popular_courses_ratio': []
        }
        
        for student_id in new_student_ids[:min(20, len(new_student_ids))]:
            recommendations = self.engine.recommend_courses(student_id, top_n=k)
            
            if recommendations:
                cold_start_metrics['recommendations_generated'] += 1
                
                # Average recommendation score
                avg_score = np.mean([rec['recommendation_score'] for rec in recommendations])
                cold_start_metrics['avg_recommendation_score'].append(avg_score)
                
                # Check if recommendations are just popular courses
                popular_ratio = np.mean([
                    rec['popularity_score'] > 0.5 for rec in recommendations
                ])
                cold_start_metrics['popular_courses_ratio'].append(popular_ratio)
        
        cold_start_metrics['avg_recommendation_score'] = np.mean(
            cold_start_metrics['avg_recommendation_score']
        ) if cold_start_metrics['avg_recommendation_score'] else 0
        
        cold_start_metrics['popular_courses_ratio'] = np.mean(
            cold_start_metrics['popular_courses_ratio']
        ) if cold_start_metrics['popular_courses_ratio'] else 0
        
        return cold_start_metrics
    
    def generate_evaluation_report(self, output_file='evaluation_report.txt'):
        """
        Generate a comprehensive evaluation report
        """
        print("Generating evaluation report...")
        
        # Run all evaluations
        accuracy_metrics = self.evaluate_recommendations(k=10)
        diversity_metrics = self.evaluate_diversity(k=10)
        cold_start_metrics = self.evaluate_cold_start(k=10)
        
        # Create report
        report = []
        report.append("=" * 60)
        report.append("COURSE RECOMMENDATION SYSTEM - EVALUATION REPORT")
        report.append("=" * 60)
        report.append("")
        
        report.append("1. ACCURACY METRICS")
        report.append("-" * 60)
        for metric, value in accuracy_metrics.items():
            report.append(f"  {metric}: {value:.4f}")
        report.append("")
        
        report.append("2. DIVERSITY METRICS")
        report.append("-" * 60)
        report.append(f"  Unique courses recommended: {diversity_metrics['unique_courses_recommended']}")
        report.append(f"  Diversity ratio: {diversity_metrics['diversity_ratio']:.4f}")
        report.append(f"  Category Gini coefficient: {diversity_metrics['category_gini']:.4f}")
        report.append(f"  Categories covered: {diversity_metrics['num_categories_covered']}")
        report.append("")
        report.append("  Category distribution:")
        for cat, count in diversity_metrics['category_distribution'].items():
            report.append(f"    {cat}: {count}")
        report.append("")
        
        report.append("3. COLD START PERFORMANCE")
        report.append("-" * 60)
        for metric, value in cold_start_metrics.items():
            if isinstance(value, float):
                report.append(f"  {metric}: {value:.4f}")
            else:
                report.append(f"  {metric}: {value}")
        report.append("")
        
        report.append("=" * 60)
        
        # Print and save report
        report_text = "\n".join(report)
        print(report_text)
        
        with open(output_file, 'w') as f:
            f.write(report_text)
        
        print(f"\nReport saved to {output_file}")
        
        return {
            'accuracy': accuracy_metrics,
            'diversity': diversity_metrics,
            'cold_start': cold_start_metrics
        }
