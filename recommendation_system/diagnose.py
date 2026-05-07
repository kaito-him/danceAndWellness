from data_loader import DataLoader
from collections import Counter

dl = DataLoader()

students = list(dl.db['students'].find({}, {'_id': 1, 'userId': 1}))
print("=== STUDENTS ===")
for s in students:
    print(f"  _id={s['_id']}  userId={s.get('userId', 'N/A')}")

print()
profiles = list(dl.db['user_profiles'].find({}, {'studentId': 1, 'preferences': 1, 'skillLevel': 1}))
print(f"=== USER_PROFILES ({len(profiles)}) ===")
for p in profiles:
    print(f"  studentId={p.get('studentId')}  prefs={p.get('preferences')}  level={p.get('skillLevel')}")

print()
enrollments = list(dl.db['enrollments'].find({}, {'studentId': 1, 'courseId': 1}))
print(f"=== ENROLLMENTS ({len(enrollments)}) ===")
counts = Counter(str(e.get('studentId')) for e in enrollments)
for uid, cnt in counts.items():
    print(f"  studentId(userId)={uid}  count={cnt}")

dl.close()
