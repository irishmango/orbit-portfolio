# Orbit

Orbit is a **task management & collaboration app** built with **Flutter** and **Firebase**.  
It showcases modern mobile development practices including real-time collaboration, chat, and even an **AI chatbot teammate**.

---

## Features

- **Authentication**
  - Email/password login & registration
  - Guest account mode (for demoing without signup)
  - Email verification flow

- **Personal Productivity**
  - Personal tasks
  - Personal projects with nested tasks

- **Collaboration**
  - Create and join collaborations
  - Each collaboration has:
    - Shared projects and tasks
    - Real-time chat
    - Member list with admin/member roles
  - Avatar display with profile photos or initials

- **Chat**
  - Real-time messaging inside collaborations
  - Read/unread indicators
  - Message delivery/error states
  - Timestamps formatted (today, yesterday, weekday, or full date)
  - **AI Bot** integration (OpenAI) to simulate teammates or provide assistance

- **Profile**
  - Editable profile (name, photo, email)
  - Update or remove profile image
  - Settings, account, FAQ, and report-a-problem sections

---

## Tech Stack

- **Frontend**: Flutter (Dart), Provider for state management
- **Backend**: Firebase
  - Authentication
  - Firestore (users, tasks, projects, collaborations, chat)
  - Firebase Storage (profile images)
  - Firebase Functions (OpenAI chatbot integration)
- **Services**:
  - OpenAI API (simulated chat participants / productivity assistant)

---

## Firestore Structure
users/{userId}
├── projects/{projectId}/projectTasks/{taskId}
├── personalTasks/{taskId}
└── collabReads/{collabId}

collaborations/{collabId}
├── collabProjects/{projectId}/collabProjectTasks/{taskId}
├── messages/{messageId}
└── metadata (bot typing indicators, etc.)


---

## Getting Started

### Prerequisites
- [Flutter](https://flutter.dev/docs/get-started/install) (3.x or later)
- Firebase project with:
  - Authentication enabled
  - Firestore + Storage
  - Cloud Functions

### Setup
1. Clone the repo:
   ```bash
   git clone https://github.com/yourusername/orbit.git
   cd orbit
2.	Install dependencies:
    flutter pub get
3.	Configure Firebase:
	•	Add google-services.json (Android) and GoogleService-Info.plist (iOS)
	•	Enable Firestore & Authentication in the Firebase console
	•	Set Firestore rules (see firestore.rules in this repo)
4.	Run the App

### Project Structure
	•	lib/src/features/ — Feature-based modules
	•	auth/ — Authentication & user domain
	•	tasks/ — Personal tasks
	•	projects/ — Projects & project tasks
	•	collaborations/ — Collab domain, chat, and UI
	•	profile/ — Profile & settings
	•	lib/src/models/ — Firestore repository, domain models
	•	lib/theme.dart — App-wide theming


### Author

**Shokri Francis Raoof**
Built as a portfolio project to demonstrate Flutter, and Firebase integrations.


### License

MIT License – feel free to fork and experiment.
