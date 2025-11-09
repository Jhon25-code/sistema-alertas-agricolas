-- SIAAS v2 Schema (igual a v1 con nombres amigables)
create extension if not exists "uuid-ossp";
create table if not exists public.users (
  id uuid primary key default uuid_generate_v4(),
  auth_user_id uuid unique,
  name text not null,
  role text check (role in ('trabajador','jefe_cuadrilla','topico')) not null,
  phone text,
  created_at timestamptz not null default now()
);
create table if not exists public.reference_points (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  area text,
  lat double precision,
  lng double precision,
  created_at timestamptz not null default now()
);
create table if not exists public.incidents (
  id uuid primary key,
  reported_by_user_id uuid references public.users(id) on delete set null,
  created_at_local timestamptz not null,
  type text check (type in ('picadura_abeja','corte','insolacion','intoxicacion','caida','otro')) not null,
  severity_reported text check (severity_reported in ('leve','medio','grave')) not null,
  smart_score int check (smart_score between 0 and 100) not null,
  location_mode text check (location_mode in ('gps','referencia')) not null,
  lat double precision,
  lng double precision,
  reference_point_id uuid references public.reference_points(id),
  description text,
  status text check (status in ('nuevo','en_atencion','cerrado')) not null default 'nuevo',
  assigned_to uuid references public.users(id),
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
create table if not exists public.incident_attachments (
  id uuid primary key default uuid_generate_v4(),
  incident_id uuid references public.incidents(id) on delete cascade,
  url text not null,
  type text check (type in ('foto','audio')) not null,
  created_at timestamptz not null default now()
);
