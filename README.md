# Smash Fit 🏋️‍♂️📱
**AI-Based Mobile Fitness and Workout Tracking Application**

![Flutter](https://img.shields.io/badge/Frontend-Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Backend-Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)
![Android](https://img.shields.io/badge/Deployment-Android_APK-3DDC84?style=flat&logo=android&logoColor=white)

## 📖 Overview
**Smash Fit** is an intelligent, personalized fitness mobile application designed to help users plan, track, and optimize their workouts. 

Many traditional fitness apps offer generic, "one-size-fits-all" routines that lead to low motivation and poor results. Smash Fit solves this by generating tailored workout plans based on individual goals, performance, and constraints. By combining user profiling, exercise databases, and adaptive progression strategies, Smash Fit provides data-driven feedback for a sustainable fitness journey.

## 🎯 Target Audience
* **Gym Goers**
* **Fitness Enthusiasts**
* Users of all fitness levels looking for data-driven personalization.

## ✨ Key Features & User Flow
1. **User Profile & Onboarding:** Users register/log in and create a profile containing basic info and fitness goals.
2. **Personalized Workouts:** The app generates tailored plans. Users can select and log their daily workouts based on these recommendations.
3. **Diet Tracking:** Users can log their daily meals and track calorie intake.
4. **Data-Driven Analysis:** The system automatically updates to show progress, insights, and continuous recommendations based on user performance.

<img width="323" height="691" alt="Screenshot 2026-06-18 151823" src="https://github.com/user-attachments/assets/4b84360c-f40b-47cf-8ee9-e160514a3c29" />

<img width="323" height="691" alt="Screenshot 2026-06-18 151322" src="https://github.com/user-attachments/assets/a3e10960-0299-4fc4-944d-dc71266076f1" />

<img width="323" height="687" alt="Screenshot 2026-06-18 151747" src="https://github.com/user-attachments/assets/f6e1db75-d381-4ef7-930f-d9eccfe9e869" />

<img width="329" height="687" alt="Screenshot 2026-06-18 151621" src="https://github.com/user-attachments/assets/a6b44351-84a6-45f6-9630-a4955a54bdb2" />

<img width="326" height="693" alt="Screenshot 2026-06-22 234052" src="https://github.com/user-attachments/assets/4d78081a-d8dc-4b4e-8750-ab9cf0d18ec9" />

<img width="328" height="702" alt="image" src="https://github.com/user-attachments/assets/276c2dc9-a924-44db-bfcb-4d401e26bf57" />


## 🛠️ Technology Stack
* **Frontend:** Flutter (Dart)
* **Backend:** Firebase (Backend-as-a-Service, serverless)
* **Database:** Firebase Cloud Firestore
* **Deployment:** Android APK

## 🏗️ System Architecture
The application follows a structured **MVC (Model-View-Controller)** approach:
* **View (Presentation Layer):** Displays app screens (Profile, Workout, Diet, Progress) and captures user actions (taps, inputs).
* **Controller (Business Layer):** Receives user inputs, validates them, runs the core app logic, and communicates with the data layer.
* **Model (Data Layer + AI):** Stores all data centrally in Firebase. Uses logical processes to generate workout routines, calorie targets, and progress insights.
* **Service (Analysis & Coaching Layer):** Executes the core analysis logic to calculate daily calorie targets, analyze fitness data, and generate personalized workout.

<img width="680" height="469" alt="Poster (1)" src="https://github.com/user-attachments/assets/c95e2a17-7acc-4c16-a49a-5ae258f88744" />

## 📈 Development Methodology (Waterfall)
The project was developed using the Waterfall methodology:
1.  **Requirement Analysis:** Reviewed existing fitness apps to identify gaps in personalization and progression.
2.  **Design:** Planned system architecture and database structure. Designed UI screens using UML and Figma.
3.  **Implementation/Development:** Built the mobile app integrating Flutter with Firebase.
4.  **Testing:** Conducted functional testing for main features like authentication, workout generation, and data logging.

## 🎓 About the Project
This project was developed for **FYP II (Final Year Project II)**.

**Authors:** 
* Muhammad Faozan Zikry Bin Mohd Rizal

**Institution:** Faculty of Computer Science and Mathematics, Universiti Malaysia Terengganu (UMT)

---
*Innovating ideas, Inspiring Futures.*
