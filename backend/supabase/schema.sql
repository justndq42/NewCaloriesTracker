create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create table if not exists public.profiles (
    user_id uuid primary key references auth.users(id) on delete cascade,
    display_name text not null default '',
    gender text not null default 'unspecified',
    age int check (age between 1 and 120),
    height_cm numeric(5, 1) check (height_cm between 50 and 260),
    current_weight_kg numeric(5, 1) check (current_weight_kg between 20 and 400),
    target_weight_kg numeric(5, 1) check (target_weight_kg between 20 and 400),
    goal_type text not null default 'maintain' check (goal_type in ('lose', 'maintain', 'gain')),
    activity_level text not null default 'moderate',
    joined_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.nutrition_goals (
    user_id uuid primary key references auth.users(id) on delete cascade,
    target_calories int not null check (target_calories between 800 and 8000),
    protein_percent int not null check (protein_percent between 0 and 100),
    carbs_percent int not null check (carbs_percent between 0 and 100),
    fat_percent int not null check (fat_percent between 0 and 100),
    bmr int check (bmr between 500 and 6000),
    tdee int check (tdee between 500 and 8000),
    calorie_delta int default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint nutrition_goals_macro_total check (protein_percent + carbs_percent + fat_percent = 100)
);

create table if not exists public.custom_foods (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    client_id text,
    name text not null,
    calories int not null check (calories >= 0),
    protein_g numeric(7, 2) not null default 0 check (protein_g >= 0),
    carbs_g numeric(7, 2) not null default 0 check (carbs_g >= 0),
    fat_g numeric(7, 2) not null default 0 check (fat_g >= 0),
    unit text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.diary_entries (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    client_id text,
    custom_food_id uuid references public.custom_foods(id) on delete set null,
    food_name text not null,
    calories int not null check (calories >= 0),
    protein_g numeric(7, 2) not null default 0 check (protein_g >= 0),
    carbs_g numeric(7, 2) not null default 0 check (carbs_g >= 0),
    fat_g numeric(7, 2) not null default 0 check (fat_g >= 0),
    unit text not null,
    meal text not null,
    eaten_at timestamptz not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.water_logs (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    log_date date not null,
    consumed_ml int not null default 0 check (consumed_ml >= 0),
    goal_ml int not null default 3000 check (goal_ml between 500 and 10000),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id, log_date)
);

create table if not exists public.weight_logs (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    client_id text,
    weight_kg numeric(5, 1) not null check (weight_kg between 20 and 400),
    recorded_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table public.custom_foods
    add column if not exists client_id text;

alter table public.diary_entries
    add column if not exists client_id text;

alter table public.weight_logs
    add column if not exists client_id text;

create unique index if not exists custom_foods_user_id_client_id_key
    on public.custom_foods (user_id, client_id);

create unique index if not exists diary_entries_user_id_client_id_key
    on public.diary_entries (user_id, client_id);

create unique index if not exists weight_logs_user_id_client_id_key
    on public.weight_logs (user_id, client_id);

create index if not exists custom_foods_user_id_created_at_idx
    on public.custom_foods (user_id, created_at desc);

create index if not exists diary_entries_user_id_eaten_at_idx
    on public.diary_entries (user_id, eaten_at desc);

create index if not exists water_logs_user_id_log_date_idx
    on public.water_logs (user_id, log_date desc);

create index if not exists weight_logs_user_id_recorded_at_idx
    on public.weight_logs (user_id, recorded_at desc);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists nutrition_goals_set_updated_at on public.nutrition_goals;
create trigger nutrition_goals_set_updated_at
before update on public.nutrition_goals
for each row execute function public.set_updated_at();

drop trigger if exists custom_foods_set_updated_at on public.custom_foods;
create trigger custom_foods_set_updated_at
before update on public.custom_foods
for each row execute function public.set_updated_at();

drop trigger if exists diary_entries_set_updated_at on public.diary_entries;
create trigger diary_entries_set_updated_at
before update on public.diary_entries
for each row execute function public.set_updated_at();

drop trigger if exists water_logs_set_updated_at on public.water_logs;
create trigger water_logs_set_updated_at
before update on public.water_logs
for each row execute function public.set_updated_at();

drop trigger if exists weight_logs_set_updated_at on public.weight_logs;
create trigger weight_logs_set_updated_at
before update on public.weight_logs
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.nutrition_goals enable row level security;
alter table public.custom_foods enable row level security;
alter table public.diary_entries enable row level security;
alter table public.water_logs enable row level security;
alter table public.weight_logs enable row level security;

drop policy if exists "Users can manage their own profile" on public.profiles;
create policy "Users can manage their own profile"
on public.profiles
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can manage their own nutrition goals" on public.nutrition_goals;
create policy "Users can manage their own nutrition goals"
on public.nutrition_goals
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can manage their own custom foods" on public.custom_foods;
create policy "Users can manage their own custom foods"
on public.custom_foods
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can manage their own diary entries" on public.diary_entries;
create policy "Users can manage their own diary entries"
on public.diary_entries
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can manage their own water logs" on public.water_logs;
create policy "Users can manage their own water logs"
on public.water_logs
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can manage their own weight logs" on public.weight_logs;
create policy "Users can manage their own weight logs"
on public.weight_logs
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
