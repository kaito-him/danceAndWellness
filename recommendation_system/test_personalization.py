import requests

students = [
    ("YOGA+DANCE_FITNESS",   "69ea1a1248a9b18466a188ca"),
    ("BALLET+MEDITATION",    "69f9ed5dc8a77df96a5c1e76"),
    ("YOGA+INJURY_PREV",     "69fb565d5906b5caebbb79c6"),
    ("BALLET+YOGA",          "69fc539c5906b5caebbb7cc3"),
    ("no prefs",             "69e9539248a9b18466a1889a"),
]

for label, sid in students:
    r = requests.get(f"http://localhost:5000/recommend/{sid}?top_n=4")
    data = r.json()
    print(f"\n=== {label} (..{sid[-6:]}) ===")
    for rec in data.get("recommendations", []):
        title = rec["title"][:38]
        cat   = rec["category"]
        score = rec["recommendation_score"]
        print(f"  {title:38} | {cat:22} | {score:.3f}")
