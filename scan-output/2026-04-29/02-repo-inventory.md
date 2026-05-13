# Repo Inventory

## 1. File count summary

Thong ke trong scan nay bo qua `.git`, `node_modules`, `dist`, `build`.

| Repo | Tong file | Dinh dang chinh |
| --- | ---: | --- |
| `qor-crm-website-master` | 147 | `96 .ts`, `12 .json`, `11 .html`, `6 .scss` |
| `qor-crm-service-master` | 311 | `162 .ts`, `93 .yaml`, `12 .html` |
| `qor-crm-portal-master` | 244 | `111 .ts`, `17 .html`, `17 .js`, `13 .json`, `13 .png` |

## 2. Website structure

Thu muc cap 2 cua `website/src/app`:

- `configs`
- `directives`
- `helpers`
- `models`
- `models/search`
- `modules`
- `modules/mapper`
- `modules/transfer-http`
- `pages`
- `pages/application`
- `pages/error`
- `pages/home`
- `pages/maintainer`
- `services`
- `themes`
- `themes/components`
- `themes/pipes`
- `themes/scss`

Nhan xet:

- Route public duoc lazy-load qua `home`, `application`, `maintainer`, `error` (`../../src/app/app-routing.module.ts:6-20`).
- `application` la module business quan trong nhat cua website (`../../src/app/pages/application/application.routing.module.ts:7-20`).

## 3. Service structure

Thu muc cap 2 cua `service/src`:

- `configs`
- `data`
- `data/redis`
- `data/sql`
- `infrastructures`
- `interactors`
- `libs`
- `libs/mapper`
- `locales`
- `middlewares`
- `middlewares/reusables`
- `models`
- `models/firebase`
- `resources`
- `resources/email_templates`
- `resources/printers`
- `routes`
- `routes/api`

Nhan xet:

- Phan backend tach layer kha ro: `routes` -> `interactors` -> `data` -> `sql`.
- `swagger/yaml` chua mat contract API va model docs ben canh code TypeScript.

## 4. Portal structure

Thu muc cap 2 cua `portal/src/app`:

- `configs`
- `helpers`
- `models`
- `models/search`
- `modules`
- `modules/mapper`
- `modules/transfer-http`
- `pages`
- `pages/account`
- `pages/apply`
- `pages/dashboard`
- `pages/forgot_password`
- `pages/login`
- `pages/users`
- `redux`
- `redux/reducer`
- `redux/state`
- `services`
- `themes`
- `themes/components`
- `themes/pipes`
- `themes/scss`

Nhan xet:

- Portal co them Redux state layer, khac voi website public.
- Admin surface xoay quanh `dashboard`, `apply`, `users`, `account` (`../../../qor-crm-portal-master/src/app/app-routing.module.ts:10-17`).

## 5. Stack summary

### Website

- Angular 7.1.4
- Angular Universal / SSR
- Bootstrap 4
- jQuery plugins (`smartwizard`, `mask`, `datepicker`)
- `@ngx-config`, `@ngx-meta`, `@ngx-translate`
  (`../../package.json:16-94`)

### Portal

- Angular 7.1.4
- Angular Universal / SSR
- Redux
- Chart.js / ng2-charts
- same `@ngx-config`, `@ngx-meta`, `@ngx-translate`
  (`../../../qor-crm-portal-master/package.json:16-96`)

### Service

- Express 4
- Inversify IoC
- Knex + Bookshelf
- PostgreSQL driver `pg`
- Redis client
- Firebase Admin
- Mailgun / Nodemailer
- Twilio / Nexmo
  (`../../../qor-crm-service-master/package.json:18-136`)

## 6. Testing inventory

Trong scan nay, khong tim thay bo unit test/frontend spec ro rang o `website` va `portal`.

`service` co script `test`/`coverage` trong `package.json`, nhung scan khong thay test suite thuc te; chi thay test handler endpoint (`../../../qor-crm-service-master/package.json:5-8`, `../../../qor-crm-service-master/src/routes/api/v1/test/test.router.ts:15-23`).
