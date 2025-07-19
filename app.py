from flask import Flask, jsonify, request
from flask_cors import CORS
from user_model import User

import pg8000
import bcrypt
from user_model import User  # ודא שהקובץ user_model.py נמצא באותה תיקייה
from datetime import datetime, timedelta
app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "http://localhost:4997"}})

def get_db_connection():
    """יצירת חיבור למסד הנתונים"""
    try:
        conn = pg8000.connect(
            database="parking_db",
            user="postgres",
            password="S123",
            host="localhost",
            port=5432
        )
        return conn
    except Exception as e:
        print(f"Database connection error: {str(e)}")
        return None

def hash_password(password):
    """הצפנת סיסמה"""
    salt = bcrypt.gensalt()
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed_password.decode('utf-8')

def check_password(hashed_password, user_password):
    """בדיקת תקינות סיסמה מוצפנת"""
    try:
        return bcrypt.checkpw(user_password.encode('utf-8'), hashed_password.encode('utf-8'))
    except (ValueError, AttributeError):
        return False

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    if not data or "email" not in data or "password" not in data:
        return jsonify({"message": "Missing email or password", "status": "error"}), 400

    email = data["email"]
    password = data["password"]

    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed", "status": "error"}), 500

    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name, email, phone, role, password FROM users WHERE email = %s;", (email,))
            user = cur.fetchone()

            if user:
                user_id, name, email, phone, role, stored_password = user
                if check_password(stored_password, password):
                    return jsonify({
                        "message": "Login successful",
                        "status": "success",
                        "user_id": user_id,
                        "role": role,
                        "name": name,
                        "email": email,  # ✅ הוספת מייל
                        "phone": phone   # ✅ הוספת טלפון
                    }), 200
                else:
                    return jsonify({"message": "Invalid credentials", "status": "error"}), 401
            else:
                return jsonify({"message": "User not found", "status": "error"}), 404

    except Exception as e:
        return jsonify({"message": f"Database error: {str(e)}", "status": "error"}), 500

    finally:
        conn.close()
@app.route('/update_user_status', methods=['POST'])
def update_user_status():
    data = request.json
    user_id = data['user_id']
    new_status = data['status']

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            UPDATE users
            SET status = %s,
                force_status_override = true
            WHERE id = %s
        """, (new_status, user_id))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'message': 'User status updated successfully'}), 200
    except Exception as e:
        return jsonify({'message': f'Error: {str(e)}'}), 500

@app.route('/users', methods=['GET'])
def get_users():
    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed", "status": "error"}), 500

    try:
        cur = conn.cursor()
        cur.execute("SELECT id, name, email, status, force_status_override FROM users ORDER BY name ASC;")
        users = cur.fetchall()
        cur.close()
        conn.close()

        return jsonify({
            "status": "success",
            "users": [{
                "id": u[0],
                "name": u[1],
                "email": u[2],
                "status": u[3],
                "force_status_override": u[4]  # ✅ נוסף כאן!
            } for u in users]
        }), 200

    except Exception as e:
        return jsonify({"message": f"Database error: {str(e)}", "status": "error"}), 500


from datetime import datetime, timedelta
@app.route('/available_spots_range', methods=['POST'])
def get_available_spots_range():
    data = request.get_json()
    required_fields = ['start_time', 'end_time', 'user_id']
    if not all(field in data for field in required_fields):
        return jsonify({"message": "Missing fields", "status": "error"}), 400

    start_time = data['start_time']
    end_time = data['end_time']
    user_id = data['user_id']

    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed", "status": "error"}), 500

    try:
        cur = conn.cursor()

        # שליפת סטטוס המשתמש
        cur.execute("SELECT status FROM users WHERE id = %s;", (user_id,))
        user = cur.fetchone()
        if not user:
            return jsonify({"message": "User not found", "status": "error"}), 404

        user_status = user[0]

        # שליפת חניות לפי סטטוס המשתמש
        if user_status == 'blocked':
            # רק חניות רחוקות
            cur.execute("""
                SELECT ps.id, ps.lot_name, ps.spot_number, ps.distance_from_college, ps.distance_category
                FROM parking_spots ps
                WHERE ps.distance_category = 'רחוק'
                  AND ps.id NOT IN (
                      SELECT r.spot_id FROM reservations r
                      WHERE r.status = 'confirmed' AND
                            (%s, %s) OVERLAPS (r.start_time, r.end_time)
                  )
                ORDER BY ps.distance_from_college ASC;
            """, (start_time, end_time))
        else:
            # כל החניות
            cur.execute("""
                SELECT ps.id, ps.lot_name, ps.spot_number, ps.distance_from_college, ps.distance_category
                FROM parking_spots ps
                WHERE ps.id NOT IN (
                    SELECT r.spot_id FROM reservations r
                    WHERE r.status = 'confirmed' AND
                          (%s, %s) OVERLAPS (r.start_time, r.end_time)
                )
                ORDER BY ps.distance_from_college ASC;
            """, (start_time, end_time))

        spots = cur.fetchall()
        cur.close()
        conn.close()

        if not spots:
            return jsonify({"message": "אין חניות זמינות בטווח הזמן הזה", "status": "error"}), 404

        spots_list = [{
            "id": s[0],
            "lot_name": s[1],
            "spot_number": s[2],
            "distance_from_college": s[3],
            "distance_category": s[4]
        } for s in spots]

        return jsonify({"status": "success", "parking_spots": spots_list}), 200

    except Exception as e:
        return jsonify({"message": f"Database error: {str(e)}", "status": "error"}), 500

def auto_cancel_expired_reservations(conn):
    try:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE reservations
                SET status = 'illegal_cancelled'
                WHERE status = 'confirmed'
                  AND start_time + INTERVAL '10 minutes' < NOW();
            """)
            conn.commit()
    except Exception as e:
        print("Auto cancel error:", e)
        conn.rollback()





@app.route('/add_reservation', methods=['POST'])
def add_reservation():
    data = request.get_json()

    required_fields = ["user_id", "spot_id", "start_time", "end_time"]
    for field in required_fields:
        if field not in data or not data[field]:
            return jsonify({"message": f"Missing or empty field: {field}", "status": "error"}), 400

    user_id = data["user_id"]
    spot_id = data["spot_id"]
    start_time = datetime.fromisoformat(data["start_time"])
    end_time = datetime.fromisoformat(data["end_time"])
    # ✅ בדיקה: לא ניתן להזמין לשעה שכבר עברה
    if start_time < datetime.now():
        return jsonify({"message": "❌ לא ניתן להזמין לשעה שכבר עברה", "status": "error"}), 400

    # חישוב גבולות השבוע (ראשון עד שבת)
    today = datetime.today()
    start_of_week = today - timedelta(days=today.weekday() + 1 if today.weekday() != 6 else 0)
    start_of_week = start_of_week.replace(hour=0, minute=0, second=0, microsecond=0)
    end_of_week = start_of_week + timedelta(days=6, hours=23, minutes=59, seconds=59)

    if not (start_of_week <= start_time <= end_of_week):
        return jsonify({"message": "ניתן להזמין רק לשבוע הנוכחי (ראשון עד שבת)", "status": "error"}), 400

    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed", "status": "error"}), 500

    try:
        with conn.cursor() as cur:
            # 🔒 שלב 1: בדוק את סטטוס המשתמש
            cur.execute("SELECT status FROM users WHERE id = %s;", (user_id,))
            user = cur.fetchone()
            if not user:
                return jsonify({"message": "User not found", "status": "error"}), 404
            user_status = user[0]

            # 🔒 שלב 2: נעל את שורת החניה כדי למנוע התנגשויות
            cur.execute("""
                SELECT distance_category FROM parking_spots 
                WHERE id = %s 
                FOR UPDATE;
            """, (spot_id,))
            spot = cur.fetchone()
            if not spot:
                return jsonify({"message": "Parking spot not found", "status": "error"}), 404
            distance_category = spot[0]

            # 🔒 שלב 3: בדיקת חסימה מול קטגוריית מרחק
            if user_status == 'blocked' and distance_category != 'רחוק':
                return jsonify({
                    "message": "משתמש חסום יכול להזמין רק חניה רחוקה",
                    "status": "error"
                }), 403

            # 🔒 שלב 4: בדיקת חפיפה עם הזמנה קיימת לאותה חניה
            cur.execute("""
                SELECT id FROM reservations 
                WHERE spot_id = %s 
                  AND ((start_time, end_time) OVERLAPS (%s, %s))
            """, (spot_id, start_time, end_time))
            if cur.fetchone():
                return jsonify({"message": "המקום כבר שמור לשעה זו", "status": "error"}), 409

            # 🔒 שלב 5: בדיקת חפיפה עם הזמנה אחרת של אותו משתמש באותו זמן
            cur.execute("""
                SELECT id FROM reservations 
                WHERE user_id = %s 
                  AND ((start_time, end_time) OVERLAPS (%s, %s))
                  AND status = 'confirmed';
            """, (user_id, start_time, end_time))
            if cur.fetchone():
                return jsonify({"message": "כבר יש לך הזמנה בשעות האלו", "status": "error"}), 409

            # ✅ שלב 6: הכנסת ההזמנה
            cur.execute("""
                INSERT INTO reservations (user_id, spot_id, start_time, end_time, status) 
                VALUES (%s, %s, %s, %s, 'confirmed') RETURNING id;
            """, (user_id, spot_id, start_time, end_time))
            reservation_id = cur.fetchone()[0]
            conn.commit()
            return jsonify({"message": "ההזמנה נוספה", "status": "success", "reservation_id": reservation_id}), 201

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Database error: {str(e)}", "status": "error"}), 500

    finally:
        conn.close()


@app.route('/update_profile', methods=['POST'])
def update_profile():
    data = request.get_json()

    if "user_id" not in data or "name" not in data or "email" not in data or "phone" not in data:
        return jsonify({"message": "Missing fields", "status": "error"}), 400

    user_id = data["user_id"]
    name = data["name"]
    email = data["email"]
    phone = data["phone"]

    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed", "status": "error"}), 500

    try:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE users SET name = %s, email = %s, phone = %s WHERE id = %s;
            """, (name, email, phone, user_id))

            conn.commit()
            return jsonify({"message": "Profile updated successfully", "status": "success"}), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Database error: {str(e)}", "status": "error"}), 500

    finally:
        conn.close()
@app.route('/available_spots', methods=['GET'])
def get_available_spots():
    """שליפת חניות פנויות"""
    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            SELECT id, lot_name, spot_number, distance_from_college, distance_category
            FROM parking_spots
            WHERE status = 'זמין'
            ORDER BY distance_from_college ASC;
        """)

        spots = cur.fetchall()
        cur.close()
        conn.close()

        if not spots:
            return jsonify({"message": "אין חניות פנויות", "status": "error"}), 404

        spots_list = []
        for spot in spots:
            spots_list.append({
                "id": spot[0],
                "lot_name": spot[1],
                "spot_number": spot[2],
                "distance_from_college": spot[3],
                "distance_category": spot[4]
            })

        return jsonify({"status": "success", "parking_spots": spots_list}), 200

    except Exception as e:
        return jsonify({"message": f"שגיאת מסד נתונים: {str(e)}", "status": "error"}), 500

from datetime import datetime, timedelta

@app.route('/reserve_spot', methods=['POST'])
def reserve_spot():
    data = request.get_json()

    if "user_id" not in data or "spot_id" not in data:
        return jsonify({"message": "נתונים חסרים", "status": "error"}), 400

    user_id = data["user_id"]
    spot_id = data["spot_id"]

    now = datetime.now()

    # 🕒 חישוב טווח השבוע הנוכחי (מיום ראשון ב־06:00 עד שבת ב־23:59)
    weekday = now.weekday()  # ראשון = 6, שני = 0 ...
    if weekday == 6:  # אם היום ראשון
        week_start = datetime.combine(now.date(), datetime.min.time()) + timedelta(hours=6)
    else:
        last_sunday = now - timedelta(days=(weekday + 1))
        week_start = datetime.combine(last_sunday.date(), datetime.min.time()) + timedelta(hours=6)

    week_end = week_start + timedelta(days=6, hours=17, minutes=59)  # שבת ב־23:59

    if not (week_start <= now <= week_end):
        return jsonify({
            "message": f"ההזמנות מותרות רק מ־{week_start.strftime('%Y-%m-%d %H:%M')} עד {week_end.strftime('%Y-%m-%d %H:%M')}",
            "status": "error"
        }), 403

    # המשך ההזמנה הרגילה
    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed", "status": "error"}), 500

    try:
        cur = conn.cursor()

        # בדיקה אם החניה זמינה
        cur.execute("SELECT status FROM parking_spots WHERE id = %s;", (spot_id,))
        spot = cur.fetchone()

        if not spot or spot[0] != "זמין":
            return jsonify({"message": "החניה אינה זמינה", "status": "error"}), 400

        # הוספת ההזמנה
        cur.execute("""
            INSERT INTO reservations (user_id, spot_id, start_time, end_time, status)
            VALUES (%s, %s, NOW(), NOW() + INTERVAL '1 HOUR', 'confirmed');
        """, (user_id, spot_id))

        # עדכון סטטוס חניה ל"תפוס"
        cur.execute("UPDATE parking_spots SET status = 'תפוס' WHERE id = %s;", (spot_id,))

        conn.commit()
        return jsonify({"message": "ההזמנה בוצעה בהצלחה!", "status": "success"}), 200

    except pg8000.InterfaceError:
        return jsonify({"message": "Database connection lost", "status": "error"}), 500

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"שגיאת מסד נתונים: {str(e)}", "status": "error"}), 500

    finally:
        cur.close()
        conn.close()
@app.route('/confirm_arrival', methods=['POST'])
def confirm_arrival():
    data = request.get_json()
    reservation_id = data.get("reservation_id")

    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database error", "status": "error"}), 500

    try:
        with conn.cursor() as cur:
            cur.execute("SELECT start_time, status FROM reservations WHERE id = %s", (reservation_id,))
            row = cur.fetchone()

            if not row:
                return jsonify({"message": "Reservation not found", "status": "error"}), 404

            start_time, status = row
            now = datetime.now()

            if status != "confirmed":
                return jsonify({"message": "Reservation cannot be confirmed", "status": "error"}), 400

            if not (start_time - timedelta(minutes=10) <= now <= start_time + timedelta(minutes=10)):
                return jsonify({"message": "Too early or too late to confirm arrival", "status": "error"}), 403

            cur.execute("UPDATE reservations SET status = 'arrived' WHERE id = %s", (reservation_id,))
            conn.commit()

            return jsonify({"message": "Arrival confirmed", "status": "success"}), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Error: {str(e)}", "status": "error"}), 500

    finally:
        conn.close()


@app.route('/cancel_reservation', methods=['POST'])
def cancel_reservation():
    data = request.get_json()

    if "reservation_id" not in data:
        return jsonify({"message": "Missing reservation_id", "status": "error"}), 400

    reservation_id = data["reservation_id"]

    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed", "status": "error"}), 500

    try:
        cur = conn.cursor()

        # שליפת מספר החניה של ההזמנה
        cur.execute("SELECT spot_id FROM reservations WHERE id = %s AND status = 'confirmed';", (reservation_id,))
        spot = cur.fetchone()

        if not spot:
            return jsonify({"message": "Reservation not found or already cancelled", "status": "error"}), 404

        spot_id = spot[0]

        # עדכון הסטטוס של ההזמנה ל'cancelled'
        cur.execute("UPDATE reservations SET status = 'cancelled' WHERE id = %s;", (reservation_id,))

        # עדכון הסטטוס של החניה ל'זמין' כדי שתוכל להיות מוזמנת שוב
        cur.execute("UPDATE parking_spots SET status = 'זמין' WHERE id = %s;", (spot_id,))

        conn.commit()
        return jsonify({"message": "Reservation cancelled successfully, spot is now available", "status": "success"}), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Database error: {str(e)}", "status": "error"}), 500

    finally:
        cur.close()
        conn.close()

@app.route('/all_reservations', methods=['GET'])
def get_all_reservations():
    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed", "status": "error"}), 500

    try:
        cur = conn.cursor()
        cur.execute("""
            SELECT r.id, r.user_id, p.spot_number, r.start_time, r.end_time, r.status
            FROM reservations r
            JOIN parking_spots p ON r.spot_id = p.id
            ORDER BY r.start_time DESC;
        """)
        reservations = cur.fetchall()
        conn.close()

        return jsonify({
            "status": "success",
            "reservations": [
                {"id": r[0], "user_id": r[1], "spot_number": r[2], "start_time": r[3], "end_time": r[4], "status": r[5]}
                for r in reservations
            ]
        }), 200

    except Exception as e:
        return jsonify({"message": f"Database error: {str(e)}", "status": "error"}), 500
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()

    required_fields = ["name", "email", "phone", "password", "role"]
    if not all(field in data for field in required_fields):
        return jsonify({"message": "Missing fields", "status": "error"}), 400

    name = data["name"]
    email = data["email"]
    phone = data["phone"]
    role = data["role"]
    password = hash_password(data["password"])

    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection error", "status": "error"}), 500

    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id FROM users WHERE email = %s", (email,))
            if cur.fetchone():
                return jsonify({"message": "Email already exists", "status": "error"}), 409

            cur.execute("""
                INSERT INTO users (name, email, phone, password, role)
                VALUES (%s, %s, %s, %s, %s)
            """, (name, email, phone, password, role))

            conn.commit()
            return jsonify({"message": "User registered successfully", "status": "success"}), 201

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Database error: {str(e)}", "status": "error"}), 500

    finally:
        conn.close()
@app.route('/edit_reservation', methods=['POST'])
def edit_reservation():
    data = request.get_json()

    required_fields = ["reservation_id", "start_time", "end_time"]
    if not all(field in data for field in required_fields):
        return jsonify({"message": "Missing fields", "status": "error"}), 400

    reservation_id = data["reservation_id"]
    new_start = datetime.fromisoformat(data["start_time"])
    new_end = datetime.fromisoformat(data["end_time"])

    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed", "status": "error"}), 500

    try:
        with conn.cursor() as cur:
            # שליפת זמן ההתחלה המקורי
            cur.execute("SELECT start_time, spot_id FROM reservations WHERE id = %s AND status = 'confirmed';", (reservation_id,))
            result = cur.fetchone()
            if not result:
                return jsonify({"message": "Reservation not found or cannot be edited", "status": "error"}), 404

            original_start, spot_id = result

            # בדיקה אם נותרו פחות מ-12 שעות
            if original_start - datetime.now() < timedelta(hours=12):
                return jsonify({"message": "ניתן לערוך הזמנה רק אם נותרו יותר מ-12 שעות לתחילתה", "status": "error"}), 403

            # בדיקה אם הזמן החדש פנוי
            cur.execute("""
                SELECT id FROM reservations 
                WHERE spot_id = %s AND id != %s
                AND ((start_time, end_time) OVERLAPS (%s, %s))
                AND status = 'confirmed';
            """, (spot_id, reservation_id, new_start, new_end))

            if cur.fetchone():
                return jsonify({"message": "הזמן החדש כבר שמור", "status": "error"}), 409

            # עדכון ההזמנה
            cur.execute("""
                UPDATE reservations SET start_time = %s, end_time = %s
                WHERE id = %s;
            """, (new_start, new_end, reservation_id))
            conn.commit()

            return jsonify({"message": "ההזמנה עודכנה בהצלחה", "status": "success"}), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Database error: {str(e)}", "status": "error"}), 500

    finally:
        conn.close()

@app.route('/my_reservations/<int:user_id>', methods=['GET'])
def get_reservations(user_id):
    """שליפת ההזמנות של המשתמש"""
    conn = get_db_connection()
    cur = conn.cursor()
    auto_cancel_expired_reservations(conn)
    try:
        cur.execute("""
            SELECT r.id, p.spot_number, r.start_time, r.end_time, r.status
            FROM reservations r
            JOIN parking_spots p ON r.spot_id = p.id
            WHERE r.user_id = %s
            ORDER BY r.start_time DESC;
        """, (user_id,))

        reservations = cur.fetchall()
        cur.close()
        conn.close()

        if not reservations:
            return jsonify({"message": "No reservations found", "status": "error"}), 404

        reservations_list = []
        for res in reservations:
            reservations_list.append({
                "id": res[0],
                "spot_number": res[1],
                "start_time": res[2].strftime('%Y-%m-%d %H:%M'),
                "end_time": res[3].strftime('%Y-%m-%d %H:%M'),
                "status": res[4]
            })

        return jsonify({"status": "success", "reservations": reservations_list}), 200

    except Exception as e:
        return jsonify({"message": f"Database error: {str(e)}", "status": "error"}), 500
    


@app.route('/stats_by_month', methods=['GET'])
def stats_by_month():
    conn = psycopg2.connect(...)  # פרטי ההתחברות
    cur = conn.cursor()
    
    query = """
        SELECT 
            DATE_TRUNC('month', start_time) AS month,
            COUNT(*) AS total,
            COUNT(*) FILTER (WHERE status = 'APPROVED') AS approved,
            COUNT(*) FILTER (WHERE status = 'CANCELLED') AS legal_cancelled,
            COUNT(*) FILTER (WHERE status = 'ILLEGAL_CANCELLED') AS illegal_cancelled
        FROM reservations
        GROUP BY month
        ORDER BY month;
    """
    cur.execute(query)
    result = cur.fetchall()
    conn.close()

    # החזרה בפורמט JSON
    stats = [{
        "month": row[0].strftime('%Y-%m'),
        "total": row[1],
        "approved": row[2],
        "legal_cancelled": row[3],
        "illegal_cancelled": row[4]
    } for row in result]

    return jsonify(stats)
@app.route('/stats', methods=['GET'])
def get_overall_stats():
    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed"}), 500

    try:
        cur = conn.cursor()
        cur.execute("""
            SELECT 
                COUNT(*) AS total,
                COUNT(*) FILTER (WHERE status = 'arrived') AS arrived,
                COUNT(*) FILTER (WHERE status = 'cancelled') AS canceled,
                COUNT(*) FILTER (WHERE status = 'illegal_cancelled') AS illegal
            FROM reservations;
        """)
        result = cur.fetchone()
        conn.close()

        # ודא ש־None הופך ל־0
        total = result[0] or 0
        arrived = result[1] or 0
        canceled = result[2] or 0
        illegal = result[3] or 0

        return jsonify({
            "reservations": total,
            "arrived": arrived,
            "canceled": canceled,
            "illegal": illegal
        }), 200

    except Exception as e:
        return jsonify({"message": f"Database error: {str(e)}"}), 500


@app.route('/monthly_stats', methods=['POST'])
def get_monthly_stats():
    data = request.get_json()
    month = data.get('month')  # ציפייה לפורמט YYYY-MM

    if not month:
        return jsonify({"message": "Missing 'month'", "status": "error"}), 400

    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed", "status": "error"}), 500

    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 
                    COUNT(*) AS total,
                    COUNT(*) FILTER (WHERE status = 'confirmed') AS approved,
                    COUNT(*) FILTER (WHERE status = 'cancelled') AS canceled,
                    COUNT(*) FILTER (WHERE status = 'illegal_cancelled') AS illegal,
                    COUNT(*) FILTER (WHERE status = 'arrived') AS arrived
                FROM reservations
                WHERE TO_CHAR(start_time, 'YYYY-MM') = %s;
            """, (month,))
            result = cur.fetchone()
            total, approved, canceled, illegal, arrived = result

            return jsonify({
                "reservations": total,
                "approved": approved,
                "canceled": canceled,
                "illegal": illegal,
                "arrived": arrived
            }), 200

    except Exception as e:
        return jsonify({"message": f"Database error: {str(e)}", "status": "error"}), 500

    finally:
        conn.close()

def compute_user_grade_and_status(statuses):
    if not statuses:
        return 60.0, 'active'

    total = len(statuses)
    score = 0
    for status in statuses:
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

 
@app.route('/user_behavior/<int:user_id>', methods=['GET'])
def simulate_user_behavior(user_id):
    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed"}), 500

    try:
        # עדכון הזמנות שהסתיימו מסטטוס 'arrived' ל־'completed'
        update_expired_arrivals(conn)

        cur = conn.cursor()
        cur.execute("SELECT id, name, role, status, force_status_override FROM users WHERE id = %s;", (user_id,))
        user_data = cur.fetchone()

        if not user_data:
            cur.close()
            conn.close()
            return jsonify({"message": "User not found"}), 404

        user_id, name, role, current_status, force_override = user_data

        # שליפת כל ההזמנות של המשתמש כולל זמנים
        cur.execute("""
            SELECT start_time, end_time, status
            FROM reservations
            WHERE user_id = %s;
        """, (user_id,))
        all_reservations = cur.fetchall()
        cur.close()
        conn.close()

        # חישוב ציון
        total = len(all_reservations)
        if total == 0:
            grade = 60.0
        else:
            points = 0
            for start, end, res_status in all_reservations:
                if res_status in ('arrived', 'completed'):
                    points += 10
                elif res_status == 'cancelled':
                    points += 0
                elif res_status == 'illegal_cancelled':
                    points -= 20
            grade = max(0.0, min(100.0, (points / (10 * total)) * 100))

        # קביעת סטטוס נוכחי לפי הזמן האמיתי
        now = datetime.now()
        status_now = 'unknown'
        for start, end, res_status in all_reservations:
            if res_status == 'arrived' and start <= now <= end:
                status_now = 'arrived'
                break
            elif res_status == 'arrived' and end < now:
                status_now = 'completed'
                break

        # קביעת סטטוס חדש רק אם אין force_status_override
        if not force_override:
            new_status = 'blocked' if grade < 30 else 'active'

            if new_status != current_status:
                conn2 = get_db_connection()
                if conn2:
                    with conn2.cursor() as cur2:
                        cur2.execute("UPDATE users SET status = %s WHERE id = %s;", (new_status, user_id))
                        conn2.commit()
                    conn2.close()

        return jsonify({
            "user_id": user_id,
            "name": name,
            "role": role,
            "status_now": status_now,
            "grade": round(grade, 1)
        })

    except Exception as e:
        return jsonify({"message": f"Error: {str(e)}"}), 500


@app.route('/reset_override', methods=['POST'])
def reset_override():
    data = request.json
    user_id = data.get('user_id')

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            UPDATE users
            SET force_status_override = false
            WHERE id = %s
        """, (user_id,))
        conn.commit()
        cur.close()
        conn.close()

        # ✅ קריאה לחישוב אוטומטי מחדש של התנהגות (ניקוד → חסימה אם צריך)
        simulate_user_behavior_internal(user_id)

        return jsonify({"message": "override reset"}), 200

    except Exception as e:
        return jsonify({"message": f"Error: {str(e)}"}), 500



def update_expired_arrivals(conn):
    try:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE reservations
                SET status = 'completed'
                WHERE status = 'arrived' AND end_time < NOW();
            """)
            conn.commit()
    except Exception as e:
        print(f"Error updating completed reservations: {str(e)}")
        conn.rollback()

from datetime import datetime
@app.route('/simulate_efficiency', methods=['POST'])
def simulate_efficiency():
    data = request.get_json()
    no_show_prob = data.get("no_show_prob", 0.03)
    cancellation_prob = data.get("cancellation_prob", 0.05)

    user = User(user_id=0, name="Simulation")
    user.parametersForTimeTables_set({
        "arrival_mean_hour": 8,
        "arrival_stddev": 1,
        "departure_mean_hour": 17,
        "departure_stddev": 1,
        "days_of_week": list(range(5)),
        "no_show_prob": no_show_prob,
        "cancellation_prob": cancellation_prob
    })
    user.generalWeekTimeTable_make()
    user.realTimeTable_make()
    grade, status = user.compute_grade_and_status()

    return jsonify({
        "grade": grade,
        "status": status,
        "arrived": user.reservation_statuses.count("arrived"),
        "cancelled": user.reservation_statuses.count("cancelled"),
        "illegal_cancelled": user.reservation_statuses.count("illegal_cancelled"),
        "total_reservations": len(user.reservation_statuses)
    })
@app.route('/real_efficiency', methods=['POST'])
def real_efficiency():
    data = request.get_json()
    start_date = data.get("start_date")
    end_date = data.get("end_date")

    if not start_date or not end_date:
        return jsonify({"message": "Missing date range", "status": "error"}), 400

    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed", "status": "error"}), 500

    try:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT status FROM reservations
                WHERE start_time::date BETWEEN %s AND %s;
            """, (start_date, end_date))

            statuses = [row[0] for row in cur.fetchall()]
            total = len(statuses)
            arrived = statuses.count("arrived")
            cancelled = statuses.count("cancelled")
            illegal = statuses.count("illegal_cancelled")

            if total == 0:
                return jsonify({"message": "No data", "status": "error"}), 404

            # נוסחה בסיסית ליעילות
            gamma = 2  # אפשר להפוך את זה לפרמטר בעתיד
            efficiency = (arrived / total) - gamma * (illegal / total)

            return jsonify({
                "status": "success",
                "efficiency": round(efficiency, 3),
                "arrived": arrived,
                "cancelled": cancelled,
                "illegal_cancelled": illegal,
                "total": total
            })

    except Exception as e:
        return jsonify({"message": f"Error: {str(e)}", "status": "error"}), 500

    finally:
        conn.close()
# ✅ קטע חדש להוספה בסוף הקובץ app.py

@app.route('/real_efficiency_with_params', methods=['POST'])
def real_efficiency_with_params():
    data = request.get_json()
    points_arrived = data.get("points_arrived", 10)
    points_cancelled = data.get("points_cancelled", 0)
    points_illegal = data.get("points_illegal", -20)

    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed"}), 500

    try:
        cur = conn.cursor()
        cur.execute("SELECT id FROM users;")
        user_ids = [row[0] for row in cur.fetchall()]

        total_users = len(user_ids)
        total_grade = 0
        blocked_count = 0

        total_arrived = 0
        total_cancelled = 0
        total_illegal = 0
        total_reservations = 0

        # ניקוד מקסימלי מוחלט
        max_single_score = max(abs(points_arrived), abs(points_cancelled), abs(points_illegal))

        for user_id in user_ids:
            cur.execute("SELECT status FROM reservations WHERE user_id = %s;", (user_id,))
            statuses = [r[0] for r in cur.fetchall()]
            total = len(statuses)
            if total == 0:
                grade = 60.0  # ניקוד ברירת מחדל
            else:
                score = 0
                for s in statuses:
                    if s == 'arrived':
                        score += points_arrived
                        total_arrived += 1
                    elif s == 'cancelled':
                        score += points_cancelled
                        total_cancelled += 1
                    elif s == 'illegal_cancelled':
                        score += points_illegal
                        total_illegal += 1
                max_score = total * max_single_score
                grade = max(0, min(100, (score / max_score) * 100))
            total_grade += grade
            total_reservations += total

            if grade < 30:
                blocked_count += 1

        avg_grade = round(total_grade / total_users, 1) if total_users > 0 else 0
        return jsonify({
            "avg_grade": avg_grade,
            "blocked_percent": round((blocked_count / total_users) * 100, 1),
            "arrived": total_arrived,
            "cancelled": total_cancelled,
            "illegal_cancelled": total_illegal,
            "total_reservations": total_reservations
        })

    except Exception as e:
        return jsonify({"message": str(e)}), 500

    finally:
        conn.close()


def simulate_user_behavior_internal(user_id, points_arrived=10, points_cancelled=0, points_illegal=-20):
    conn = get_db_connection()
    if not conn:
        return

    try:
        cur = conn.cursor()
        cur.execute("SELECT force_status_override FROM users WHERE id = %s;", (user_id,))
        result = cur.fetchone()
        if not result:
            return

        force_override = result[0]

        # שליפת כל ההזמנות של המשתמש
        cur.execute("""
            SELECT start_time, end_time, status
            FROM reservations
            WHERE user_id = %s;
        """, (user_id,))
        reservations = cur.fetchall()

        # חישוב ניקוד
        total = len(reservations)
        if total == 0:
            grade = 60.0
        else:
            points = 0
            for start, end, res_status in reservations:
                if res_status in ('arrived', 'completed'):
                    points += points_arrived
                elif res_status == 'cancelled':
                    points += points_cancelled
                elif res_status == 'illegal_cancelled':
                    points += points_illegal
            max_score = total * points_arrived
            grade = max(0.0, min(100.0, (points / max_score) * 100)) if max_score > 0 else 0.0

        # אם אין שליטת אדמין — עדכן סטטוס לפי ניקוד
        if not force_override:
            new_status = 'blocked' if grade < 30 else 'active'
            cur.execute("UPDATE users SET status = %s WHERE id = %s;", (new_status, user_id))
            conn.commit()

        cur.close()
        conn.close()
    except Exception as e:
        print("Error in internal behavior calc:", e)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

