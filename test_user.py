from user_model import User
from datetime import datetime

# יצירת יוזר לדוגמה
user = User(user_id=1, name="Test Student", status="student")

# הגדרת פרמטרים
user.parametersForTimeTables_set({
    "arrival_mean_hour": 8,
    "arrival_stddev": 1,
    "departure_mean_hour": 16,
    "departure_stddev": 1,
    "days_of_week": [0, 1, 2, 3, 4],  # ראשון עד חמישי
    "cancellation_prob": 0.05
})

# יצירת לו"ז שבועי ושנתי
user.generalWeekTimeTable_make()
user.realTimeTable_make()

# בדיקה בזמן נוכחי
now = datetime.now()
status = user.status_get(now)
grade = user.grade_get(now)

print("🟢 סטטוס נוכחי:", status)
print("📊 ציון אמינות:", grade)

# דוגמה לבדיקה האם ההזמנה פעילה ברגע מסוים
fake_res_time = now.replace(hour=9, minute=0)
reservation_status = user.statusOfReservation_get(fake_res_time)
print("📅 האם הזמנה פעילה כרגע?", reservation_status)
