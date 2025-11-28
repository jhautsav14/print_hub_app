# 🖨️ Print App – Code Walkthrough for Students

A simple explanation of how the **Print App** works. This app allows users to **upload PDFs**, **choose print settings** (Color/B&W, Copies), and **send the order to Supabase**.

---

## 1. 🚀 Entry Point — `main.dart`

### **What it does**

This is the **entry point** of the app — the first file that runs when you open the app.

### **Important parts**

* **Supabase.initialize()**: Connects to the cloud backend (Supabase) using a URL + Secret Key. This allows the app to save orders and files online.
* **runApp(const MyApp())**: Starts the Flutter UI.
* **MaterialApp()**: Sets the theme (colors, fonts) and loads the first screen → `PrintHomeScreen`.

---

## 2. 🧱 Blueprint — `models/print_document.dart`

### **What it does**

Defines a **class** (a data model) for every document the user uploads.

### **Properties**

Each `PrintDocument` stores:

* `name` – File name
* `pageCount` – Number of pages
* `settings` – User-chosen options such as Copies, Double-sided/Single-sided, Color/Black & White

### **Why it matters**

Instead of passing many variables around, we store all details in **one object**.

---

## 3. 🛠️ Worker Layer — `services/pdf_service.dart`

### **What it does**

A helper service that handles reading files and extracting PDF information.

### **pickAndProcessDocument()**

1. Opens file picker → user selects a PDF
2. Reads file bytes
3. **Generates a thumbnail** (using `printing` package)
4. **Counts the pages** (using `syncfusion_flutter_pdf`)

This prepares everything needed for the UI.

---

## 4. 📄 Main Screen — `screens/home_screen.dart`

### **What it does**

This is the screen where the user spends most time.

### **Key Components**

* **State (List of _documents)**: Stores all PDFs the user has added.
* **_selectedIndex**: Remembers which document is being edited.

### **Price Calculation**

Automatically calculates:

```
Total Price = Price Per Page × Page Count × Copies
```

### **UI Sections**

* **Top** → List of added documents
* **Middle** → Settings (Color/B&W, Orientation, Copies...)
* **Bottom** → Shows total price + "Add to Cart" button

---

## 5. 🛒 Checkout — `screens/cart_summary_screen.dart`

### **Purpose**

Shows the cart summary and handles **uploading the order** to Supabase.

### **Most important function: `_handlePlaceOrder()`**

Uploads everything in **3 steps**:

#### 1️⃣ Create Order

Creates a new row in the `orders` table (database returns an `order_id`).

#### 2️⃣ Upload Files

Loops through all PDFs and uploads each to **Supabase Storage**.

#### 3️⃣ Save Details

Adds rows to the `order_items` table for each file, including Copies, Settings, and linked `order_id`.

---

## 6. 📜 Order History — `screens/orders_list_screen.dart`

### **What it does**

Loads past orders so the user can view their history.

### **Logic**

* **_fetchOrders()**: Fetches rows from the `orders` table, sorted newest → oldest.
* **FutureBuilder**:

  * Shows loading spinner while waiting
  * Displays orders when ready

### **Status Colors**

* Green → Delivered
* Orange → Pending

---

## 7. 🔍 Order Details — `screens/order_detail_screen.dart`

### **What it does**

Shows the contents of a selected order.

### **How it works**

Queries Supabase:

> “Show me all items where `order_id` = the one the user clicked.”

Displays:

* File name
* Copies
* Color/B&W
* Print settings

---

# 🔁 Summary of Full Data Flow

```
User picks PDF
       ↓
Service processes PDF (thumbnail, page count)
       ↓
Home Screen adds it to document list
       ↓
User edits settings
       ↓
User places order → Cart Screen uploads files + details to Supabase
       ↓
User can view past orders → History screen
```

---
