import database


# הוספת משתמש
user_id = database.add_user("David Cohen", "david@example.com", "050-1234567", "student")

print(f" New user added with ID: {user_id}")

# הצגת כל המשתמשים
print(" All users in the system:")
users = database.get_all_users()

for user in users:
    print(user)

# הוספת הזמנת חניה
reservation_id = database.add_reservation(user_id, "A-202", "confirmed")

print(f" Reservation added with ID: {reservation_id}")
