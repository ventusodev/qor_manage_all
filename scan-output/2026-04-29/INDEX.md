# QOR CRM Scan Output

Ngay scan: `2026-04-29`

Thu muc nay luu bo scan tong hop cho cum du an:

- `qor-crm-website-master`
- `qor-crm-service-master`
- `qor-crm-portal-master`

Danh muc file:

- `01-system-overview.md`: tong quan kien truc, luong du lieu, entrypoints
- `02-repo-inventory.md`: inventory repo, so luong file, cau truc thu muc, stack
- `03-api-surface.md`: mat API backend `/api/v1`
- `04-findings-and-risks.md`: cac phat hien va rui ro dang chu y

Ket luan nhanh:

- `website` la Angular 7 SSR public-facing site cho merchant/application flow (`../../src/app/app-routing.module.ts:5-20`).
- `portal` la Angular 7 SSR admin/backoffice voi login, dashboard, applies, users, account (`../../../qor-crm-portal-master/src/app/app-routing.module.ts:6-22`).
- `service` la Node/Express + Inversify + Knex/Bookshelf + PostgreSQL, mount toan bo API tai `/api/v1` (`../../../qor-crm-service-master/src/app.ts:90-105`, `../../../qor-crm-service-master/src/routes/index.ts:9-13`, `../../../qor-crm-service-master/src/routes/api/v1/index.ts:21-38`).
- Flow business quan trong nhat la public application form -> `POST /api/v1/applies` -> persist DB -> gui email thong bao (`../../src/app/pages/application/components/process.component.ts:200-219`, `../../../qor-crm-service-master/src/routes/api/v1/apply/apply.router.ts:30-32`, `../../../qor-crm-service-master/src/interactors/apply.service.ts:42-87`).
