📚 FOCUS – Study Planner & Coaching Platform

FOCUS is a Flutter + Firebase based study planning and coaching platform designed for students preparing for major exams (such as YKS / LGS) and their mentors.

The platform allows students to organize their daily study plans, while coaches can track progress, assign tasks, and guide students effectively.

🚀 Features
👨‍🎓 Student Features

Daily and weekly study planning

Topic-based study tasks

Test and trial exam planning

Task completion tracking

Performance statistics

Real-time messaging with coaches

Personal study progress dashboard

👨‍🏫 Coach Features

View all assigned students

Track student progress

Assign study tasks

Monitor daily performance

Communicate with students through chat

💬 Real-Time Chat

The app includes a real-time chat system allowing:

student ↔ coach communication

unread message tracking

last message preview

real-time updates

📅 Smart Study Planner

The planner allows:

weekly study schedules

TYT / AYT lesson separation

study session duration tracking

test question tracking

branch trial planning

📊 Study Statistics

Students can track their performance with:

correct answers

incorrect answers

empty answers

success percentage

🏗️ Tech Stack
Frontend

Flutter

Riverpod (State Management)

Material UI

Backend

Firebase Authentication

Cloud Firestore

Firebase Realtime Streams

Architecture

The project follows a clean and scalable architecture:

UI (Screens)
    ↓
State Management (Riverpod Providers)
    ↓
Repositories
    ↓
Services
    ↓
Firebase (Auth + Firestore)
📂 Project Structure
lib/
 ├── models
 ├── services
 ├── repositories
 ├── providers
 ├── screens
 ├── widgets
 ├── utils
 └── main.dart
🔐 Authentication

User authentication is handled via Firebase Authentication.

Supported features:

email / password signup

login

password reset

role-based navigation (Student / Coach)

📡 Database

The application uses Cloud Firestore.

Main collections:

users
plans
chats
messages
aggregatedStats
lessons
topics
📱 Screens

Main application screens include:

Student Dashboard

Coach Dashboard

Study Planner

Chat

Student Statistics

Profile

⚙️ Setup

1️⃣ Clone the repository

git clone https://github.com/yourusername/focus-study-planner.git

2️⃣ Install dependencies

flutter pub get

3️⃣ Configure Firebase

Run:

flutterfire configure

4️⃣ Run the application

flutter run
🎯 Purpose of the Project

This project was built as a learning project and portfolio application to explore:

Flutter mobile development

Firebase backend architecture

scalable app structure

real-time data handling

study productivity tools

🔮 Future Improvements

Planned features include:

AI-based study recommendations

Pomodoro timer

push notifications

leaderboard system

advanced analytics

exam simulation tools

👨‍💻 Author

Kerem Berk Yağcı
Computer Science Student

💡 Built as a learning project to improve mobile development and system design skills.
