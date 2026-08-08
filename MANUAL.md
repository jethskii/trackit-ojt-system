# TRACKIT — Student Module Manual

**TRACKIT** (Centralized OJT Tracking and Documentation System) is a capstone
project for DCSE at Dalubhasaan ng Lungsod ng San Pablo. This manual covers
everything built so far: the **Student Module** (Flutter, mobile) and its
real backend (Node/Express + PostgreSQL on Neon). The Instructor and Admin
modules are not built yet — see [What's Not Built Yet](#whats-not-built-yet).

---

## 1. Tech Stack

| Layer | Technology |
|---|---|
| Mobile app (Student) | Flutter, Material 3 |
| Backend API | Node.js + Express |
| Database | PostgreSQL (hosted on Neon, serverless) |
| Auth | JWT (`jsonwebtoken`) + `bcrypt` password hashing |
| File uploads | `multer` (avatars, requirement docs) |
| Device location | `geolocator` (Attendance geofencing) |
| Client state | `flutter_secure_storage` (JWT token), `ChangeNotifier` (notifications badge) |

**Why this stack:** Flutter was chosen so the Student and Instructor mobile
apps — and eventually an Admin web dashboard — can share the same Dart
codebase (Flutter Web) instead of maintaining separate frontends. Express +
PostgreSQL is a conventional, well-documented combination that's easy for a
small team to run and deploy, and Neon gives free serverless Postgres
hosting with no server to manage.

---

## 2. Project Structure

```
trackit-ojt-system/
├── package.json              # root convenience script: `npm start` from anywhere
├── run-app.ps1                # convenience script: launches Flutter regardless of cwd
└── trackit_app/
    ├── lib/
    │   ├── main.dart           # launches AuthGate
    │   ├── models/             # plain Dart data classes (Student, OjtProgress, ...)
    │   ├── services/           # repository-style API clients (Http*Service)
    │   ├── screens/
    │   │   ├── auth/           # login / register
    │   │   └── student/        # Home, Attendance, Documents, Notifications, Profile
    │   ├── widgets/
    │   │   ├── common/         # shared UI (headers, badges, empty states, skeletons)
    │   │   └── student/        # feature-specific widgets
    │   └── utils/               # app_colors.dart, location_helper.dart
    └── server/
        ├── index.js             # Express app entry point
        ├── db.js                # PostgreSQL connection pool
        ├── middleware/auth.js   # JWT verification
        ├── routes/               # one file per resource
        └── sql/
            ├── schema.sql                                  # run first
            ├── schema_notifications_profile.sql
            ├── migration_company_details_remarks.sql
            ├── migration_attendance_geofence_corrections.sql
            ├── migration_ojt_start_date.sql
            ├── migration_weekly_accomplishment_reports.sql
            ├── migration_instructor_auth_and_dashboard.sql
            ├── migration_instructor_classes.sql
            ├── migration_teacher_notifications_announcements.sql
            ├── migration_teacher_documents.sql
            ├── migration_announcement_images.sql
            ├── migration_attendance_daily_attempts.sql
            ├── migration_student_profile_enhancements.sql
            └── migration_admin.sql                          # run last
```

Every feature follows the same pattern: a Dart **model**, an abstract
**service interface** with an `Http*Service` implementation that calls the
real API, a **screen**, and small reusable **widgets**. Nested nav ("Tab
Navigators") are used inside the Document, Attendance, and Profile tabs so
pushing a sub-screen keeps the bottom nav bar visible.

---

## 3. Running It

### Server
```powershell
# from the repo root, works from anywhere thanks to package.json
npm start
```
Requires `trackit_app/.env` (see `trackit_app/.env.example`) with
`DATABASE_URL`, `JWT_SECRET`, `PORT`, `NODE_ENV`.

### Database setup (Neon SQL Editor, in order)
1. `schema.sql`
2. `schema_notifications_profile.sql`
3. `migration_company_details_remarks.sql`
4. `migration_attendance_geofence_corrections.sql`
5. `migration_ojt_start_date.sql`
6. `migration_weekly_accomplishment_reports.sql`
7. `migration_instructor_auth_and_dashboard.sql`
8. `migration_instructor_classes.sql`
9. `migration_teacher_notifications_announcements.sql`
10. `migration_teacher_documents.sql`
11. `migration_announcement_images.sql`
12. `migration_attendance_daily_attempts.sql`
13. `migration_student_profile_enhancements.sql`
14. `migration_admin.sql`

All migrations are non-destructive (`ADD COLUMN IF NOT EXISTS`, etc.) and
safe to re-run.

### App
```powershell
# from the repo root
.\run-app.ps1
# or manually:
cd trackit_app
flutter pub get
flutter run -d chrome
```

---

## 4. Features

### 4.1 Authentication
- Register / Login with email + password (`bcrypt` hashed).
- JWT issued on login, stored via `flutter_secure_storage`, attached to
  every API request as a bearer token.
- `AuthGate` decides whether to show the login flow or the Student Shell
  based on whether a valid token is stored.

### 4.2 Home Tab
- **Profile card**: student name, program, section.
- **Company card**: shows a muted **"Not yet deployed"** placeholder until
  the student completes *Confirm Company Details*; once confirmed, shows
  the company name with a logo-style icon avatar (there's no real logo
  upload — this is a generic building-icon avatar consistent with the
  rest of the app's avatar style).
- **OJT Hours Progress**: completed/total hours, percentage bar, days
  attended, estimated completion date, average hours/day, weekly average.
- **Status badge**: **On Track / Behind / Needs Attention / Ahead of
  Schedule**, computed server-side from the student's **OJT Start Date**
  (self-reported) against an assumed standard pace (8 hrs/weekday), plus a
  "Needs Attention" trigger if there's been no clock-in for 7+ days. Once
  hours reach the requirement, it becomes a **"Completed — Total Hours
  Attended: X hrs"** banner.
- **Latest Announcement/Notification preview**: the 3 most recent
  notifications (real data, shared with the Notifications tab), tap to
  mark read and jump to the relevant tab, "See All" to open Notifications.

### 4.3 Attendance Tab
- **OJT Hours Progress** summary (mirrors Home).
- **Today's Attendance**: clock-in time, clock-out time, total hours for
  the day, and an overall status pill (Completed / Ongoing / Unavailable).
- **Clock In / Clock Out**: captures the device's GPS position and sends
  it to the server, which rejects the request if the student is more than
  **100 meters** from their company's saved location, or if that location
  hasn't been set yet.
- **Company location ("geofence center")**: captured by the student via a
  **"Set My Location"** button on Confirm Company Details while physically
  at the company (there's no Admin module yet to set a verified location
  instead).
- **Quick Actions**: the Clock In/Out button, and a **Correction Request
  Form** button.
- **Correction Request Form**: required reason/note, optional file
  attachment, submitted for instructor review. Stays "Pending" since
  there's no Instructor module yet to approve/reject it — the workflow
  and data model are ready for when that exists.
- **Attendance History**: full chronological log (date, clock in/out,
  total hours, status) plus the student's Correction Request history,
  reachable via "View All".

### 4.4 Documents Tab
Three sections, reached from a hub screen:

**HTE Directory** — a read-only, admin-seeded list of partner companies
(name, industry, address, contact info, available slots). For reference
only; students apply directly, not through the app.

**OJT Requirements** — a 4-phase sequential workflow (Pre-Application →
Requirements → Internship Docs → Final Documents). Each phase unlocks once
the previous one is fully submitted. Each document supports:
- Download Template (where applicable)
- Upload / Re-upload
- Submission status (Missing/Submitted/Approved/Rejected)
- **Remarks** — instructor feedback on a rejection (field is live; no
  Instructor module yet to write it)

Once all 4 phases hit 100%, a **Confirm Company Details** step appears
(not counted in the progress bar):
- Manual, self-reported entry: company name, address, industry,
  supervisor name, contact number, and **OJT Start Date**. Done manually
  (not OCR/auto-extracted) so students can correct any misreads from their
  uploaded documents.
- Independent of the HTE Directory — the student's real company doesn't
  need to be listed there.
- This is the source of truth for the Home/Profile company card.
- Also includes the **"Set My Location"** GPS capture for the Attendance
  geofence.

**Activity Reports** — Weekly Accomplishment Reports (AR): one recurring
upload slot per OJT week, auto-generated from the student's OJT Start Date
through the current week. Purely a record/compilation — **no hours field,
no link to attendance or hours calculation**. Each week: a required
accomplishments write-up + at least one file attachment. One submission
per week is enforced by a database constraint, not just the UI.

### 4.5 Notifications Tab
- Categorized (Admin / Instructor / System), searchable, filterable
  (category + unread-only).
- Read/unread state, swipe to delete, badge count on the bottom nav.
- Tapping a notification marks it read and deep-links to the relevant tab.

### 4.6 Profile Tab
- Editable avatar (UI ready; real upload needs a camera/gallery plugin
  not wired up yet).
- Adviser / Company / Supervisor contact rows (Company/Supervisor come
  from Confirm Company Details).
- **Help Center**: FAQs, guides, policies (static content, DB-backed).
- **Settings**: account info, logout.

---

## 5. Database Schema (high level)

| Table | Purpose |
|---|---|
| `students` | Identity, course/section, avatar, required hours |
| `student_profiles` | 1:1 extension: phone, adviser link, self-reported company (name/address/industry/supervisor/contact/lat/lng/**ojt_start_date**) |
| `advisers` | OJT adviser directory |
| `hte_companies` | HTE Directory listings (reference only) |
| `attendance_records` | One row per student per day (clock_in/clock_out) |
| `attendance_corrections` | Correction requests (pending/approved/rejected) |
| `ojt_requirement_phases` / `ojt_requirement_templates` | The 4 fixed phases and their document templates |
| `student_requirement_submissions` | One row per student per requirement document, incl. `remarks` |
| `activity_reports` | Weekly Accomplishment Reports, keyed by `(student_id, week_number)` |
| `activity_report_attachments` | Files attached to a weekly report |
| `notifications` / `notification_preferences` | Notification feed and per-category toggles |
| `help_center_articles` | Static Help Center content |

Two deliberate design choices worth knowing:
- **Computed, not stored.** OJT hours progress (completed hours, days
  attended, averages, status) is computed from `attendance_records` with
  SQL aggregates on every request, not cached in a column — avoids drift.
- **Additive migrations.** Every schema change after the initial
  `schema.sql` is a separate, non-destructive `migration_*.sql` file
  (`ADD COLUMN IF NOT EXISTS`, etc.) so real student data is never at risk.

---

## 6. API Endpoints

All routes below (except `/api/auth/*`) require a `Bearer` JWT and are
scoped to the logged-in student.

| Method | Path | Purpose |
|---|---|---|
| POST | `/api/auth/register` | Create account |
| POST | `/api/auth/login` | Get a JWT |
| GET | `/api/attendance/today` | Today's clock in/out |
| POST | `/api/attendance/clock-in` | Clock in (geofence-checked) |
| POST | `/api/attendance/clock-out` | Clock out (geofence-checked) |
| GET | `/api/attendance/history` | Full attendance log |
| GET | `/api/attendance/progress` | Hours, days, averages, status badge |
| GET | `/api/attendance/corrections` | List correction requests |
| POST | `/api/attendance/corrections` | Submit a correction request |
| GET | `/api/hte-companies` | HTE Directory listing |
| GET | `/api/requirements` | 4-phase requirements + submission status |
| POST | `/api/requirements/:templateId/submit` | Upload/submit a requirement doc |
| GET | `/api/activity-reports` | Generated weekly report slots |
| POST | `/api/activity-reports/:weekNumber/submit` | Submit a week's report |
| GET | `/api/notifications` | Notification feed |
| PATCH | `/api/notifications/:id/read` | Mark one read |
| PATCH | `/api/notifications/read-all` | Mark all read |
| DELETE | `/api/notifications/:id` | Delete a notification |
| GET | `/api/profile` | Full student profile |
| PATCH | `/api/profile` | Update phone/address/etc. |
| POST | `/api/profile/company` | Confirm Company Details (+ location + start date) |
| POST | `/api/profile/avatar` | Upload avatar image |

---

## 7. What's Not Built Yet

- **Instructor module** — the review/approve side of Requirements docs,
  Correction Requests, and Weekly Reports (`remarks`/status fields already
  exist and are wired up on the student side, ready for this).
- **Admin module** — company assignment, master list management, reports.
  Flutter Web is the intended stack for this so it can share code with the
  mobile apps.
- **Real file picking** — uploads currently use a mock file picker sheet
  (returns a fake filename) since `file_picker`/`image_picker` aren't
  wired up; the server already accepts real multipart files where it
  matters (requirement docs, avatars), so swapping this in is additive.
- **Push/real-time notifications** — the feed is pull-based (fetched on
  load), no WebSocket/push infrastructure yet.
