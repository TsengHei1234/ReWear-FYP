-- ReWear MVP — core schema (Database Reference §3–§10).
-- Postgres 17: gen_random_uuid() is built-in (no extension needed).

-- Shared trigger to keep updated_at fresh.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ── profiles ───────────────────────────────────────────────────
-- App settings per authenticated user. id == auth.users.id.
create table public.profiles (
  id                  uuid primary key references auth.users(id) on delete cascade,
  email               text,
  display_name        text,
  style_preferences   jsonb       not null default '{"preferred_colours": [], "disliked_colours": []}'::jsonb,
  laundry_cycle_days  integer     not null default 3   check (laundry_cycle_days >= 1),
  recommendation_mode text        not null default 'BALANCED'
                                   check (recommendation_mode in ('BALANCED','PURE_ROTATION')),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ── items ──────────────────────────────────────────────────────
create table public.items (
  id                            uuid primary key default gen_random_uuid(),
  user_id                       uuid not null references public.profiles(id) on delete cascade,
  image_path                    text,
  name                          text not null,
  -- metadata
  category                      text not null
                                check (category in ('TOP','BOTTOM','OUTERWEAR','FOOTWEAR','OTHERS')),
  type                          text not null,
  color_tags                    text[] not null check (cardinality(color_tags) >= 1),
  occasion_tags                 text[] not null default '{}'
                                check (occasion_tags <@ array['CASUAL','WORK','ACTIVE','RELAX']::text[]),
  formality_level               integer not null check (formality_level between 1 and 5),
  condition                     integer not null default 5 check (condition between 1 and 5),
  condition_review_mode         text not null default 'AUTO'
                                check (condition_review_mode in ('AUTO','MANUAL')),
  condition_next_drop           integer,
  is_favorite                   boolean not null default false,
  status                        text not null default 'IN_WARDROBE'
                                check (status in ('IN_WARDROBE','LAUNDRY','LENT','STORED','DONATED','DELETED')),
  -- initial history
  date_added                    date not null default current_date,
  is_new_item                   boolean not null default false,
  initial_history_type          text not null
                                check (initial_history_type in ('BRAND_NEW','ALREADY_OWNED_WORN','ALREADY_OWNED_UNWORN')),
  initial_last_worn_option      text,
  initial_wear_count_option     text,
  initial_owned_duration_option text,
  initial_usage_age_days        integer not null default 0 check (initial_usage_age_days >= 0),
  wear_count_unknown            boolean not null default false,
  last_worn_unknown             boolean not null default false,
  -- rule-engine summary
  wear_count                    integer not null default 0 check (wear_count >= 0),
  last_worn_date                date,
  skip_count                    integer not null default 0 check (skip_count >= 0),
  -- status / donation support
  laundry_started_at            date,
  kept_until                    date,
  donated_at                    date,
  created_at                    timestamptz not null default now(),
  updated_at                    timestamptz not null default now()
);

create index idx_items_user_id on public.items (user_id);
create index idx_items_user_status on public.items (user_id, status);

create trigger trg_items_updated_at
  before update on public.items
  for each row execute function public.set_updated_at();

-- ── outfit_logs ────────────────────────────────────────────────
create table public.outfit_logs (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles(id) on delete cascade,
  occasion     text check (occasion in ('CASUAL','WORK','ACTIVE','RELAX')),
  outfit_score numeric,
  source       text not null check (source in ('OUTFIT_GENERATOR','MANUAL')),
  logged_at    timestamptz not null default now()
);

create index idx_outfit_logs_user_id on public.outfit_logs (user_id);

-- ── item_events ────────────────────────────────────────────────
-- WORN / SKIPPED actions. outfit_log_id links events from a logged outfit (C8).
create table public.item_events (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  item_id       uuid not null references public.items(id) on delete cascade,
  event_type    text not null check (event_type in ('WORN','SKIPPED')),
  source        text not null
                check (source in ('DAILY_ROTATION','OUTFIT_GENERATOR','ITEM_DETAIL','MANUAL')),
  occasion      text check (occasion in ('CASUAL','WORK','ACTIVE','RELAX')),
  outfit_log_id uuid references public.outfit_logs(id) on delete set null,
  event_at      timestamptz not null default now()
);

create index idx_item_events_user_id on public.item_events (user_id);
create index idx_item_events_item_id on public.item_events (item_id);

-- ── outfit_log_items ───────────────────────────────────────────
-- layer_type is the outfit SLOT, not the item category (FOOTWEAR → SHOES).
create table public.outfit_log_items (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  outfit_log_id uuid not null references public.outfit_logs(id) on delete cascade,
  item_id       uuid not null references public.items(id) on delete cascade,
  layer_type    text not null check (layer_type in ('TOP','BOTTOM','OUTERWEAR','SHOES'))
);

create index idx_outfit_log_items_log_id on public.outfit_log_items (outfit_log_id);
create index idx_outfit_log_items_item_id on public.outfit_log_items (item_id);
