# Final MVP Supabase Database Design — Clean Reference

**Project:** Rule-Based Wardrobe Recommendation and Donation Decision Support System  
**Database:** Supabase PostgreSQL + Supabase Auth + Supabase Storage  
**Scope:** MVP only  
**Status:** Clean database reference based on locked database decisions

---

## 1. Final MVP Table List

Only these tables are needed for the MVP:

| Table | Purpose |
|---|---|
| `profiles` | Stores app-specific user settings linked to Supabase Auth. |
| `items` | Stores each wardrobe item and all rule-engine summary data. |
| `item_events` | Stores important item actions: worn and skipped. |
| `outfit_logs` | Stores outfits that were actually logged/worn. |
| `outfit_log_items` | Stores the items inside each logged outfit. |

Do **not** create these for MVP:

| Removed / Not Created | Reason |
|---|---|
| `users` | Supabase already has `auth.users`; use `profiles` instead. |
| `wear_history` | Renamed to `item_events` because it stores both worn and skipped events. |
| `saved_outfits` | Saved outfits are out of MVP scope. |
| `saved_outfit_items` | Saved outfits are out of MVP scope. |
| `donation_candidates` | Donation candidates are computed from item data and rules. |
| `insight_results` | Insights are computed from item data and events. |
| `notification_logs` | Notifications are local-only for MVP. |

---

## 2. Supabase Auth and Profile Structure

Supabase Auth handles login accounts through:

```text
auth.users
```

The app should not create its own login table. Instead, create:

```text
profiles
```

Relationship:

```text
auth.users.id → profiles.id
```

---

## 3. `profiles` Table

**Purpose:** Stores app settings for each authenticated user.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key. References `auth.users.id`. |
| `email` | text | User email copied from Supabase Auth for display/debugging. |
| `display_name` | text / nullable | Optional name for greeting/profile display. |
| `style_preferences` | jsonb | Stores preferred and disliked colours for Preference Score. |
| `laundry_cycle_days` | integer | Number of days before laundry auto-return. Default `3`. |
| `recommendation_mode` | text | `BALANCED` or `PURE_ROTATION`. |
| `created_at` | timestamptz | Profile creation time. |
| `updated_at` | timestamptz | Last profile/settings update time. |

---

## 4. `items` Table

**Purpose:** Main wardrobe item table. Stores item details, status, initial history, and rule-engine summary fields.

### 4.1 Identity and Ownership

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key. |
| `user_id` | uuid | References `profiles.id`. Owner of the item. |
| `image_path` | text | Supabase Storage path for the clothing photo. |
| `name` | text | Item name shown to user. |
| `created_at` | timestamptz | Row creation time. |
| `updated_at` | timestamptz | Last item update time. |

### 4.2 Item Metadata

| Field | Type | Notes |
|---|---|---|
| `category` | text | `TOP`, `BOTTOM`, `OUTERWEAR`, `FOOTWEAR`, or `OTHERS`. |
| `type` | text | Display type such as T-shirt, jeans, hoodie, sneakers. |
| `color_tags` | text[] | Item colours. First colour is the primary colour. |
| `occasion_tags` | text[] | Suitable occasions: `CASUAL`, `WORK`, `ACTIVE`, `RELAX`. |
| `formality_level` | integer | 1–5 formality scale used by outfit formality rules. |
| `condition` | integer | 1–5 item condition. Condition 1 is not recommendable. |
| `condition_review_mode` | text | `AUTO` or `MANUAL`. Controls condition degradation behaviour. |
| `condition_next_drop` | integer / nullable | Next wear count threshold for automatic condition drop. Null if not applicable. |
| `is_favorite` | boolean | Used only inside Preference Score. |
| `status` | text | Current item status. Controls availability and visibility. |

### 4.3 Initial History Fields

These fields handle items the user already owned before adding them to the app.

| Field | Type | Notes |
|---|---|---|
| `date_added` | date | Date the item was added into the app. Do not backdate this. |
| `is_new_item` | boolean | True only for brand-new, never-worn items. Used by New Item Boost. |
| `initial_history_type` | text | `BRAND_NEW`, `ALREADY_OWNED_WORN`, or `ALREADY_OWNED_UNWORN`. |
| `initial_last_worn_option` | text / nullable | Original approximate last-worn selection. Preserved for edit/review clarity. |
| `initial_wear_count_option` | text / nullable | Original approximate wear-count selection. Used by WFSS unknown-history logic. |
| `initial_owned_duration_option` | text / nullable | Original approximate owned-duration selection. Preserved for edit/review clarity. |
| `initial_usage_age_days` | integer | Estimated days owned before app. Used by WFSS. |
| `wear_count_unknown` | boolean | True when initial wear count was unknown. Becomes false after real wear log. |
| `last_worn_unknown` | boolean | True when initial last worn was unknown. Becomes false after real wear log. |

### 4.4 Rule-Engine Summary Fields

| Field | Type | Notes |
|---|---|---|
| `wear_count` | integer | Total worn count. Used by WFSS, Insights, and item detail. |
| `last_worn_date` | date / nullable | Latest worn date. Used by TDS and long-unworn rules. |
| `skip_count` | integer | Total explicit skip count. Used by SPS, Insights, and donation review. |

### 4.5 Status and Donation Support Fields

| Field | Type | Notes |
|---|---|---|
| `laundry_started_at` | date / nullable | Set when item status changes to `LAUNDRY`. Used for auto-return. |
| `kept_until` | date / nullable | Suppresses item from donation candidates until this date. |
| `donated_at` | date / nullable | Set when item status changes to `DONATED`. |

### 4.6 Removed from `items`

| Field | Decision |
|---|---|
| `purchase_price` | Removed from MVP. CPW is out of MVP scope. |
| `season_tag` | Not needed. Season/weather rules are out of MVP. |
| `brand`, `material`, `size`, `notes` | Not needed by current rule engine. |
| Stored score fields | Do not store TDS, SPS, WFSS, NIBS, PS, FRS, OutfitScore, or donation score. Compute at runtime. |

---

## 5. `item_events` Table

**Purpose:** Stores important item-level actions. This replaces the old `WEAR_HISTORY` table.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key. |
| `user_id` | uuid | References `profiles.id`. Owner of the event. |
| `item_id` | uuid | References `items.id`. Item involved in the event. |
| `event_type` | text | `WORN` or `SKIPPED`. |
| `source` | text | Where the action happened: `DAILY_ROTATION`, `OUTFIT_GENERATOR`, `ITEM_DETAIL`, or `MANUAL`. |
| `occasion` | text / nullable | Occasion context if available. |
| `outfit_log_id` | uuid / nullable | References `outfit_logs.id` when event comes from a logged outfit. |
| `event_at` | timestamptz | Time the action happened. Replaces old `worn_at`. |

### Event Behaviour

When an item is worn:

```text
items.wear_count += 1
items.last_worn_date = today
items.wear_count_unknown = false
items.last_worn_unknown = false
insert item_events row with event_type = WORN
```

When an item is skipped:

```text
items.skip_count += 1
insert item_events row with event_type = SKIPPED
```

---

## 6. `outfit_logs` Table

**Purpose:** Stores outfits that were actually logged/worn by the user.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key. |
| `user_id` | uuid | References `profiles.id`. Owner of the outfit log. |
| `occasion` | text / nullable | Occasion used when outfit was logged. |
| `outfit_score` | numeric / nullable | Stored only if the outfit came from the generator. Optional for history display. |
| `source` | text | `OUTFIT_GENERATOR` or `MANUAL`. |
| `logged_at` | timestamptz | Time the outfit was logged/worn. |

### Removed from `outfit_logs`

| Field | Decision |
|---|---|
| `color_score` | Removed from storage. Colour compatibility is computed during outfit generation only. |
| `created_at` | Not needed for MVP because `logged_at` is enough. |

---

## 7. `outfit_log_items` Table

**Purpose:** Connects each logged outfit to the items worn in that outfit.

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key. |
| `user_id` | uuid | References `profiles.id`. Added for easier RLS and ownership safety. |
| `outfit_log_id` | uuid | References `outfit_logs.id`. |
| `item_id` | uuid | References `items.id`. |
| `layer_type` | text | Outfit layer: `TOP`, `BOTTOM`, `OUTERWEAR`, or `SHOES`. |

Note: `layer_type` is the outfit slot, not the item category. Shoe items use `item.category = FOOTWEAR` but `layer_type = SHOES`.

---

## 8. Runtime-Only Values

Do not store these in the database. Calculate them when needed.

| Runtime Value | Based On |
|---|---|
| `days_since_worn` | `last_worn_date` |
| `days_since_added` | `date_added` |
| `skip_ratio` | `wear_count`, `skip_count` |
| `usage_period_days` | `initial_usage_age_days`, `date_added` |
| `wear_rate` | `wear_count`, `usage_period_days` |
| `TDS` | `last_worn_date`, `date_added`, category count |
| `SPS` | `wear_count`, `skip_count` |
| `WFSS` | `wear_count`, `initial_usage_age_days`, unknown flags |
| `NIBS` | `is_new_item`, `wear_count`, `date_added` |
| `PS` | `is_favorite`, `color_tags`, `style_preferences` |
| `FRS` | TDS, SPS, WFSS, NIBS, PS |
| `ColorCompatibilityScore` | Primary colours of outfit items |
| `OutfitScore` | Average item FRS + colour compatibility |
| Donation candidate status | Item data + donation rules |
| Insight sections | Item data + item events |

---

## 9. Allowed Values / Constraints

### Core Enums / Checks

```text
category: TOP, BOTTOM, OUTERWEAR, FOOTWEAR, OTHERS
status: IN_WARDROBE, LAUNDRY, LENT, STORED, DONATED, DELETED
occasion: CASUAL, WORK, ACTIVE, RELAX
recommendation_mode: BALANCED, PURE_ROTATION
condition_review_mode: AUTO, MANUAL
initial_history_type: BRAND_NEW, ALREADY_OWNED_WORN, ALREADY_OWNED_UNWORN
event_type: WORN, SKIPPED
item_event_source: DAILY_ROTATION, OUTFIT_GENERATOR, ITEM_DETAIL, MANUAL
outfit_log_source: OUTFIT_GENERATOR, MANUAL
layer_type: TOP, BOTTOM, OUTERWEAR, SHOES
```

### Numeric Checks

```text
condition BETWEEN 1 AND 5
formality_level BETWEEN 1 AND 5
wear_count >= 0
skip_count >= 0
initial_usage_age_days >= 0
laundry_cycle_days >= 1
```

---

## 10. Relationships

```text
auth.users.id
  → profiles.id

profiles.id
  → items.user_id
  → item_events.user_id
  → outfit_logs.user_id
  → outfit_log_items.user_id

items.id
  → item_events.item_id
  → outfit_log_items.item_id

outfit_logs.id
  → outfit_log_items.outfit_log_id
  → item_events.outfit_log_id (nullable)
```

---

## 11. RLS Rule Summary

Enable Row Level Security on all public tables.

Basic rule:

```text
Users can only read, insert, update, or delete rows where user_id = auth.uid().
```

For `profiles`:

```text
Users can only access the profile row where id = auth.uid().
```

For child tables such as `item_events` and `outfit_log_items`, RLS should also prevent linking to another user's item or outfit log.

---

## 12. Supabase Storage

Use Supabase Storage for clothing photos.

```text
Bucket: wardrobe-items
items.image_path = storage path to item photo
```

Do not store image files directly in PostgreSQL tables.

Recommended path pattern:

```text
{user_id}/{item_id}/main.jpg
```

---

## 13. Required Rename Updates from Old Rule Engine MD

| Old Name / Reference | Final Name / Reference |
|---|---|
| `USERS` | `profiles` |
| `WEAR_HISTORY` | `item_events` |
| `worn_at` | `event_at` |
| `WEAR_HISTORY.event_type` | `item_events.event_type` |
| latest `WEAR_HISTORY.worn_at` | latest `item_events.event_at WHERE event_type = WORN` |
| insert `WEAR_HISTORY` row | insert `item_events` row |
| `OUTFIT_LOGS.color_score` | removed |
| `purchase_price` | removed |
| CPW / Cost Per Wear | out of MVP |

---

## 14. Final MVP Schema Summary

```text
profiles
items
item_events
outfit_logs
outfit_log_items
```

This database supports:

```text
Wardrobe CRUD
Daily Rotation
Outfit Generator
Log Wear
Skip Item / Skip Outfit
Outfit History
Donation Decision Support
Insights
Laundry Auto-Return
Rule-Based Explanations
Supabase Auth Ownership
Supabase Storage Item Photos
```
