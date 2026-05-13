# Findings And Risks

## 1. Hard-coded external keys va IDs trong frontend config

Frontend config commit san:

- Website hard-code API URL, media URL, Facebook App ID, Google Maps key (`../../src/app/configs/setting.template.ts:1-5`, `../../src/app/configs/setting.template.ts:42-49`).
- Portal cung hard-code API URL, media URL, Facebook App ID, Google Maps key (`../../../qor-crm-portal-master/src/app/configs/setting.template.ts:1-5`, `../../../qor-crm-portal-master/src/app/configs/setting.template.ts:42-49`).

Tac dong:

- De lo integration metadata tren client bundle.
- Kho rotate/reconfigure theo moi truong neu khong co build-time replacement discipline.

## 2. Public apply endpoints la surface business quan trong

API cho phep:

- `POST /api/v1/applies` public
- `GET /api/v1/applies/:id` public
  (`../../../qor-crm-service-master/src/routes/api/v1/apply/apply.router.ts:22-32`)

Tac dong:

- Day la bieu mau kinh doanh public nen hop ly theo product, nhung can xem xet rate limit, spam protection, id exposure va audit trail.

## 3. Auth middleware ho tro nhieu kenh token

Middleware auth nhan token tu:

- query string
- request body
- bearer header
  (`../../../qor-crm-service-master/src/middlewares/reusables/authentication.ts:32-89`)

Tac dong:

- Linh hoat cho legacy client, nhung tang attack surface va kha nang token leakage qua URL/body logging.
- Middleware co check RFC6750 violation khi token xuat hien o nhieu hon mot noi, nhung ban than viec cho query/body token da la legacy-friendly hon la security-first.

## 4. Backend auto-migrate tren startup

Khi boot, service doi DB available roi chay `migrate.latest()` (`../../../qor-crm-service-master/src/data/sql/connection.ts:86-123`).

Tac dong:

- Tien cho dev/test va deployment don gian.
- Rui ro o production neu migration khong duoc gate rieng, canary, hoac review truoc.

## 5. Legacy stack

Phien ban phu thuoc cho thay stack da cu:

- Website: Angular `7.1.4`, TypeScript `3.1.1` (`../../package.json:16-94`)
- Portal: Angular `7.1.4`, TypeScript `3.1.1` (`../../../qor-crm-portal-master/package.json:16-96`)
- Service: TypeScript `2.9.2`, Express `4.16.x`, Knex `0.13.0` (`../../../qor-crm-service-master/package.json:9-136`)

Tac dong:

- Debt nang o compatibility, security patching, CI maintenance, va nang cap ecosystem.

## 6. jQuery-driven form workflow tren website

Public application flow dung:

- `smartWizard`
- DOM-ready callbacks
- jQuery event bindings
  (`../../src/app/pages/application/components/process.component.ts:101-149`, `../../src/app/pages/application/components/process.component.ts:156-181`)

Tac dong:

- Logic UI quan trong nam o imperative DOM layer, kho test, kho refactor, de phat sinh side effects SSR/browser lifecycle.

## 7. Domain-aware multi-brand behavior

He thong co logic phu thuoc hostname:

- Website chon language theo domain (`../../src/app/app.component.ts:46-67`)
- Frontend gui header `domain` moi request (`../../src/app/services/base.service.ts:57-74`, `../../../qor-crm-portal-master/src/app/services/base.service.ts:55-69`)
- Backend report/apply schema co field `domain` (`../../../qor-crm-service-master/src/data/sql/schema.ts:195-220`, `../../../qor-crm-service-master/src/interactors/apply.service.ts:152-177`)

Tac dong:

- Multi-tenant/multi-brand behavior dang ton tai, nhung policy tach tenant chua duoc the hien ro trong scan nay.

## 8. Testing gap

Trong scan nay:

- `website` va `portal` khong lo test suite ro rang.
- `service` co script test trong `package.json` nhung scan khong thay bo test source thuc te; route `test` co ve la endpoint utility hon la automated test (`../../../qor-crm-service-master/package.json:5-8`, `../../../qor-crm-service-master/src/routes/api/v1/test/test.router.ts:15-23`).

Tac dong:

- Rui ro regression cao neu nang cap Angular/TypeScript/backend dependencies.

## 9. Recommended next scan

Neu can scan sau vong nay, uu tien:

1. Trace handler-level implementation cho `auth`, `users`, `notifications`, `media`.
2. Audit `.env` contract va `libs/config` de biet moi truong production can gi.
3. Chay dependency/security inventory co phan loai CVE cho 3 repo.
4. Ve ma tran field mapping giua frontend `ApplyModel` va backend `ApplyModel`.
