# Smart College Attendance & Automatic WhatsApp Notification System

A responsive, production-ready full-stack web application designed for collegiate institutions. The system enables faculty to manually mark attendance and automatically triggers real-time WhatsApp notifications to registered parents of absent students using the **Official Meta WhatsApp Business Cloud API**.

---

## 1. System Architecture & Data Flow

```
                                +---------------------------+
                                |      Faculty / Admin      |
                                |   (Responsive Web UI)     |
                                +-------------+-------------+
                                              |
                                     HTTP POST / JSON
                                              |
                                              v
+-----------------------------------------------------------------------------------+
|                           Flask Application Server                                 |
|                                                                                   |
|  [Authentication & RBAC]         [Academic Services]         [Audit & Logging]     |
|   - Flask-Login                   - Attendance Tracker        - Security Events   |
|   - Werkzeug Hash                 - Excel / PDF Exporters     - System Audits     |
|                                                                                   |
|                              [WhatsApp Cloud Service]                             |
|                               - Phone Normalization (E.164)                       |
|                               - Parental Consent Verification                     |
|                               - Duplicate Alert Suppression                       |
|                               - Exponential Backoff Retries                       |
+-------------------------------------+---------------------------------------------+
                                      |
                     +----------------+----------------+
                     |                                 |
                     v                                 v
        +-------------------------+       +-------------------------+
        |   MySQL 8.0 / MariaDB   |       |  Meta WhatsApp Cloud API|
        |  (Normalized Relational |       | (Official Graph v19.0)  |
        |   Storage with Foreign  |       |                         |
        |    Keys and Indexes)    |       |  -> Registered Parents  |
        +-------------------------+       +-------------------------+
```

---

## 2. Technology Stack

- **Frontend**: HTML5, CSS3, JavaScript (ES6+), Bootstrap 5.3, Bootstrap Icons
- **Backend**: Python 3.10+ with Flask Framework
- **ORM & Database**: Flask-SQLAlchemy, PyMySQL, MySQL / MariaDB (UTF8mb4)
- **WhatsApp Integration**: Official Meta WhatsApp Business Cloud API (`v19.0`)
- **Authentication**: Flask-Login with custom role-based access decorators (`@admin_required`, `@teacher_required`)
- **Password Security**: Werkzeug password hashing (Scrypt / PBKDF2)
- **CSRF Protection**: Flask-WTF CSRFProtect
- **Reporting Engine**: `openpyxl` (Excel .xlsx with customized styling) & `reportlab` (Printable vector PDF)

---

## 3. Project Directory Structure

```
smart_college_attendance/
│
├── app.py                      # Application factory, CLI commands & blueprints
├── config.py                   # Environment configuration loader
├── requirements.txt            # Pinned Python package dependencies
├── .env.example                # Sample environment configuration template
├── .env                        # Active local configuration file
├── database.sql                # Complete MySQL DDL schema and seed records
├── run.py                      # Root launcher script
│
├── models/                     # SQLAlchemy ORM Database Models
│   ├── __init__.py             # Database instance and model exports
│   ├── user.py                 # User authentication model & Flask-Login UserMixin
│   ├── academic.py             # Course, ClassModel, Subject, TeacherAssignment
│   ├── teacher.py              # Teacher faculty profile linked to User
│   ├── student.py              # Student record with parent details & consent
│   ├── attendance.py           # Attendance record (enforces unique session rule)
│   ├── whatsapp.py             # WhatsApp delivery audit log
│   └── audit.py                # System-wide administrative security audit log
│
├── routes/                     # Blueprint Route Controllers
│   ├── __init__.py             # Role decorators (@admin_required, @teacher_required)
│   ├── auth.py                 # Sign-in, sign-out, and password updates
│   ├── admin.py                # Admin dashboard, students/teachers/academics CRUD
│   ├── teacher.py              # Faculty dashboard, attendance marking & roster
│   ├── reports.py              # Daily, monthly, student percentage & WhatsApp reports
│   └── api.py                  # Dynamic cascading dropdown JSON endpoints
│
├── services/                   # Core Business Logic & External Integrations
│   ├── __init__.py             # Service package exports
│   ├── whatsapp_service.py     # Official Meta WhatsApp Cloud API client
│   ├── report_service.py       # OpenPyXL and ReportLab export generators
│   └── audit_service.py        # Centralized audit logging utility
│
├── templates/                  # Jinja2 HTML5 Templates
│   ├── base.html               # Master layout (sidebar, topbar, responsive nav)
│   ├── auth/
│   │   ├── login.html          # Clean sign-in page with quick demo login pills
│   │   └── profile.html        # User profile and change password
│   ├── admin/
│   │   ├── dashboard.html      # Admin dashboard with stat cards & WhatsApp metrics
│   │   ├── students.html       # Student management table with filters
│   │   ├── student_form.html   # Add/Edit student form with WhatsApp consent
│   │   ├── teachers.html       # Teacher directory
│   │   ├── teacher_form.html   # Add/Edit teacher with auto-account generation
│   │   ├── courses_classes.html# Courses, classes, and subjects management
│   │   ├── assignments.html    # Assign teachers to classes and subjects
│   │   ├── attendance.html     # Historical attendance records
│   │   ├── whatsapp_logs.html  # WhatsApp message history with JSON inspector
│   │   └── audit_logs.html     # Security and activity audit trail
│   ├── teacher/
│   │   ├── dashboard.html      # Teacher dashboard with assigned class cards
│   │   ├── mark_attendance.html# Interactive attendance marking sheet
│   │   └── view_attendance.html# Historical attendance taken by faculty
│   └── reports/
│       ├── index.html          # Central reports hub
│       ├── daily.html          # Daily attendance report with Excel & PDF download
│       ├── monthly.html        # Monthly matrix report
│       ├── student_summary.html# Student attendance % report with shortage filter
│       └── whatsapp_report.html# WhatsApp delivery report with Excel download
│
├── static/                     # Static Web Assets
│   ├── css/
│   │   └── style.css           # Custom college theme, status badges & variables
│   └── js/
│       ├── main.js             # Sidebar toggles, auto-dismiss alerts, modal logic
│       └── attendance.js       # Interactive attendance shortcuts & live counters
│
├── tests/                      # Automated Test Suite
│   └── test_attendance.py     # Unittest suite testing auth, WhatsApp, & reports
│
└── reports/                    # Temp storage for generated file exports
```

---

## 4. Database Schema Design

The system runs on a relational MySQL / MariaDB database (`smart_attendance`):

1. **`users`**: Authentication credentials (`username`, `email`, `password_hash`, `role` ['admin', 'teacher'], `is_active`, `created_at`, `updated_at`).
2. **`courses`**: Academic degree programs (`course_name`, `course_code` UNIQUE, `description`).
3. **`classes`**: Student cohorts (`class_name`, `course_id` FK, `section`, `academic_year`). Unique constraint on `(course_id, class_name, section, academic_year)`.
4. **`subjects`**: Course curriculum (`subject_name`, `subject_code` UNIQUE, `course_id` FK).
5. **`teachers`**: Faculty profile (`user_id` FK UNIQUE, `employee_id` UNIQUE, `full_name`, `email` UNIQUE, `phone`, `department`, `qualification`).
6. **`teacher_assignments`**: Mapping of faculty authorization (`teacher_id` FK, `class_id` FK, `subject_id` FK, `academic_year`).
7. **`students`**: Complete student data (`student_id_code` UNIQUE, `full_name`, `roll_number`, `course_id` FK, `class_id` FK, `parent_name`, `parent_phone`, `whatsapp_consent` BOOLEAN, `admission_date`, `status` ['Active', 'Inactive', 'Suspended']).
8. **`attendance`**: Daily session attendance (`student_id` FK, `class_id` FK, `subject_id` FK, `teacher_id` FK, `attendance_date`, `status` ['PRESENT', 'ABSENT', 'LATE'], `remarks`).
   - **Enforced Rule**: Unique constraint on `(student_id, class_id, subject_id, attendance_date)`. Re-submitting updates the record without duplicate rows.
9. **`whatsapp_logs`**: Outbound WhatsApp notifications audit trail (`attendance_id` FK, `student_id` FK, `recipient_phone`, `parent_name`, `template_name`, `message_id`, `status` ['SENT', 'FAILED', 'SKIPPED'], `request_payload`, `response_payload`, `error_message`, `retry_count`, `sent_at`).
10. **`audit_logs`**: Administrative and security event logs (`user_id` FK, `username`, `role`, `action`, `details`, `ip_address`, `created_at`).

---

## 5. Official Meta WhatsApp Business Cloud API Setup

### Step 5.1: Create Meta Developer App
1. Go to the [Meta for Developers Portal](https://developers.facebook.com/) and log in.
2. Click **My Apps** > **Create App**.
3. Select **Other** as use case, and choose **Business** app type.
4. Name the application (e.g. `Apex College Attendance`) and link your Meta Business Account.

### Step 5.2: Configure WhatsApp Product
1. Under **Add products to your app**, locate **WhatsApp** and click **Set up**.
2. Navigate to **WhatsApp** > **API Setup** from the left navigation menu.
3. You will see:
   - **Phone number ID** (e.g. `109876543210987`)
   - **WhatsApp Business Account ID** (e.g. `102938475610293`)
   - **Temporary Access Token** (or create a permanent System User Token under Business Settings > System Users with `whatsapp_business_messaging` permission).

### Step 5.3: Register Message Template
1. Under **WhatsApp** > **Message Templates**, click **Create Template**.
2. Template Configuration:
   - **Category**: Utility
   - **Name**: `student_absent_notification`
   - **Language**: English (US) (`en_US`)
3. Body text format:
```text
Dear Parent,

This is to inform you that your ward {{1}} was marked ABSENT today.

Student Name: {{1}}
Roll Number: {{2}}
Class: {{3}}
Subject: {{4}}
Date: {{5}}
Attendance Status: ABSENT

Regards,
College Administration.
```
4. Save and submit for Meta approval (utility templates are usually approved within minutes).

### Step 5.4: WhatsApp Service Rules in Code
- **Consent Verification**: If `student.whatsapp_consent` is `False`, the service automatically skips dispatch and logs `SKIPPED: Parent has not opted in for WhatsApp alerts`.
- **Duplicate Prevention**: Before sending, the service queries `whatsapp_logs` for an existing `SENT` alert for that student on that date. If one exists, duplicate alerts are blocked.
- **Phone Formatting**: Cleans parent numbers to international E.164 standard (e.g., `+91 98765-43210` becomes `919876543210`).
- **Resilient Retries**: Automatic 3-attempt exponential backoff retry for HTTP `429`, `500`, `502`, `503`, and `504` status codes.
- **Simulation Mode**: By default, `WHATSAPP_SIMULATION_MODE=True` is provided so you can run, mark attendance, and inspect realistic WhatsApp audit logs immediately without requiring active Meta credit card setup. Set `WHATSAPP_SIMULATION_MODE=False` in `.env` when deploying with live tokens!

---

## 6. Installation & Execution Guide

### Prerequisites
- Python 3.10 or higher
- MySQL 8.0 or MariaDB (via XAMPP, Laragon, Docker, or native installer)

### Step 1: Clone or Navigate to the Project
```bash
cd smart_college_attendance
```

### Step 2: Install Python Dependencies
```bash
pip install -r requirements.txt
```

### Step 3: Configure Database & Environment
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Edit `.env` to match your MySQL database credentials:
```ini
DATABASE_URL=mysql+pymysql://root:@localhost:3306/smart_attendance?charset=utf8mb4
```

### Step 4: Import Database Schema & Seed Data
You can initialize the database using the provided `database.sql` script:
```bash
# Using MySQL Command Line or phpMyAdmin
mysql -u root -p < database.sql
```
*(Alternatively, you can run `flask init-db` and `flask seed-db` inside the project folder).*

### Step 5: Start the Web Application
```bash
python app.py
```
Or run from the project root:
```bash
python run.py
```
Open your browser and navigate to:
```
http://localhost:5000
```

---

## 7. Default Credentials & Roles

| Role | Username | Password | Notes |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin` | `Admin@123` | Full access to student, teacher, academic, and report management |
| **Teacher 1** | `prof.smith` | `Teacher@123` | Assigned to B.Tech CSE (Sec A) - DBMS & OS |
| **Teacher 2** | `dr.sharma` | `Teacher@123` | Assigned to B.Tech CSE (Sec A & B) - Web Tech & DBMS |

*(Note: The login page includes convenient click-to-fill buttons for quick testing).*

---

## 8. User Guides & Testing Workflows

### A. Teacher Workflow (Mark Attendance & WhatsApp Trigger)
1. Sign in as `prof.smith` / `Teacher@123`.
2. On the Faculty Dashboard, click **Mark Attendance Today**.
3. Select:
   - **Class**: `B.Tech CSE - 3rd Year - Sec A (2026-2027)`
   - **Subject**: `CS301 — Database Management Systems`
   - **Date**: Today's Date
4. Click **Load Roster**.
5. All students enrolled in Section A will appear with their roll numbers, names, and parent details.
6. Use the batch shortcut **"Mark All Present"**, then toggle 1 or 2 students to **"A" (Absent)**.
7. Click **"Save Attendance & Dispatch Alerts"**.
8. A confirmation dialog will summarize the absent students and warn you that WhatsApp alerts will be dispatched.
9. Upon submission:
   - Attendance records are committed to MySQL.
   - The WhatsApp service dispatches templates for the absent students.
   - For students with consent, message IDs (`wamid...`) are recorded.
   - For students without consent, a `SKIPPED` log is registered.
   - You are redirected to the session history showing the submitted session.

### B. Admin Workflow (Monitoring & Management)
1. Sign in as `admin` / `Admin@123`.
2. **Dashboard**: View high-level statistics, today's attendance percentage, and real-time WhatsApp delivery counts.
3. **Students**: Add or edit student records, modify parent WhatsApp numbers, or toggle consent status.
4. **Faculty Assignments**: Assign or revoke teacher class/subject authorizations.
5. **WhatsApp History**: Inspect every outbound notification, review delivery status (`SENT`, `SKIPPED`, `FAILED`), and click **"View JSON"** to inspect raw Meta API payloads.
6. **Reports**:
   - **Daily Report**: View breakdown and download as styled **Excel (.xlsx)** or **PDF (.pdf)**.
   - **Monthly Report**: Check monthly attendance percentages per student.
   - **Student Attendance %**: Filter defaulter students (e.g. attendance below 75%) and export to Excel.

---

## 9. Automated Test Suite

Run the automated integration and unit test suite anytime:
```bash
python -m unittest tests/test_attendance.py
```
This tests:
1. Admin and teacher authentication with Werkzeug password hashing.
2. Full login flow and CSRF token verification.
3. WhatsApp notification consent checks and duplicate suppression.
4. Real-time generation of Excel workbooks and vector PDF reports.
