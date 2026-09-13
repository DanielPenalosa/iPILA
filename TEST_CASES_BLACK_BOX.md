# iPILA – Black Box Test Cases

**System:** iPILA – Integrated Public Information & Local Access  
**Municipality:** Municipality of Pila, Laguna  
**Testing Type:** Black Box (Functional)  
**Tester:** _______________  
**Date:** _______________

---

## Overview

Twelve test cases were developed based on the documented functional requirements of the iPILA system. Each test case targeted a specific feature or module: (TC-01) Citizen Registration and Login, (TC-02) Report Submission, (TC-03) My Reports and Report Tracking, (TC-04) Community Reports, (TC-05) Admin User Management, (TC-06) Admin Report Management, (TC-07) Department and Barangay Report Workflow, (TC-08) Ordinance Management, (TC-09) System Alerts and Notifications, (TC-10) Citizen Profile Management, (TC-11) Map and Geolocation, and (TC-12) Analytics Dashboard. Each test case includes preconditions, step-by-step procedures, expected results, and pass/fail status indicators.

---

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Pass |
| ❌ | Fail |
| ⚠️ | Partial / Needs Review |
| — | Not Run |

**Priority:** P1 = Critical &nbsp; P2 = High &nbsp; P3 = Medium &nbsp; P4 = Low

---

## TC-01: Citizen Registration and Login

**Description:** Verifies that citizens can create an account, submit it for admin approval, and log in with valid credentials. Also covers validation rules, rejected/suspended account handling, password recovery, and role-based routing upon login.

**Preconditions:**
- iPILA app is accessible (mobile or web)
- No existing account for the test email

| # | Test Scenario | Steps | Expected Result | Priority | Status |
|---|--------------|-------|-----------------|----------|--------|
| 1.1 | Register with valid data | Fill all fields (name, email, phone, barangay, password), upload valid ID photo, accept Terms, tap Register | Account created with Pending status; Registration Submitted screen shown | P1 | — |
| 1.2 | Register – password mismatch | Enter different values in Password and Confirm Password, submit | Error "Passwords do not match"; form not submitted | P1 | — |
| 1.3 | Register – weak password | Enter password shorter than 6 characters, submit | Validation error shown; registration blocked | P2 | — |
| 1.4 | Register – invalid email format | Enter "notanemail" as email, submit | Validation error for email format | P2 | — |
| 1.5 | Register – invalid phone number | Enter "12345" as phone number, submit | Validation error for phone number | P2 | — |
| 1.6 | Login – valid citizen credentials | Enter approved citizen email and password, tap Login | Redirected to Home screen with bottom navigation (mobile) | P1 | — |
| 1.7 | Login – admin account | Enter admin credentials on web, tap Login | Redirected to Admin Dashboard (`/admin`) | P1 | — |
| 1.8 | Login – department account | Enter department credentials, tap Login | Redirected to Department Dashboard (`/department`) | P1 | — |
| 1.9 | Login – barangay account | Enter barangay credentials, tap Login | Redirected to Barangay Dashboard (`/barangay`) | P1 | — |
| 1.10 | Login – wrong password | Enter valid email with incorrect password | Error message shown; user stays on login screen | P1 | — |
| 1.11 | Login – pending account | Enter credentials of unapproved citizen | Redirected to Pending Approval screen; cannot access features | P1 | — |
| 1.12 | Login – suspended account | Enter credentials of suspended citizen | Error about suspension shown; login denied | P1 | — |
| 1.13 | Forgot password | Tap Forgot Password, enter registered email, submit | Password reset email sent; success message shown | P2 | — |
| 1.14 | Logout | Tap logout icon from any screen | User logged out; redirected to Login; cannot navigate back without re-login | P1 | — |
| 1.15 | Route protection – citizen to admin | Log in as citizen, manually navigate to `/admin` | Redirected to `/home`; access denied | P1 | — |
| 1.16 | Unauthenticated access | Without logging in, navigate to `/home` | Redirected to `/login` | P1 | — |

---

## TC-02: Report Submission

**Description:** Verifies that approved citizens can submit issue reports with the correct category, barangay, description, GPS location, and optional photos. Also validates that required fields are enforced and that photo limits are respected.

**Preconditions:**
- Logged in as an approved citizen
- Device has camera/gallery access and location permissions

| # | Test Scenario | Steps | Expected Result | Priority | Status |
|---|--------------|-------|-----------------|----------|--------|
| 2.1 | Submit report – all required fields | Select category and barangay, write description, tap Get GPS, tap Submit | Report submitted; status = Pending; redirected to report detail | P1 | — |
| 2.2 | Submit report – with photos | Fill all fields, add 1–3 photos from gallery or camera, submit | Photos uploaded and attached; visible in report detail | P2 | — |
| 2.3 | Submit – missing category | Leave category blank, fill all others, submit | Validation error "Please select a category" | P1 | — |
| 2.4 | Submit – missing description | Leave description blank, fill all others, submit | Validation error for empty description | P1 | — |
| 2.5 | Submit – missing barangay | Leave barangay blank, fill all others, submit | Validation error "Please select a barangay" | P1 | — |
| 2.6 | GPS location capture | Tap Get GPS on the report form | Coordinates captured and displayed; street address geocoded and shown | P2 | — |
| 2.7 | Photo limit enforcement | Attempt to add more than 3 photos | System limits to 3 or shows a warning | P3 | — |

---

## TC-03: My Reports and Report Tracking

**Description:** Verifies that citizens can view, filter, and track all their submitted reports. Covers the status timeline, before/after photo comparison, full-screen image viewer, and report deletion rules.

**Preconditions:**
- Logged in as a citizen with at least one submitted report

| # | Test Scenario | Steps | Expected Result | Priority | Status |
|---|--------------|-------|-----------------|----------|--------|
| 3.1 | View My Reports list | Tap My Reports tab | All personal reports listed with status badges and categories | P1 | — |
| 3.2 | Filter by status | Tap In Progress filter chip | Only In Progress reports shown | P2 | — |
| 3.3 | View report detail | Tap a report card | Full details shown: category, description, barangay, date, photos, status timeline | P1 | — |
| 3.4 | Delete pending report | Open Pending report, tap Delete, confirm | Report deleted; no longer in My Reports | P2 | — |
| 3.5 | Cannot delete active report | Open an In Progress report, check for delete option | No delete button visible or action blocked | P2 | — |
| 3.6 | View status timeline | Open a report with multiple status changes | Timeline shows each status with timestamp and updated-by name | P2 | — |
| 3.7 | View before/after completion photos | Open a Resolved report | Before and after photos displayed side by side for comparison | P2 | — |
| 3.8 | Tap photo for fullscreen view | Open report detail, tap any photo | Full-screen image viewer opens; can swipe between photos | P3 | — |

---

## TC-04: Community Reports

**Description:** Verifies that citizens can browse, search, and filter all community-reported issues. Also verifies that filter bottom sheets do not overflow the screen.

**Preconditions:**
- Logged in as a citizen
- At least 5 community reports exist with varied statuses and categories

| # | Test Scenario | Steps | Expected Result | Priority | Status |
|---|--------------|-------|-----------------|----------|--------|
| 4.1 | Browse community reports | Tap Community Reports tab | All active reports listed with status badge, urgency, and reporter name | P2 | — |
| 4.2 | Filter by category | Tap Category filter, select "Road Damage" | Only Road Damage reports shown | P2 | — |
| 4.3 | Filter by status – no overflow | Tap Status filter, open the bottom sheet | Bottom sheet is scrollable and does not overflow the screen | P1 | — |
| 4.4 | Filter by barangay | Tap Barangay filter, select a barangay | Only reports from selected barangay shown | P2 | — |

---

## TC-05: Admin User Management

**Description:** Verifies all admin capabilities for managing citizen registrations and active user accounts, including approval, rejection, suspension, reactivation, deletion, and creation of department and barangay accounts. Also verifies the redesigned create account dialog with password validation and show/hide toggle.

**Preconditions:**
- Logged in as Admin
- At least one pending citizen registration exists

| # | Test Scenario | Steps | Expected Result | Priority | Status |
|---|--------------|-------|-----------------|----------|--------|
| 5.1 | View pending registrations | Navigate to Users → Pending tab | Pending citizens listed with name, email, phone, barangay, ID photo, and date | P1 | — |
| 5.2 | Approve single registration | Tap Approve on a pending user | User approved; moves to Active Users; citizen can log in | P1 | — |
| 5.3 | Reject registration | Tap Reject on a pending user, confirm | Confirmation dialog shown; user rejected and removed from Pending | P1 | — |
| 5.4 | Bulk approve | Select multiple pending users, tap Approve All | All selected users approved at once | P2 | — |
| 5.5 | Suspend active user | Tap Suspend on an active user | User suspended; cannot log in; shows Suspended status | P1 | — |
| 5.6 | Reactivate suspended user | Find suspended user, tap Reactivate | User reactivated; can log in again | P2 | — |
| 5.7 | Delete user | Tap Delete on a user, confirm | User removed from active list; cannot log in | P2 | — |
| 5.8 | Create department account – valid | Tap + Add Department, fill all fields with matching passwords, tap Create Account | Account created; appears in Department Accounts section | P1 | — |
| 5.9 | Create department – password mismatch | Enter different passwords in the dialog | Create button disabled; error "Passwords do not match" shown | P1 | — |
| 5.10 | Create department – weak password | Enter password shorter than 6 characters | Create button stays disabled | P1 | — |
| 5.11 | Show/hide password toggle | Tap eye icon on password field | Password text toggles between hidden and visible | P2 | — |
| 5.12 | Create barangay account | Tap + Add Barangay, fill all fields, tap Create Account | Barangay account created; appears in Barangay Accounts section | P1 | — |

---

## TC-06: Admin Report Management

**Description:** Verifies the complete admin report lifecycle including status transitions, department assignment, rejection, returning for revision, and final verification with before/after photos. Also covers bulk actions and filtering.

**Preconditions:**
- Logged in as Admin
- Reports in various statuses exist

| # | Test Scenario | Steps | Expected Result | Priority | Status |
|---|--------------|-------|-----------------|----------|--------|
| 6.1 | View all reports | Navigate to Reports | All reports listed with status badge, category, reporter, barangay, date | P1 | — |
| 6.2 | Transition: Pending → Under Review | Open Pending report, change status to Under Review, save | Status updated; timeline entry added with timestamp | P1 | — |
| 6.3 | Assign to department | Open Under Review report, assign to a department, save | Status changes to Assigned; department portal shows report | P1 | — |
| 6.4 | Reject report | Set status to Rejected, add remarks, save | Report marked Rejected; citizen notified | P2 | — |
| 6.5 | Return for revision | Open Done report, set status to Needs Revision, add remarks, save | Status changes to Needs Revision; department sees revision banner with remarks | P2 | — |
| 6.6 | Resolve report | Open Done report, review before/after photos, set status to Resolved, save | Report marked Resolved; before/after comparison shown; citizen notified | P1 | — |
| 6.7 | Filter by status | Apply status filter on Reports list | Only matching reports shown | P2 | — |
| 6.8 | Bulk assign reports | Select multiple reports, use Bulk Actions to assign to a department | All selected reports assigned | P2 | — |

---

## TC-07: Department and Barangay Report Workflow

**Description:** Verifies that department and barangay accounts can view assigned reports, submit progress updates, and mark reports as done. Also verifies that photo attachment is only required when marking as Done, not for In Progress updates, and that the progress update sheet is properly designed.

**Preconditions:**
- Logged in as Department or Barangay
- At least one report has been assigned

| # | Test Scenario | Steps | Expected Result | Priority | Status |
|---|--------------|-------|-----------------|----------|--------|
| 7.1 | View assigned reports | Log in as Department/Barangay, navigate to Reports | Assigned reports listed with category, barangay, and urgency | P1 | — |
| 7.2 | Progress update – In Progress, no photo required | Open Assigned report, tap Add Progress Update, select In Progress, save without photo | Status updated to In Progress; photo section not shown; update saved | P1 | — |
| 7.3 | Mark as Done – save blocked without photo | Select Done in update sheet, attempt to save without attaching photo | Save button disabled; Completion Photo (required) section visible | P1 | — |
| 7.4 | Mark as Done – with photo | Select Done, attach at least 1 photo, add remarks, tap Mark as Done | Report submitted for admin verification; status becomes Done | P1 | — |
| 7.5 | Status pill selector | Open progress update sheet | Status options shown as pill/chip buttons, not a dropdown | P2 | — |
| 7.6 | Address revision request | Open Needs Revision report, view revision banner with admin remarks, resubmit with corrected photo | Report resubmitted for admin review | P2 | — |
| 7.7 | View analytics | Navigate to Analytics | Charts showing assigned count, completion rate, average time, category breakdown | P3 | — |

---

## TC-08: Ordinance Management

**Description:** Verifies that admins can create, edit, and deactivate ordinances, and that citizens can browse and search the active ordinance list.

**Preconditions:**
- Admin logged in for management tests
- Citizen logged in for viewing tests

| # | Test Scenario | Steps | Expected Result | Priority | Status |
|---|--------------|-------|-----------------|----------|--------|
| 8.1 | Create new ordinance | Navigate to Ordinances in admin, tap + Add Ordinance, fill all fields, save | Ordinance created; appears in the list | P2 | — |
| 8.2 | Edit ordinance | Open an existing ordinance, edit title or description, save | Ordinance updated with new content | P2 | — |
| 8.3 | Deactivate ordinance | Open an ordinance, tap Delete/Deactivate, confirm | Ordinance deactivated; no longer visible to citizens | P3 | — |
| 8.4 | Citizen views ordinance list | Log in as citizen, tap Ordinances tab | Active ordinances listed with title, category, and date | P2 | — |
| 8.5 | Citizen searches ordinances | Type a keyword in the search field on Ordinances screen | List filtered in real-time to matching ordinances | P3 | — |

---

## TC-09: System Alerts and Notifications

**Description:** Verifies that admins can create and broadcast system alerts, that citizens receive notifications when their report status changes, and that unread badge counts update correctly.

**Preconditions:**
- Admin logged in for alert creation
- Citizen has an active report for notification tests

| # | Test Scenario | Steps | Expected Result | Priority | Status |
|---|--------------|-------|-----------------|----------|--------|
| 9.1 | Create system alert | Navigate to Alerts in admin, tap Create Alert, fill title and message, send | Alert created and broadcast; visible to citizens in Alerts screen | P2 | — |
| 9.2 | Citizen views alerts | Log in as citizen, navigate to Alerts screen | System alerts listed with titles and dates | P2 | — |
| 9.3 | Citizen notified on status change | Admin changes report status; check citizen notifications | Notification appears in citizen's notifications | P2 | — |
| 9.4 | Notification badge count | Receive new notifications, view notification icon | Badge count increments for each unread notification | P3 | — |

---

## TC-10: Citizen Profile Management

**Description:** Verifies that citizens can view and edit their profile information, update their profile photo, and initiate a password change.

**Preconditions:**
- Logged in as an approved citizen

| # | Test Scenario | Steps | Expected Result | Priority | Status |
|---|--------------|-------|-----------------|----------|--------|
| 10.1 | View profile | Navigate to Profile screen | Full name, email, phone, barangay, and profile photo displayed | P2 | — |
| 10.2 | Edit profile | Edit phone number or barangay, tap Save | Profile updated with new values | P2 | — |
| 10.3 | Upload profile photo | Tap profile photo, select image from gallery, save | Profile photo updated and displayed | P3 | — |
| 10.4 | Change password | Tap Change/Reset Password, follow the flow | Password reset email sent or new password saved | P2 | — |

---

## TC-11: Map and Geolocation

**Description:** Verifies that the map view loads correctly with report pins, that clicking a pin opens a report dialog, and that the "Go to Map" button from a report detail navigates to and focuses the correct pin.

**Preconditions:**
- Logged in as Admin, Department, or Barangay
- At least 3 reports with GPS coordinates exist

| # | Test Scenario | Steps | Expected Result | Priority | Status |
|---|--------------|-------|-----------------|----------|--------|
| 11.1 | Map loads with report pins | Navigate to Map in admin/department/barangay portal | Map loads; pins visible for all geolocated reports | P2 | — |
| 11.2 | Click pin opens report dialog | Click a report pin on the map | Report summary modal opens with category, status, and View Full Report link | P2 | — |
| 11.3 | Go to Map from report detail | Open any report detail, tap Go to Map | Navigates to map; flies to the exact report pin and auto-opens the dialog | P3 | — |

---

## TC-12: Analytics Dashboard

**Description:** Verifies that real-time statistics and charts render correctly for the admin dashboard and for department/barangay analytics screens.

**Preconditions:**
- Logged in as Admin or Department/Barangay
- Sufficient report data exists for meaningful chart rendering

| # | Test Scenario | Steps | Expected Result | Priority | Status |
|---|--------------|-------|-----------------|----------|--------|
| 12.1 | Admin dashboard stats | Log in as Admin, view Dashboard | Real-time stats shown: Total Reports, Awaiting Validation, In Progress, Resolved, Overdue | P2 | — |
| 12.2 | Admin analytics charts | Navigate to Analytics | Charts render: category distribution, status breakdown, response time analysis | P3 | — |
| 12.3 | Department analytics | Log in as Department, navigate to Analytics | Metrics shown: assigned count, completion rate, average time, category workload | P3 | — |
| 12.4 | Barangay analytics | Log in as Barangay, navigate to Analytics | Barangay-specific performance metrics and issue trends shown | P3 | — |

---

## Test Summary

| Test Case | Module | Total Items | Pass | Fail | Partial | Not Run |
|-----------|--------|-------------|------|------|---------|---------|
| TC-01 | Citizen Registration and Login | 16 | | | | |
| TC-02 | Report Submission | 7 | | | | |
| TC-03 | My Reports and Report Tracking | 8 | | | | |
| TC-04 | Community Reports | 4 | | | | |
| TC-05 | Admin User Management | 12 | | | | |
| TC-06 | Admin Report Management | 8 | | | | |
| TC-07 | Department and Barangay Workflow | 7 | | | | |
| TC-08 | Ordinance Management | 5 | | | | |
| TC-09 | System Alerts and Notifications | 4 | | | | |
| TC-10 | Citizen Profile Management | 4 | | | | |
| TC-11 | Map and Geolocation | 3 | | | | |
| TC-12 | Analytics Dashboard | 4 | | | | |
| **TOTAL** | | **82** | | | | |

---

*iPILA – Municipality of Pila, Laguna*
