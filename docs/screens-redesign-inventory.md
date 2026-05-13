# Screen Inventory for Redesign

This document inventories the current screens in `/website` and `/portal` based on Angular routing and the current templates/components.

## Scope

- Source apps:
  - `/Users/trandang/Documents/working/dcr/website`
  - `/Users/trandang/Documents/working/dcr/portal`
- Route sources:
  - `/Users/trandang/Documents/working/dcr/website/src/app/app-routing.module.ts`
  - `/Users/trandang/Documents/working/dcr/portal/src/app/app-routing.module.ts`
- Notes:
  - `portal` uses hash routing, so real URLs render as `/#/...`
  - This inventory focuses on user-facing screens and sub-screens, not reusable layout components

## Website

### Overview

The `website` app is a public-facing application intake flow. It has a landing page, a multi-step application wizard, a confirmation page, a maintenance page, and an error page.

### Screen List

| Screen | Route | Access | Purpose | Key UI / Content |
| --- | --- | --- | --- | --- |
| Home | `/` | Public | Entry point for applicants | Top nav/title, two application cards, merchant CTA, agent/referral CTA, language selector, SSL trust badge |
| Application Wizard | `/application` | Public | Default application flow | Multi-step form, save/resume actions, disclaimer, home shortcut |
| Application Wizard by Type | `/application/:type` | Public | Type-specific application flow | Same base wizard with different step structure depending on `type` |
| Confirmation | `/application/confirmation` | Public | Post-submit success state | Thank-you message, submission confirmation, next-step/support copy |
| Maintenance | `/maintainer` | Public | Temporary downtime page | Minimal message card with service unavailable text |
| Error / Not Found | `/page-not-found` | Public | Error state | Minimal error page shell |

### Detailed Notes

#### 1. Home

- Route: `/`
- Component: `HomeComponent`
- Source:
  - `/Users/trandang/Documents/working/dcr/website/src/app/pages/home/home.component.html`
- Current structure:
  - Fixed top nav with application title
  - Two side-by-side cards:
    - Merchants
    - Agents
  - Each card contains hero image, short description, and `Get Started` CTA
  - Language switcher appears conditionally
  - SSL/security badge shown in footer area
- Redesign implications:
  - This is the only true marketing/entry screen
  - Merchant and referral are currently treated as equal primary paths
  - Trust and multilingual entry are visible but visually secondary

#### 2. Application Wizard

- Routes:
  - `/application`
  - `/application/:type`
- Component: `ProcessFormComponent`
- Source:
  - `/Users/trandang/Documents/working/dcr/website/src/app/pages/application/components/process.component.html`
  - `/Users/trandang/Documents/working/dcr/website/src/app/pages/application/components/process.component.ts`
- Current shared structure:
  - Card-based page shell
  - Header with home icon and application title
  - Large disclaimer block
  - Save form and resume form actions
  - Step wizard navigation

##### Merchant flow

- Primary route: `/application/merchant`
- Steps:
  1. Requested Payment Methods + Referral Code
  2. Corporate Information
  3. Owner(s) Information
  4. Business Profile
  5. Settlement Information
  6. Required Documents
- Key patterns:
  - Very long form
  - Mixed control types: checkboxes, inputs, selects, textareas, uploads
  - Repeating owner sections
  - Dense enterprise/compliance content

##### Referral flow

- Primary route: `/application/referral`
- Steps:
  1. Primary Contact Information
  2. Corporate Information
  3. Settlement Information
  4. Required Documents
- Key patterns:
  - Shorter than merchant flow
  - Similar visual shell, fewer sections

##### Hidden route variant

- The component logic also accepts `/application/whitelabel`
- This variant is routable in code, but it is not linked from the home screen
- It should be considered during redesign if the product still supports it

#### 3. Confirmation

- Route: `/application/confirmation`
- Component: `ConfirmComponent`
- Source:
  - `/Users/trandang/Documents/working/dcr/website/src/app/pages/application/components/confirm.component.html`
- Current structure:
  - Thank-you title
  - Submission confirmation copy
  - Support contact email
  - No next-step CTA beyond informational copy
- Redesign implications:
  - Opportunity to make status, next steps, and support clearer
  - Could become a stronger completion screen with case/reference info

#### 4. Maintenance

- Route: `/maintainer`
- Component: `MaintainerComponent`
- Source:
  - `/Users/trandang/Documents/working/dcr/website/src/app/pages/maintainer/maintainer.component.html`
- Current structure:
  - Basic shell
  - Two-line downtime message
- Redesign implications:
  - Could be standardized into a more robust service-status state

#### 5. Error / Not Found

- Route: `/page-not-found`
- Component: `ErrorComponent`
- Source:
  - `/Users/trandang/Documents/working/dcr/website/src/app/pages/error/error.component.html`
- Current structure:
  - Minimal template
- Redesign implications:
  - Currently has little UX guidance or recovery

## Portal

### Overview

The `portal` app is an authenticated back-office/admin portal for reviewing applications, managing users, and maintaining the logged-in user account.

### Screen List

| Screen | Route | Access | Purpose | Key UI / Content |
| --- | --- | --- | --- | --- |
| Login | `/#/login` | Public | Authentication entry | Email, password, login action, forgot password link |
| Forgot Password | `/#/forgot-password` | Public | Password reset request | Email field, reset action, back-to-login link |
| Dashboard | `/#/` | Authenticated | High-level reporting | Welcome header, pending/approved/declined summary cards, statistics chart |
| Applications List | `/#/applies` | Authenticated | Review submitted applications | Filters, search, table, pagination |
| Application Detail | `/#/applies/view/:id` | Authenticated | Review a single application | Read-only application detail, accordion sections, approve/decline actions |
| Users List | `/#/users` | Authenticated | Manage portal users | Search, role filter, add user CTA, table, pagination |
| User Create | `/#/users/create` | Authenticated | Create new user | User form, role select, create action |
| User Edit | `/#/users/update/:id` | Authenticated | Update existing user | Same user form, save action |
| User Detail | `/#/users/view/:id` | Authenticated | Read-only user detail | Basic profile fields, update CTA |
| Profile | `/#/account` | Authenticated | Logged-in user account view | Personal information summary, edit profile CTA |
| Edit Profile | `/#/account/edit-profile` | Authenticated | Update account + password | Profile form, separate change-password form |

### Detailed Notes

#### 1. Login

- Route: `/#/login`
- Component: `LoginComponent`
- Source:
  - `/Users/trandang/Documents/working/dcr/portal/src/app/pages/login/login.component.html`
- Current structure:
  - Branded top header with logo
  - Centered login form
  - Email and password fields
  - Primary login button
  - Forgot-password link
- Redesign implications:
  - This is a standalone auth shell, visually separate from the internal portal layout

#### 2. Forgot Password

- Route: `/#/forgot-password`
- Component: `ForgotPasswordComponent`
- Source:
  - `/Users/trandang/Documents/working/dcr/portal/src/app/pages/forgot_password/forgot_password.component.html`
- Current structure:
  - Same auth shell as login
  - Single email field
  - Reset password CTA
  - Back-to-login link

#### 3. Dashboard

- Route: `/#/`
- Component: `DashboardComponent`
- Source:
  - `/Users/trandang/Documents/working/dcr/portal/src/app/pages/dashboard/dashboard.component.html`
- Current structure:
  - Welcome heading with first name
  - Three summary cards:
    - Pending
    - Approved
    - Declined
  - Statistics section
  - Date-range/filter dropdown
  - Bar chart
- Redesign implications:
  - This is the analytics/home screen for operations users
  - Summary cards and chart are the core information architecture

#### 4. Applications List

- Route: `/#/applies`
- Component: `ListComponent`
- Source:
  - `/Users/trandang/Documents/working/dcr/portal/src/app/pages/apply/components/list.component.html`
- Current structure:
  - Search field
  - Domain filter
  - Start/end date filters
  - Type filter
  - Status filter
  - Page-size control
  - Results table
  - Pagination
- Table columns:
  - Code
  - Date Submit
  - Merchant Name
  - Contact Info
  - Approved By
  - Type
  - Actions
- Redesign implications:
  - This is the primary operational queue screen
  - Filtering and table scanability matter more than visual richness

#### 5. Application Detail

- Route: `/#/applies/view/:id`
- Component: `ViewComponent`
- Source:
  - `/Users/trandang/Documents/working/dcr/portal/src/app/pages/apply/components/view.component.html`
- Current structure:
  - Back button
  - Conditional Approve / Decline actions when status is pending
  - Large read-only detail view
  - Accordion/collapsible sections
- Merchant application sections include:
  - Requested Payment Methods
  - Referral
  - Corporate Information
  - Owner(s) Information
  - Business Profile
  - Settlement Information
  - Required Documents
- Redesign implications:
  - This is the most information-dense portal screen
  - Strong section navigation, status hierarchy, and review actions will matter

#### 6. Users List

- Route: `/#/users`
- Component: `ListComponent`
- Source:
  - `/Users/trandang/Documents/working/dcr/portal/src/app/pages/users/components/list.component.html`
- Current structure:
  - Search field
  - Role filter
  - Page-size control
  - Add New button
  - Users table
  - Pagination
- Table columns:
  - Index
  - First Name
  - Last Name
  - Email
  - Phone Number
  - Role
  - Actions
- Row actions:
  - View
  - Edit
  - Delete

#### 7. User Create / Edit

- Routes:
  - `/#/users/create`
  - `/#/users/update/:id`
- Component: `FormComponent`
- Source:
  - `/Users/trandang/Documents/working/dcr/portal/src/app/pages/users/components/form.component.html`
- Current structure:
  - Basic information form
  - Fields:
    - First Name
    - Last Name
    - Email
    - Phone Number
    - Password
    - Confirm Password
    - Role
  - Footer actions:
    - Cancel
    - Create or Save
- Redesign implications:
  - Same form handles both create and edit states

#### 8. User Detail

- Route: `/#/users/view/:id`
- Component: `ViewComponent`
- Source:
  - `/Users/trandang/Documents/working/dcr/portal/src/app/pages/users/components/view.component.html`
- Current structure:
  - Read-only basic information layout
  - Update CTA
  - Back CTA

#### 9. Profile

- Route: `/#/account`
- Component: `ProfileComponent`
- Source:
  - `/Users/trandang/Documents/working/dcr/portal/src/app/pages/account/components/profile.component.html`
- Current structure:
  - Personal information summary
  - Masked password placeholders
  - Edit Profile CTA

#### 10. Edit Profile

- Route: `/#/account/edit-profile`
- Component: `EditProfileComponent`
- Source:
  - `/Users/trandang/Documents/working/dcr/portal/src/app/pages/account/components/edit_profile.component.html`
- Current structure:
  - Edit personal information form
  - Separate change-password form section
  - Save / cancel actions in each section
- Redesign implications:
  - This screen combines two tasks:
    - profile editing
    - password changing
  - It may be worth separating those flows in a redesign

## Navigation Summary

### Website primary paths

- `/` -> choose applicant type
- `/application/merchant` -> merchant onboarding flow
- `/application/referral` -> referral onboarding flow
- `/application/confirmation` -> completion state

### Portal primary paths

- `/#/login` -> authentication
- `/#/` -> dashboard
- `/#/applies` -> review applications
- `/#/users` -> manage users
- `/#/account` -> manage own profile

## Redesign Priorities

These screens are likely the highest-priority redesign targets:

1. `website` home screen
2. `website` application wizard
3. `portal` dashboard
4. `portal` applications list
5. `portal` application detail
6. `portal` users list and user form

## Gaps and Caveats

- `website` has a hidden `whitelabel` application route accepted by component logic but not linked from the home screen.
- `portal` menu config exposes `Dashboard`, `Application`, and `Users` as primary navigation items; `Account` is routable but not part of the main sidebar config.
- Some screens are structurally simple shells around dense forms, so visual redesign should be paired with form IA cleanup, not just styling.
