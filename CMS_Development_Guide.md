# Church Management System (CMS) — Development Guide

**Version:** 1.0
**Target audience:** Developer / development agent implementing this project
**Platforms:** Web (desktop/laptop browsers) + Windows Desktop (offline-first)
**Stack:** Flutter (single codebase, multi-target) + Firebase (Firestore, Auth, Functions, Storage, Cloud Messaging)

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Platform & Technical Requirements](#2-platform--technical-requirements)
3. [System Architecture](#3-system-architecture)
4. [Offline-First Strategy (Windows Desktop)](#4-offline-first-strategy-windows-desktop)
5. [Data Model (Firestore Schema)](#5-data-model-firestore-schema)
6. [Roles & Permissions](#6-roles--permissions)
7. [Feature Specifications & Workflows](#7-feature-specifications--workflows)
8. [Security](#8-security)
9. [UI / UX & Screen Map](#9-ui--ux--screen-map)
10. [Reporting & Analytics](#10-reporting--analytics)
11. [Non-Functional Requirements](#11-non-functional-requirements)
12. [Phase-by-Phase Development Plan](#12-phase-by-phase-development-plan)
13. [Appendix](#13-appendix)

---

## 1. Project Overview

### 1.1 Purpose
A Church Management System (CMS) built for a single Nigerian church operating **multiple branches**, each with **multiple departments/units**. The system replaces manual/paper/WhatsApp-based administration with a structured, auditable, role-based digital system covering membership, attendance, events, communication, and — most critically — financial management (budgeting, income, expenditure, disbursement, and assets).

### 1.2 Scope (v1)
- Single church (not a multi-tenant SaaS product for multiple churches).
- Multi-branch, multi-department support within that one church.
- **Admin/back-office tool** — used by church leadership and officers, not by the general congregation. No member self-service portal in v1.
- Three core roles: **Lead Pastor**, **Secretary**, **Finance Department**. The underlying permission architecture supports adding custom roles later, but the UI is scoped to these three for v1.

### 1.3 Explicitly Out of Scope for v1 (deferred to v2+)
- Live payment gateway integration (Paystack/Flutterwave) for online giving.
- Member self-service portal / mobile app for congregants.
- Sermon/media library.
- Prayer request portal.
- Multi-language UI (Yoruba, Igbo, Hausa, Pidgin).
- Custom/admin-defined roles beyond the three core roles.
- HQ-level department oversight role (a lightweight `departmentType` tag is included now as a placeholder to make this easy to add later).

---

## 2. Platform & Technical Requirements

| Concern | Decision |
|---|---|
| Framework | Flutter (single codebase) |
| Web target | Flutter Web, desktop/laptop browsers only (not optimized for mobile browser) |
| Desktop target | Flutter Windows Desktop build, **offline-first** |
| Backend | Firebase (Firestore, Firebase Auth, Cloud Functions, Cloud Storage, FCM for notifications) |
| State management | Riverpod (preferred) or Provider |
| Routing | `go_router`, with role-based route guarding |
| Local storage (desktop offline) | Firestore's built-in offline persistence **plus** a local cache/queue layer (see Section 4) |
| Tables/data grids | `data_table_2` |
| Charts | `fl_chart` |
| PDF/export | `pdf` + `printing` packages |
| File import | `file_picker` + `csv`/`excel` packages |
| SMS gateway | Local Nigerian SMS provider (e.g. Termii or BulkSMSNigeria) via Cloud Function HTTP call — not client-side |
| Auth | Firebase Auth (email/password to start), MFA (SMS-based) for Lead Pastor & Finance roles |

**Important note on Flutter Web vs Desktop divergence:** the UI layer (widgets, layout, navigation) is shared. The **data layer must be abstracted behind a repository interface** so that web can talk to Firestore directly online, while desktop can read/write through a local cache with a sync queue. This abstraction is the single most important architectural decision in this project — build it first, before any feature screens.

---

## 3. System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter Client                       │
│  ┌───────────────┐   ┌───────────────┐  ┌─────────────┐ │
│  │   UI Layer     │   │  State Layer   │  │  Routing    │ │
│  │ (Screens/      │◄─►│ (Riverpod      │  │ (go_router, │ │
│  │  Widgets)      │   │  Providers)    │  │  RBAC guard)│ │
│  └───────┬────────┘   └───────┬────────┘  └─────────────┘ │
│          │                    │                            │
│          ▼                    ▼                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │            Repository Layer (interface)               │ │
│  │  MemberRepository, AttendanceRepository, FinanceRepo…  │ │
│  └───────────┬───────────────────────────┬────────────────┘
│              │                           │
│     ┌────────▼────────┐         ┌────────▼─────────┐
│     │  Web impl:       │         │ Desktop impl:      │
│     │  direct Firestore│         │ Local cache (Hive/  │
│     │  calls           │         │ Isar) + Sync Queue  │
│     └────────┬────────┘         └────────┬─────────┘
└──────────────┼───────────────────────────┼────────────┘
               │                           │
               ▼                           ▼
     ┌─────────────────────────────────────────────┐
     │                Firebase Backend               │
     │  Firestore | Auth | Cloud Functions | Storage  │
     │  - Security Rules (RBAC enforcement)           │
     │  - onWrite triggers → Audit Log                │
     │  - onWrite triggers → Notifications             │
     │  - Scheduled Functions → recurring templates,   │
     │    aggregation, backups                         │
     └─────────────────────────────────────────────┘
```

### 3.1 Layering principles
- **UI never talks to Firestore directly.** All reads/writes go through the Repository layer, so business logic (e.g. "can't disburse more than approved amount") lives in one place regardless of platform.
- **Cloud Functions own all cross-cutting logic:** audit logging, diff computation on approval edits, disbursement total aggregation, SMS dispatch, scheduled recurring expense drafts. This keeps the client "dumb" and consistent across web and desktop.
- **Security Rules are the real authority**, not the UI. UI hides/shows based on permissions for UX, but every rule must also be enforced server-side — assume a determined user could bypass the UI.

---

## 4. Offline-First Strategy (Windows Desktop)

The Windows desktop build must remain usable with no internet connection (common in Nigerian church offices with unreliable power/data), then sync once connectivity returns. Web build relies on Firestore's standard online + short-term offline cache behavior and does **not** need the full offline-first treatment.

### 4.1 Approach: Local-first cache + outbox sync queue

1. **Local database:** use `Isar` (fast, Flutter-native, good for desktop) as the local source of truth on the desktop build.
2. **Read path:** desktop screens read from Isar first (instant, always available). A background sync service pulls Firestore changes into Isar when online.
3. **Write path:** every write (create/update) is written to Isar immediately (so the UI feels instant and works fully offline) **and** queued in a local `outbox` table with a status (`pending`, `synced`, `failed`).
4. **Sync service:** a background isolate/service periodically (and on reconnect, detected via `connectivity_plus`) processes the outbox — pushing queued writes to Firestore in order, marking them `synced` on success.
5. **Conflict handling:** use `serverTimestamp` + `updatedAt` version checks. If a document was changed remotely since the local copy was last synced, flag it for **manual review** rather than silently overwriting — surfaced as a small "sync conflict" indicator the user (typically the officer at that desktop) can resolve.
6. **Financial data caution:** because expenditures/disbursements are sensitive, disbursement and approval actions performed offline should sync with an explicit "pending sync" badge visible in the UI until confirmed — nobody should assume a disbursement is finalized until it's synced and passed through server-side validation (e.g. the over-disbursement check).

### 4.2 What must NOT be trusted purely offline
- **Approval actions** (Lead Pastor approving budgets/expenditures/announcements) should be flagged clearly as "will finalize once synced" if performed offline, since the approval Cloud Function logic (diff computation, notification to Finance) only runs once the write reaches Firestore.
- **Over-disbursement prevention** is a security-rule/Cloud-Function-level check; a fully offline disbursement entry should be treated as provisional until synced and validated.

### 4.3 Web build
Web uses Firestore's native web SDK, which has its own IndexedDB-based short-term offline cache (survives brief disconnects, not designed for extended offline use). No custom Isar/outbox layer is needed for web — this is why the Repository interface exists, so web and desktop can each use the implementation that fits their environment.

---

## 5. Data Model (Firestore Schema)

All church-specific data is nested under `/branches/{branchId}/...` since this is a single church with multiple branches (not multi-tenant across churches).

```
/branches/{branchId}
    name, address, pastorInCharge, phone, createdAt

/branches/{branchId}/members/{memberId}
    firstName, lastName, phone, gender, dob, maritalStatus,
    departmentIds: [], joinDate, memberStatus, roleId,
    importBatchId (optional), importedAt (optional)

/branches/{branchId}/roles/{roleId}
    name, permissions: [], scope: { type, departmentId? }
    // v1 seeds exactly 3 roles: leadPastor, secretary, financeDept

/branches/{branchId}/departments/{deptId}
    name, departmentType, headMemberId, memberIds: []

/branches/{branchId}/events/{eventId}
    title, type (recurring/one-off), recurrenceRule?, date, departmentIds: []

/branches/{branchId}/events/{eventId}/attendance/{attendanceId}
    checkedInMemberIds: [], totalCount, recordedBy, recordedAt

/branches/{branchId}/announcements/{announcementId}
    title, body, status (draft/pending/approved/rejected),
    createdBy, originalBody, approvedBody, approvedBy, approvedAt,
    smsTriggered (boolean)

/branches/{branchId}/correspondence/{correspondenceId}
    type, summary, source, documentedBy, date,
    attachmentUrl?, viewedByPastor (boolean), viewedAt?

/branches/{branchId}/giving/{givingId}
    memberId, type (tithe/offering/pledge), amount, date, recordedBy

/branches/{branchId}/income/{incomeId}
    amount, source, formType (cash/transfer/cheque/in-kind),
    comment, recordedBy, date

/branches/{branchId}/budgets/{budgetId}
    fiscalPeriod, departmentId?, category, requestedAmount,
    approvedAmount, status (pending/approved/rejected),
    requestedBy, approvedBy, approvedAt,
    changesSummary: [{ field, from, to }]

/branches/{branchId}/expenditureRequests/{requestId}
    amount, category, description, requestedBy, status,
    originalAmount, originalCategory, originalDescription,
    approvedAmount, approvedCategory, approvedDescription,
    changesSummary: [], approvedBy, approvedAt

/branches/{branchId}/expenditures/{expenditureId}   // created ONLY on approval
    approvedAmount, category, description, approvedBy,
    sourceRequestId, date, totalDisbursed, status
    (not-disbursed / partially-disbursed / fully-disbursed)

/branches/{branchId}/expenditures/{expenditureId}/disbursements/{disbursementId}
    amountDisbursed, date, recipientName, purpose,
    disbursedBy, receiptUrl?

/branches/{branchId}/assets/{assetId}
    itemName, quantity, condition, location,       // Secretary-owned fields
    purchaseValue, purchaseDate, vendor,            // Finance-owned fields
    assignedDepartment, lastMaintenanceDate

/branches/{branchId}/auditLogs/{logId}
    module, documentId, action, before, after,
    performedBy, performedByName, timestamp
    // immutable — written only by Cloud Functions (Admin SDK)

/branches/{branchId}/notifications/{notificationId}
    recipientUid, type (approval-change/disbursement-alert/etc.),
    message, read (boolean), createdAt
```

---

## 6. Roles & Permissions

### 6.1 Architecture
Roles are **documents, not hardcoded logic** — each role is a named bundle of atomic permissions plus an optional scope (e.g. department-restricted). This means v1 ships with exactly three seeded roles, but adding a fourth later (e.g. "Choir Director") requires no code changes — just a new role document and permission assignment.

**Permission catalog (atomic, fixed in code):**
```
manageMembers, manageRoles, recordAttendance, manageEvents,
manageDepartments, createAnnouncement, approveAnnouncement,
logCorrespondence, recordIncome, createBudgetRequest, approveBudget,
createExpenditureRequest, approveExpenditure, recordDisbursement,
manageAssetPhysical, manageAssetFinancial, viewFinancialReports,
viewNonFinancialReports, sendNotifications
```

### 6.2 RBAC implementation
- **Firebase Custom Claims** carry coarse, rarely-changing data: `branchId`, `roleId`. Cheap to check in security rules, but requires a Cloud Function + token refresh to update.
- **Fine-grained permission checks** happen via a Firestore `get()` on the user's role document inside security rules (`get(/databases/$(db)/documents/branches/$(branchId)/roles/$(roleId)).data.permissions`).
- **Flutter UI mirrors the same checks** to hide/show screens and buttons — this is UX only, never the actual security boundary.

### 6.3 Role × Feature Matrix (v1)

| Feature | Lead Pastor | Secretary | Finance Dept |
|---|---|---|---|
| Member Management | View all, edit status | Full CRUD | Read-only (limited fields) |
| Role Assignment | Full control | None | None |
| Attendance | View-only | Full CRUD | None |
| Department Mgmt | Full CRUD | Manage rosters | None |
| Event Calendar | Full CRUD, approve | Full CRUD | View-only |
| Announcements | Approve/edit | Draft/create | None |
| Correspondence | View only | Full CRUD (log/document) | None |
| Reports Dashboard | Full access | Non-financial only | Financial only |
| SMS Notifications | Broadcast/approve | Routine sends | None |
| Giving Records | View-only | None | Full CRUD |
| Income Tracking | View-only | None | Full create (with form type + comment) |
| Budget | Approve/edit, full visibility | View approved only | Create request; view approved only |
| Expenditure | Approve/edit, full visibility | View approved only | Create request; view approved only |
| Disbursement | View-only | None | Full create (no approval needed once expenditure approved) |
| Asset — physical (condition/location) | View-only | Full CRUD | None |
| Asset — financial (value/purchase) | View-only | None | Full CRUD |
| Audit Log | Full access | Scoped to own actions | Scoped to own actions |

---

## 7. Feature Specifications & Workflows

### 7.1 Member Management
Secretary maintains full member records per branch. Supports CSV/Excel bulk import (see 7.9). Lead Pastor can edit status (active/inactive/transferred) for oversight but doesn't do routine entry. Finance has read-only access to name/contact fields only, for giving-record linkage.

### 7.2 Attendance (event-driven)
Attendance is **not a standalone module** — it's a subcollection of Events. Creating any event (recurring service or one-off program) automatically enables attendance recording against it. Secretary records attendance (manual count or checked-in member list); Lead Pastor views trends across branches/event types.

### 7.3 Department/Unit Management
Branch-scoped departments with a `departmentType` tag (e.g. "Choir") to allow future cross-branch rollups without redesigning the schema. Lead Pastor creates/dissolves departments and appoints heads; Secretary manages rosters.

### 7.4 Event & Program Calendar
Secretary creates/edits most events day-to-day; Lead Pastor can create/edit and approves major additions. Finance has view-only access (to anticipate related costs).

### 7.5 Announcements (approval workflow)
```
Secretary drafts announcement (status: pending)
  → Lead Pastor reviews → approves as-is, or edits then approves
  → Approved announcement can trigger an SMS broadcast (7.7)
```
Store both `originalBody` and `approvedBody` so edits are traceable via the audit log.

### 7.6 Correspondence Log
Secretary logs incoming correspondence (letters, memos, external requests) as an "in-tray" the Lead Pastor reviews (`viewedByPastor` flag). Not a two-way approval flow — just structured visibility.

### 7.7 SMS Notifications
Triggered by: approved announcements, event reminders, finance-related notices (pledge reminders). Dispatched via a Cloud Function calling the SMS gateway API (never client-side, to protect API credentials and allow retry logic). Every send is logged in a **Notification/Communication Log** (recipient count, message, timestamp) for accountability.

### 7.8 Financial Workflows

**Budget:**
```
Finance creates budget request (status: pending)
  → Lead Pastor reviews → approves as-is, or edits then approves
  → Cloud Function computes changesSummary diff (original vs approved)
  → Finance notified of exact changes + final approved figure
  → Approved budget becomes visible on Secretary's documentation view
  → Finance sees only the approved copy going forward
```

**Expenditure:**
```
Finance submits expenditure request (status: pending)
  → Lead Pastor reviews → approves as-is, or edits then approves
  → Cloud Function computes changesSummary diff
  → Finance notified of exact changes + final approved figure
  → ONLY on approval: an /expenditures/{id} record is created (the official ledger entry)
  → Secretary's documentation view shows the approved record only
```
Modeling requests and final records as **separate documents** keeps the official expenditure ledger clean (approved, final data only) while the request document retains its own pending/edit history — this also makes the audit log trail unambiguous (request edited → request approved → expenditure record created are three distinct, traceable events).

**Disbursement (sub-ledger under each approved expenditure):**
```
Finance records a disbursement against an approved expenditure:
  amount, date, recipient, purpose
  → Cloud Function atomically increments expenditure.totalDisbursed (FieldValue.increment)
  → Cloud Function updates expenditure.status:
      not-disbursed → partially-disbursed → fully-disbursed
  → Client + security rule blocks a disbursement that would push
    totalDisbursed above approvedAmount
  → No approval step required — Finance is trusted to disburse
    freely once the expenditure itself is approved
```
This creates three accountable layers per spend item: **Budget (planned) → Expenditure (approved) → Disbursement (actually paid out)** — each a check against the last, and each reportable (Budget vs Actual, Approved vs Disbursed).

**Income:** Finance records all income directly (no approval step), with `formType` (cash/transfer/cheque/in-kind) and a free-text `comment` field for context.

**Notification-on-edit mechanic (shared by Budget & Expenditure):** a Cloud Function trigger on approval compares original vs. approved fields, writes a `changesSummary` array, and creates a `/notifications` document for the requesting Finance user — surfaced in-app (and optionally via SMS/email later).

### 7.9 Data Import (Member CSV/Excel)
```
Upload file → client-side parse (csv/excel packages) →
Preview table with per-row validation flags
  (missing required field / duplicate phone / bad date) →
User corrects/excludes flagged rows →
Confirm → chunked batched Firestore writes (≤500 ops/batch) →
Each imported record tagged with importBatchId, importedAt
```

### 7.10 Asset/Inventory Tracking (split ownership)
One `/assets/{assetId}` document, but field-level ownership:
- **Secretary** writes: `condition`, `location`, `assignedDepartment`, `lastMaintenanceDate`.
- **Finance** writes: `purchaseValue`, `purchaseDate`, `vendor`.
Security rules should validate that each role can only write its own field subset on this document (Firestore rules can check `request.resource.data.diff(resource.data).affectedKeys()` against an allowed field set per role).

### 7.11 Audit Log
Cloud Functions `onWrite` triggers on every sensitive collection (members, budgets, expenditureRequests, expenditures, disbursements, roles, announcements) write an immutable entry to `/auditLogs` with before/after state. Security rules deny all client writes to this collection — only the Admin SDK (Cloud Functions) can write here.

### 7.12 Session Security
- `Persistence.SESSION` as default Firebase Auth persistence (no persistent login on shared office devices).
- Inactivity auto-logout: 10–15 minutes for Lead Pastor & Finance, longer for Secretary.
- MFA (SMS-based, via Firebase Auth) enrolled for Lead Pastor & Finance roles.
- Optional: device/session visibility with remote force-logout via an incrementing `sessionVersion` custom claim.

---

## 8. Security

- **Security Rules are the true access boundary** — every permission in Section 6 must be enforced in `firestore.rules`, not just hidden in the UI.
- **Segregation of duties is structural:** Finance cannot approve its own budget/expenditure requests (only Lead Pastor can) — enforce this in rules by checking `request.auth.uid != resource.data.requestedBy` on approval-type writes, in addition to role/permission checks.
- **Immutable audit trail:** `/auditLogs` writable only by Cloud Functions.
- **Over-disbursement guard:** enforced both client-side (fast feedback) and in security rules / Cloud Function validation (real guarantee).
- **NDPR awareness:** member personal data (contact, marital status, etc.) should have a documented collection basis and a data-correction/deletion path, even if handled informally at this stage.
- **Backups:** scheduled Firestore export to Cloud Storage (via Cloud Scheduler + Functions) for disaster recovery and data portability.

---

## 9. UI / UX & Screen Map

### 9.1 Layout pattern
Fixed **sidebar navigation + main content area** (classic admin dashboard), since both web and desktop targets are desktop/laptop-sized screens — no need to design for small/mobile breakpoints.

### 9.2 Screens by role

**Lead Pastor**
- Dashboard (cross-branch KPIs: attendance trend, income vs expenditure, pending approvals count)
- Unified **Approval Queue** (budgets, expenditures, announcements — pending items across modules in one inbox, approve/edit/reject action on each)
- Member directory (view/edit status)
- Department management
- Event calendar (full control)
- Correspondence inbox (read/mark viewed)
- Reports & Analytics (financial + non-financial, cross-branch)
- Role & permission overview
- Audit log viewer (full)

**Secretary**
- Dashboard (upcoming events, pending correspondence, membership snapshot)
- Member management (full CRUD)
- Attendance entry (per event)
- Department roster management
- Event calendar (create/edit)
- Announcement drafting
- Correspondence logging
- Approved budget/expenditure documentation view (read-only)
- Asset — physical tracking (condition/location)
- Non-financial reports

**Finance Dept**
- Dashboard (budget vs actual snapshot, pending requests status, disbursement summary)
- Income entry (with form type + comment)
- Budget request creation + status tracker
- Expenditure request creation + status tracker
- Disbursement entry (against approved expenditures)
- Giving records
- Asset — financial tracking (value/purchase)
- Financial reports
- Notifications (edit-on-approval alerts)

### 9.3 Key interaction pattern: the Approval Queue
Rather than three separate approval UIs (one each for budgets, expenditures, announcements), build **one generic queue component** the Lead Pastor uses for all three — same card layout, same approve/edit/reject actions, filterable by type. Reduces both build effort and the pastor's cognitive load.

---

## 10. Reporting & Analytics

- **Attendance trends** — by event type, branch, over time.
- **Membership growth** — new members, transfers, by branch/department.
- **Budget vs Actual** — per department/category/fiscal period.
- **Approved vs Disbursed** — per expenditure, surfacing outstanding balances.
- **Income breakdown** — by source/form type, over time.
- **Cross-branch rollups** — via Firestore collection-group queries (e.g. all `attendance` subcollections across branches).
- **Cost control:** for dashboards with heavy aggregate reads, use scheduled Cloud Functions to pre-compute daily/weekly summary documents rather than reading every record live on each dashboard load.

---

## 11. Non-Functional Requirements

- **Performance:** dashboard loads should rely on pre-aggregated summary documents, not live full-collection scans.
- **Data integrity:** all financial state transitions (request → approved → disbursed) go through Cloud Functions, never raw client writes to derived fields like `totalDisbursed`.
- **Traceability:** every sensitive write must be attributable (audit log) and, where relevant, diffed (changesSummary).
- **Portability:** church data must be exportable independent of the app (Firestore export, plus in-app CSV/PDF export for reports).
- **Usability for non-technical users:** short in-app guidance/tooltips per role, since users may not be highly tech-literate.

---

## 12. Phase-by-Phase Development Plan

### Phase 0 — Foundation & Architecture Setup
**Goal:** nothing user-facing yet, but the skeleton everything else depends on is solid.
- Set up Firebase project (Firestore, Auth, Functions, Storage).
- Define and implement the **Repository layer interface** (critical — do this before any feature screens).
- Implement web Firestore-direct repository implementation.
- Implement desktop Isar local-cache + outbox sync skeleton (can be a stub initially, fleshed out in Phase 5).
- Seed the 3 core roles + permission catalog in Firestore.
- Implement Firebase Auth (email/password), Custom Claims (branchId, roleId), and basic security rules skeleton.
- Set up `go_router` with role-based route guarding.
- Set `Persistence.SESSION` as default; implement inactivity auto-logout.
- **Deliverable:** empty-shell app that logs in, assigns a role, and shows a role-appropriate (empty) dashboard on both web and desktop builds.

### Phase 1 — Core Records
**Goal:** the foundational data entities other features depend on.
- Branch and Department management (Lead Pastor CRUD).
- Member management (Secretary CRUD, Lead Pastor view/edit status, Finance read-only).
- Role assignment UI (Lead Pastor assigns Secretary/Finance/Lead Pastor to members).
- CSV/Excel member import (preview, validation, batched write).
- Audit log Cloud Function triggers on members/departments/roles; basic audit log viewer.
- **Deliverable:** a church's branch/department/member structure can be fully set up and imported.

### Phase 2 — Attendance & Events
**Goal:** operational day-to-day usage begins.
- Event calendar (Secretary create/edit, Lead Pastor full control + approve, Finance view-only).
- Attendance recording tied to events.
- Correspondence log (Secretary log, Lead Pastor view).
- Announcement draft → approve workflow (Secretary draft, Lead Pastor approve/edit).
- **Deliverable:** the church can run its weekly calendar and take attendance digitally; correspondence and announcements are tracked.

### Phase 3 — Financial Core
**Goal:** the most complex and highest-value module.
- Income recording (Finance, with form type + comment).
- Giving records (Finance).
- Budget request → approval workflow (with changesSummary diff + Finance notification).
- Expenditure request → approval workflow (with changesSummary diff + Finance notification).
- Disbursement sub-ledger under approved expenditures (with atomic `totalDisbursed` aggregation and over-disbursement guard).
- Asset/Inventory tracking with split field ownership (Secretary physical, Finance financial).
- Segregation-of-duties security rules (requester ≠ approver).
- **Deliverable:** full budget → expenditure → disbursement lifecycle is usable end-to-end, auditable, with approval notifications working.

### Phase 4 — Reporting, Dashboards & Notifications
**Goal:** turn recorded data into actionable insight.
- Role-scoped dashboards (Lead Pastor cross-branch KPIs, Secretary non-financial, Finance financial).
- Unified Approval Queue screen (replacing/wrapping the individual approval flows built in Phase 3).
- Budget vs Actual and Approved vs Disbursed reports.
- Scheduled Cloud Functions for pre-aggregated summary documents.
- SMS Notification dispatch (Cloud Function + SMS gateway integration) tied to approved announcements and finance reminders; Communication Log.
- PDF/Excel export for financial statements and reports.
- **Deliverable:** leadership has real visibility into church operations and finances without manual compilation.

### Phase 5 — Offline-First Desktop Hardening
**Goal:** the Windows desktop build works reliably with no internet.
- Full Isar local-cache implementation across all repositories.
- Outbox sync queue with retry logic and `connectivity_plus`-based reconnect detection.
- Conflict detection/resolution UI ("sync conflict" indicator).
- "Pending sync" UI badges for offline-created approvals/disbursements.
- End-to-end offline test scenarios (create member offline, record attendance offline, submit expenditure request offline, reconnect and verify correct sync + Cloud Function side effects fire correctly).
- **Deliverable:** a church office can use the desktop app through an internet outage and trust that everything syncs correctly once back online.

### Phase 6 — Security Hardening & Compliance
**Goal:** production-readiness from a trust/compliance standpoint.
- MFA enrollment flow for Lead Pastor & Finance.
- Full security rules review — every collection re-verified against the Role × Feature matrix, including field-level rules for split-ownership Assets.
- NDPR-aligned data handling review (consent basis, correction/deletion path).
- Scheduled Firestore backups to Cloud Storage.
- Session/device visibility + remote force-logout (optional, if time allows).
- Load/read-cost review of dashboard queries against Firestore billing.
- **Deliverable:** system is ready for real member/financial data and ongoing production use.

### Phase 7 — Pilot, Training & Launch
**Goal:** get the church actually using it.
- Onboarding materials/tooltips per role.
- Pilot with one branch first (if multi-branch, staged rollout reduces risk).
- Bulk import of real member data.
- Staff training sessions per role (Lead Pastor, Secretary, Finance).
- Feedback loop → fix list → second branch rollout.
- **Deliverable:** the church is running the system as its actual system of record.

---

## 13. Appendix

### 13.1 Permission Catalog (reference)
```
manageMembers, manageRoles, recordAttendance, manageEvents,
manageDepartments, createAnnouncement, approveAnnouncement,
logCorrespondence, recordIncome, createBudgetRequest, approveBudget,
createExpenditureRequest, approveExpenditure, recordDisbursement,
manageAssetPhysical, manageAssetFinancial, viewFinancialReports,
viewNonFinancialReports, sendNotifications
```

### 13.2 Glossary
- **Branch** — a physical church location under the single church organization.
- **Department/Unit** — a ministry group within a branch (choir, ushering, welfare, etc.).
- **Request vs Record** — a Budget/Expenditure starts as a *request* (mutable, pending) and becomes a *record* (final, approved) only after Lead Pastor approval.
- **Disbursement** — an actual payment made against an already-approved expenditure; tracked as a sub-ledger.
- **Outbox** — the local queue of pending writes on the offline-first desktop build, synced to Firestore when connectivity returns.

### 13.3 Deferred Features (not in this document's scope, revisit post-v1)
Live payment gateway integration, member self-service portal, sermon/media library, prayer request portal, multi-language UI, custom/admin-defined roles beyond the 3 core roles, HQ-level department oversight role.
