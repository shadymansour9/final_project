import pg8000

import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))


# התחברות ל-PostgreSQL
def connect_db():
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
        print(f" Database connection failed: {e}")
        return None
def get_all_users():
    conn = connect_db()
    if conn:
        cur = conn.cursor()
        cur.execute("SELECT * FROM users;")
        users = cur.fetchall()
        conn.close()
        return users
    return []
def add_user(name, email, phone, role):
    conn = connect_db()
    if conn:
        cur = conn.cursor()
        cur.execute("INSERT INTO users (name, email, phone, role) VALUES (%s, %s, %s, %s) RETURNING id;", 
                    (name, email, phone, role))
        user_id = cur.fetchone()[0]
        conn.commit()
        conn.close()
        return user_id
    return None
def add_reservation(user_id, parking_slot, status='pending'):
    conn = connect_db()
    if conn:
        cur = conn.cursor()
        cur.execute("INSERT INTO reservations (user_id, parking_slot, status) VALUES (%s, %s, %s) RETURNING id;", 
                    (user_id, parking_slot, status))
        reservation_id = cur.fetchone()[0]
        conn.commit()
        conn.close()
        return reservation_id
    return None
