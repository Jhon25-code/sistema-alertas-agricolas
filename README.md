# SIAAS v2 Starter (Offline-first)
Adaptado al diseño mostrado (Inicio, Tipo de incidente, Reporte, Portal web - Tópico).

## Estructura
- `mobile_flutter/` Flutter app (Android/iOS)
- `web_react/` Web Tópico (React + Vite)
- `api/openapi.yaml` API mínima
- `db/schema.sql` Esquema Postgres/Supabase
- `backlog/github_issues_backlog.csv` Backlog importable

## Flutter Quick Start
```bash
cd mobile_flutter
flutter pub get
flutter run
```
**Recursos:** coloca tu logo en `assets/images/logo_siaas.png` e íconos en `assets/icons/` (ya hay placeholders).

## Web Quick Start
```bash
cd web_react
npm i
npm run dev
```
(El código usa datos mock hasta conectar Supabase/Firebase.)

## Flujo
1. Inicio → “Reportar incidente”
2. Tipo de incidente (6 tarjetas)
3. Reporte (hora auto, ubicación offline) → Enviar (guarda en SQLite y cola a sync)
4. Web Tópico recibe alerta al sincronizar.
