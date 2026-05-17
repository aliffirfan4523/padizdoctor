# PadizDoctor 🌾

PadizDoctor is an intelligent Flutter application designed to assist farmers and agricultural experts in diagnosing paddy (rice) plant diseases. By leveraging advanced Machine Learning and Generative AI (LLMs), PadizDoctor provides accurate disease detection, detailed treatment plans, and actionable agricultural insights right from your smartphone.

<p align="center">
  <img src="https://firebasestorage.googleapis.com/v0/b/padizdoctor-fyp-6820b.firebasestorage.app/o/images%2Fintrogif.gif?alt=media&token=1da9d9a9-63ac-441a-929f-184678aa7f19" width="100%" alt="PadizDoctor Banner" />
</p>

## ✨ Key Features

*   **🔍 Smart Image Diagnosis:** Take a photo or upload an image from your gallery to instantly detect paddy leaf diseases using our robust machine learning backend.
*   **🤖 LLM-Powered Expert Advice:** Get detailed, context-aware treatment suggestions, severity assessments, and symptom breakdowns powered by Generative AI.
*   **📊 Advanced Metrics Dashboard:** Track your crop's health trends over time. View weekly/monthly detection charts, disease distribution pie charts, average scan processing times, and a calendar heatmap of your activity.
*   **📚 Comprehensive History:** Access your previous scans anytime. Review the AI's recommendations and view the exact bounding boxes of detected diseases on your uploaded images.
*   **🔒 Secure Authentication:** Seamless and secure login using Firebase Authentication, supporting both Email/Password and Google Sign-in.
*   **🎨 Modern & Intuitive UI:** A beautifully crafted, responsive interface with smooth animations, premium styling, and support for Dark/Light themes.

## 📱 Screenshots

| Home & Scanning | AI Analysis Results | Advanced Metrics | History |
|:---:|:---:|:---:|:---:|
| ![Home](https://firebasestorage.googleapis.com/v0/b/padizdoctor-fyp-6820b.firebasestorage.app/o/images%2Fhomepage.jpeg?alt=media&token=9fd763d3-74b8-4779-9471-ab72b61cfb1d) | ![Results](https://firebasestorage.googleapis.com/v0/b/padizdoctor-fyp-6820b.firebasestorage.app/o/images%2Fresult.jpeg?alt=media&token=d51069b9-6d9f-407f-aced-288a565a20e2) | ![Metrics](https://firebasestorage.googleapis.com/v0/b/padizdoctor-fyp-6820b.firebasestorage.app/o/images%2Factivity.jpeg?alt=media&token=99c29837-3625-4c44-94c8-561bdd8672d8) | ![History](https://firebasestorage.googleapis.com/v0/b/padizdoctor-fyp-6820b.firebasestorage.app/o/images%2Fhistory.jpeg?alt=media&token=dc659c41-8512-4d25-99ae-69002cd534de) |

## 🛠️ Technology Stack

*   **Frontend:** [Flutter](https://flutter.dev/) & Dart
*   **Backend API:** FastAPI / Python (Machine Learning Inference & RAG/LLM pipelines)
*   **Database & Storage:** Firebase Firestore & Firebase Cloud Storage
*   **Authentication:** Firebase Auth

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK installed
*   Firebase project configured (ensure `google-services.json` and `GoogleService-Info.plist` are placed in their respective directories).

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/padizdoctor.git
   ```
2. Navigate to the project directory:
   ```bash
   cd padizdoctor
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   ```bash
   flutter run
   ```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the issues page.
