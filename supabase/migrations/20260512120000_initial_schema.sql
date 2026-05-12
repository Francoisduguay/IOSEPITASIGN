create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  role text not null default 'student' check (role in ('student', 'teacher', 'admin')),
  first_name text,
  last_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.student_cards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  tag_hash text not null unique,
  label text,
  created_at timestamptz not null default now()
);

create table if not exists public.courses (
  id text primary key,
  title text not null,
  room text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.attendance_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  course_id text not null references public.courses(id) on delete cascade,
  tag_hash text not null,
  tag_type text,
  technologies text[] not null default '{}',
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  course_id text not null references public.courses(id) on delete cascade,
  token_id uuid not null unique references public.attendance_tokens(id) on delete restrict,
  status text not null default 'signed' check (status in ('signed', 'late', 'rejected', 'manual_teacher')),
  signature_storage_path text not null,
  signature_metrics jsonb not null,
  signed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.student_cards enable row level security;
alter table public.courses enable row level security;
alter table public.attendance_tokens enable row level security;
alter table public.attendance_records enable row level security;

create or replace function public.is_teacher_or_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role in ('teacher', 'admin')
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles' and policyname = 'profiles self read'
  ) then
    create policy "profiles self read"
    on public.profiles for select
    using (id = auth.uid() or public.is_teacher_or_admin());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles' and policyname = 'profiles admin write'
  ) then
    create policy "profiles admin write"
    on public.profiles for all
    using (public.is_admin())
    with check (public.is_admin());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'student_cards' and policyname = 'student cards admin read'
  ) then
    create policy "student cards admin read"
    on public.student_cards for select
    using (public.is_admin());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'student_cards' and policyname = 'student cards admin write'
  ) then
    create policy "student cards admin write"
    on public.student_cards for all
    using (public.is_admin())
    with check (public.is_admin());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'courses' and policyname = 'courses signed in read'
  ) then
    create policy "courses signed in read"
    on public.courses for select
    using (auth.uid() is not null);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'courses' and policyname = 'courses teacher write'
  ) then
    create policy "courses teacher write"
    on public.courses for all
    using (public.is_teacher_or_admin())
    with check (public.is_teacher_or_admin());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'attendance_records' and policyname = 'attendance records owner or staff read'
  ) then
    create policy "attendance records owner or staff read"
    on public.attendance_records for select
    using (user_id = auth.uid() or public.is_teacher_or_admin());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'attendance_tokens' and policyname = 'attendance tokens no direct access'
  ) then
    create policy "attendance tokens no direct access"
    on public.attendance_tokens for select
    using (false);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'attendance_records' and policyname = 'attendance records no direct write'
  ) then
    create policy "attendance records no direct write"
    on public.attendance_records for insert
    with check (false);
  end if;
end $$;

insert into storage.buckets (id, name, public)
values ('signatures', 'signatures', false)
on conflict (id) do nothing;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'signature owner read'
  ) then
    create policy "signature owner read"
    on storage.objects for select
    using (
      bucket_id = 'signatures'
      and auth.uid()::text = (storage.foldername(name))[1]
    );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'signature no direct write'
  ) then
    create policy "signature no direct write"
    on storage.objects for insert
    with check (false);
  end if;
end $$;
