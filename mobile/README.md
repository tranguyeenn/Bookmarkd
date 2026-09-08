# ShelfTxt Mobile Client (Flutter)

A cross-platform mobile client for **ShelfTxt**, built using Flutter. It connects to the ShelfTxt REST API (`GET /books`, `POST /books`, `PATCH /books/{id}`) for library management, reading progress tracking, and search on iOS and Android.

---

## Features

- **Personal Library**: View all books with cover images, status badges, and reading progress bars.
- **Status Filter Tabs**: Filter books by *All*, *Reading*, *Want to Read*, and *Completed*.
- **Live Search**: Instant client-side search across titles and authors.
- **Add New Book**: Dialog to add custom books directly to your personal library.
- **Configurable Server**: Easily change or test the backend URL from the in-app server settings dialog.
- **Robust Error Handling**: Friendly error and empty states with retry triggers.

---

## Getting Started

### 1. Start the ShelfTxt Backend

From the repository root:

```bash
pip install -r requirements.txt
uvicorn api:app --reload
```

The backend will start at `http://127.0.0.1:8000`.

---

### 2. Run the Mobile App

From the `mobile/` directory:

```bash
flutter pub get
flutter run
```

To configure a custom backend host (e.g. Android emulator):

```bash
flutter run --dart-define=SHELFTXT_BASE_URL=http://10.0.2.2:8000
```

---

### 3. Run Tests

```bash
flutter test
```
