# Fintech Redesign Plan — DCR Pay

> **Scope:** UI-only redesign. Zero functional changes. Pure HTML prototypes first, then migrate to Angular templates.
> **Direction:** Premium B2B fintech — Stripe / Mercury / Brex aesthetic. Trust-first, data-dense, minimal.

---

## 1. Design System

### Color Tokens

| Token | Value | Usage |
|---|---|---|
| `--sidebar` | `#1A2430` | Sidebar background (original brand dark) |
| `--sidebar-hover` | `#22303F` | Sidebar row hover |
| `--brand` | `#BE222F` | Primary CTA, active nav, buttons, accents |
| `--brand-hover` | `#A31E29` | Button hover state |
| `--bg` | `#F8FAFC` | Page background |
| `--surface` | `#FFFFFF` | Cards, modals, table rows |
| `--text` | `#0F172A` | Body text |
| `--text-muted` | `#64748B` | Labels, secondary copy |
| `--text-light` | `#94A3B8` | Placeholder, disabled |
| `--border` | `#E2E8F0` | Dividers, card borders |
| `--green` | `#16A34A` | Approved status |
| `--green-bg` | `#F0FDF4` | Approved badge background |
| `--amber` | `#D97706` | Pending status |
| `--amber-bg` | `#FFFBEB` | Pending badge background |
| `--red` | `#DC2626` | Declined / error status |
| `--red-bg` | `#FEF2F2` | Declined badge background |

### Typography

| Role | Font | Weight | Size |
|---|---|---|---|
| Body | Inter | 400 | 14–16px |
| Label / Caption | Inter | 500 | 11–13px |
| Subheading | Inter | 600 | 15–17px |
| Heading | Inter | 700 | 20–28px |
| Hero / Display | Inter | 700 | 32–42px |

- Line-height: `1.5` body · `1.15` headings
- Letter-spacing: `−0.02em` headings · `+0.07em` uppercase labels

### Spacing & Shape

- Base unit: `4px`
- Border-radius: `6px` inputs/buttons · `8px` cards · `12px` large cards
- Sidebar width: `240px` (collapsed: `64px`)
- Content max-width: `1200px`

### Elevation

| Level | Box-shadow |
|---|---|
| Flat | none |
| Raised | `0 1px 3px rgba(0,0,0,.10)` |
| Float | `0 4px 12px rgba(0,0,0,.08)` |
| Modal | `0 20px 40px rgba(0,0,0,.15)` |

### Icon System

- Library: **Heroicons** (outline, 24×24 viewBox)
- Stroke-width: `1.5` default · `2` emphasis
- Never use emoji as icons

---

## 2. Layout Architecture

### Website (Public)

```
┌─────────────────────────────────────────────┐
│  NAV  [Logo]                    [Lang ▾]    │  sticky, navy bg
├─────────────────────────────────────────────┤
│                                             │
│              HERO CONTENT                   │  centered, F8FAFC bg
│                                             │
├─────────────────────────────────────────────┤
│  FOOTER  [SSL badge]          [Legal links] │  white bg
└─────────────────────────────────────────────┘
```

### Portal (Authenticated)

```
┌──────────┬──────────────────────────────────┐
│          │  TOPBAR  [breadcrumb]  [user ▾]  │  64px, white, border-b
│ SIDEBAR  ├──────────────────────────────────┤
│  240px   │                                  │
│  navy    │        MAIN CONTENT              │  F8FAFC bg, padding 24px
│          │                                  │
│ [nav]    │                                  │
│ [nav]    │                                  │
│          │                                  │
│ [user]   │                                  │
└──────────┴──────────────────────────────────┘
```

---

## 3. Component Library (shared across screens)

| Component | Description |
|---|---|
| **StatusBadge** | Pill: Approved (green) / Pending (amber) / Declined (red) |
| **DataTable** | Sticky header, row hover `#F8FAFC`, sortable columns |
| **FilterBar** | Search + select dropdowns inline, compact 36px height |
| **SummaryCard** | Icon + metric + label + delta trend |
| **StepIndicator** | Horizontal progress bar for wizard steps |
| **SectionAccordion** | Collapsible form/detail section with chevron |
| **FormField** | Label + input + error message, 40px height inputs |
| **ActionMenu** | 3-dot dropdown: View / Edit / Delete |
| **Pagination** | Prev / numbered pages / Next, compact |
| **ConfirmModal** | Destructive action confirmation overlay |

---

## 4. Screen-by-Screen Plan

### Priority 1 — Website: Home `/`

**Current problems:** Generic card layout, no trust hierarchy, language switcher hidden.

**Redesign:**
- Sticky navy nav: logo left · language selector right
- Hero: eyebrow pill + H1 + subtitle (max 500px wide)
- Two equal-width cards with top color stripe (blue = merchant, purple = agent)
- Each card: icon · type label · title · description · CTA button · divider · meta row (steps, time, SSL)
- Footer: SSL badge left · legal links right

---

### Priority 2 — Portal: Dashboard `/#/`

**Current problems:** Plain cards, basic chart, no visual hierarchy.

**Redesign:**
- Dark sidebar: logo · Dashboard · Applications · Users · separator · account row
- Topbar: page title left · user avatar + name right
- Welcome line: "Good morning, [Name] — [date]"
- 3 summary cards in a row:
  - Pending (amber icon, count, delta from last period)
  - Approved (green icon, count, delta)
  - Declined (red icon, count, delta)
- Stats section:
  - Section title + date-range dropdown right
  - Bar chart (Chart.js CDN) — monthly submissions grouped by status
  - Chart legend: Approved · Pending · Declined

---

### Priority 3 — Portal: Applications List `/#/applies`

**Current problems:** Filters and table are visually undifferentiated, status is hard to scan.

**Redesign:**
- Page header: "Applications" H1 + application count badge
- Filter bar (single row): Search | Domain | Date From | Date To | Type | Status | Rows per page
- Table:
  - Columns: Code · Submitted · Merchant · Contact · Assigned To · Type · Status · Actions
  - Status rendered as **StatusBadge** component
  - Actions: 3-dot menu (View · Approve · Decline)
  - Zebra-free, row hover with `#F8FAFC` background
- Pagination below table: showing "1–20 of 143 results"

---

### Priority 4 — Website: Application Wizard Step 1 `/application/merchant`

**Current problems:** Dense disclaimer, unclear progress, form controls unstyled.

**Redesign:**
- Nav: logo · home icon right (no text)
- Progress indicator: step bubbles 1–6 with connector line, current step highlighted
- Page title: "Step 1 — Payment Methods & Referral"
- Disclaimer: collapsed by default with "View disclaimer ▾" toggle
- Save/resume row: "Save for later" link · "Resume existing application" link (muted, right-aligned)
- Form card (white, raised):
  - Section: "Select Payment Methods" — checkbox grid (2 cols)
  - Section: "Referral Code (Optional)" — single text input
- Footer: Back (disabled on step 1) | Next →

---

### Priority 5 — Portal: Login `/#/login`

**Redesign:**
- Full-height split: left panel (navy, logo + tagline) · right panel (white, centered form)
- Form: email · password · "Forgot password?" link · Login button (full-width blue)
- No registration link (internal tool)

---

### Priority 6 — Portal: Application Detail `/#/applies/view/:id`

**Redesign:**
- Sticky sub-header: back button · app code + merchant name · StatusBadge · Approve / Decline actions
- Sidebar TOC: anchor links to each accordion section
- Accordion sections (expanded by default for first, collapsed for rest)
- Each section: section title + chevron · read-only field grid (2 cols on desktop)
- Documents section: file thumbnails with download icons

---

### Priority 7 — Portal: Users List `/#/users`

**Redesign:**
- Same filter bar pattern as Applications List
- Table: Index · Name · Email · Phone · Role badge · Actions
- Role badge: Admin (blue) · Staff (slate) · Viewer (gray)
- "Add User" button top-right (primary blue)

---

### Priority 8 — Portal: User Create / Edit `/#/users/create`

**Redesign:**
- Full-page form card, max-width 640px, centered
- Section: "Personal Information" — First Name · Last Name · Email · Phone (2-col grid)
- Section: "Access" — Role select · Password · Confirm Password
- Footer actions: Cancel (ghost) · Create / Save (blue, right-aligned)

---

### Priority 9 — Website: Confirmation `/application/confirmation`

**Redesign:**
- Centered success state: large green checkmark icon · "Application Submitted" H1
- Reference number in monospace badge
- Timeline steps: Submitted → Under Review → Decision → Onboarding
- Support contact block: email link · estimated response time
- "Return Home" ghost button

---

### Priority 10 — Portal: Profile & Edit Profile `/#/account`

**Redesign:**
- Profile: avatar initials circle · name/role · two-column read-only fields · "Edit Profile" button
- Edit Profile: split into two cards — Personal Info · Change Password
- Each card independent save action

---

### Priority 11 — Website: Maintenance & Error

**Redesign:**
- Shared minimal shell: centered logo · icon · title · message · support link
- Maintenance: wrench icon, "We'll be back shortly" copy, ETA if available
- 404: broken-link icon, "Page not found", back-to-home button

---

## 5. Delivery Phases

### Phase A — HTML Prototypes (current phase)
Output self-contained `.html` files in `/docs/redesign/`. No Angular. Pure HTML + CSS custom properties. Used for stakeholder review.

| File | Screen |
|---|---|
| `01-website-home.html` | Website Home |
| `02-portal-dashboard.html` | Portal Dashboard |
| `03-portal-applications-list.html` | Portal Applications List |
| `04-website-wizard-step1.html` | Application Wizard Step 1 |
| `05-portal-login.html` | Portal Login |
| `06-portal-application-detail.html` | Application Detail |
| `07-portal-users-list.html` | Users List |
| `08-portal-user-form.html` | User Create/Edit |
| `09-website-confirmation.html` | Confirmation |
| `10-portal-profile.html` | Profile / Edit Profile |
| `11-website-maintenance.html` | Maintenance + Error |

### Phase B — Angular Migration
Apply HTML/CSS from Phase A into existing Angular component templates. Replace inline styles with component SCSS. Extract shared tokens to `_variables.scss`.

### Phase C — Component Polish
- Add `@media (prefers-reduced-motion: reduce)` guards
- Responsive pass: 375px / 768px / 1024px / 1440px
- Keyboard navigation audit
- WCAG AA contrast check on all text

---

## 6. Anti-patterns to Avoid

- No gradients on backgrounds
- No box-shadow on sidebar items (use background color only)
- No emojis as icons
- No border-radius > 12px on cards
- No animations > 300ms
- No color as the only status indicator (always pair with text/icon)
- No placeholder text as label substitute

---

## 7. Checklist Before Each Screen Ships

- [ ] All clickable elements have `cursor: pointer`
- [ ] Hover transitions are 150–200ms
- [ ] Focus rings visible (not removed with `outline: none`)
- [ ] All images/icons have `aria-label` or `aria-hidden`
- [ ] Form inputs have associated `<label>` elements
- [ ] Status is conveyed by text + color (not color alone)
- [ ] No horizontal scroll at 375px viewport
- [ ] Content not hidden behind fixed headers
