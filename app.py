from flask import Flask, jsonify, request
import pg8000
import bcrypt

app = Flask(__name__)

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
    data = request.get_json()

    if "user_id" not in data or "status" not in data:
        return jsonify({"message": "Missing user_id or status", "status": "error"}), 400

    user_id = data["user_id"]
    status = data["status"]

    if status not in ['active', 'blocked']:
        return jsonify({"message": "Invalid status value", "status": "error"}), 400

    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed", "status": "error"}), 500

    try:
        with conn.cursor() as cur:
            cur.execute("UPDATE users SET status = %s WHERE id = %s;", (status, user_id))
            conn.commit()
            return jsonify({"message": f"User status updated to {status}", "status": "success"}), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"message": f"Database error: {str(e)}", "status": "error"}), 500

    finally:
        conn.close()

@app.route('/users', methods=['GET'])
def get_users():
    conn = get_db_connection()
    if not conn:
        return jsonify({"message": "Database connection failed", "status": "error"}), 500

    try:
        cur = conn.cursor()
        cur.execute("SELECT id, name, email, status FROM users ORDER BY name ASC;")
        users = cur.fetchall()
        cur.close()
        conn.close()

        return jsonify({
            "status": "success",
            "users": [{"id": u[0], "name": u[1], "email": u[2], "status": u[3]} for u in users]
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

            # 🔒 שלב 2: בדוק את הקטגוריה של מקום החניה
            cur.execute("SELECT distance_category FROM parking_spots WHERE id = %s;", (spot_id,))
            spot = cur.fetchone()
            if not spot:
                return jsonify({"message": "Parking spot not found", "status": "error"}), 404

            distance_category = spot[0]

            # 🔒 שלב 3: אם המשתמש חסום ורוצה להזמין חניה שאינה רחוקה – נחסום
            if user_status == 'blocked' and distance_category != 'רחוק':
                return jsonify({
                    "message": "משתמש חסום יכול להזמין רק חניה רחוקה",
                    "status": "error"
                }), 403

            # בדיקה אם המקום תפוס באותו טווח זמן
            cur.execute("""
                SELECT id FROM reservations 
                WHERE spot_id = %s AND 
                      ((start_time, end_time) OVERLAPS (%s, %s))
            """, (spot_id, start_time, end_time))

            if cur.fetchone():
                return jsonify({"message": "המקום כבר שמור לשעה זו", "status": "error"}), 409

            # הכנסת ההזמנה
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


@app.route('/my_reservations/<int:user_id>', methods=['GET'])
def get_reservations(user_id):
    """שליפת ההזמנות של המשתמש"""
    conn = get_db_connection()
    cur = conn.cursor()

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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
