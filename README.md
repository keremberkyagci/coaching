# 📚 FOCUS – Study Planner & Coaching Platform

A professional, scalable, and high-performance **Flutter** application integrated with **Firebase**, designed to bridge the gap between students and educational coaches. FOCUS simplifies exam preparation (YKS, LGS, KPSS) by providing a structured, real-time ecosystem for task management, performance analytics, and mentoring.

---

## 🚀 Core Features

### 👨‍🎓 For Students: Digital Mentor in Your Pocket
- **Intelligent Planner:** Manage weekly study schedules with specialized tracks for different exam types.
- **Task Management:** Real-time tracking of study sessions, test results, and trial exams.
- **Performance Analytics:** Visualized data insights (Correct/Wrong/Blank ratios) powered by `fl_chart`.
- **Self-Assessment:** Interactive **Star Rating System** for topic-based proficiency tracking.
- **Manual Logging:** Quickly log ad-hoc study sessions with a sleek, slider-based UI.

### 👨‍🏫 For Coaches: Data-Driven Mentoring
- **Unified Student Registry:** Monitor all assigned students from a single, real-time dashboard.
- **Progress Tracking:** Instant visibility into student completion rates and daily study habits.
- **Direct Intervention:** Remote task assignment and plan adjustments.
- **Integrated Chat:** Professional communication hub to guide students without leaving the app.

---

## 🏢 Technical Architecture

The project is built with **Scalability** and **Separation of Concerns** at its core. It follows a modernized **MVVM / Clean Architecture** hybrid:

### 🛠️ Tech Stack
- **Frontend:** Flutter (Dart)
- **State Management:** `Riverpod 2.0` (Comprehensive Provider usage)
- **Backend:** Firebase (Auth, Cloud Firestore)
- **Data Modeling:** `Equatable` (Immutable state management)
- **Analytics:** `fl_chart` (Custom performance visualization)

### 📂 Directory Structure
- `lib/models/`: Immutable data structures (`UserModel`, `PlanModel`, `MessageModel`, etc.).
- `lib/services/`: Pure business logic and Firebase API wrappers (`AuthService`, `ChatService`, `PerformanceService`).
- `lib/repositories/`: Data access layer with Typed Firestore Converters (`PlanRepository`, `UserRepository`).
- `lib/providers/`: The "Brain" of the app – centralizing all global state and data streams.
- `lib/screens/`: Feature-sliced UI components.
- `lib/widgets/`: Atomic UI units, reorganized into `dialogs/`, `planner/`, and `statistics/`.

---

## 🇹🇷 Educational Component: Source Code Documentation
To aid Computer Science students and developers, the entire codebase has been enriched with **Turkish Explanatory Comments**. Every major class, method, and architectural decision is documented directly in the source code to provide a clear understanding of:
- Firebase initialization and Auth status wrapping.
- Riverpod provider lifecycle and dependency injection.
- Atomic Firestore updates and batch operations.

---

## ⚙️ Development Setup

1. **Clone & Install:**
   ```bash
   git clone https://github.com/keremberkyagci/coaching.git
   flutter pub get
   ```

2. **Firebase Configuration:**
   - Initialize Firebase on your local machine: `flutterfire configure`.
   - The app uses `firebase_options.dart` for environment-specific settings.

3. **Run:**
   - Launch on Android, iOS, or Web: `flutter run`.

---

## 👨‍💻 Author
**Kerem Berk Yağcı**  
*Computer Science Student & Developer ,On The Way to Become a Product Engineer *

---

> [!TIP]
> This platform utilizes **Real-time Streams**, ensuring that any change made by a coach is instantly reflected on the student's dashboard without manual refresh.

---
*Built with ❤️ for better education.*
