# Smash Fit 🏋️‍♂️📱

**AI-Based Mobile Fitness and Workout Tracking Application**

![Flutter](https://img.shields.io/badge/Frontend-Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Backend-Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)
![Android](https://img.shields.io/badge/Deployment-Android_APK-3DDC84?style=flat&logo=android&logoColor=white)
![Dart](https://img.shields.io/badge/Language-Dart-0175C2?style=flat&logo=dart&logoColor=white)

---

## 🚀 Project Summary

**Smash Fit** is an intelligent mobile fitness application that helps users plan workouts, track meals, monitor weight progress, and analyze their fitness journey through personalized insights.

The app was developed as my **Final Year Project II (FYP II)** and is designed to solve a common problem in many fitness apps: generic workout and diet tracking that does not adapt well to individual goals, habits, and progress.

Smash Fit combines **Flutter**, **Firebase**, **fitness data**, **nutrition tracking**, and **AI-powered coaching insights** to create a more personalized and practical fitness companion.

---

## 🎯 Problem Statement

Many traditional fitness apps provide a one-size-fits-all experience. Users often receive generic workout plans, manually track meals without meaningful feedback, and struggle to understand their long-term progress.

Smash Fit addresses this by offering:

- Personalized workout planning
- Daily workout and meal tracking
- Weight progress monitoring
- Data-driven fitness analysis
- AI-based coaching recommendations
- Exportable progress reports

The goal is to help users make better fitness decisions based on their own data.

---

## 👥 Target Users

Smash Fit is designed for:

- Gym goers
- Fitness enthusiasts
- Beginners who need workout guidance
- Users who want to track meals and calories
- Users who want personalized progress insights
- Anyone looking for a structured fitness tracking experience

---

## ✨ Key Features

<details>
<summary><strong>🔐 User Authentication and Profile Management</strong></summary>

Users can register, log in, reset passwords, and manage their personal fitness profile.

The app uses **Firebase Authentication** for secure access and **Cloud Firestore** to store user-related data such as profile details, goals, workout logs, diet records, and progress history.

</details>

<details>
<summary><strong>🏋️ Personalized Workout Planning</strong></summary>

Smash Fit helps users access structured workout plans based on their fitness goals and preferences.

Users can:

- View workout plans
- Preview workout sessions
- Follow workout roadmaps
- Access exercise recommendations
- Continue from their active workout plan

</details>

<details>
<summary><strong>⏱️ Active Workout Tracking</strong></summary>

Users can record workout sessions directly inside the app.

The workout tracker supports:

- Exercise cards
- Set and rep tracking
- Workout input fields
- Workout timer
- Workout history
- Session progress tracking

</details>

<details>
<summary><strong>🔎 Exercise Search and Details</strong></summary>

The app includes exercise search and exercise detail pages.

It integrates with the **WorkoutX API** to retrieve exercise data and also includes fallback mock data to keep the app usable when external API access is unavailable.

</details>

<details>
<summary><strong>🍽️ Diet and Meal Tracking</strong></summary>

Users can log their meals and monitor their daily nutrition intake.

The app tracks:

- Calories
- Protein
- Carbohydrates
- Fat
- Daily calorie targets
- Macronutrient progress

</details>

<details>
<summary><strong>🇲🇾 Malaysian and USDA Food Search</strong></summary>

Smash Fit supports food search using both:

- Local Malaysian/custom food data
- USDA FoodData Central API

This makes the diet tracking feature more useful for users whose meals may not be fully represented in generic international food databases.

</details>

<details>
<summary><strong>⚖️ Weight Tracking and Milestone Feedback</strong></summary>

Users can track body weight progress over time.

The app can detect meaningful progress milestones and encourage users to update their profile metrics so calorie and macro targets remain accurate.

</details>

<details>
<summary><strong>📊 Data-Driven Analysis</strong></summary>

Smash Fit provides analysis features for workouts, diet, and overall progress.

The app helps users understand their data through:

- Workout analysis
- Diet analysis
- Exercise insights
- Nutrition insights
- Progress trends
- Charts and visual summaries

</details>

<details>
<summary><strong>🤖 AI Coaching Insights</strong></summary>

Smash Fit integrates **Google Gemini AI** to generate personalized coaching insights.

AI is used to provide:

- Adaptive workout tips
- Nutrition strategies
- Food quality insights
- Personalized recommendations based on user data

AI works as an enhancement layer, while the core tracking features remain usable independently.

</details>

<details>
<summary><strong>📄 PDF Progress Reports</strong></summary>

Users can generate PDF progress reports that summarize their fitness data over a selected timeframe.

This feature allows users to review and share their progress outside the app.

</details>

---

## 🧭 User Flow

```text
Register / Login
       ↓
Create Fitness Profile
       ↓
Generate or Select Workout Plan
       ↓
Track Workout Sessions
       ↓
Log Meals and Nutrition
       ↓
Track Weight Progress
       ↓
View Analysis and Insights
       ↓
Receive AI Coaching Recommendations
       ↓
Export Progress Report
```

---

## 📱 Screenshots

### Profile

<img width="323" height="691" alt="Login screen" src="https://github.com/user-attachments/assets/4b84360c-f40b-47cf-8ee9-e160514a3c29" />

### Workout Dashboard

<img width="323" height="691" alt="Home dashboard" src="https://github.com/user-attachments/assets/a3e10960-0299-4fc4-944d-dc71266076f1" />

### Diet Tracking

<img width="323" height="687" alt="Workout planning screen" src="https://github.com/user-attachments/assets/f6e1db75-d381-4ef7-930f-d9eccfe9e869" />

### Analysis and Progress

<img width="329" height="687" alt="Diet tracking screen" src="https://github.com/user-attachments/assets/a6b44351-84a6-45f6-9630-a4955a54bdb2" />

<img width="326" height="693" alt="Analysis screen" src="https://github.com/user-attachments/assets/4d78081a-d8dc-4b4e-8750-ab9cf0d18ec9" />

### Active Workout Screen

<img width="328" height="702" alt="Additional Smash Fit app screen" src="https://github.com/user-attachments/assets/276c2dc9-a924-44db-bfcb-4d401e26bf57" />

---

## 🛠️ Technology Stack

| Category | Technologies |
|---|---|
| Frontend | Flutter, Dart, Material Design |
| State Management | Provider, GetX support |
| Backend | Firebase |
| Authentication | Firebase Authentication |
| Database | Firebase Cloud Firestore |
| AI Integration | Google Gemini API |
| Exercise Data | WorkoutX API |
| Food Data | USDA FoodData Central API, local Malaysian/custom food data |
| Charts | fl_chart |
| Reports | pdf, printing |
| Localization / Formatting | intl |
| Deployment | Android APK |

---

## 🏗️ System Architecture

Smash Fit follows a structured **Model-View-Controller (MVC)** style architecture with an additional **service layer** for API integrations, AI coaching, analysis, and report generation.

<img width="680" height="469" alt="Smash Fit system architecture diagram" src="https://github.com/user-attachments/assets/c95e2a17-7acc-4c16-a49a-5ae258f88744" />

<details>
<summary><strong>View Layer</strong></summary>

The View layer contains the user interface screens and reusable widgets.

Examples include:

- Login screen
- Signup screen
- Home dashboard
- Workout pages
- Diet pages
- Analysis pages
- Profile page
- Weight tracking page
- Report page

This layer focuses on layout, navigation, and user interaction.

</details>

<details>
<summary><strong>Controller Layer</strong></summary>

The Controller layer manages app state, validates user actions, coordinates user flows, and connects the UI with services.

Controllers are used for:

- Authentication
- Workout planning
- Active workout tracking
- Workout history
- Exercise search
- Diet tracking
- Weight tracking
- Reports
- Workout and diet analysis
- AI-generated insights

</details>

<details>
<summary><strong>Model Layer</strong></summary>

The Model layer defines the structure of the app data.

Models are used for:

- User profiles
- Diet records
- Workout records
- Workout plans
- Exercise analysis
- Diet insights
- AI coaching insights

This keeps data consistent across the application.

</details>

<details>
<summary><strong>Service Layer</strong></summary>

The Service layer handles external systems and business logic.

Services include:

- Firebase operations
- Exercise API requests
- Food API requests
- AI coaching requests
- Health calculations
- Analysis logic
- PDF report generation

This separation keeps the UI cleaner and makes the project easier to maintain.

</details>

---

## 💡 System Design

### 1. Provider-Based State Management

I used **Provider** to manage shared state across major app features such as authentication, workouts, diet, analysis, reports, and weight tracking.

This allowed the UI to update reactively when user data changed.

### 2. Service-Based API Integration

External APIs and backend operations were separated into service classes.

This made the code easier to maintain because Firebase logic, API requests, AI calls, and PDF generation are not directly mixed into UI screens.

### 3. Fallback Logic for Exercise Data

The exercise service includes fallback mock data when the live API is unavailable.

This improves reliability and allows users to continue using important app flows even when an external service fails.

### 4. AI as an Enhancement Layer

AI coaching was designed as a recommendation layer, not as a dependency for the entire app.

This means the main workout, diet, and progress tracking features can still function even if AI responses are unavailable.

### 5. Local and External Food Data

Smash Fit combines Malaysian/custom food data with USDA food search.

This decision makes nutrition tracking more practical for users with local eating habits.

---

## 📈 Development Methodology

This project was developed using the **Waterfall methodology**.

| Phase | Description |
|---|---|
| Requirement Analysis | Reviewed existing fitness apps and identified gaps in personalization, progress tracking, and nutrition support |
| Design | Planned system architecture, database structure, user flows, UML diagrams, and UI screens using Figma |
| Implementation | Built the mobile app using Flutter and integrated Firebase, APIs, AI coaching, analytics, and reporting features |
| Testing | Conducted functional testing for authentication, workout generation, workout logging, diet tracking, analysis, and data storage |
| Documentation | Prepared project documentation, architecture explanation, screenshots, and presentation materials |

---

## 🧩 Challenges and Solutions

<details>
<summary><strong>Challenge 1: Managing Many Connected Features</strong></summary>

Smash Fit includes authentication, workout planning, active workout tracking, diet logging, weight tracking, analytics, AI coaching, and PDF reports.

**Solution:**  
I separated responsibilities into views, controllers, models, services, and utilities. This made the codebase easier to organize and maintain.

</details>

<details>
<summary><strong>Challenge 2: Making Fitness Data Easy to Understand</strong></summary>

Raw workout, nutrition, and weight data can be difficult for users to interpret.

**Solution:**  
I added dashboards, progress indicators, charts, analysis pages, milestone feedback, and AI-generated insights to help users understand their progress.

</details>

<details>
<summary><strong>Challenge 3: Handling External API Reliability</strong></summary>

External APIs may fail due to network issues, missing credentials, or service limitations.

**Solution:**  
I implemented fallback handling in key areas, such as exercise search, so users can continue using the app even when live API calls are unavailable.

</details>

<details>
<summary><strong>Challenge 4: Supporting Local Food Tracking</strong></summary>

Generic nutrition databases may not fully represent local meals.

**Solution:**  
I combined Malaysian/custom food data with USDA food search to make the diet tracking feature more relevant and flexible.

</details>

---

## 🎓 About the Project

This project was developed for **FYP II (Final Year Project II)**.

**Author**

- Muhammad Faozan Zikry Bin Mohd Rizal

**Institution**

- Faculty of Computer Science and Mathematics, Universiti Malaysia Terengganu (UMT)

---

*Innovating Ideas, Inspiring Futures.*
