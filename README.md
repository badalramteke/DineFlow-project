# 🍽️ DineFlow - Smart Restaurant Management System

**DineFlow** is a comprehensive, AI-powered restaurant management ecosystem designed to streamline operations, enhance customer experience, and provide real-time insights for restaurant owners. It bridges the gap between customers, the kitchen, and management through a seamless, real-time digital interface.

---

## 🚩 The Problem

Traditional restaurant operations often suffer from:

- **Inefficient Ordering:** Waiters running back and forth, leading to delays and errors.
- **Lack of Personalization:** Customers struggle to choose dishes without guidance.
- **Communication Gaps:** Miscommunication between the dining area and the kitchen.
- **Data Silos:** Owners lack real-time visibility into sales, inventory, and customer feedback.
- **Static Menus:** Physical menus are hard to update and don't reflect real-time availability.

## 💡 The Solution

**DineFlow** digitizes the entire dining lifecycle:

1.  **QR-Based Ordering:** Customers scan a QR code to access a digital menu and place orders directly.
2.  **AI Foodie Guide:** An integrated AI chatbot (powered by **Google Gemini**) helps customers choose meals based on budget, taste, and group size.
3.  **Real-Time Kitchen Display:** Orders flash instantly in the kitchen, reducing wait times.
4.  **Manager Dashboard:** A mobile app for owners to manage menus, track sales, and view analytics on the go.

---

## 🏗️ Tech Stack & Google Technologies

We leverage the power of the Google ecosystem to deliver a robust solution:

- **🧠 AI & ML:**

  - **Google Gemini API (1.5 Flash):** Powers the "AI Foodie Guide" for natural language recommendations and structured order parsing.
  - **Google AI Studio:** For prompt engineering and model management.

- **☁️ Backend & Infrastructure:**

  - **Firebase Firestore:** Real-time NoSQL database for instant order syncing.
  - **Firebase Authentication:** Secure login for restaurant managers.
  - **Firebase Hosting:** Fast, global hosting for the Web Client and Kitchen Dashboard.

- **📱 Frontend & Mobile:**
  - **Flutter:** High-performance Android app for the Manager Dashboard.
  - **React.js (Vite):** Responsive web application for the Customer Menu and Kitchen Display.
  - **Google Fonts:** Modern typography (Poppins/Inter).

---

## 📂 Project Structure

```
DineFlow-Project/
├── client/                 # Web Application (React + Vite)
│   ├── src/
│   │   ├── pages/
│   │   │   ├── CustomerMenu.jsx    # Customer Ordering Interface
│   │   │   ├── KitchenDashboard.jsx # Kitchen Display System (KDS)
│   │   │   ├── Checkout.jsx        # Order Status & Bill
│   │   │   └── ...
│   │   ├── components/             # Reusable UI Components
│   │   └── firebase.js             # Firebase Configuration
│   └── ...
│
├── dineflow_manager/       # Mobile Application (Flutter)
│   ├── lib/
│   │   ├── features/
│   │   │   ├── auth/               # Login/Signup
│   │   │   ├── dashboard/          # Analytics & Overview
│   │   │   ├── menu/               # Menu Management (CRUD)
│   │   │   ├── orders/             # Order Management
│   │   │   ├── settings/           # App Settings & Reviews
│   │   │   └── ...
│   │   ├── core/                   # Theme, Constants, Utils
│   │   └── main.dart               # App Entry Point
│   └── ...
│
├── firebase.json           # Firebase Hosting Config
└── firestore.rules         # Database Security Rules
```

---

## ✨ Key Features

### 📱 Customer Web App (Client)

- **QR Code Access:** No app download required; works instantly via browser.
- **AI Foodie Guide (Gemini):**
  - Chat with an AI waiter.
  - Ask queries like _"Suggest a meal for 3 under ₹3000"_.
  - Auto-adds recommended items to the cart.
- **Smart Menu:**
  - Filter by Veg/Non-Veg and Categories.
  - Search functionality.
  - Real-time availability status.
- **Live Order Tracking:**
  - View order status: _Pending -> Cooking -> Ready_.
  - Cancel items before the chef starts cooking.
- **Review System:**
  - Post-payment popup to rate **Service** and **Food** separately.
  - Smart logic ensures only valid, recent customers can review.

### 👨‍🍳 Kitchen Dashboard (Web)

- **Real-Time KDS:** Orders appear instantly as they are placed.
- **Status Management:** Chefs can mark items as _Cooking_ or _Ready_.
- **Table Organization:** Orders are grouped by table for clarity.

### 📱 Manager App (Flutter)

- **Dashboard:**
  - View total sales, active orders, and daily revenue.
  - Visual charts for sales trends.
- **Menu Management:**
  - Add, edit, or delete menu items.
  - Upload food images.
  - Toggle item availability (In Stock / Out of Stock).
- **Order Management:**
  - View all active and past orders.
  - Update payment status (Pending -> Paid).
- **Customer Reviews:**
  - View detailed feedback with Service vs. Food ratings.
  - Track overall restaurant rating.
- **QR Code Generation:**
  - Generate unique QR codes for each table.

---

## 🔄 User Flow

1.  **Manager Setup:**

    - Manager logs into the Flutter app.
    - Adds menu items and sets up tables.
    - Prints QR codes for tables.

2.  **Customer Ordering:**

    - Customer scans QR code at the table.
    - Browses menu or asks AI for suggestions.
    - Adds items to cart and places order.

3.  **Kitchen Processing:**

    - Order flashes on the Kitchen Dashboard.
    - Chef marks status as "Cooking" -> "Ready".
    - Customer sees status update on their phone.

4.  **Payment & Review:**
    - Customer requests bill / pays at counter.
    - Manager marks order as "Paid".
    - Customer gets a popup to rate the food and service.

---

## 🚀 Getting Started

### Prerequisites

- Node.js & npm
- Flutter SDK
- Firebase Account

### Installation

**1. Web Client (React)**

```bash
cd client
npm install
# Create .env file with VITE_GEMINI_API_KEY
npm run dev
```

**2. Manager App (Flutter)**

```bash
cd dineflow_manager
flutter pub get
flutter run
```

---

## 🤝 Contributors

- **Badal Ramteke** - _Lead Developer_
- **Vansh shende** - _developer_

---

_Built with ❤️ for the Google AI Hackathon_
