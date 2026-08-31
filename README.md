# PlateRoute Courier Mobile Application

Production-ready, high-performance Flutter mobile application for the **PlateRoute** food delivery platform, designed specifically for **Delivery Riders**. Built with real-time tracking, background location services, and efficient order management.

---

## 1. Architectural Overview & Design System

### 1.1 Architecture
The application is structured using **Feature-First Clean Architecture** powered by **Riverpod 2.x**:
- `lib/core/`: Networking (`ApiClient`, `WebSocketClient`), Location (`LocationService`, `BackgroundTracker`), Router (`GoRouter`), and Storage.
- `lib/features/`: Isolated feature modules such as `auth`, `offers`, `active_task`, `earnings`, and `profile`.

### 1.2 Design Tokens & Rules
- **Color Palette:**
  - **Plate Blue** (`#2563EB` light / `#60A5FA` dark) as Primary brand token.
  - **Success Green** (`#10B981`) for completed tasks and active states.
  - Dark Canvas (`#0A0F1D`) and Dark Surface (`#121B2E`) optimized for outdoor visibility.
- **Typography & Tabular Figures:** Proportional Inter font for text, with `FontFeature.tabularFigures()` applied to all earnings and distance displays.

---

## 2. Core Features & Screen Catalog

| Module | Feature Description |
| :--- | :--- |
| **Auth** | Secure login for vetted couriers, token verification, and session bootstrap. |
| **Dashboard** | Home screen displaying online/offline toggle, current earnings, and today's stats. |
| **Offers** | Incoming delivery offer cards with pickup/dropoff map preview, distance, and estimated payout. |
| **Active Task** | Step-by-step active order tracking (Navigate to Vendor -> Pickup -> Navigate to Customer -> Dropoff). |
| **Navigation** | Interactive map integration for real-time routing to pickup and dropoff locations. |
| **Earnings** | Detailed wallet and earnings breakdown (daily, weekly, historical payouts). |
| **Profile** | Rider profile management, vehicle details, and settings. |

---

## 3. Technology Stack

- **Flutter SDK:** `>=3.3.0 <4.0.0`
- **State Management:** `flutter_riverpod: ^2.5.1`
- **Routing:** `go_router: ^14.2.0`
- **Networking:** `dio: ^5.4.3+1` & `web_socket_channel: ^3.0.0`
- **Location:** `geolocator` & background tracking services.
- **Mapping:** `flutter_map` (OpenStreetMap / CartoDB tiles).

---

## 4. Environment & Getting Started

1. Clone repository and navigate to workspace:
   ```bash
   cd apps/courier
   ```

2. Setup Environment:
   ```bash
   cp .env.example .env
   # Edit values (dev defaults point at 10.0.2.2 emulator host)
   ```

3. Fetch Flutter packages:
   ```bash
   flutter pub get
   ```

4. Run in development environment:
   ```bash
   flutter run
   ```

> **Note:** Implementation plan and internal technical documentation lives in `docs/IMPLEMENTATION_PLAN.md`.
