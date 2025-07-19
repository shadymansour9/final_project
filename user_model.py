import random
from datetime import datetime, timedelta

class User:
    def __init__(self, user_id, name, status='student'):
        self.user_id = user_id
        self.name = name
        self.status = status  # student / lecturer / administrator / guest
        self.parametersForTimeTables = {}
        self.generalWeekTimeTable = {}  # {day_of_week: (arrival_hour, departure_hour)}
        self.realTimeTable = {}         # {date: (arrival_datetime, departure_datetime)}
        self.reservation_statuses = []  # סטטוסים של ההזמנות בפועל (לציון)

    # הגדרת פרמטרים לדפוסי הגעה
    def parametersForTimeTables_set(self, params):
        self.parametersForTimeTables = params

    # בניית לוח שבועי כללי
    def generalWeekTimeTable_make(self):
        days_of_week = self.parametersForTimeTables.get('days_of_week', list(range(7)))
        arrival_mean = self.parametersForTimeTables.get('arrival_mean_hour', 8)
        arrival_stddev = self.parametersForTimeTables.get('arrival_stddev', 1)
        departure_mean = self.parametersForTimeTables.get('departure_mean_hour', 17)
        departure_stddev = self.parametersForTimeTables.get('departure_stddev', 1)

        for day in days_of_week:
            arrival_hour = int(random.gauss(arrival_mean, arrival_stddev))
            departure_hour = int(random.gauss(departure_mean, departure_stddev))
            arrival_hour = max(6, min(arrival_hour, 18))
            departure_hour = max(arrival_hour + 1, min(departure_hour, 22))
            self.generalWeekTimeTable[day] = (arrival_hour, departure_hour)

    # יצירת לוח אמיתי יומיומי
    def realTimeTable_make(self):
        today = datetime.today()
        for i in range(365):
            date = today + timedelta(days=i)
            day_of_week = date.weekday()

            if day_of_week in self.generalWeekTimeTable:
                arrival_hour, departure_hour = self.generalWeekTimeTable[day_of_week]
                arrival = datetime(date.year, date.month, date.day, arrival_hour) + timedelta(minutes=random.randint(-15, 15))
                departure = datetime(date.year, date.month, date.day, departure_hour) + timedelta(minutes=random.randint(-15, 15))

                if random.random() < self.parametersForTimeTables.get('cancellation_prob', 0.05):
                    self.reservation_statuses.append("cancelled")
                    continue

                # סימולציה של illegal_cancelled
                if random.random() < self.parametersForTimeTables.get('no_show_prob', 0.03):
                    self.reservation_statuses.append("illegal_cancelled")
                    continue

                self.realTimeTable[date.date()] = (arrival, departure)
                self.reservation_statuses.append("arrived")

    # החזרת סטטוס בזמן מסוים
    def status_get(self, t: datetime):
        today = t.date()
        if today not in self.realTimeTable:
            return 'not arrived'
        arrival, departure = self.realTimeTable[today]
        if arrival <= t <= departure:
            return 'arrived'
        else:
            return 'departed'

    # בדיקת האם המשתמש נוכח בזמן של הזמנה
    def statusOfReservation_get(self, reservation_time: datetime):
        today = reservation_time.date()
        if today in self.realTimeTable:
            arrival, departure = self.realTimeTable[today]
            return arrival <= reservation_time <= departure
        return False

    # חישוב ציון לפי היסטוריית ההזמנות
    def compute_grade_and_status(self):
        if not self.reservation_statuses:
            return 60.0, "active"

        total = len(self.reservation_statuses)
        score = 0

        for status in self.reservation_statuses:
            if status == 'arrived':
                score += 10
            elif status == 'cancelled':
                score += 0
            elif status == 'illegal_cancelled':
                score -= 20

        max_score = total * 10
        grade = (score / max_score) * 100
        grade = max(0.0, min(100.0, grade))

        user_status = 'blocked' if grade < 30 else 'active'
        return round(grade, 1), user_status
