# QOR API — Backend

## Claude Rules

- **NEVER read `.env` files** — chứa credentials thật. Chỉ đọc `.env.example` nếu cần hiểu cấu hình.
- Sau mỗi lần fix code, chạy `sh dev.sh restart`.
- **Chỉ được thao tác trên server ở môi trường sandbox** (`*-sandbox` PM2 apps, `sandbox-*.qorteams.com`, `/var/www/dcr/sandbox/*`, DB `qor_sandbox`). **KHÔNG** đụng vào production (`api`, `merchant`, `portal`, `website`/`service` chạy tại `/var/www/dcr/{api,merchant,portal,website,service}`, domain `*.qorteams.com` không có prefix `sandbox-`, DB `qor_db`) — không restart, không sửa file, không chạy migration trên prod trừ khi user yêu cầu rõ ràng.
- **Quy ước branch của các submodule** (`api`, `merchant`, `portal`, `service`, `website`): branch `main` = code production, branch `sandbox` = code sandbox. Khi cần build/deploy cho môi trường nào, checkout đúng branch tương ứng.
- **KHÔNG sửa trực tiếp file build/dist đã deploy** (`/var/www/dcr/**/dist/**`, `/var/www/dcr/sandbox/**/dist/**`). Mọi thay đổi code phải sửa ở **source trong repo này** (đúng branch — `sandbox` để test, `main` là production), sau đó user tự commit + trigger auto build/deploy. Chỉ đọc dist để chẩn đoán lỗi (reverse-engineer bug từ bundle đã compile), không patch thẳng vào đó.
- **Quy trình sửa code (bắt buộc):** Claude **chỉ được sửa code trong repo `qor_manage_all` này, trên branch `sandbox`** của submodule liên quan — không tự tay sửa gì trên branch `main`, không sửa trực tiếp trên server. Sau khi Claude sửa xong, **user tự commit và tự merge `sandbox` → `main`**; GitHub Action trên branch `main` sẽ tự động trigger build/deploy production. Claude không tự merge, không tự push lên `main`, không tự trigger build.
  - ⚠️ Lưu ý khi merge `sandbox` → `main`: một số giá trị trong source **khác nhau theo môi trường** (port nội bộ trong `server.ts` — ví dụ sandbox dùng `6000`/`6001`, production dùng `3000`/`3001`; các file `setting.*.ts`). Merge thẳng tay (`git merge`) có thể vô tình mang giá trị sandbox đè lên giá trị production đúng — cần soát lại các chỗ này trước khi merge, không merge mù.

## Server Infrastructure (production host)

> Ghi chú: `/home/ubuntu/qor_manage_all` (repo này) là **dev monorepo** với 5 submodule. Bản build production/sandbox được deploy riêng dưới `/var/www/dcr`, không chạy trực tiếp từ repo này.

### Domains / Nginx (`qorteams.com`) — reverse proxy → PM2 port

| Domain | Proxy → port | PM2 app | Repo (submodule) |
|--------|--------------|---------|-------------------|
| `api.qorteams.com` | 3001 | `api` | `qor_api` |
| `merchant.qorteams.com` | 5000 | `merchant` | `qor_merchant` |
| `portal.qorteams.com` | 4000 | `portal` | `qor_crm_portal` |
| `apply.qorteams.com` | 8080 | `website` | `qor_crm_website` |
| default catch-all (`server_name _`, port 80) | `/api/` → 3000, `/` → 8080 | `service` / `website` | `qor_crm_backend` |
| `sandbox-api.qorteams.com` | 6001 | `api-sandbox` | — |
| `sandbox-merchant.qorteams.com` | 6003 | `merchant-sandbox` | — |
| `sandbox-portal.qorteams.com` | 6002 | `portal-sandbox` | — |
| `sandbox-apply.qorteams.com` | 6004 | `website-sandbox` | — |
| (no nginx vhost found) | 3000 / 6000 | `service` / `service-sandbox` | `qor_crm_backend` |

TLS certs via Certbot/Let's Encrypt for `api`, `apply`, `merchant`, `portal` (`.qorteams.com`). Sandbox vhosts are plain HTTP (port 80), no cert.

### PM2 processes (`pm2 list`)

Production apps live in `/var/www/dcr/{api,merchant,service,website,portal}` (defined in `/var/www/dcr/ecosystem.config.js`, plus extra apps started separately — `portal`/`website`/`service` are not in that ecosystem file).

| App | Deployed name | Version | cwd | Port |
|-----|---------------|---------|-----|------|
| api | `qor-api` | 1.0.0 | `/var/www/dcr/api` | 3001 |
| merchant | `qor-merchant` | 0.1.0 | `/var/www/dcr/merchant` | 5000 |
| service | `trucash-crm-service` | 1.0.9 | `/var/www/dcr/service` | 3000 |
| website | `trucash-crm-website` | 1.0.17 | `/var/www/dcr/website` | 8080 |
| portal | `trucash-crm-portal` | 1.0.10 | `/var/www/dcr/portal` | 4000 |
| api-sandbox | `qor-api` | 1.0.0 | `/var/www/dcr/sandbox/api` | 6001 |
| merchant-sandbox | `qor-merchant` | 0.1.0 | `/var/www/dcr/sandbox/merchant` | 6003 |
| service-sandbox | — | — | `/var/www/dcr/sandbox/service` | 6000 |
| website-sandbox | — | — | `/var/www/dcr/sandbox/website` | 6004 |
| portal-sandbox | — | — | `/var/www/dcr/sandbox/portal` | 6002 |

> **Fixed 2026-07-07:** `api-sandbox`/`merchant-sandbox` were zombie PM2 processes (`status=online` but `pid=None`) pointing at the defunct `/var/www/sandbox/{api,merchant}` path → nginx 502 on `sandbox-api`/`sandbox-merchant.qorteams.com`. Recreated via `pm2 delete` + `pm2 start npm --cwd /var/www/dcr/sandbox/{api,merchant} --name ... -- start` with `PORT=6001`/`6003`, `NODE_ENV=production`, then `pm2 save`. Both domains now respond (404/307, no longer 502).

> **Fixed 2026-07-07 — portal-sandbox "Could not connect to server" on login:** two stacked misconfigs in the compiled build at `/var/www/dcr/sandbox/portal/dist` (no source repo checked out on this host, so patched in place — originals backed up alongside as `*.bak-<timestamp>`):
> 1. `dist/client/main.<hash>.js` had `apiUrl:"http://localhost:6000"` baked in — the browser tried to hit `localhost:6000` on the **visitor's own machine**, not the server. Patched to `apiUrl:""` (relative, same-origin).
> 2. `dist/server.js`'s internal Express `/api` proxy was hardcoded to `127.0.0.1:3000` (**production** `service`) instead of `6000` (`service-sandbox`) — even after fixing (1), sandbox-portal would have silently talked to the prod backend. Patched both occurrences (`port: 3000` → `6000`, `host: "127.0.0.1:3000"` → `"127.0.0.1:6000"`).
> Verified: proxied request through `sandbox-portal.qorteams.com/api/...` now returns the same JSON as calling `service-sandbox` on 6000 directly. Production `portal`/`service` files and processes were not touched (verified `port: 3000` / `apiUrl:""` unchanged in `/var/www/dcr/portal/dist`, `restart_time` unchanged).
> ⚠️ This is a **build-artifact patch, not a source fix** — if `portal-sandbox` (or `merchant`/`portal` prod, which share the same server.js template) is ever rebuilt from `qor_crm_portal` source and redeployed, this proxy-port bug will reappear unless the source's environment/proxy config is corrected upstream (currently hardcodes `3000` regardless of environment — that's a real bug in the app repo, not just a bad deploy).

> **Naming legacy:** `service`, `website`, `portal` deployed packages are still named `trucash-crm-*` — QOR was rebranded from an earlier product called "trucash"; repo names (`qor_crm_backend`, `qor_crm_website`, `qor_crm_portal`) already use the new name but `package.json` `name` fields weren't updated.

### Node versions (nvm, `/home/ubuntu/.nvm/versions/node/`)

- `v24.15.0` — default (`node -v`), used by `api` / `merchant` (npm start)
- `v20.20.2` — installed, unclear which app uses it
- `v10.24.1` / `v10.16.0` — **required** for `website` and `portal` (Angular 7 / `http_parser`, removed in Node 12+). Do not upgrade these apps' runtime without an Angular upgrade first.

### Database (PostgreSQL, local, active)

| DB | Owner | Used by |
|----|-------|---------|
| `qor_db` | `uqor` | production `api` |
| `qor_sandbox` | `uqor_sandbox` | `api-sandbox` |

(Credentials live in each app's `.env` — never read per the rule above.)

### Host

Ubuntu 24.04.4 LTS · 3.7Gi RAM (no swap) · 77G disk (8.5G used) · single instance, all services co-located on one box via PM2 (no containers in prod; `service/docker-compose.yml` exists in-repo but isn't what's running).

### Dev repo ↔ prod path mapping

| This repo (dev, `qor_manage_all/`) | Prod path | Dev port (`ecosystem.config.js` here) | Prod port |
|---|---|---|---|
| `api/` | `/var/www/dcr/api` | 3011 | 3001 |
| `merchant/` | `/var/www/dcr/merchant` | 3000 | 5000 |
| `service/` | `/var/www/dcr/service` | 3002 | 3000 |
| `website/` | `/var/www/dcr/website` | 4000 | 8080 |
| `portal/` | `/var/www/dcr/portal` | 4200 | 4000 |

Ports differ between dev and prod for every app except none — be careful when reasoning about "port 3000/4000" etc., always check which environment is meant.

## Business Logic

- Merchant hoặc 3rd-party tích hợp trực tiếp với QOR để thực hiện payment / refund / check balance
- API layer **hide Finix / Zum credentials** của Platform — merchant không bao giờ gọi thẳng gateway
- Mỗi payment: validate API key → call gateway → tính QOR fee → lưu DB → trả về transaction_id + status + fee
- Mỗi refund: validate key + transaction tồn tại → call gateway → update refund table + transaction status
- Rate limit 100 req/min per merchant để tránh abuse
- Tất cả request/response được log cho auditing

### Payment Request Flow
```
Merchant system → POST /v1/payments → QOR backend
  → Validate API key + merchant status
  → Call Finix / Zum (mock gatewayService)
  → Calculate QOR fee (2.9% + $0.30)
  → Save transaction in DB
  → Return transaction_id + status + fee
```

### Refund Request Flow
```
Merchant system → POST /v1/refunds → QOR backend
  → Validate API key + transaction exists + merchant owns it
  → Validate refund amount ≤ (original − already refunded)
  → Call Finix / Zum to refund
  → Update refund table + transaction status (if full refund → status = 'refunded')
  → Return refund_id + status
```

### Features / Modules
1. **Auth** — Single auth via `users` table, JWT cho dashboard + merchant, HTTP Basic Auth cho M2M
2. **Payments** — charge customer, fee calculation, gateway call
3. **Transactions** — list (filterable/paginated), detail view
4. **Refunds** — partial hoặc full, validate không over-refund
5. **Payouts** — request + async processing (pending → processing → completed)
6. **Balance** — computed real-time từ DB (earned − fees − paid out)
7. **Reports** — CSV/JSON export theo date range
8. **Webhooks** — nhận events từ gateway để update trạng thái
9. **API Keys** — generate/revoke per merchant, secret shown once
10. **Merchant Onboarding** — applies flow, KYC review, gateway onboarding

**Stack:** Node.js · Express · TypeScript · Prisma · PostgreSQL
**Port:** 3001
**Base path:** `/v1`

## Architecture — 4-layer

```
routes (.routes.ts)  →  controllers  →  models + services
                              ↑
                         middleware
```

- **routes**: pure HTTP wiring (~5 lines each), no business logic
- **controllers**: validate input, orchestrate models/services, format response
- **models**: TypeScript DTOs + Prisma data-access helpers per entity
- **services**: gateway mock + fee calculation (stateless utilities)
- **middleware**: `auth.ts` (JWT), `apiKey.ts` (Basic Auth → req.merchantApiKey), `flexAuth.ts` (accepts JWT or Basic Auth), `errorHandler.ts`

`flexAuth` + `resolveMerchantId()` in `middleware/flexAuth.ts` — used on endpoints that accept both JWT and API Key auth (payments, refunds).

## DB Schema

### `users` — Single auth source for ALL roles
```
users
  ├── role = SystemAdmin  → QOR internal, full access
  ├── role = Agent      → Sale/Agent QOR, quản lý merchant portfolio
  ├── role = Merchant     → Khách hàng QOR, login dashboard
  └── role = User         → TBD (reserved v3)
```
- `users` = identity + auth (ai được login, role là gì)
- `merchants` = business profile (gateway data, KYC status, bank account)
- Linked qua `merchants.user_id` FK

### `merchants` — Business profile only (no password)
```sql
id                VARCHAR  PRIMARY KEY
user_id           VARCHAR  REFERENCES users(id)        -- auth link
agent_id          VARCHAR  REFERENCES users(id) NULL   -- sale agent phụ trách
apply_id          VARCHAR  REFERENCES applies(id) NULL -- apply gốc tạo ra merchant
name              TEXT
email             TEXT
status            TEXT  DEFAULT 'active'
kyc_status        TEXT  DEFAULT 'pending'
provider_id       TEXT  DEFAULT 'finix'   -- gateway đang dùng: 'finix' | 'zum'
finix_merchant_id VARCHAR NULL
finix_identity_id VARCHAR NULL
zum_id            VARCHAR NULL            -- reserved, chưa implement
bank_account      TEXT NULL
phone             TEXT NULL
created_at        TIMESTAMP
updated_at        TIMESTAMP
```
> `password` đã bỏ khỏi merchants — auth hoàn toàn qua `users` table

### `applies` — Merchant/Agent onboarding applications
```sql
id                   VARCHAR  PRIMARY KEY
-- Auth link
user_id              VARCHAR  REFERENCES users(id) NULL  -- NULL nếu guest submit
-- Result link (populated sau khi approved)
merchant_id          VARCHAR  REFERENCES merchants(id) NULL
-- Form data (KYC)
type                 VARCHAR  NOT NULL  -- 'merchant' | 'referral'
request_payment_method VARCHAR         -- Visa, Mastercard, ... (loại TT merchant muốn nhận)
primary_contact_info TEXT
corporate_info       TEXT
owner_info           TEXT
website_info         TEXT
business_profile_info TEXT
settlement_info      TEXT
required_document    TEXT
-- Gateway (admin chọn khi approve)
gateway              VARCHAR NULL  -- 'finix' | 'zum'
provider_id          VARCHAR NULL  -- ID trả về từ Finix/Zum sau onboard
-- Review
status               VARCHAR  -- pending | under_review | needs_info | approved | rejected
approved_by          VARCHAR  REFERENCES users(id) NULL
declined_by          VARCHAR  REFERENCES users(id) NULL
review_note          TEXT NULL
reviewed_at          TIMESTAMPTZ NULL
-- Resubmission
resubmit_count       INT DEFAULT 0
previous_apply_id    VARCHAR REFERENCES applies(id) NULL
-- Metadata
is_saved             BOOL DEFAULT false  -- true = draft
code                 VARCHAR NULL
domain               VARCHAR NULL
referral_code        VARCHAR NULL
is_deleted           BOOL DEFAULT false
is_enable            BOOL DEFAULT true
created_date         TIMESTAMPTZ DEFAULT NOW()
updated_date         TIMESTAMPTZ DEFAULT NOW()
```

### `merchant_api_keys` — M2M authentication
```sql
id           VARCHAR  PRIMARY KEY
merchant_id  VARCHAR  REFERENCES merchants(id)  -- link về business entity
name         VARCHAR
key          VARCHAR  UNIQUE   -- public key, lookup index
secret       VARCHAR           -- bcrypt hashed, shown once
status       VARCHAR           -- active | revoked
last_used_at TIMESTAMPTZ NULL
created_at   TIMESTAMPTZ
```
Indexes:
```sql
CREATE INDEX idx_api_keys_key ON merchant_api_keys(key);         -- M2M lookup
CREATE INDEX idx_api_keys_merchant_id ON merchant_api_keys(merchant_id);
```

API Key query chain:
```
API Key → merchant_api_keys.merchant_id
        → merchants.user_id, merchants.status, merchants.provider_id
        → proceed
```

## Roles & Personas

| Role | Là ai | Mục tiêu chính |
|------|-------|----------------|
| **SystemAdmin** | QOR internal, full access | Quản lý toàn bộ hệ thống, users, merchants, review applies |
| **Agent** | Sale/Agent QOR — onboard merchant | Xem và hỗ trợ portfolio merchants được assign (1 agent → nhiều merchants) |
| **Manager** | Role riêng biệt, khác Agent | TBD — không phải Agent, không quản lý merchant portfolio |
| **Merchant** | Khách hàng QOR | Quản lý payment business, xem applies của mình |
| **User** | TBD — reserved v3 | — |

> **Agent ≠ Manager** — đây là 2 `roleId` khác nhau trong `users` table. Agent là sale onboard merchant. Manager là role riêng chưa có business logic cụ thể.

### Relationship Model
```
SystemAdmin
    │
    ├── manages ──→ Agent (nhiều)        ← roleId = 'Agent'
    │                   │
    │                   └── onboards ──→ Merchant (nhiều)
    │                                    (1 merchant = 1 agent)
    │
    ├── manages ──→ Manager (nhiều)      ← roleId = 'Manager' — role riêng, khác Agent
    │
    └── direct access to all Merchants + all Applies
```

## Auth Flow — Register / Login / Status

### `users.status` — Values & Meaning

| Value | Meaning |
|-------|---------|
| `pending` | Mới register, chưa submit apply |
| `under_review` | Đã submit apply, chờ admin duyệt |
| `active` | Admin approved, có `merchants` record |
| `rejected` | Admin rejected, có thể resubmit |
| `suspended` | Bị khóa bởi admin |

### Register — `POST /v1/auth/register`

**Request:**
```json
{ "first_name": "string", "last_name": "string", "email": "string", "password": "string (min 8)", "phone_number": "string (optional)" }
```

**Logic:**
- Validate input
- Check email chưa tồn tại
- Hash password (bcrypt rounds=12)
- Tạo `users` record: `role_id = 'Merchant'`, `status = 'pending'`
- Return JWT + user profile

**JWT payload:** `{ userId, role, status, merchantId? }`  
> `merchantId` chỉ có khi `status = 'active'`

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJ...",
    "user": { "id": "...", "email": "...", "first_name": "...", "last_name": "...", "role": "Merchant", "status": "pending" }
  }
}
```

**Errors:**
```json
{ "success": false, "error": { "code": "EMAIL_TAKEN", "message": "Email already exists" } }
{ "success": false, "error": { "code": "VALIDATION_ERROR", "message": "..." } }
```

### Login — `POST /v1/auth/login`

**Response thêm `status`** để frontend redirect đúng màn hình:

```json
{
  "success": true,
  "data": {
    "token": "eyJ...",
    "user": { "id": "...", "email": "...", "firstName": "...", "lastName": "...", "role": "Merchant", "status": "pending", "merchantId": null }
  }
}
```

**Frontend redirect logic (qor_merchant):**
| `status` | Redirect |
|----------|---------|
| `pending` | `/applications/new` — submit apply |
| `under_review` | `/applications` — xem trạng thái |
| `active` | `/dashboard` — full dashboard |
| `rejected` | `/applications/new` — resubmit |

### Status Sync — Apply Flow

| Trigger | Action |
|---------|--------|
| `POST /v1/applications` (submit, not draft) | `users.status = 'under_review'` |
| Admin approve apply | `users.status = 'active'` + tạo `merchants` record |
| Admin reject apply | `users.status = 'rejected'` |

> Draft (`isSaved = true`) **không** thay đổi `users.status`.

### Route Protection (qor_merchant dashboard)

Non-`active` users chỉ được truy cập `/applications/*`. Mọi route khác bị redirect về màn hình tương ứng với status.

Sidebar cũng bị giới hạn:
- `pending` / `rejected` → chỉ hiện link **"Submit Application"** → `/applications/new`
- `under_review` → chỉ hiện link **"My Application"** → `/applications`
- `active` → full sidebar

---

## Merchant Onboarding Flow

### Apply Status Flow
```
is_saved=true → [draft]
                  │
                  └──→ pending (submitted)
                            │
                            ├──→ under_review (admin đang xem)
                            │         │
                            │         ├──→ needs_info (cần bổ sung tài liệu)
                            │         │         │
                            │         │         └──→ pending (merchant resubmit)
                            │         │
                            │         ├──→ approved
                            │         │       → Admin chọn gateway (finix/zum)
                            │         │       → Gửi KYC lên gateway
                            │         │       → Gateway trả về provider_id
                            │         │       → Tạo merchant record
                            │         │       → Flow 1: tạo users record, gửi email set password
                            │         │       → Flow 2: update users.role = Merchant
                            │         │
                            │         └──→ rejected (có lý do, có thể resubmit)
                            │
                            └──→ (admin có thể skip thẳng approved/rejected)
```

### Flow 1 — Guest submit (không có account)
```
Guest điền form → POST /v1/applications (no auth)
  → Tạo applies record (user_id = NULL, status = pending)
  → Gửi email xác nhận + tracking token

Admin approve + chọn gateway:
  → Gửi KYC lên Finix/Zum → nhận provider_id
  → Tạo users record (role = Merchant, is_enable = false)
  → Tạo merchants record (user_id, provider_id, apply_id)
  → Update applies (status = approved, merchant_id, gateway, provider_id)
  → Gửi email "Set your password" kèm link token
```

### Flow 2 — Registered submit (đã có account)
```
User đăng ký → Login → Điền form → POST /v1/applications (JWT)
  → Tạo applies record (user_id = JWT.userId, status = pending)

Admin approve + chọn gateway:
  → Gửi KYC lên Finix/Zum → nhận provider_id
  → Update users.role = Merchant
  → Tạo merchants record (user_id, provider_id, apply_id)
  → Update applies (status = approved, merchant_id, gateway, provider_id)
  → Gửi email thông báo approved
```

### Resubmit Logic
```
Merchant resubmit sau rejected/needs_info:
  → Tạo applies record MỚI (previous_apply_id = app cũ, resubmit_count + 1)
  → App cũ giữ nguyên status (audit trail)
  → App mới status = pending
```

### Notification Events
| Trigger | Gửi cho | Nội dung |
|---------|---------|----------|
| Submit thành công | Merchant/Guest | Xác nhận + tracking token (guest only) |
| under_review | Merchant | Đang được xem xét |
| needs_info | Merchant | Yêu cầu bổ sung + review_note |
| approved (flow 1) | Guest | Set password link |
| approved (flow 2) | Merchant | Chào mừng, account activated |
| rejected | Merchant | Lý do + hướng dẫn resubmit |

## API Endpoints

### Auth
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/v1/auth/register` | — | Tạo account (users table), returns JWT |
| POST | `/v1/auth/login` | — | Login (users table), returns JWT + profile |
| GET | `/v1/auth/me` | JWT | Current user profile |
| PUT | `/v1/auth/me` | JWT | Update profile |

### Applications — Merchant Onboarding
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/v1/applications` | None or JWT | Submit form (guest hoặc logged-in) |
| GET | `/v1/applications/status` | — | Guest check status (?email=&token=) |
| GET | `/v1/applications/mine` | JWT (Merchant) | Xem apply của mình |
| PUT | `/v1/applications/mine` | JWT (Merchant) | Resubmit sau reject/needs_info |
| DELETE | `/v1/applications/mine` | JWT (Merchant) | Withdraw (chỉ khi draft/pending) |

### Applications — Admin Review
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/v1/admin/applications` | JWT (Admin) | List all (filter: status, type, gateway, date) |
| GET | `/v1/admin/applications/:id` | JWT (Admin) | Detail + history |
| PUT | `/v1/admin/applications/:id/review` | JWT (Admin) | Chuyển sang under_review |
| PUT | `/v1/admin/applications/:id/request-info` | JWT (Admin) | needs_info + note |
| PUT | `/v1/admin/applications/:id/approve` | JWT (Admin) | Approve + chọn gateway → onboard Finix/Zum |
| PUT | `/v1/admin/applications/:id/reject` | JWT (Admin) | Reject + lý do |

### Admin Management
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/v1/admin/users` | JWT (Admin) | List all users |
| POST | `/v1/admin/users` | JWT (Admin) | Create user |
| PUT | `/v1/admin/users/:id` | JWT (Admin) | Update user |
| DELETE | `/v1/admin/users/:id` | JWT (Admin) | Soft delete |
| GET | `/v1/admin/agents` | JWT (Admin) | List agents + merchant count |
| GET | `/v1/admin/agents/:id` | JWT (Admin) | Agent detail + portfolio |

> **Code naming bug:** route hiện tại là `/v1/admin/managers` (file `admin/manager.routes.ts`) nhưng controller query `roleId = 'Agent'`. Cần đổi route về `/v1/admin/agents` cho đúng.

### Merchant Management (scoped by role)
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/v1/merchants` | JWT | List (Admin: all, Agent: portfolio, Merchant: ❌) |
| GET | `/v1/merchants/:id` | JWT | Detail (scoped) |
| PUT | `/v1/merchants/:id` | JWT | Update (scoped) |
| PUT | `/v1/merchants/:id/assign-agent` | JWT (Admin) | Reassign agent (⚠️ code hiện có bug: route là `assign-manager`) |
| PUT | `/v1/merchants/:id/status` | JWT (Admin) | Enable/disable |

### Transactions
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/v1/transactions` | JWT | List (scoped by role, +?merchantId= for Admin) |
| GET | `/v1/transactions/:id` | JWT or API Key | Detail |

### Payments
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/v1/payments` | JWT (Merchant) or API Key | Create payment → gateway → fee → save |

### Refunds
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/v1/refunds` | JWT (Merchant/Admin) or API Key | Create refund |
| GET | `/v1/refunds` | JWT | List (scoped) |

### Payouts
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/v1/payouts` | JWT (Merchant) | Request payout |
| GET | `/v1/payouts` | JWT | List (scoped) |
| PUT | `/v1/payouts/:id/approve` | JWT (Admin) | Approve payout |

### Balance & Reports
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/v1/balance` | JWT | Computed: earned − fees − paid out (scoped) |
| GET | `/v1/reports/transactions` | JWT | CSV or JSON, date range (scoped) |
| GET | `/v1/reports/payouts` | JWT | CSV or JSON (scoped) |

### API Keys (Merchant only)
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/v1/api-keys` | JWT (Merchant) | List keys (no secret) |
| POST | `/v1/api-keys` | JWT (Merchant) | Generate key (secret shown once) |
| DELETE | `/v1/api-keys/:id` | JWT (Merchant) or Admin | Revoke key |

### Webhooks
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/v1/webhooks` | — | Inbound: gateway events (HMAC verified) |
| GET | `/v1/webhook-subscriptions` | JWT or API Key | List outbound subscriptions |
| POST | `/v1/webhook-subscriptions` | JWT or API Key | Register merchant endpoint |
| PUT | `/v1/webhook-subscriptions/:id` | JWT or API Key | Update |
| DELETE | `/v1/webhook-subscriptions/:id` | JWT or API Key | Remove |

## Permission Matrix

### Merchant Management
| Endpoint | SystemAdmin | Agent | Merchant |
|----------|:-----------:|:-------:|:--------:|
| GET `/v1/merchants` | all | own portfolio | NO |
| GET `/v1/merchants/:id` | YES | if assigned | own only |
| PUT `/v1/merchants/:id` | YES | if assigned | own only |
| PUT `/v1/merchants/:id/assign-agent` | YES | NO | NO |
| PUT `/v1/merchants/:id/status` | YES | NO | NO |

### Transactions / Payments / Refunds
| Endpoint | SystemAdmin | Agent | Merchant |
|----------|:-----------:|:-------:|:--------:|
| GET `/v1/transactions` | all + ?merchantId= | portfolio only | own only |
| POST `/v1/payments` | NO | NO | YES |
| POST `/v1/refunds` | YES (override) | NO | YES |
| GET `/v1/refunds` | all | portfolio only | own only |

### Payouts / Balance / Reports
| Endpoint | SystemAdmin | Agent | Merchant |
|----------|:-----------:|:-------:|:--------:|
| GET `/v1/payouts` | all | portfolio only | own only |
| POST `/v1/payouts` | NO | NO | YES |
| PUT `/v1/payouts/:id/approve` | YES | NO | NO |
| GET `/v1/balance` | YES (?merchantId=) | portfolio only | own only |
| GET `/v1/reports/*` | all | portfolio only | own only |

### API Keys
| Endpoint | SystemAdmin | Agent | Merchant |
|----------|:-----------:|:-------:|:--------:|
| GET `/v1/api-keys` | NO | NO | own only |
| POST `/v1/api-keys` | NO | NO | own only |
| DELETE `/v1/api-keys/:id` | YES (any) | NO | own only |

## Machine-to-Machine (M2M) — API Key Flow

Merchant third-party tích hợp QOR qua HTTP Basic Auth. 4 patterns:

### Pattern 1 — POST payment
```
POST /v1/payments
Authorization: Basic base64("qor_live_xxx:sec_live_yyy")
Body: { amount, currency, customerId, metadata }
Response: { transaction_id, status, fee, net_amount }
```

### Pattern 2 — Refund
```
POST /v1/refunds
Authorization: Basic base64("qor_live_xxx:sec_live_yyy")
Body: { transaction_id, amount, reason }
Response: { refund_id, status, refunded_amount }
```

### Pattern 3 — Query status (polling)
```
GET /v1/transactions/:id
Authorization: Basic base64("qor_live_xxx:sec_live_yyy")
Response: { id, status, amount, fee, created_date, ... }
```
> Khuyến khích dùng Webhook thay vì polling.

### Pattern 4 — Outbound Webhook
QOR gửi event ra merchant endpoint:
```
POST https://merchant-server.com/qor-events
Headers:
  X-QOR-Signature: sha256=<HMAC-SHA256(payload, secret)>
  X-QOR-Event: transaction.completed
  X-QOR-Delivery: <uuid>
Body: { event, data: { transaction_id, merchant_id, amount, status }, timestamp }
```

## API Key — How It Works

### Storage
```ts
const rawSecret = generateRandom()
const hashed    = await bcrypt.hash(rawSecret, 12)
// DB: { key: 'qor_live_...', secret: '$2b$12$...' }
// rawSecret shown once, never retrievable again
```

### Verification + Query Chain
```ts
// Authorization: Basic base64("key:secret")
// 1. Parse → extract key + secret
// 2. Lookup merchant_api_keys by key (indexed)
// 3. bcrypt.compare(secret, record.secret)
// 4. Lookup merchants by merchant_id → check status = 'active'
// 5. Lookup users by user_id → get role, permissions
// 6. Touch lastUsedAt (fire-and-forget)
```

### Auth flow (flexAuth)
```
Authorization: Bearer <token>  → authenticateJWT    → req.user = { userId, role, merchantId? }
Authorization: Basic <b64>     → authenticateApiKey → req.merchantApiKey = { merchantId, keyId }
resolveMerchantId(req) → returns merchantId from whichever auth succeeded
```

## v1 Issues — Fix Plan

### Fix 1: Rate limit per merchantId
- **Problem:** per IP sai khi merchant dùng load balancer
- **Fix:** `rateLimiter.key = resolveMerchantId(req) ?? req.ip`

### Fix 2: Webhook inbound HMAC verification
- **Problem:** `/v1/webhooks` không verify signature → fake events
- **Fix:** middleware `verifyGatewayWebhook.ts` — HMAC verify trước khi process

### Fix 3: Payout async queue interface
- **Problem:** `setTimeout` fire-and-forget mất job khi server restart
- **Fix:** `queueService.ts` — `InMemoryQueue` (v2), swap `BullMQQueue` (v3)

## File Structure

```
src/
├── middleware/
│   ├── auth.ts                      # JWT → { userId, role, merchantId? }
│   ├── apiKey.ts                    # Basic Auth → req.merchantApiKey
│   ├── flexAuth.ts                  # JWT or API Key; resolveMerchantId()
│   ├── requireRole.ts               # requireRole('SystemAdmin') guard
│   ├── scopeMerchant.ts             # inject merchantId filter by role
│   ├── rateLimiter.ts               # key = merchantId ?? ip
│   ├── verifyGatewayWebhook.ts      # HMAC verify inbound
│   └── errorHandler.ts
├── controllers/
│   ├── admin/
│   │   ├── user.controller.ts
│   │   ├── agent.controller.ts
│   │   └── application.controller.ts
│   ├── auth.controller.ts
│   ├── application.controller.ts    # public + merchant
│   ├── merchant.controller.ts
│   ├── transaction.controller.ts
│   ├── payment.controller.ts
│   ├── refund.controller.ts
│   ├── payout.controller.ts
│   ├── balance.controller.ts
│   ├── report.controller.ts
│   ├── webhook.controller.ts
│   ├── webhookSubscription.controller.ts
│   └── apiKey.controller.ts
├── models/
│   ├── user.model.ts
│   ├── merchant.model.ts
│   ├── apply.model.ts
│   ├── transaction.model.ts
│   ├── payout.model.ts
│   ├── refund.model.ts
│   ├── apiKey.model.ts
│   ├── merchantWebhook.model.ts
│   └── auditLog.model.ts
└── services/
    ├── gatewayService.ts            # Finix (mock), Zum (reserved)
    ├── feeService.ts                # 2.9% + $0.30
    ├── webhookDispatcher.ts         # outbound HMAC dispatch
    └── queueService.ts              # InMemoryQueue (v2) → BullMQ (v3)
```

## Response Format

```json
{ "success": true, "data": { ... } }
{ "success": true, "data": [...], "pagination": { "page": 1, "limit": 20, "total": 100, "totalPages": 5 } }
{ "success": false, "error": { "code": "...", "message": "..." } }
```

## Key Behaviors
- All mutations write to `audit_logs`
- Balance computed dynamically from DB (no stored balance field)
- Refunds validate against already-refunded amount to prevent over-refunding
- Payout: pending → processing (2s) → completed (5s) via queueService
- CORS allows `http://localhost:3000`
- Rate limit: 100 req/min per merchantId (fallback: per IP)

## Env Variables

```
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/qor_dev"
JWT_SECRET="qor-jwt-secret-dev-2024"
JWT_EXPIRES_IN="7d"
PORT=3001
QOR_FEE_PERCENT=2.9
QOR_FEE_FIXED=0.30
GATEWAY_WEBHOOK_SECRET="..."
```

## Gateway — Finix / Zum

| | Finix | Zum |
|-|-------|-----|
| Status | Active | Reserved (not implemented) |
| merchant_id field | `finix_merchant_id` | `zum_id` |
| identity_id field | `finix_identity_id` | — |
| Onboard trigger | Admin approve apply | Admin approve apply |
| provider_id value | `'finix'` | `'zum'` |

## Out of Scope — v2 (defer to v3)
- Multi-user per merchant (staff/sub-user roles)
- Role `User` — no use case yet
- BullMQ production queue
- Zum gateway implementation
- Admin aggregate analytics dashboard
