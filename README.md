📘 Linux Tutor – User Management & Quiz System

Linux Tutor is a Bash-based interactive learning tool that combines secure authentication, user management, and a Linux command quiz using the dialog interface. It provides a hands-on environment for practicing Linux commands while managing real system users securely.

🚀 Features
🔐 Authentication

Sign Up with username & password

SHA-256 password hashing

Secure Sign In

Prevents empty input

Stores credentials in credentials.txt

👥 User Management

Add, modify, or delete system users

Displays only users created through the script

Automatically deletes quiz logs on user removal

Stores raw users in created_users.txt

📝 Linux Command Quiz

10 random questions

Real-time score updates

Logs score & time in tutorial_scores.log

Case-insensitive answering

Requires re-login before quiz

🏆 Leaderboard

Shows top 10 scores
Linux.sh
credentials.txt
created_users.txt
tutorial_scores.log
/tmp/linux_tutor/
▶️ How to Run
1. Install requirements
sudo apt install dialog

2. Make executable
chmod +x Linux.sh

3. Run as root
sudo ./Linux.sh

🎯 Purpose

This project helps users learn Linux commands, practice Bash scripting, and understand Linux system user management through an interactive, GUI-like terminal experience.

📚 Future Improvements

Quiz difficulty levels

MCQ questions

PDF certificate generation

More command categories

📜 License

This project is released under the MIT License.
Sorted by highest score, then lowest time

📦 File Structure
