# CMS Finance Module — Detailed Development Guide

**Scope:** How Lead Pastor, Finance Department, and Secretary interact around church finances — budgets, income, expenditures, disbursements, and asset financial records.
**Platforms:** Flutter (Web + Windows Desktop, offline-first) + Firebase
**Companion document:** `CMS_Development_Guide.md` (full-system guide) — this document expands Sections 6, 7.8, and 9 of that guide in full implementation detail.

---

## Table of Contents

1. [Narrative Overview — How the Three Roles Work Together](#1-narrative-overview)
2. [The Three-Layer Financial Model](#2-the-three-layer-financial-model)
3. [Data Models](#3-data-models)
4. [State Machines & Flow Diagrams](#4-state-machines--flow-diagrams)
5. [Screens & Pages](#5-screens--pages)
6. [UI Components](#6-ui-components)
7. [Functions & Business Logic](#7-functions--business-logic)
8. [Cloud Functions (Server-Side Logic)](#8-cloud-functions-server-side-logic)
9. [Security Rules](#9-security-rules)
10. [Notification Logic](#10-notification-logic)
11. [Offline-First Considerations](#11-offline-first-considerations)
12. [Edge Cases & Validation Rules](#12-edge-cases--validation-rules)
13. [Implementation Checklist](#13-implementation-checklist)

---

## 1. Narrative Overview

Think of the finance module as a **relay with three runners**, where each runner has a distinct, non-overlapping job, and the baton (the money record) changes shape as it passes hands.

**Finance Department is the initiator and executor.** They propose — creating budget requests and expenditure requests — and they execute — recording income as it comes in, and disbursing money once an expenditure is approved. What Finance never does is approve their own proposals. This separation (segregation of duties) is the backbone of the whole module: it means no single person in the finance chain can both request and authorize spending, which is exactly the kind of control that protects both the church's money and the Finance Officer's own reputation from suspicion.

**Lead Pastor is the approver and final authority.** Every budget and every expenditure passes through the pastor before it becomes "real." The pastor can approve as submitted, or edit the figures/details and then approve — because ultimately the pastor is accountable for church funds and needs the power to adjust, not just rubber-stamp. When the pastor edits something, Finance isn't left in the dark — they get a clear notification of exactly what changed and the final approved version, so trust is maintained and Finance can calibrate future requests.

**Secretary is the record-keeper and documentarian.** The Secretary doesn't touch money at all — no create, no edit, no approve. Their role is purely to **view and document the approved outcomes** — once a budget or expenditure has been approved by the pastor, it appears on the Secretary's documentation tab, ready to be referenced in meeting minutes, board reports, or general church records. The Secretary is, in effect, the historian of financial decisions, not a participant in making them.

**Putting it together as a single flow:**

```
Finance proposes  →  Pastor decides  →  Secretary documents
   (create)            (approve/edit)        (read-only record)
```

And underneath the "expenditure" layer sits one more relay leg that belongs to Finance alone: once an expenditure is approved, **Finance disburses** the actual money — to vendors, artisans, service providers — and logs each disbursement without needing further approval, because the approval gate already happened at the expenditure-request stage. This gives leadership two different, equally important pictures: **"what did we agree to spend?"** (expenditure) and **"how much of that has actually gone out the door, to whom, and for what?"** (disbursement).

Income sits slightly apart from this relay — it has no approval workflow at all. Finance simply records money as it comes in (tithes, offerings, donations, rentals), tagged with how it arrived (cash, transfer, cheque, in-kind) and a comment for context, because income doesn't carry the same risk as expenditure — nobody needs to "approve" money entering the church, only money leaving it.

---

## 2. The Three-Layer Financial Model

Every planned expenditure in this system passes through three distinct, linked layers — each one a check against the one before it:

| Layer | Question it answers | Who creates it | Who approves it |
|---|---|---|---|
| **Budget** | "What do we plan to spend, and on what?" | Finance | Lead Pastor |
| **Expenditure** | "What have we actually approved to spend?" | Finance (as a request) | Lead Pastor |
| **Disbursement** | "How much has actually been paid out, to whom, for what?" | Finance | *No approval needed* — trusted once expenditure is approved |

This gives three reportable relationships: **Budget vs. Actual** (planned vs. approved), and **Approved vs. Disbursed** (approved vs. actually paid). Both matter — the first protects planning discipline, the second protects execution accountability.

---

## 3. Data Models

### 3.1 Budget
```
/branches/{branchId}/budgets/{budgetId}
{
  fiscalPeriod: string          // e.g. "2026-Q3"
  departmentId: string | null   // optional, if budget is department-specific
  category: string              // e.g. "Building Maintenance"
  requestedAmount: number
  requestedDescription: string
  status: "pending" | "approved" | "rejected"

  // Finance's original submission (never overwritten)
  originalAmount: number
  originalCategory: string
  originalDescription: string

  // Pastor's final version (populated on approval)
  approvedAmount: number | null
  approvedCategory: string | null
  approvedDescription: string | null
  changesSummary: [ { field: string, from: any, to: any } ]  // auto-computed

  requestedBy: string           // Finance user uid
  approvedBy: string | null     // Lead Pastor uid
  approvedAt: Timestamp | null
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

### 3.2 Expenditure Request (pre-approval)
```
/branches/{branchId}/expenditureRequests/{requestId}
{
  amount: number
  category: string
  description: string
  status: "pending" | "approved" | "rejected"

  originalAmount: number
  originalCategory: string
  originalDescription: string

  approvedAmount: number | null
  approvedCategory: string | null
  approvedDescription: string | null
  changesSummary: []

  requestedBy: string
  approvedBy: string | null
  approvedAt: Timestamp | null
  createdAt: Timestamp
}
```

### 3.3 Expenditure (official record — created only on approval)
```
/branches/{branchId}/expenditures/{expenditureId}
{
  sourceRequestId: string        // link back to the originating request
  approvedAmount: number
  category: string
  description: string
  approvedBy: string
  date: Timestamp
  totalDisbursed: number         // maintained by Cloud Function, never client-written
  status: "not-disbursed" | "partially-disbursed" | "fully-disbursed"
  createdAt: Timestamp
}
```

### 3.4 Disbursement (sub-ledger)
```
/branches/{branchId}/expenditures/{expenditureId}/disbursements/{disbursementId}
{
  amountDisbursed: number
  date: Timestamp
  recipientName: string
  purpose: string
  disbursedBy: string            // Finance user uid
  receiptUrl: string | null
  createdAt: Timestamp
}
```

### 3.5 Income
```
/branches/{branchId}/income/{incomeId}
{
  amount: number
  source: string                 // tithe/offering/donation/fundraising/rental/etc.
  formType: "cash" | "transfer" | "cheque" | "in-kind"
  comment: string
  recordedBy: string
  date: Timestamp
  createdAt: Timestamp
}
```

### 3.6 Notification (drives the "Finance is told what changed" requirement)
```
/branches/{branchId}/notifications/{notificationId}
{
  recipientUid: string
  type: "budget-approved-with-changes" | "expenditure-approved-with-changes"
       | "budget-approved" | "expenditure-approved"
  referenceId: string             // budgetId or requestId
  message: string                 // human-readable summary
  changesSummary: []              // copied from the source doc for quick display
  read: boolean
  createdAt: Timestamp
}
```

---

## 4. State Machines & Flow Diagrams

### 4.1 Budget lifecycle
```
[Finance creates]
       │
       ▼
   ┌────────┐
   │ pending │──────── Lead Pastor rejects ───────► [rejected]
   └────┬───┘
        │ Lead Pastor approves (as-is OR after editing fields)
        ▼
   ┌──────────┐
   │ approved │
   └────┬─────┘
        │
        ├──► Cloud Function computes changesSummary (if any fields differ)
        ├──► Notification created for Finance (requestedBy)
        └──► Document becomes visible on Secretary's documentation view
```

### 4.2 Expenditure lifecycle (request → record → disbursement)
```
[Finance creates expenditureRequest]  status: pending
       │
       ▼
Lead Pastor reviews ──── rejects ────► status: rejected (ends here)
       │
       │ approves (as-is or edited)
       ▼
status: approved
       │
       ├──► Cloud Function computes changesSummary
       ├──► Notification sent to Finance
       ├──► Cloud Function CREATES a new /expenditures/{id} record
       │      (totalDisbursed: 0, status: "not-disbursed")
       └──► Secretary's documentation view now shows this expenditure

[Finance records disbursement(s) against the expenditure]
       │
       ▼
Cloud Function on disbursement create:
   - increments expenditure.totalDisbursed
   - recalculates status:
        totalDisbursed == 0            → not-disbursed
        0 < totalDisbursed < approved  → partially-disbursed
        totalDisbursed >= approved     → fully-disbursed
   - blocks (rule + function validation) if new total > approvedAmount
```

### 4.3 Income lifecycle (no approval — simplest flow)
```
[Finance creates income record] → immediately final, visible in reports.
```

---

## 5. Screens & Pages

### 5.1 Finance Department screens

**5.1.1 Finance Dashboard**
- Summary cards: Total income (this period), Total approved expenditure, Total disbursed, Outstanding (approved − disbursed).
- Pending requests widget: count + list of budget/expenditure requests awaiting pastor action, with status chips.
- Recent notifications preview (edit-on-approval alerts).
- Quick-action buttons: "New Income Entry", "New Budget Request", "New Expenditure Request".

**5.1.2 Income Entry & List**
- Form: amount, source (dropdown), formType (segmented control: Cash/Transfer/Cheque/In-Kind), comment (multiline), date.
- List view below: filterable/sortable table (date, source, formType, amount, comment, recordedBy).
- No edit/delete after submission in v1 (append-only) — corrections go through a documented adjustment entry instead, to preserve the audit trail. *(Decide with the church if a limited edit-window is wanted — see Section 12.)*

**5.1.3 Budget Request Form & Tracker**
- Form: fiscalPeriod, departmentId (optional dropdown), category, requestedAmount, requestedDescription.
- Tracker list: all budget requests created by this Finance user, with status chip (Pending / Approved / Rejected), and — if approved with changes — an inline "changed" badge that opens the diff detail.

**5.1.4 Expenditure Request Form & Tracker**
- Same pattern as Budget: form to submit + tracker list with status and diff-on-change visibility.

**5.1.5 Approved Expenditures & Disbursement Screen**
- List of approved expenditures (read-only header: category, approvedAmount, description, approvedBy, date).
- Expandable per-row: disbursement sub-ledger table (date, recipient, purpose, amount, disbursedBy) + running balance ("₦155,000 of ₦200,000 disbursed — ₦45,000 remaining").
- "Record Disbursement" button per expenditure (disabled/hidden once `status == fully-disbursed`).
- Disbursement form: amountDisbursed, date, recipientName, purpose, optional receipt photo/file upload.

**5.1.6 Giving Records**
- Similar list/entry pattern to Income, scoped to tithe/offering/pledge tied to a member.

**5.1.7 Asset — Financial View**
- List of assets showing Finance-owned fields only (purchaseValue, purchaseDate, vendor) with the ability to add/edit these fields; Secretary-owned fields (condition, location) shown read-only for context.

**5.1.8 Notifications**
- List of "approved with changes" notifications, each expandable to show the before/after diff and the final approved figure.

### 5.2 Lead Pastor screens

**5.2.1 Approval Queue (unified)**
- Tabbed or filterable list: All / Budgets / Expenditures / Announcements.
- Each card: requester, amount/category/description, submitted date, and three actions — **Approve**, **Edit & Approve**, **Reject**.
- "Edit & Approve" opens an inline editable form pre-filled with the request's values; saving triggers the approval + diff computation in one action.

**5.2.2 Financial Overview Dashboard**
- Cross-branch (if applicable) income vs. expenditure trend chart.
- Budget vs. Actual chart per department/category.
- Approved vs. Disbursed chart per expenditure/category.
- Outstanding disbursement balances list (approved but not fully disbursed).

**5.2.3 Expenditure & Budget Full History (read/edit)**
- Full list of all budgets/expenditures regardless of status, with the ability to open any **approved** one and edit it further if needed (e.g. correcting a mistake after the fact) — this edit should also flow through the audit log and, if it changes the approved figures, should trigger a fresh notification to Finance.

### 5.3 Secretary screens

**5.3.1 Financial Documentation View (read-only)**
- Two tabs: **Approved Budgets** and **Approved Expenditures**.
- Table view: category, approvedAmount, approvedBy, approvedAt, description.
- No income, no disbursement detail, no pending/rejected items — strictly the approved record, for minute-taking and documentation purposes.
- Export button (PDF) for compiling into meeting minutes/board reports.

---

## 6. UI Components

Reusable widgets to build once and share across the above screens:

| Component | Used in | Purpose |
|---|---|---|
| `StatusChip` | Budget/Expenditure trackers, Approval Queue | Color-coded pending/approved/rejected indicator |
| `ApprovalCard` | Approval Queue | Generic card showing request summary + Approve/Edit/Reject actions; type-agnostic (works for budget, expenditure, announcement) |
| `DiffViewer` | Notifications, tracker detail | Renders a `changesSummary` array as a clean "field: old → new" list |
| `DisbursementBalanceBar` | Disbursement screen | Progress bar showing disbursed vs. approved amount |
| `MoneyInputField` | All finance forms | Formatted Naira input (₦ prefix, thousand separators, numeric validation) |
| `FormTypeSelector` | Income entry | Segmented control for Cash/Transfer/Cheque/In-Kind |
| `FinanceDataTable` | Income/Giving/Expenditure lists | Wraps `data_table_2` with consistent sorting/filtering/pagination |
| `ApprovedOnlyBadge` | Secretary documentation view | Visual cue reinforcing that only finalized records are shown |
| `PendingSyncBadge` | Desktop offline builds | Shown on any finance record created while offline, until confirmed synced |

---

## 7. Functions & Business Logic (Client-Side / Repository Layer)

These live in the Repository layer (see main architecture doc, Section 3), never directly in UI widgets.

```
FinanceRepository:
  createBudgetRequest(budget) -> writes status: "pending"
  createExpenditureRequest(request) -> writes status: "pending"
  approveBudget(budgetId, finalFields, approverUid)
      -> writes approvedAmount/Category/Description, status: "approved", approvedBy, approvedAt
      -> (diff computation happens server-side, see Section 8)
  approveExpenditure(requestId, finalFields, approverUid)
      -> same pattern
  rejectBudget(budgetId, approverUid) / rejectExpenditure(requestId, approverUid)
  recordIncome(income) -> simple create, no status field needed
  recordDisbursement(expenditureId, disbursement)
      -> client-side pre-check: disbursement.amount + expenditure.totalDisbursed <= expenditure.approvedAmount
         (fast UX feedback; the real guard is server-side, Section 8/9)
      -> writes to disbursements subcollection
  getApprovedBudgets(branchId) / getApprovedExpenditures(branchId)
      -> used by Secretary's documentation view; queries with status == "approved" filter
  getOutstandingBalance(expenditureId) -> approvedAmount - totalDisbursed
```

---

## 8. Cloud Functions (Server-Side Logic)

This is where the real integrity of the module lives — never trust the client for these operations.

### 8.1 `onBudgetApproved` (Firestore trigger: update on `/budgets/{budgetId}`)
```
Trigger condition: status changes from "pending" to "approved"
1. Compare original* fields vs approved* fields
2. Build changesSummary[] for any field that differs
3. Write a /notifications document for requestedBy:
     type: changesSummary.length > 0 ? "budget-approved-with-changes" : "budget-approved"
4. (Document is now naturally visible to Secretary via status=="approved" query — no extra action needed)
```

### 8.2 `onExpenditureRequestApproved` (trigger: update on `/expenditureRequests/{requestId}`)
```
Trigger condition: status changes from "pending" to "approved"
1. Compute changesSummary (same pattern as budget)
2. Create the official /expenditures/{expenditureId} record:
     sourceRequestId: requestId, approvedAmount, category, description,
     approvedBy, date: now, totalDisbursed: 0, status: "not-disbursed"
3. Write notification to requestedBy (Finance) with changesSummary + final figures
```

### 8.3 `onDisbursementCreated` (trigger: create on `.../expenditures/{expenditureId}/disbursements/{id}`)
```
1. Read parent expenditure doc (approvedAmount, current totalDisbursed)
2. VALIDATE: if (currentTotalDisbursed + newAmount) > approvedAmount:
     -> reject the write (delete the doc / throw), do NOT increment
     -> optionally write an error notification back to disbursedBy
3. Otherwise, atomically:
     expenditure.totalDisbursed = FieldValue.increment(newAmount)
     recalculate status based on new total vs approvedAmount
```

### 8.4 `logAuditEntry` (generic trigger, reused across all finance collections)
```
onWrite on: /budgets/*, /expenditureRequests/*, /expenditures/*,
            /disbursements/*, /income/*
-> write to /auditLogs: module, documentId, action (create/update),
   before, after, performedBy (from request context / lastEditedBy field),
   timestamp: serverTimestamp()
```

### 8.5 Why these must be Cloud Functions, not client logic
- **`totalDisbursed` aggregation** must be atomic and race-condition-safe — two disbursements logged seconds apart by two devices (possible with offline desktop clients syncing) could both read a stale total if computed client-side.
- **changesSummary diffing** must be computed from server-trusted before/after state, not from what the client claims changed.
- **Over-disbursement blocking** must not be bypassable by a modified/offline client — the function is the last line of defense even if the client-side check (Section 7) is skipped or stale.

---

## 9. Security Rules

Key rules to implement in `firestore.rules` (illustrative, not exhaustive):

```javascript
// Only Finance can create budget/expenditure requests
match /branches/{branchId}/budgets/{budgetId} {
  allow create: if hasPermission('createBudgetRequest') && belongsToBranch(branchId);
  allow update: if hasPermission('approveBudget')
                && belongsToBranch(branchId)
                && request.auth.uid != resource.data.requestedBy; // segregation of duties
  allow read: if belongsToBranch(branchId) &&
              (hasPermission('approveBudget')                         // Lead Pastor: all
               || (hasPermission('createBudgetRequest')
                   && resource.data.status == 'approved')              // Finance: approved only
               || (hasPermission('viewNonFinancialReports')            // Secretary: approved only
                   == false && hasRole('secretary')
                   && resource.data.status == 'approved'));
}

match /branches/{branchId}/expenditures/{expenditureId}/disbursements/{id} {
  allow create: if hasPermission('recordDisbursement')
                && belongsToBranch(branchId)
                && willNotExceedApprovedAmount(branchId, expenditureId, request.resource.data.amountDisbursed);
  allow update, delete: if false; // disbursements are append-only
}

match /branches/{branchId}/auditLogs/{logId} {
  allow read: if hasPermission('viewFinancialReports') || isLeadPastor();
  allow write: if false; // Cloud Functions (Admin SDK) only
}
```

**Core principles encoded above:**
- Requester ≠ approver, enforced at the rule level, not just the UI.
- Secretary's read access is filtered to `status == "approved"` directly in the rule, so a client can't even query pending items.
- Disbursements are immutable once written (corrections happen via a new, clearly-labeled adjustment disbursement, not an edit — preserves the ledger's integrity).
- `willNotExceedApprovedAmount()` is a rules helper function performing a `get()` on the parent expenditure — a second, rule-level guard alongside the Cloud Function check in 8.3.

---

## 10. Notification Logic

| Event | Recipient | Message pattern |
|---|---|---|
| Budget approved, no changes | Finance (requester) | "Your budget request for [category] was approved." |
| Budget approved, with changes | Finance (requester) | "Your budget request for [category] was approved with changes: amount ₦X → ₦Y." |
| Expenditure approved, no changes | Finance (requester) | "Your expenditure request for [description] was approved." |
| Expenditure approved, with changes | Finance (requester) | "Your expenditure request for [description] was approved with changes: [diff]." |
| Budget/Expenditure rejected | Finance (requester) | "Your request for [description] was rejected." |

Notifications render via the `DiffViewer` component (Section 6) when `changesSummary` is non-empty, and are surfaced both as an in-app badge/list (Section 5.1.8) and optionally pushed via FCM for real-time awareness.

---

## 11. Offline-First Considerations (Desktop)

- **Income and disbursement entries** are low-risk to create offline — they don't require approval, so they can be written to the local Isar cache and queued in the outbox immediately, with a `PendingSyncBadge` shown until confirmed synced.
- **Budget/Expenditure requests created offline** by Finance: safe to queue, since they simply enter "pending" status once synced — no urgency.
- **Approvals performed offline** by the Lead Pastor: higher caution. The actual approval (and its side effects — diff computation, expenditure record creation, notification) only truly happens once the write reaches Firestore and the Cloud Function fires. The UI should clearly label an offline approval as **"Approval pending sync — not yet final"** rather than implying it's complete.
- **Disbursements created offline**: the client-side over-disbursement check (Section 7) uses the last-synced `totalDisbursed` value, which may be stale if another disbursement was made elsewhere and not yet synced. Treat any offline-created disbursement as provisional until the server-side check in 8.3 confirms it — surface a clear "provisional, pending validation" state, and handle the rare rejection case (sync brings back a rejection because the approved amount was exceeded by a race condition) with a clear in-app alert to Finance so they can adjust.

---

## 12. Edge Cases & Validation Rules

- **Can Finance edit or delete an income/disbursement entry after submission?** Recommended default: **no direct edit** — append a correcting entry instead (e.g. a negative/adjustment income entry with a comment explaining the correction), preserving full history. Confirm this with the church; if a short edit-window is wanted, implement it as a time-boxed exception with its own audit trail, not a silent overwrite.
- **What happens if Lead Pastor rejects a request?** It stays visible in Finance's tracker as "rejected" (not deleted), so Finance retains a record of what was declined and why (a rejection reason field is worth adding).
- **Can a rejected budget/expenditure be resubmitted?** Recommended: Finance creates a **new** request rather than reopening the rejected one — keeps each request's history clean and linear.
- **Partial approval nuance:** "Edit & Approve" already covers this — the pastor reducing the requested amount before approving IS the partial-approval mechanism; no separate "partial approval" status is needed.
- **Multiple disbursements exceeding approved amount due to a race condition (rare, mainly relevant offline):** handled by the server-side atomic check in 8.3 as the ultimate authority, with the offline UI treating any such entry as provisional (Section 11).
- **Currency/rounding:** store amounts as integers in kobo (smallest unit) internally to avoid floating-point rounding issues common with currency in JavaScript-based Cloud Functions; format to Naira with `MoneyInputField`/display formatters only at the UI layer.

---

## 13. Implementation Checklist

- [ ] Data models for `budgets`, `expenditureRequests`, `expenditures`, `disbursements`, `income`, `notifications` created in Firestore
- [ ] `FinanceRepository` interface + web/desktop implementations
- [ ] `MoneyInputField`, `StatusChip`, `ApprovalCard`, `DiffViewer`, `DisbursementBalanceBar` components built
- [ ] Finance screens: Dashboard, Income Entry/List, Budget Tracker, Expenditure Tracker, Disbursement screen, Notifications
- [ ] Lead Pastor screens: Approval Queue, Financial Overview Dashboard, Full History (edit-capable)
- [ ] Secretary screen: Financial Documentation View (approved-only, read-only, exportable)
- [ ] Cloud Functions: `onBudgetApproved`, `onExpenditureRequestApproved`, `onDisbursementCreated`, `logAuditEntry`
- [ ] Security rules: segregation of duties, Secretary approved-only filtering, disbursement immutability, over-disbursement guard
- [ ] Notification rendering (in-app list + diff viewer)
- [ ] Offline: outbox queue for finance writes, `PendingSyncBadge`, provisional-state handling for offline approvals/disbursements
- [ ] Currency stored in kobo internally; formatted at UI layer only
- [ ] End-to-end test: submit expenditure request → pastor edits & approves → Finance notified with diff → expenditure record created → Secretary sees it documented → Finance disburses in two parts → balance and status update correctly → attempt over-disbursement is blocked
