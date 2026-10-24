# Production Deployment & Firebase Configuration Guide

## LuxeStore — Production-Grade Flutter E-Commerce Application

This guide contains deployment instructions, Firestore security policies, composite index configurations, and testing credentials for **LuxeStore**.

---

## 1. Quick Start & Testing Credentials

The application includes an embedded, high-fidelity offline/sandbox engine that functions immediately out-of-the-box before connecting your live Firebase project.

### Pre-Configured Test Accounts

| Role | Email Address | Password | Permissions |
| :--- | :--- | :--- | :--- |
| **Customer** | `customer@example.com` | `Customer@1234` | Browse, Cart, Address Management, Order Placement, UPI QR Payment Submission, Order Tracking |
| **Administrator** | `admin@luxestore.com` | `Admin@1234` | Verification Console, UTR & Screenshot Verification, Approval/Rejection, Order Fulfillment Transitions, Inventory Management, UPI QR Configuration |

*(Quick-fill buttons are provided on the Login screen for instant testing).*

---

## 2. Live Firebase Project Setup (Connected: `iplteams-6eb14`)

The application is now connected with your `google-services.json`:
- **Firebase Project ID:** `iplteams-6eb14`
- **Project Number / Sender ID:** `29343418210`
- **Storage Bucket:** `iplteams-6eb14.firebasestorage.app`
- **Android Package:** `com.example.ecommerce_app`

### Step 1: Enable Firebase Authentication
1. Go to **Firebase Console** -> [iplteams-6eb14](https://console.firebase.google.com/project/iplteams-6eb14/overview) -> **Authentication** -> **Sign-in method**.
2. Enable **Email/Password**.

### Step 2: Deploy Cloud Firestore Security Rules & Indexes
```bash
firebase deploy --project=iplteams-6eb14 --only firestore:rules,firestore:indexes
```

### Step 3: Deploy Firebase Storage Security Rules
```bash
firebase deploy --project=iplteams-6eb14 --only storage:rules
```

---

## 3. Database Schema Overview

```
├── users/ (Collection)
│   └── {userId}/ (Document: email, fullName, phoneNumber, role, createdAt)
│       └── addresses/ (Subcollection: fullName, streetAddress, city, state, pinCode, isDefault)
│
├── categories/ (Collection: name, slug, icon, isActive, productCount, createdAt)
│
├── products/ (Collection: name, description, categoryId, categoryName, sellingPrice, originalPrice, stockQuantity, images, isFeatured, isActive)
│
├── carts/ (Collection)
│   └── {userId}/ (Document: items[{productId, quantity, unitPrice, availableStock}], updatedAt)
│
├── orders/ (Collection)
│   └── {orderId}/ (Document: customerId, customerName, items, shippingAddress, subtotal, gstAmount, deliveryFee, totalAmount, status, utrNumber, paymentScreenshotUrl, paymentRejectionReason, createdAt, updatedAt, verifiedAt)
│
├── payment_settings/ (Collection)
│   └── default (Document: upiId, receiverName, qrImageUrl, instructions, updatedAt, updatedBy)
│
├── payment_submissions/ (Collection)
│   └── {submissionId}/ (Document: orderId, customerId, customerName, amount, utrNumber, screenshotUrl, status, rejectionReason, submittedAt, verifiedAt, verifiedBy)
│
└── audit_logs/ (Collection: action, orderId, adminId, previousStatus, newStatus, reason, utrNumber, timestamp)
```

---

## 4. Manual UPI QR Payment Verification & Security Architecture

### Why Manual Verification Is More Secure
1. **Never Automatically Mark Paid:** Automated webhook integrations with third-party gateways are bypassed; manual payments are strictly marked as **Payment Verification Pending** (`payment_verification_pending`).
2. **Independent Bank Check:** An order is only fulfilled once the admin cross-references the submitted 12-digit UTR with the merchant bank statement.
3. **Price Freezing:** Every order creates an immutable snapshot of `OrderItemModel` with frozen unit prices, delivery fee, and GST calculations at checkout time. Future price changes do not alter existing orders.
4. **Concurrency-Safe Stock Deduction:** Stock deductions are executed using Firestore atomic transactions (`runTransaction`), preventing overselling and ensuring stock never becomes negative during concurrent checkouts.
5. **Audit Logging:** Every approval or rejection is recorded immutably in the `audit_logs` collection.

---

## 5. Running the Application

### Running Automated Test Suite
```bash
flutter test
```
*Executes all 14 unit and widget tests (cart calculations, 18% GST formula, free delivery threshold, order state machine transitions, inventory atomic deduction, and smoke tests).*

### Running on Device / Emulator
```bash
flutter run
```
